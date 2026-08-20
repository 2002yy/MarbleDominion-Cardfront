extends SceneTree

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const ProjectileTypeScript = preload("res://scripts/cardfront/volley/CardfrontProjectileType.gd")
const MapRegistryScript = preload("res://scripts/cardfront/maps/CardfrontMapRegistry.gd")

const CAPTURE_EXTENT := Vector2i(40, 50)
const DEFAULT_VIEWPORT := Vector2i(1120, 720)
const DEFAULT_OUTPUT_DIR := "res://artifacts/formal-tower-live"
const SCREEN_MARGIN_PX: float = 10.0

var _errors: Array[String] = []


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Formal Tower live capture requires a rendering display; omit --headless")
		quit(1)
		return

	var capture_viewport := _capture_viewport()
	var capture_label := _capture_label(capture_viewport)
	var output_dir := _absolute_output_dir(_output_dir())
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
	var entity_runtime = main.runtime.battlefield.capture_interceptor.entity_runtime
	if view == null or entity_runtime == null:
		push_error("Formal Tower live capture could not resolve presentation/runtime")
		quit(2)
		return
	view.set_presentation_scale(1.12, false)
	var fixture := _build_tower_fixture(entity_runtime)
	_spawn_projectile_matrix(main)
	await _flush(5)
	view._process(0.0)
	entity_runtime.tower_counter_fired.emit(str(fixture.get("player_id", "")), RulesScript.PLAYER_FACTION)
	await _flush(1)

	var dir_error := DirAccess.make_dir_recursive_absolute(output_dir)
	if dir_error != OK:
		push_error("Formal Tower live capture could not create output directory: %s" % output_dir)
		quit(3)
		return

	var logical_viewport := Vector2(root.content_scale_size)
	if logical_viewport.x <= 0.0 or logical_viewport.y <= 0.0:
		logical_viewport = Vector2(capture_viewport)
	var manifest := _validate_fixture(main, view, fixture, logical_viewport)
	manifest["capture_label"] = capture_label
	manifest["viewport"] = [capture_viewport.x, capture_viewport.y]
	manifest["logical_viewport"] = [logical_viewport.x, logical_viewport.y]
	manifest["presentation_scale"] = 1.12
	manifest["map_id"] = MapRegistryScript.DEFAULT_DUEL_MAP_ID
	manifest["grid_extent"] = [CAPTURE_EXTENT.x, CAPTURE_EXTENT.y]
	manifest["commit_sha"] = OS.get_environment("CARDFRONT_FT1_COMMIT_SHA").strip_edges()
	manifest["working_tree_dirty"] = OS.get_environment("CARDFRONT_FT1_WORKTREE_DIRTY") == "true"
	manifest["working_tree_changes"] = _working_tree_changes()

	var image_path := output_dir.path_join("formal-tower-live-%s.png" % capture_label)
	var image_error := _save_root_png(image_path)
	if image_error != OK:
		_errors.append("screenshot write failed: %s" % error_string(image_error))
	manifest["image"] = image_path.get_file()
	manifest["absolute_image_path"] = image_path
	manifest["status"] = "PASS" if _errors.is_empty() else "FAIL"
	manifest["errors"] = _errors.duplicate()
	var manifest_path := output_dir.path_join("formal-tower-live-%s-manifest.json" % capture_label)
	var manifest_error := _write_json(manifest_path, manifest)
	if manifest_error != OK:
		_errors.append("manifest write failed: %s" % error_string(manifest_error))

	if _errors.is_empty():
		print("[CardfrontFormalTowerLiveCapture] PASS %s" % capture_label)
		print("[CardfrontFormalTowerLiveCapture] Image: %s" % image_path)
	else:
		for message in _errors:
			push_error(message)
		print("[CardfrontFormalTowerLiveCapture] FAIL %s" % capture_label)

	main.runtime.bullet_pool.clear_active()
	main.queue_free()
	await _flush(2)
	quit(0 if _errors.is_empty() else 4)


