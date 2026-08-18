extends SceneTree

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const CreatureStateScript = preload(
	"res://scripts/cardfront/entities/CardfrontCreatureState.gd"
)
const ProjectileTypeScript = preload("res://scripts/cardfront/volley/CardfrontProjectileType.gd")
const MapRegistryScript = preload("res://scripts/cardfront/maps/CardfrontMapRegistry.gd")


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Screenshot capture requires a rendering display; omit --headless")
		quit(1)
		return
	var capture_viewport := _capture_viewport()
	root.size = capture_viewport
	var capture_extent := _capture_extent()
	var extent_label := "%dx%d" % [capture_extent.x, capture_extent.y]
	var viewport_label := "%dx%d" % [capture_viewport.x, capture_viewport.y]
	var capture_label := extent_label
	if not OS.get_environment("CARDFRONT_CAPTURE_VIEWPORT").strip_edges().is_empty():
		capture_label = "%s-viewport-%s" % [extent_label, viewport_label]
	var capture_map_id := _capture_map_id()
	if not OS.get_environment("CARDFRONT_CAPTURE_MAP_ID").strip_edges().is_empty():
		capture_label = "%s-map-%s" % [capture_label, capture_map_id]
	GameConfig.reset_runtime_defaults()
	var capture_quality := OS.get_environment("CARDFRONT_CAPTURE_QUALITY").strip_edges()
	if not capture_quality.is_empty():
		GameConfig.set_quality_by_name(capture_quality)
	paused = false
	var scene: PackedScene = load("res://scenes/Main.tscn")
	var main = scene.instantiate()
	root.add_child(main)
	await process_frame
	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_extent = capture_extent
	main.selected_cardfront_map_id = capture_map_id
	main._start_game(capture_extent, true, false)
	Input.warp_mouse(
		Vector2(float(capture_viewport.x - 10), float(capture_viewport.y) * 0.5)
	)
	await _flush(5)

	var entity_runtime = main.runtime.battlefield.get_node_or_null(
		"CardfrontBattlefieldEntityRuntime"
	)
	if entity_runtime == null:
		push_error("Cardfront entity runtime was not created")
		quit(2)
		return
	_populate_entities(entity_runtime)
	if main.runtime.orthographic_arena_view != null:
		main.runtime.orthographic_arena_view.mark_tiles_dirty()
	_fire_preview_volleys(main)
	await create_timer(0.32).timeout
	await _flush(4)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
	var battle_error := _save_root_png(
		"res://artifacts/cardfront-full-battle-%s.png" % capture_label
	)
	var scale_errors: Array[int] = []
	for scale_value in [1.0, 1.12, 1.20]:
		main.runtime.orthographic_arena_view.set_presentation_scale(scale_value, false)
		await _flush(2)
		scale_errors.append(
			_save_root_png(
				"res://artifacts/cardfront-battle-%s-scale-%d.png" % [
					capture_label,
					roundi(scale_value * 100.0),
				]
			)
		)
	main.runtime.orthographic_arena_view.set_presentation_scale(1.12, false)

	main.runtime.round_director.set_seed_for_tests(331)
	main.runtime.round_director.force_open_draft_for_test()
	await _flush(4)
	var draft_error := _save_root_png(
		"res://artifacts/cardfront-full-draft-%s.png" % capture_label
	)
	var scale_capture_ok: bool = scale_errors.all(func(error_code: int) -> bool: return error_code == OK)
	quit(0 if battle_error == OK and draft_error == OK and scale_capture_ok else 1)


func _capture_extent() -> Vector2i:
	var value: String = OS.get_environment("CARDFRONT_CAPTURE_EXTENT").strip_edges().to_lower()
	if value.is_empty():
		return Vector2i(40, 60)
	var parts: PackedStringArray = value.split("x", false, 1)
	if parts.size() != 2:
		push_warning("Invalid CARDFRONT_CAPTURE_EXTENT=%s; using 40x60" % value)
		return Vector2i(40, 60)
	var width: int = maxi(1, int(parts[0]))
	var height: int = maxi(1, int(parts[1]))
	return Vector2i(width, height)


func _capture_viewport() -> Vector2i:
	var value: String = OS.get_environment("CARDFRONT_CAPTURE_VIEWPORT").strip_edges().to_lower()
	if value.is_empty():
		return Vector2i(1120, 720)
	var parts: PackedStringArray = value.split("x", false, 1)
	if parts.size() != 2:
		push_warning("Invalid CARDFRONT_CAPTURE_VIEWPORT=%s; using 1120x720" % value)
		return Vector2i(1120, 720)
	var width: int = maxi(320, int(parts[0]))
	var height: int = maxi(320, int(parts[1]))
	return Vector2i(width, height)


