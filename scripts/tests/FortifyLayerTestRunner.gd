extends SceneTree

const FortifyLayerScript = preload("res://scripts/cardfront/fortify/FortifyLayer.gd")
const FortifyRulesScript = preload("res://scripts/cardfront/fortify/FortifyRules.gd")
const FortifyTargetSelectorScript = preload("res://scripts/cardfront/fortify/FortifyTargetSelector.gd")
const CardfrontCaptureInterceptorScript = preload("res://scripts/cardfront/fortify/CardfrontCaptureInterceptor.gd")
const DeploymentRulesScript = preload("res://scripts/cardfront/deployment/DeploymentRules.gd")
const RegionMapScript = preload("res://scripts/cardfront/regions/RegionMap.gd")
const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[FortifyLayerTest] Starting Cardfront fortify layer tests")
	await process_frame

	_test_initial_stacks_all_zero()
	_test_set_get_add_clear()
	_test_stacks_not_exceed_max()
	_test_consume_hit_with_stacks()
	_test_consume_hit_without_stacks()
	_test_enemy_hit_on_fortified_cell_blocked()
	_test_fortify_zero_then_next_hit_flips()
	_test_own_hit_on_own_cell_no_consume()
	_test_fortify_target_selector_owned_border_only()
	_test_fortify_target_selector_excludes_internal_enemy_neutral()
	_test_old_ballwar_no_fortify_layer()
	_test_region_map_not_mutated()
	_test_snapshot_restore_roundtrip()

	GameConfig.reset_runtime_defaults()
	await _flush()

	_assert.report("[FortifyLayerTest]")
	if _assert.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _flush() -> void:
	await process_frame
	await process_frame


func _make_fortify_layer(grid_size: int = 40):
	var layer = FortifyLayerScript.new()
	layer.configure(grid_size)
	return layer


func _make_battlefield(grid_size: int = 40):
	var bf = Battlefield.new()
	bf.configure(grid_size)
	get_root().add_child(bf)
	if bf.owners.is_empty():
		bf.reset_quadrants()
	return bf


func _make_region_map(grid_size: int = 40):
	var rm = RegionMapScript.new()
	rm.configure(grid_size)
	rm.generate_default_layout()
	return rm


func _cleanup_node(node) -> void:
	if node != null and is_instance_valid(node):
		node.queue_free()


func _set_cell_owner(bf, cell: Vector2i, owner: int) -> void:
	TestFixtures.set_owner_cell_raw(bf, cell.x, cell.y, owner)
	if bf.has_method("rebuild_owner_counts"):
		bf.rebuild_owner_counts()


func _test_initial_stacks_all_zero() -> void:
	var layer = _make_fortify_layer(20)
	for x in range(20):
		for y in range(20):
			_assert.eq(layer.get_fortify_stack(Vector2i(x, y)), 0, "fortify: initial stacks should be 0 at (%d,%d)" % [x, y])


func _test_set_get_add_clear() -> void:
	var layer = _make_fortify_layer(20)
	var cell = Vector2i(5, 3)

	_assert.eq(layer.get_fortify_stack(cell), 0, "fortify: get_fortify_stack should be 0 initially")
	layer.set_fortify_stack(cell, 2)
	_assert.eq(layer.get_fortify_stack(cell), 2, "fortify: set_fortify_stack to 2")
	layer.add_fortify_stack(cell, 1)
	_assert.eq(layer.get_fortify_stack(cell), 3, "fortify: add_fortify_stack from 2 to 3")
	layer.clear_fortify_stack(cell)
	_assert.eq(layer.get_fortify_stack(cell), 0, "fortify: clear_fortify_stack should reset to 0")


func _test_stacks_not_exceed_max() -> void:
	var layer = _make_fortify_layer(20)
	var cell = Vector2i(10, 10)
	layer.set_fortify_stack(cell, FortifyRulesScript.MAX_FORTIFY_STACKS + 5)
	_assert.between(layer.get_fortify_stack(cell), 0, FortifyRulesScript.MAX_FORTIFY_STACKS, "fortify: stacks should not exceed MAX_FORTIFY_STACKS")
	layer.add_fortify_stack(cell, 10)
	_assert.between(layer.get_fortify_stack(cell), 0, FortifyRulesScript.MAX_FORTIFY_STACKS, "fortify: add_fortify_stack should not push beyond MAX")


func _test_consume_hit_with_stacks() -> void:
	var layer = _make_fortify_layer(20)
	var cell = Vector2i(7, 7)
	layer.set_fortify_stack(cell, 2)
	_assert.that(layer.consume_hit(cell), "fortify: consume_hit with stacks should return true")
	_assert.eq(layer.get_fortify_stack(cell), 1, "fortify: consume_hit should decrement from 2 to 1")
	_assert.that(layer.consume_hit(cell), "fortify: second consume_hit should return true")
	_assert.eq(layer.get_fortify_stack(cell), 0, "fortify: consume_hit should decrement from 1 to 0")