func _build_tower_fixture(entity_runtime) -> Dictionary:
	var player_build: Dictionary = entity_runtime.build_or_upgrade_tower(
		RulesScript.PLAYER_FACTION,
		entity_runtime.TOWER_INTERCEPTOR
	)
	entity_runtime.build_or_upgrade_tower(RulesScript.PLAYER_FACTION, entity_runtime.TOWER_INTERCEPTOR)
	entity_runtime.build_or_upgrade_tower(RulesScript.PLAYER_FACTION, entity_runtime.TOWER_INTERCEPTOR)
	var ai_build: Dictionary = entity_runtime.build_or_upgrade_tower(
		RulesScript.AI_FACTION,
		entity_runtime.TOWER_INTERCEPTOR
	)
	entity_runtime.build_or_upgrade_tower(RulesScript.AI_FACTION, entity_runtime.TOWER_INTERCEPTOR)
	var player_tower = entity_runtime._find_owner_tower(RulesScript.PLAYER_FACTION, entity_runtime.TOWER_INTERCEPTOR)
	var ai_tower = entity_runtime._find_owner_tower(RulesScript.AI_FACTION, entity_runtime.TOWER_INTERCEPTOR)
	if player_tower != null:
		player_tower.hp = 2
		player_tower.configure_interceptor(3)
		player_tower.intercepts_remaining = 0
	if ai_tower != null:
		ai_tower.hp = 3
		ai_tower.configure_interceptor(2)
	entity_runtime._mark_visuals_dirty()
	return {
		"player_build_success": bool(player_build.get("success", false)),
		"ai_build_success": bool(ai_build.get("success", false)),
		"player_id": str(player_tower.entity_id) if player_tower != null else "",
		"ai_id": str(ai_tower.entity_id) if ai_tower != null else "",
		"player_level": int(player_tower.tower_level) if player_tower != null else 0,
		"ai_level": int(ai_tower.tower_level) if ai_tower != null else 0,
		"player_hp": int(player_tower.hp) if player_tower != null else -1,
		"ai_hp": int(ai_tower.hp) if ai_tower != null else -1,
	}


func _spawn_projectile_matrix(main) -> void:
	main.runtime.bullet_pool.clear_active()
	var battlefield = main.runtime.battlefield
	var pixel_extent: Vector2 = battlefield.get_pixel_extent()
	var types: Array[String] = [
		ProjectileTypeScript.STANDARD,
		ProjectileTypeScript.SIEGE,
		ProjectileTypeScript.SUPPRESSION,
	]
	for faction_index in range(2):
		var faction_id := RulesScript.PLAYER_FACTION if faction_index == 0 else RulesScript.AI_FACTION
		var y_ratio := 0.56 if faction_id == RulesScript.PLAYER_FACTION else 0.44
		var direction := Vector2.UP if faction_id == RulesScript.PLAYER_FACTION else Vector2.DOWN
		for type_index in range(types.size()):
			var bullet = main.runtime.bullet_pool.spawn_bullet(
				faction_id,
				battlefield.global_position + Vector2(pixel_extent.x * (0.32 + 0.18 * type_index), pixel_extent.y * y_ratio),
				direction,
				battlefield,
				main.runtime.turrets,
				1,
				0,
				{"projectile_type": types[type_index]}
			)
			bullet.set_physics_process(false)


func _validate_fixture(main, view, fixture: Dictionary, logical_viewport: Vector2) -> Dictionary:
	if not bool(fixture.get("player_build_success", false)):
		_errors.append("player Formal Tower build fixture failed")
	if not bool(fixture.get("ai_build_success", false)):
		_errors.append("AI Formal Tower build fixture failed")
	var player_id := str(fixture.get("player_id", ""))
	var ai_id := str(fixture.get("ai_id", ""))
	if view.get_turret_proxy_count_for_test() != 2:
		_errors.append("capture must retain both HQ proxies")
	if view.get_bridge_count_for_test() < 2:
		_errors.append("capture must retain both bridges/frontline crossings")
	if view.get_formal_tower_module_count_for_test(player_id) != 4:
		_errors.append("player Formal Tower must assemble four modules")
	if view.get_formal_tower_module_count_for_test(ai_id) != 4:
		_errors.append("AI Formal Tower must assemble four modules")
	if view.get_visible_bullet_proxy_count_for_test() != 6:
		_errors.append("capture must expose both factions and all three projectile types")
	if view.get_formal_tower_counter_event_count_for_test(player_id) != 1:
		_errors.append("player L3 Formal Tower must expose one explicit counter event")
	if view.get_formal_tower_counter_flash_count_for_test(player_id) != 1:
		_errors.append("player L3 Formal Tower must retain one muzzle flash at the evidence frame")
	var screen_positions := {
		"player": view.get_entity_screen_position_for_test(player_id),
		"ai": view.get_entity_screen_position_for_test(ai_id),
	}
	for faction: String in screen_positions:
		var point: Vector2 = screen_positions[faction]
		if (
			point.x < SCREEN_MARGIN_PX
			or point.y < SCREEN_MARGIN_PX
			or point.x > logical_viewport.x - SCREEN_MARGIN_PX
			or point.y > logical_viewport.y - SCREEN_MARGIN_PX
		):
			_errors.append("%s Formal Tower is outside safe screen bounds: %s" % [faction, point])
	return {
		"status": "PENDING",
		"fixture": fixture,
		"hq_proxy_count": view.get_turret_proxy_count_for_test(),
		"bridge_count": view.get_bridge_count_for_test(),
		"visible_projectile_count": view.get_visible_bullet_proxy_count_for_test(),
		"player_counter_event_count": view.get_formal_tower_counter_event_count_for_test(player_id),
		"player_counter_flash_count": view.get_formal_tower_counter_flash_count_for_test(player_id),
		"tower_screen_positions": {
			"player": [screen_positions["player"].x, screen_positions["player"].y],
			"ai": [screen_positions["ai"].x, screen_positions["ai"].y],
		},
	}


func _capture_viewport() -> Vector2i:
	var value := OS.get_environment("CARDFRONT_FT1_CAPTURE_VIEWPORT").strip_edges().to_lower()
	if value.is_empty():
		return DEFAULT_VIEWPORT
	var parts := value.split("x", false, 1)
	if parts.size() != 2:
		return DEFAULT_VIEWPORT
	return Vector2i(maxi(320, int(parts[0])), maxi(320, int(parts[1])))


func _capture_label(capture_viewport: Vector2i) -> String:
	var explicit_label := OS.get_environment("CARDFRONT_FT1_CAPTURE_LABEL").strip_edges()
	if not explicit_label.is_empty():
		return explicit_label
	return "%dx%d" % [capture_viewport.x, capture_viewport.y]


func _output_dir() -> String:
	var value := OS.get_environment("CARDFRONT_FT1_OUTPUT_DIR").strip_edges()
	return value if not value.is_empty() else DEFAULT_OUTPUT_DIR


func _absolute_output_dir(path_value: String) -> String:
	if path_value.begins_with("res://"):
		return ProjectSettings.globalize_path(path_value)
	if path_value.is_absolute_path():
		return path_value
	return ProjectSettings.globalize_path("res://").path_join(path_value)


func _working_tree_changes() -> Array[String]:
	var raw := OS.get_environment("CARDFRONT_FT1_CHANGED_PATHS")
	var result: Array[String] = []
	for value in raw.split("|", false):
		if not value.strip_edges().is_empty():
			result.append(value.strip_edges())
	return result


func _save_root_png(absolute_path: String) -> int:
	var image := root.get_texture().get_image()
	if image == null:
		return ERR_UNAVAILABLE
	return image.save_png(absolute_path)


func _write_json(absolute_path: String, data: Dictionary) -> int:
	var file := FileAccess.open(absolute_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data, "\t", false) + "\n")
	file.close()
	return OK


func _flush(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame
