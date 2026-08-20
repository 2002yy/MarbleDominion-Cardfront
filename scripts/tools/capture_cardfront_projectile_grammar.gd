extends SceneTree

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const ProjectileTypeScript = preload("res://scripts/cardfront/volley/CardfrontProjectileType.gd")
const MapRegistryScript = preload("res://scripts/cardfront/maps/CardfrontMapRegistry.gd")

const CAPTURE_EXTENT := Vector2i(40, 50)
const DEFAULT_VIEWPORT := Vector2i(1120, 720)
const DEFAULT_OUTPUT_DIR := "res://artifacts/projectile-grammar-pg1"
const DIAGNOSTIC_COPIES_PER_PAIR: int = 1
const VOLLEY_COPIES_PER_PAIR: int = 3
const SCREEN_MARGIN_PX: float = 6.0
const DIAGNOSTIC_MIN_SEPARATION_PX: float = 14.0

var _errors: Array[String] = []


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("PG1 capture requires a rendering display; omit --headless")
		quit(1)
		return

	var capture_viewport := _capture_viewport()
	var presentation_scale := _presentation_scale()
	var capture_label := _capture_label(capture_viewport, presentation_scale)
	var output_dir := _output_dir()
	root.size = capture_viewport
	GameConfig.reset_runtime_defaults()
	GameConfig.set_quality_by_name("medium")

	var scene: PackedScene = load("res://scenes/Main.tscn")
	var main = scene.instantiate()
	root.add_child(main)
	await process_frame
	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_extent = CAPTURE_EXTENT
	main.selected_cardfront_map_id = MapRegistryScript.DEFAULT_DUEL_MAP_ID
	main._start_game(CAPTURE_EXTENT, true, false)
	Input.warp_mouse(Vector2(float(capture_viewport.x - 8), float(capture_viewport.y) * 0.5))
	await _flush(6)

	var view = main.runtime.orthographic_arena_view
	if view == null or not is_instance_valid(view):
		push_error("PG1 capture could not resolve CardfrontOrthographicArenaView")
		quit(2)
		return
	view.set_presentation_scale(presentation_scale, false)
	var region_detail_mode := OS.get_environment("CARDFRONT_PG1_REGION_DETAIL_MODE").strip_edges().to_lower()
	_configure_region_detail_mode(main, view, region_detail_mode)
	await _flush(3)

	var absolute_output_dir := _absolute_output_dir(output_dir)
	var dir_error := DirAccess.make_dir_recursive_absolute(absolute_output_dir)
	if dir_error != OK:
		push_error("PG1 capture could not create output directory: %s" % absolute_output_dir)
		quit(3)
		return

	var manifest: Dictionary = {
		"experiment": "P0-PG1 Projectile Grammar Prototype",
		"status": "PENDING",
		"commit_sha": OS.get_environment("CARDFRONT_PG1_COMMIT_SHA").strip_edges(),
		"working_tree_dirty": OS.get_environment("CARDFRONT_PG1_WORKTREE_DIRTY") == "true",
		"working_tree_changes": _working_tree_changes(),
		"map_id": MapRegistryScript.DEFAULT_DUEL_MAP_ID,
		"grid_extent": [CAPTURE_EXTENT.x, CAPTURE_EXTENT.y],
		"viewport": [capture_viewport.x, capture_viewport.y],
		"presentation_scale": presentation_scale,
		"quality": "medium",
		"capture_label": capture_label,
		"region_detail_mode": region_detail_mode,
		"captures": [],
	}

	_spawn_diagnostic_projectiles(main)
	view.set_projectile_trails_visible_for_capture(false)
	await _flush(3)
	_capture_scenario(
		main,
		view,
		manifest,
		absolute_output_dir,
		capture_label,
		"trail-off",
		DIAGNOSTIC_COPIES_PER_PAIR,
		false,
		true
	)

	view.set_projectile_trails_visible_for_capture(true)
	await _flush(3)
	_capture_scenario(
		main,
		view,
		manifest,
		absolute_output_dir,
		capture_label,
		"trail-on",
		DIAGNOSTIC_COPIES_PER_PAIR,
		true,
		true
	)

	_spawn_volley_projectiles(main)
	view.set_projectile_trails_visible_for_capture(true)
	await _flush(3)
	_capture_scenario(
		main,
		view,
		manifest,
		absolute_output_dir,
		capture_label,
		"volley",
		VOLLEY_COPIES_PER_PAIR,
		true,
		false
	)

	manifest["status"] = "PASS" if _errors.is_empty() else "FAIL"
	manifest["errors"] = _errors.duplicate()
	var manifest_path := absolute_output_dir.path_join("pg1-%s-manifest.json" % capture_label)
	var manifest_error := _write_json(manifest_path, manifest)
	if manifest_error != OK:
		_errors.append("manifest write failed: %s" % error_string(manifest_error))

	if _errors.is_empty():
		print("[CardfrontProjectileGrammarCapture] PASS %s" % capture_label)
		print("[CardfrontProjectileGrammarCapture] Manifest: %s" % manifest_path)
	else:
		for message in _errors:
			push_error(message)
		print("[CardfrontProjectileGrammarCapture] FAIL %s" % capture_label)

	main.runtime.bullet_pool.clear_active()
	main.queue_free()
	await _flush(2)
	quit(0 if _errors.is_empty() else 4)