func _test_consume_hit_without_stacks() -> void:
	var layer = _make_fortify_layer(20)
	var cell = Vector2i(9, 9)
	_assert.that(not layer.consume_hit(cell), "fortify: consume_hit with no stacks should return false")
	_assert.eq(layer.get_fortify_stack(cell), 0, "fortify: stacks should remain 0 after failed consume")


func _test_enemy_hit_on_fortified_cell_blocked() -> void:
	var bf = _make_battlefield(20)
	var cell = Vector2i(5, 6)
	_set_cell_owner(bf, cell, CardfrontRulesScript.PLAYER_FACTION)

	var fortify_layer = _make_fortify_layer(20)
	fortify_layer.set_fortify_stack(cell, 2)

	var interceptor = CardfrontCaptureInterceptorScript.new()
	interceptor.setup(fortify_layer)
	bf.capture_interceptor = interceptor

	var result: String = bf.apply_bullet(cell, CardfrontRulesScript.AI_FACTION)
	_assert.eq(result, "BLOCKED_BY_FORTIFY", "fortify: enemy hit on fortified cell should be blocked")
	_assert.eq(fortify_layer.get_fortify_stack(cell), 1, "fortify: stack should decrement after blocked hit")
	_assert.eq(DeploymentRulesScript.get_owner_at(bf, cell), CardfrontRulesScript.PLAYER_FACTION, "fortify: owner should NOT change on blocked hit")

	_cleanup_node(bf)


func _test_fortify_zero_then_next_hit_flips() -> void:
	var bf = _make_battlefield(20)
	var cell = Vector2i(5, 6)
	_set_cell_owner(bf, cell, CardfrontRulesScript.PLAYER_FACTION)

	var fortify_layer = _make_fortify_layer(20)
	fortify_layer.set_fortify_stack(cell, 1)

	var interceptor = CardfrontCaptureInterceptorScript.new()
	interceptor.setup(fortify_layer)
	bf.capture_interceptor = interceptor

	var result1: String = bf.apply_bullet(cell, CardfrontRulesScript.AI_FACTION)
	_assert.eq(result1, "BLOCKED_BY_FORTIFY", "fortify: first hit should be blocked")
	_assert.eq(fortify_layer.get_fortify_stack(cell), 0, "fortify: stack should be 0 after first hit")

	var result2: String = bf.apply_bullet(cell, CardfrontRulesScript.AI_FACTION)
	_assert.eq(result2, "HIT_ENEMY_CELL", "fortify: second hit should flip when stack is 0")
	_assert.eq(DeploymentRulesScript.get_owner_at(bf, cell), CardfrontRulesScript.AI_FACTION, "fortify: owner should flip to AI after stack depleted")

	_cleanup_node(bf)


func _test_own_hit_on_own_cell_no_consume() -> void:
	var bf = _make_battlefield(20)
	var cell = Vector2i(5, 6)
	_set_cell_owner(bf, cell, CardfrontRulesScript.PLAYER_FACTION)

	var fortify_layer = _make_fortify_layer(20)
	fortify_layer.set_fortify_stack(cell, 2)

	var interceptor = CardfrontCaptureInterceptorScript.new()
	interceptor.setup(fortify_layer)
	bf.capture_interceptor = interceptor

	var result: String = bf.apply_bullet(cell, CardfrontRulesScript.PLAYER_FACTION)
	_assert.eq(result, "SAME_CELL", "fortify: own hit on own cell should be SAME_CELL")
	_assert.eq(fortify_layer.get_fortify_stack(cell), 2, "fortify: own hit should not consume stacks")

	_cleanup_node(bf)


func _test_fortify_target_selector_owned_border_only() -> void:
	var bf = _make_battlefield(20)
	var rm = _make_region_map(20)

	_set_cell_owner(bf, Vector2i(3, 3), CardfrontRulesScript.PLAYER_FACTION)
	_set_cell_owner(bf, Vector2i(4, 3), CardfrontRulesScript.PLAYER_FACTION)
	_set_cell_owner(bf, Vector2i(4, 4), CardfrontRulesScript.PLAYER_FACTION)
	_set_cell_owner(bf, Vector2i(5, 4), CardfrontRulesScript.PLAYER_FACTION)

	var cells: Array = FortifyTargetSelectorScript.select_owned_border_cells(rm, bf, CardfrontRulesScript.PLAYER_FACTION, 100)
	_assert.that(not cells.is_empty(), "fortify target: should find owned border cells")

	for cell in cells:
		_assert.that(DeploymentRulesScript.is_owned_border(rm, bf, cell, CardfrontRulesScript.PLAYER_FACTION), "fortify target: every returned cell should be owned border")

	_cleanup_node(bf)


