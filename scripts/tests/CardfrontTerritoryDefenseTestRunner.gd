extends SceneTree

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const TuningScript = preload("res://scripts/cardfront/run/CardfrontRunTuning.gd")
const FortifyLayerScript = preload("res://scripts/cardfront/fortify/FortifyLayer.gd")
const HeroRegistryScript = preload("res://scripts/cardfront/heroes/CardfrontHeroRegistry.gd")

var _assert: TestAssert


class DirtyTracker:
	extends RefCounted

	var calls: int = 0

	func mark_dirty() -> void:
		calls += 1


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontTerritoryDefenseTest] Starting territory defense tests")
	await process_frame

	_test_refill_uses_owner_caps_and_neutral_zero()
	_test_consuming_defense_marks_overlay_dirty()
	await _test_live_defense_persists_without_refill()
	GameConfig.reset_runtime_defaults()
	paused = false

	_assert.report("[CardfrontTerritoryDefenseTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_refill_uses_owner_caps_and_neutral_zero() -> void:
	var layer = FortifyLayerScript.new()
	layer.configure(3)
	var owners: Array = [
		[RulesScript.PLAYER_FACTION, RulesScript.AI_FACTION, RulesScript.NEUTRAL_OWNER],
		[RulesScript.PLAYER_FACTION, RulesScript.AI_FACTION, RulesScript.NEUTRAL_OWNER],
		[RulesScript.PLAYER_FACTION, RulesScript.AI_FACTION, RulesScript.NEUTRAL_OWNER],
	]
	var defended_count: int = layer.refill_from_owner_caps(owners, {
		RulesScript.PLAYER_FACTION: 2,
		RulesScript.AI_FACTION: 4,
	})

	_assert.eq(defended_count, 6, "refill: only player and AI cells should be defended")
	_assert.eq(layer.get_fortify_stack(Vector2i(0, 0)), 2, "refill: player cells should use the player cap")
	_assert.eq(layer.get_fortify_stack(Vector2i(0, 1)), 4, "refill: AI cells should use the AI cap")
	_assert.eq(layer.get_fortify_stack(Vector2i(0, 2)), 0, "refill: neutral cells should remain undefended")

	layer.refill_from_owner_caps(owners, {
		RulesScript.PLAYER_FACTION: 99,
		RulesScript.AI_FACTION: 99,
	})
	_assert.eq(
		layer.get_fortify_stack(Vector2i(0, 0)),
		TuningScript.MAX_TERRITORY_DEFENSE_CAP,
		"refill: defense should clamp to the tuning cap"
	)


func _test_consuming_defense_marks_overlay_dirty() -> void:
	var layer = FortifyLayerScript.new()
	layer.configure(2)
	var tracker := DirtyTracker.new()
	layer.overlay_dirty_callback = Callable(tracker, "mark_dirty")
	layer.set_fortify_stack(Vector2i(0, 0), 2)
	var calls_before_hit: int = tracker.calls

	_assert.that(layer.consume_hit(Vector2i(0, 0)), "consume: a defended cell should consume one armor point")
	_assert.eq(layer.get_fortify_stack(Vector2i(0, 0)), 1, "consume: one armor point should remain")
	_assert.eq(tracker.calls, calls_before_hit + 1, "consume: the overlay should be marked dirty")


func _test_live_defense_persists_without_refill() -> void:
	var main = await _start_main()
	var director = main.runtime.round_director
	var defense = main.runtime.territory_defense_system
	var player_state = director.get_run_state(RulesScript.PLAYER_FACTION)
	var ai_state = director.get_run_state(RulesScript.AI_FACTION)
	var player_cells: Array = _find_owned_cells(main.runtime.battlefield, RulesScript.PLAYER_FACTION, 2)
	var ai_cell: Vector2i = _find_owned_cell(main.runtime.battlefield, RulesScript.AI_FACTION)
	var neutral_cell: Vector2i = _find_owned_cell(main.runtime.battlefield, RulesScript.NEUTRAL_OWNER)
	var drained_cell: Vector2i = player_cells[0] if not player_cells.is_empty() else Vector2i(-1, -1)
	var untouched_cell: Vector2i = player_cells[1] if player_cells.size() > 1 else Vector2i(-1, -1)

	_assert.eq(player_state.territory_defense_cap, 2, "runtime: engineer should start with defense capacity two")
	_assert.eq(ai_state.territory_defense_cap, 1, "runtime: gunner should start with defense capacity one")
	_assert.eq(defense.get_cell_defense(drained_cell), 1, "runtime: starting territory should begin with one defense")
	_assert.that(main.runtime.battlefield.apply_bullet(drained_cell, RulesScript.AI_FACTION) == "BLOCKED_BY_FORTIFY", "runtime: first hostile hit should consume starting defense")
	_assert.eq(defense.get_cell_defense(drained_cell), 0, "runtime: consumed defense should stay depleted")

	player_state.territory_defense_cap = 3
	ai_state.territory_defense_cap = 2

	director.force_open_draft_for_test()
	_assert.that(main.runtime.three_choice_panel.choose_index_for_test(0), "runtime: player should lock a draft choice")
	director.complete_reveal_for_test()

	var player_cap: int = defense.get_owner_cap(RulesScript.PLAYER_FACTION)
	var ai_cap: int = defense.get_owner_cap(RulesScript.AI_FACTION)

	_assert.that(drained_cell.x >= 0 and untouched_cell.x >= 0 and ai_cell.x >= 0, "runtime: both factions should own test cells")
	_assert.that(player_cap >= 3, "runtime: volley launch should synchronize the raised player defense cap")
	_assert.that(ai_cap >= 2, "runtime: volley launch should synchronize the raised AI defense cap")
	_assert.eq(defense.get_cell_defense(drained_cell), 0, "runtime: volley launch must not refill depleted territory")
	_assert.eq(defense.get_cell_defense(untouched_cell), 1, "runtime: increasing the cap must not increase current defense")
	_assert.eq(defense.get_cell_defense(ai_cell), 1, "runtime: AI territory must not refill to its raised cap")
	if neutral_cell.x >= 0:
		_assert.eq(defense.get_cell_defense(neutral_cell), 0, "runtime: neutral territory should not receive defense")

	var capture_result: String = main.runtime.battlefield.apply_bullet(drained_cell, RulesScript.AI_FACTION)
	_assert.eq(capture_result, "HIT_ENEMY_CELL", "capture: the next hit should capture after defense is exhausted")
	_assert.eq(
		int(main.runtime.battlefield.owners[drained_cell.x][drained_cell.y]),
		RulesScript.AI_FACTION,
		"capture: ownership should change only after all defense is gone"
	)
	_assert.eq(defense.get_cell_defense(drained_cell), 0, "capture: newly captured territory should begin at zero current defense")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)
	await _flush()


