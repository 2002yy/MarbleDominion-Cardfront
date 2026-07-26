extends SceneTree

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontArenaRuntimeTest] Starting arena runtime tests")
	await process_frame

	await _test_cardfront_builds_arena_runtime()
	await _test_ballwar_does_not_build_arena_runtime()
	GameConfig.reset_runtime_defaults()

	_assert.report("[CardfrontArenaRuntimeTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_cardfront_builds_arena_runtime() -> void:
	var main = await _start_main(GameConfig.GAME_MODE_CARDFRONT, 40)
	var battlefield_rect: Rect2 = main.runtime.current_layout.get("battlefield_rect", Rect2())
	var player_turret = main.runtime.turrets.get(CardfrontRulesScript.PLAYER_FACTION, null)
	var ai_turret = main.runtime.turrets.get(CardfrontRulesScript.AI_FACTION, null)

	_assert.that(bool(main.runtime.current_layout.get("cardfront_arena", false)), "arena runtime: Cardfront should use arena layout")
	_assert.eq(int(main.runtime.battlefield.cell_size), int(main.runtime.current_layout.get("battlefield_cell_size", 0)), "arena runtime: Battlefield should use layout cell size")
	_assert.that(main.runtime.arena_presentation_layer != null and is_instance_valid(main.runtime.arena_presentation_layer), "arena runtime: presentation layer should exist")
	_assert.eq(main.runtime.arena_presentation_layer.get_floor_polygon_for_test().size(), 4, "arena runtime: perspective floor should be a readable trapezoid")
	_assert.eq(main.runtime.command_chambers.size(), 2, "arena runtime: two command chamber views should exist")
	_assert.that(main.runtime.direction_controller != null and is_instance_valid(main.runtime.direction_controller), "arena runtime: direction controller should exist")
	_assert.that(main.runtime.aim_guide_layer != null and is_instance_valid(main.runtime.aim_guide_layer), "arena runtime: aim guide should exist")
	_assert.that(main.runtime.aim_control != null and is_instance_valid(main.runtime.aim_control) and main.runtime.aim_control.visible, "arena runtime: formal aim control should be visible")
	_assert.that(ai_turret.global_position.y < battlefield_rect.position.y, "arena runtime: AI turret should sit beyond the top map edge")
	_assert.that(player_turret.global_position.y > battlefield_rect.end.y, "arena runtime: player turret should sit beyond the bottom map edge")
	_assert.that(bool(player_turret.manual_aim_enabled), "arena runtime: player turret should be manually aimed")
	_assert.that(main.runtime.fire_director.has_owner_manual_angle(CardfrontRulesScript.PLAYER_FACTION), "arena runtime: player FireDirector angle should be manual")
	_assert.that(not main.runtime.fire_director.has_owner_manual_angle(CardfrontRulesScript.AI_FACTION), "arena runtime: AI FireDirector should stay automatic")

	var player_chamber = main.runtime.command_chambers.get(CardfrontRulesScript.PLAYER_FACTION, null)
	var ai_chamber = main.runtime.command_chambers.get(CardfrontRulesScript.AI_FACTION, null)
	var player_bounds: Rect2 = player_chamber.get_global_bounds_for_test()
	var ai_bounds: Rect2 = ai_chamber.get_global_bounds_for_test()
	_assert.that(player_bounds.position.y < battlefield_rect.end.y and player_bounds.end.y > battlefield_rect.end.y, "arena runtime: player chamber should straddle the lower arena edge")
	_assert.that(ai_bounds.position.y < battlefield_rect.position.y and ai_bounds.end.y > battlefield_rect.position.y, "arena runtime: AI chamber should straddle the upper arena edge")

	TestFixtures.cleanup_node(main)
	await _flush()


func _test_ballwar_does_not_build_arena_runtime() -> void:
	var main = await _start_main(GameConfig.GAME_MODE_BASIC, 20)
	_assert.that(not bool(main.runtime.current_layout.get("cardfront_arena", false)), "arena runtime: BallWar should keep legacy layout")
	_assert.eq(main.runtime.arena_presentation_layer, null, "arena runtime: BallWar should not create presentation layer")
	_assert.eq(main.runtime.command_chambers.size(), 0, "arena runtime: BallWar should not create Cardfront chamber views")
	_assert.eq(main.runtime.direction_controller, null, "arena runtime: BallWar should not create direction controller")
	_assert.eq(main.runtime.aim_control, null, "arena runtime: BallWar should not create Cardfront aim UI")

	TestFixtures.cleanup_node(main)
	await _flush()


func _start_main(mode_name: String, grid_size: int):
	GameConfig.reset_runtime_defaults()
	var scene: PackedScene = load("res://scenes/Main.tscn")
	var main = scene.instantiate()
	get_root().add_child(main)
	await process_frame
	main.selected_game_mode_name = mode_name
	main.selected_grid_size = grid_size
	main._start_game(grid_size, true, false)
	await _flush()
	return main


func _flush() -> void:
	await process_frame
	await process_frame