func _test_fortify_target_selector_excludes_internal_enemy_neutral() -> void:
	var bf = _make_battlefield(20)
	var rm = _make_region_map(20)

	var internal_cell = Vector2i(3, 3)
	_set_cell_owner(bf, internal_cell, CardfrontRulesScript.PLAYER_FACTION)
	_set_cell_owner(bf, Vector2i(2, 3), CardfrontRulesScript.PLAYER_FACTION)
	_set_cell_owner(bf, Vector2i(3, 2), CardfrontRulesScript.PLAYER_FACTION)
	_set_cell_owner(bf, Vector2i(4, 3), CardfrontRulesScript.PLAYER_FACTION)
	_set_cell_owner(bf, Vector2i(3, 4), CardfrontRulesScript.PLAYER_FACTION)
	_set_cell_owner(bf, Vector2i(2, 2), CardfrontRulesScript.PLAYER_FACTION)
	_set_cell_owner(bf, Vector2i(4, 2), CardfrontRulesScript.PLAYER_FACTION)
	_set_cell_owner(bf, Vector2i(2, 4), CardfrontRulesScript.PLAYER_FACTION)
	_set_cell_owner(bf, Vector2i(4, 4), CardfrontRulesScript.PLAYER_FACTION)

	var cells: Array = FortifyTargetSelectorScript.select_owned_border_cells(rm, bf, CardfrontRulesScript.PLAYER_FACTION, 100)
	_assert.that(not cells.has(internal_cell), "fortify target: surrounded internal cell should not be border")
	for cell in cells:
		_assert.eq(DeploymentRulesScript.get_owner_at(bf, cell), CardfrontRulesScript.PLAYER_FACTION, "fortify target: only player-owned cells returned")

	_cleanup_node(bf)


func _test_old_ballwar_no_fortify_layer() -> void:
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_BASIC)
	var bf = _make_battlefield(20)
	_assert.that(bf.capture_interceptor == null, "fortify: old BallWar mode should not have capture interceptor set")
	_cleanup_node(bf)


func _test_region_map_not_mutated() -> void:
	var rm = _make_region_map(20)
	var snapshot_before: Dictionary = rm.snapshot()
	var layer = _make_fortify_layer(20)
	layer.set_fortify_stack(Vector2i(5, 5), 2)
	layer.set_fortify_stack(Vector2i(8, 3), 1)
	layer.consume_hit(Vector2i(5, 5))
	var snapshot_after: Dictionary = rm.snapshot()
	_assert.eq(snapshot_before, snapshot_after, "fortify: RegionMap should not be mutated by fortify operations")

	var bf = _make_battlefield(20)
	var interceptor = CardfrontCaptureInterceptorScript.new()
	interceptor.setup(layer)
	bf.capture_interceptor = interceptor
	_set_cell_owner(bf, Vector2i(5, 5), CardfrontRulesScript.PLAYER_FACTION)
	bf.apply_bullet(Vector2i(5, 5), CardfrontRulesScript.AI_FACTION)
	snapshot_after = rm.snapshot()
	_assert.eq(snapshot_before, snapshot_after, "fortify: RegionMap should not be mutated by intercepted bullet")
	_cleanup_node(bf)


func _test_snapshot_restore_roundtrip() -> void:
	var layer = _make_fortify_layer(20)
	layer.set_fortify_stack(Vector2i(3, 3), 2)
	layer.set_fortify_stack(Vector2i(5, 7), 1)
	layer.set_fortify_stack(Vector2i(12, 14), 3)

	var snap: Dictionary = layer.snapshot()
	_assert.eq(int(snap.get("grid_size", 0)), 20, "fortify: snapshot should preserve grid_size")

	var layer2 = FortifyLayerScript.new()
	layer2.restore(snap)
	_assert.eq(layer2.get_fortify_stack(Vector2i(3, 3)), 2, "fortify: restore roundtrip (3,3)")
	_assert.eq(layer2.get_fortify_stack(Vector2i(5, 7)), 1, "fortify: restore roundtrip (5,7)")
	_assert.eq(layer2.get_fortify_stack(Vector2i(12, 14)), 3, "fortify: restore roundtrip (12,14)")
	_assert.eq(layer2.get_fortify_stack(Vector2i(0, 0)), 0, "fortify: restore roundtrip untouched cell stays 0")
