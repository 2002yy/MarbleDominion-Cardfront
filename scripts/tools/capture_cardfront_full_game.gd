extends SceneTree

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const CreatureStateScript = preload(
	"res://scripts/cardfront/entities/CardfrontCreatureState.gd"
)
const ProjectileTypeScript = preload("res://scripts/cardfront/volley/CardfrontProjectileType.gd")


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	root.size = Vector2i(1120, 720)
	GameConfig.reset_runtime_defaults()
	paused = false
	var scene: PackedScene = load("res://scenes/Main.tscn")
	var main = scene.instantiate()
	root.add_child(main)
	await process_frame
	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_size = 20
	main._start_game(20, true, false)
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
	var battle_error := root.get_texture().get_image().save_png(
		ProjectSettings.globalize_path("res://artifacts/cardfront-full-battle.png")
	)

	main.runtime.round_director.set_seed_for_tests(331)
	main.runtime.round_director.force_open_draft_for_test()
	await _flush(4)
	var draft_error := root.get_texture().get_image().save_png(
		ProjectSettings.globalize_path("res://artifacts/cardfront-full-draft.png")
	)
	quit(0 if battle_error == OK and draft_error == OK else 1)


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