func _capture_map_id() -> String:
	var value: String = OS.get_environment("CARDFRONT_CAPTURE_MAP_ID").strip_edges()
	if value.is_empty():
		return MapRegistryScript.DEFAULT_DUEL_MAP_ID
	if MapRegistryScript.get_registered_map_ids().has(value):
		return value
	push_warning("Invalid CARDFRONT_CAPTURE_MAP_ID=%s; using default_duel" % value)
	return MapRegistryScript.DEFAULT_DUEL_MAP_ID


func _save_root_png(relative_path: String) -> int:
	var image := root.get_texture().get_image()
	if image == null:
		push_error(
			"Capture texture is unavailable; run this screenshot tool without --headless"
		)
		return ERR_UNAVAILABLE
	return image.save_png(ProjectSettings.globalize_path(relative_path))


func _populate_entities(entity_runtime) -> void:
	entity_runtime.spawn_repair_units(RulesScript.PLAYER_FACTION, 2)
	entity_runtime.spawn_armored_guard(RulesScript.PLAYER_FACTION)
	entity_runtime.spawn_sapper_unit(RulesScript.PLAYER_FACTION)
	entity_runtime.spawn_repair_units(RulesScript.AI_FACTION, 2)
	entity_runtime.spawn_armored_guard(RulesScript.AI_FACTION)
	entity_runtime.spawn_sapper_unit(RulesScript.AI_FACTION)
	_spawn_scout(entity_runtime, RulesScript.PLAYER_FACTION, "capture_player_scout")
	_spawn_scout(entity_runtime, RulesScript.AI_FACTION, "capture_ai_scout")
	entity_runtime.debug_spawn_fire_control_beacon(RulesScript.PLAYER_FACTION, 0)
	entity_runtime.build_or_upgrade_tower(
		RulesScript.PLAYER_FACTION,
		entity_runtime.TOWER_INTERCEPTOR
	)
	entity_runtime.debug_spawn_fire_control_beacon(RulesScript.AI_FACTION, 0)
	entity_runtime.build_or_upgrade_tower(
		RulesScript.AI_FACTION,
		entity_runtime.TOWER_INTERCEPTOR
	)
	entity_runtime._neutral_creature_system.spawn(RulesScript.PLAYER_FACTION)
	entity_runtime._mark_visuals_dirty()


func _spawn_scout(entity_runtime, owner_id: int, entity_id: String) -> void:
	var spawn_cell: Vector2i = entity_runtime._creature_action_coordinator.find_owner_spawn_cell(
		owner_id,
		3
	)
	var scout = entity_runtime.registry.spawn_creature(
		entity_id,
		entity_runtime.CREATURE_SCOUT_UNIT,
		owner_id,
		spawn_cell,
		1,
		CreatureStateScript.ARMOR_NORMAL,
		1,
		"scout_guidance",
		-1
	)
	if scout != null:
		entity_runtime.entity_spawned.emit(
			scout.entity_id,
			scout.entity_kind,
			scout.owner_id,
			scout.cell
		)


func _fire_preview_volleys(main) -> void:
	var player_turret = main.runtime.turrets.get(RulesScript.PLAYER_FACTION, null)
	var ai_turret = main.runtime.turrets.get(RulesScript.AI_FACTION, null)
	if player_turret != null:
		player_turret.fire_directed(3, -PI * 0.5, 0.08)
	if ai_turret != null:
		ai_turret.fire_directed(3, PI * 0.5, 0.08)
	var projectile_types: Array[String] = [
		ProjectileTypeScript.STANDARD,
		ProjectileTypeScript.SIEGE,
		ProjectileTypeScript.SUPPRESSION,
	]
	for index in range(projectile_types.size()):
		var x_offset: float = float(index - 1) * 22.0
		if player_turret != null:
			main.runtime.bullet_pool.spawn_bullet(
				RulesScript.PLAYER_FACTION,
				player_turret.global_position + Vector2(x_offset, -24.0),
				Vector2(0.08 * float(index - 1), -1.0).normalized(),
				main.runtime.battlefield,
				main.runtime.turrets,
				1,
				0,
				{"projectile_type": projectile_types[index]}
			)
		if ai_turret != null:
			main.runtime.bullet_pool.spawn_bullet(
				RulesScript.AI_FACTION,
				ai_turret.global_position + Vector2(x_offset, 24.0),
				Vector2(-0.08 * float(index - 1), 1.0).normalized(),
				main.runtime.battlefield,
				main.runtime.turrets,
				1,
				0,
				{"projectile_type": projectile_types[index]}
			)


func _flush(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame
