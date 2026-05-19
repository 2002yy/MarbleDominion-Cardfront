extends SceneTree

const CardfrontTargetBiasSystemScript = preload("res://scripts/cardfront/effects/CardfrontTargetBiasSystem.gd")
const RegionMapScript = preload("res://scripts/cardfront/regions/RegionMap.gd")
const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontTargetBiasTest] Starting Cardfront target bias tests")
	await process_frame

	_test_apply_region_bias_sets_region_and_cell()
	_test_tick_expires_bias()
	_test_clear_removes_owner_only()
	_test_invalid_region_or_duration_rejected()

	GameConfig.reset_runtime_defaults()
	await _flush()

	_assert.report("[CardfrontTargetBiasTest]")
	if _assert.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _flush() -> void:
	await process_frame
	await process_frame


func _test_apply_region_bias_sets_region_and_cell() -> void:
	var rm = _make_region_map()
	var system = CardfrontTargetBiasSystemScript.new()
	system.setup(rm)
	var region_id: int = _region_id_at(rm, 0)

	var applied: bool = system.apply_region_bias(CardfrontRulesScript.PLAYER_FACTION, region_id, 3.0)
	var target_cell: Vector2i = system.get_biased_target_cell(CardfrontRulesScript.PLAYER_FACTION)

	_assert.that(applied, "target bias: apply_region_bias should accept valid region")
	_assert.eq(system.get_biased_region(CardfrontRulesScript.PLAYER_FACTION), region_id, "target bias: biased region should be queryable")
	_assert.that(target_cell.x >= 0 and target_cell.y >= 0, "target bias: biased target cell should be valid")
	_assert.eq(rm.get_region_id(target_cell), region_id, "target bias: target cell should belong to biased region")
	_cleanup_system(system)


func _test_tick_expires_bias() -> void:
	var rm = _make_region_map()
	var system = CardfrontTargetBiasSystemScript.new()
	system.setup(rm)
	var region_id: int = _region_id_at(rm, 0)

	system.apply_region_bias(CardfrontRulesScript.PLAYER_FACTION, region_id, 2.0)
	system.tick(0.75)
	_assert.eq(system.get_biased_region(CardfrontRulesScript.PLAYER_FACTION), region_id, "target bias: bias should remain before duration expires")

	system.tick(1.25)
	_assert.eq(system.get_biased_region(CardfrontRulesScript.PLAYER_FACTION), -1, "target bias: bias should expire after duration")
	_assert.eq(system.get_biased_target_cell(CardfrontRulesScript.PLAYER_FACTION), Vector2i(-1, -1), "target bias: expired bias should not expose target cell")
	_cleanup_system(system)


func _test_clear_removes_owner_only() -> void:
	var rm = _make_region_map()
	var system = CardfrontTargetBiasSystemScript.new()
	system.setup(rm)
	var player_region_id: int = _region_id_at(rm, 0)
	var ai_region_id: int = _region_id_at(rm, 1)

	system.apply_region_bias(CardfrontRulesScript.PLAYER_FACTION, player_region_id, 4.0)
	system.apply_region_bias(CardfrontRulesScript.AI_FACTION, ai_region_id, 4.0)
	system.clear(CardfrontRulesScript.PLAYER_FACTION)

	_assert.eq(system.get_biased_region(CardfrontRulesScript.PLAYER_FACTION), -1, "target bias: clear should remove requested owner")
	_assert.eq(system.get_biased_region(CardfrontRulesScript.AI_FACTION), ai_region_id, "target bias: clear should not remove other owners")
	_cleanup_system(system)


func _test_invalid_region_or_duration_rejected() -> void:
	var rm = _make_region_map()
	var system = CardfrontTargetBiasSystemScript.new()
	system.setup(rm)
	var region_id: int = _region_id_at(rm, 0)

	_assert.that(not system.apply_region_bias(CardfrontRulesScript.PLAYER_FACTION, -1, 3.0), "target bias: negative region id should be rejected")
	_assert.that(not system.apply_region_bias(CardfrontRulesScript.PLAYER_FACTION, 999999, 3.0), "target bias: unknown region id should be rejected")
	_assert.that(not system.apply_region_bias(CardfrontRulesScript.PLAYER_FACTION, region_id, 0.0), "target bias: zero duration should be rejected")
	_assert.eq(system.get_biased_region(CardfrontRulesScript.PLAYER_FACTION), -1, "target bias: rejected requests should not create bias")
	_cleanup_system(system)


func _make_region_map():
	var rm = RegionMapScript.new()
	rm.configure(20)
	rm.generate_default_layout()
	return rm


func _region_id_at(region_map, index: int) -> int:
	var ids: Array = region_map.get_controllable_region_ids()
	if ids.is_empty():
		return 0
	return int(ids[clampi(index, 0, ids.size() - 1)])


func _cleanup_system(system) -> void:
	if system != null and is_instance_valid(system):
		system.free()