func _configure_region_detail_mode(main, view, mode: String) -> void:
	if mode == "review":
		view.set_stronghold_labels_visible(true)
		return
	if mode != "pinned":
		return
	var panel = main.runtime.region_info_panel
	if panel == null or not is_instance_valid(panel):
		_errors.append("region detail mode requested without a live info panel")
		return
	var region_ids: Array = main.runtime.region_map.get_controllable_region_ids()
	if region_ids.is_empty():
		_errors.append("region detail mode could not find a controllable region")
		return
	var region_cells: Array = main.runtime.region_map.get_region_cells(int(region_ids[0]))
	if region_cells.is_empty() or not panel.toggle_pinned_cell(region_cells[0]):
		_errors.append("region detail mode could not pin the first controllable region")


func _spawn_diagnostic_projectiles(main) -> void:
	main.runtime.bullet_pool.clear_active()
	var battlefield = main.runtime.battlefield
	var pixel_extent: Vector2 = battlefield.get_pixel_extent()
	var types: Array[String] = _projectile_types()
	for faction_index in range(2):
		var faction_id: int = _faction_for_index(faction_index)
		var y_ratio: float = 0.62 if faction_id == CardfrontRulesScript.PLAYER_FACTION else 0.38
		var direction := Vector2.UP if faction_id == CardfrontRulesScript.PLAYER_FACTION else Vector2.DOWN
		for type_index in range(types.size()):
			var x_ratio: float = 0.30 + float(type_index) * 0.20
			var bullet = main.runtime.bullet_pool.spawn_bullet(
				faction_id,
				battlefield.global_position + Vector2(pixel_extent.x * x_ratio, pixel_extent.y * y_ratio),
				direction,
				battlefield,
				main.runtime.turrets,
				1,
				0,
				{"projectile_type": types[type_index]}
			)
			bullet.set_physics_process(false)


func _spawn_volley_projectiles(main) -> void:
	main.runtime.bullet_pool.clear_active()
	var battlefield = main.runtime.battlefield
	var pixel_extent: Vector2 = battlefield.get_pixel_extent()
	var types: Array[String] = _projectile_types()
	for faction_index in range(2):
		var faction_id: int = _faction_for_index(faction_index)
		var direction_sign: float = -1.0 if faction_id == CardfrontRulesScript.PLAYER_FACTION else 1.0
		var base_y_ratio: float = 0.54 if faction_id == CardfrontRulesScript.PLAYER_FACTION else 0.46
		for type_index in range(types.size()):
			for copy_index in range(VOLLEY_COPIES_PER_PAIR):
				var x_ratio: float = (
					0.28
					+ float(type_index) * 0.22
					+ float(copy_index - 1) * 0.035
				)
				var y_ratio: float = base_y_ratio - direction_sign * float(copy_index - 1) * 0.025
				var direction := Vector2(
					0.07 * float(type_index - 1) + 0.025 * float(copy_index - 1),
					direction_sign
				).normalized()
				var bullet = main.runtime.bullet_pool.spawn_bullet(
					faction_id,
					battlefield.global_position + Vector2(pixel_extent.x * x_ratio, pixel_extent.y * y_ratio),
					direction,
					battlefield,
					main.runtime.turrets,
					1,
					0,
					{"projectile_type": types[type_index]}
				)
				# This is a real BulletPool volley fixture, frozen at the evidence frame
				# so contact/recycle timing cannot silently change the type matrix.
				bullet.set_physics_process(false)