func _find_owned_cell(battlefield, owner_id: int) -> Vector2i:
	for x in range(int(battlefield.grid_size)):
		for y in range(int(battlefield.grid_size)):
			if int(battlefield.owners[x][y]) == int(owner_id):
				return Vector2i(x, y)
	return Vector2i(-1, -1)


func _find_owned_cells(battlefield, owner_id: int, count: int) -> Array:
	var cells: Array = []
	for x in range(int(battlefield.grid_size)):
		for y in range(int(battlefield.grid_size)):
			if int(battlefield.owners[x][y]) == int(owner_id):
				cells.append(Vector2i(x, y))
				if cells.size() >= count:
					return cells
	return cells


func _start_main():
	GameConfig.reset_runtime_defaults()
	paused = false
	var scene: PackedScene = load("res://scenes/Main.tscn")
	var main = scene.instantiate()
	get_root().add_child(main)
	await process_frame
	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_size = 20
	main.selected_cardfront_player_hero_id = HeroRegistryScript.HERO_FORTIFICATION_ENGINEER
	main.selected_cardfront_ai_hero_id = HeroRegistryScript.HERO_RAPID_GUNNER
	main._start_game(20, true, false)
	await _flush()
	return main


func _flush() -> void:
	await process_frame
	await process_frame