func _capture_scenario(
	main,
	view,
	manifest: Dictionary,
	absolute_output_dir: String,
	capture_label: String,
	scenario: String,
	expected_copies_per_pair: int,
	expect_trails: bool,
	require_separation: bool
) -> void:
	view._process(0.0)
	var validation := _validate_scenario(
		main,
		view,
		scenario,
		expected_copies_per_pair,
		expect_trails,
		require_separation
	)
	var file_name := "pg1-%s-%s.png" % [capture_label, scenario]
	var absolute_path := absolute_output_dir.path_join(file_name)
	var save_error := _save_root_png(absolute_path)
	if save_error != OK:
		var save_message := "%s screenshot write failed: %s" % [scenario, error_string(save_error)]
		_errors.append(save_message)
		(validation.get("errors", []) as Array).append(save_message)
	validation["file"] = file_name
	validation["absolute_path"] = absolute_path
	(manifest["captures"] as Array).append(validation)


func _validate_scenario(
	main,
	view,
	scenario: String,
	expected_copies_per_pair: int,
	expect_trails: bool,
	require_separation: bool
) -> Dictionary:
	var scenario_errors: Array[String] = []
	var active: Array = main.runtime.bullet_pool.get_active_bullets()
	var visuals: Array[Dictionary] = view.get_projectile_visuals_for_test()
	var expected_total: int = 2 * _projectile_types().size() * expected_copies_per_pair
	if active.size() != expected_total:
		scenario_errors.append("%s expected %d active bullets, got %d" % [scenario, expected_total, active.size()])
	if visuals.size() != expected_total:
		scenario_errors.append("%s expected %d visible proxies, got %d" % [scenario, expected_total, visuals.size()])

	var counts: Dictionary = {}
	for bullet in active:
		var key := "%d:%s" % [int(bullet.faction_id), str(bullet.projectile_type)]
		counts[key] = int(counts.get(key, 0)) + 1
	for faction_index in range(2):
		var faction_id: int = _faction_for_index(faction_index)
		for projectile_type in _projectile_types():
			var key := "%d:%s" % [faction_id, projectile_type]
			if int(counts.get(key, 0)) != expected_copies_per_pair:
				scenario_errors.append(
					"%s expected %d instances for %s, got %d" % [
						scenario,
						expected_copies_per_pair,
						key,
						int(counts.get(key, 0)),
					]
				)

	var viewport_size: Vector2 = Vector2(view.world_viewport.size)
	var screen_positions: Array[Vector2] = []
	var suppression_seen: bool = false
	for visual in visuals:
		var screen_array: Array = visual.get("screen_position", []) as Array
		if screen_array.size() != 2:
			scenario_errors.append("%s visual is missing a screen position" % scenario)
			continue
		var screen_position := Vector2(float(screen_array[0]), float(screen_array[1]))
		screen_positions.append(screen_position)
		if (
			screen_position.x < SCREEN_MARGIN_PX
			or screen_position.y < SCREEN_MARGIN_PX
			or screen_position.x > viewport_size.x - SCREEN_MARGIN_PX
			or screen_position.y > viewport_size.y - SCREEN_MARGIN_PX
		):
			scenario_errors.append("%s projectile outside safe screen bounds at %s" % [scenario, screen_position])
		if bool(visual.get("trail_visible", false)) != expect_trails:
			scenario_errors.append("%s projectile trail visibility does not match the capture mode" % scenario)
		if not bool(visual.get("rim_matches_body_mesh", false)):
			scenario_errors.append("%s faction rim does not match the type body mesh" % scenario)
		if str(visual.get("projectile_type", "")) == ProjectileTypeScript.SUPPRESSION:
			suppression_seen = true
			if float(visual.get("footprint_aspect", 0.0)) < 2.15:
				scenario_errors.append("%s suppression footprint fell below the 2.2:1 prototype gate" % scenario)
	if not suppression_seen:
		scenario_errors.append("%s contains no visible suppression projectile" % scenario)

	if require_separation:
		for left_index in range(screen_positions.size()):
			for right_index in range(left_index + 1, screen_positions.size()):
				if screen_positions[left_index].distance_to(screen_positions[right_index]) < DIAGNOSTIC_MIN_SEPARATION_PX:
					scenario_errors.append("%s diagnostic projectiles overlap in screen space" % scenario)
					left_index = screen_positions.size()
					break

	for message in scenario_errors:
		_errors.append(message)
	return {
		"scenario": scenario,
		"status": "PASS" if scenario_errors.is_empty() else "FAIL",
		"active_count": active.size(),
		"visible_proxy_count": visuals.size(),
		"counts_by_faction_and_type": counts,
		"visuals": visuals,
		"errors": scenario_errors,
	}


func _projectile_types() -> Array[String]:
	return [
		ProjectileTypeScript.STANDARD,
		ProjectileTypeScript.SIEGE,
		ProjectileTypeScript.SUPPRESSION,
	]


func _faction_for_index(index: int) -> int:
	return CardfrontRulesScript.PLAYER_FACTION if index == 0 else CardfrontRulesScript.AI_FACTION


func _capture_viewport() -> Vector2i:
	var value := OS.get_environment("CARDFRONT_PG1_CAPTURE_VIEWPORT").strip_edges().to_lower()
	if value.is_empty():
		return DEFAULT_VIEWPORT
	var parts := value.split("x", false, 1)
	if parts.size() != 2:
		push_warning("Invalid CARDFRONT_PG1_CAPTURE_VIEWPORT=%s; using 1120x720" % value)
		return DEFAULT_VIEWPORT
	return Vector2i(maxi(320, int(parts[0])), maxi(320, int(parts[1])))


func _presentation_scale() -> float:
	var value := OS.get_environment("CARDFRONT_PG1_PRESENTATION_SCALE").strip_edges()
	if value.is_empty():
		return 1.12
	return clampf(float(value), 1.0, 1.20)


func _capture_label(capture_viewport: Vector2i, presentation_scale: float) -> String:
	var explicit_label := OS.get_environment("CARDFRONT_PG1_CAPTURE_LABEL").strip_edges()
	if not explicit_label.is_empty():
		return explicit_label
	return "%dx%d-scale-%d" % [
		capture_viewport.x,
		capture_viewport.y,
		roundi(presentation_scale * 100.0),
	]


func _output_dir() -> String:
	var value := OS.get_environment("CARDFRONT_PG1_OUTPUT_DIR").strip_edges()
	return DEFAULT_OUTPUT_DIR if value.is_empty() else value


func _working_tree_changes() -> Array[String]:
	var value := OS.get_environment("CARDFRONT_PG1_CHANGED_PATHS")
	if value.is_empty():
		return []
	var result: Array[String] = []
	for path_value in value.split("|", false):
		result.append(path_value)
	return result


func _absolute_output_dir(path_value: String) -> String:
	if path_value.begins_with("res://") or path_value.begins_with("user://"):
		return ProjectSettings.globalize_path(path_value)
	return path_value


func _save_root_png(absolute_path: String) -> int:
	var image := root.get_texture().get_image()
	if image == null:
		return ERR_UNAVAILABLE
	return image.save_png(absolute_path)


func _write_json(absolute_path: String, data: Dictionary) -> int:
	var file := FileAccess.open(absolute_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data, "\t") + "\n")
	file.close()
	return OK


func _flush(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame
