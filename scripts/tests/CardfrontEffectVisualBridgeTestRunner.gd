extends SceneTree

const FeedbackBusScript = preload("res://scripts/cardfront/ui/CardfrontFeedbackBus.gd")
const EffectVisualBridgeScript = preload("res://scripts/cardfront/ui/CardfrontEffectVisualBridge.gd")
const CardfrontVfxLayerScript = preload("res://scripts/cardfront/vfx/CardfrontVfxLayer.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontEffectVisualBridgeTest] Starting card effect visual bridge tests")
	await process_frame

	_test_four_card_effects_trigger_vfx()
	_test_missing_vfx_layer_no_crash()

	GameConfig.reset_runtime_defaults()
	await _flush()

	_assert.report("[CardfrontEffectVisualBridgeTest]")
	if _assert.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _flush() -> void:
	await process_frame
	await process_frame


func _make_fixture() -> Dictionary:
	var bf = Battlefield.new()
	bf.configure(20)
	get_root().add_child(bf)
	bf.reset_quadrants()

	var RegionMapScript = load("res://scripts/cardfront/regions/RegionMap.gd")
	var rm = RegionMapScript.new()
	rm.configure(20)
	rm.generate_default_layout()

	var vfx = CardfrontVfxLayerScript.new()
	vfx.setup(bf, rm, GameConfig.GAME_MODE_CARDFRONT)
	get_root().add_child(vfx)

	var bus = FeedbackBusScript.new()
	get_root().add_child(bus)

	var bridge = EffectVisualBridgeScript.new()
	get_root().add_child(bridge)
	bridge.setup(bus, vfx)

	return {
		"bf": bf,
		"vfx": vfx,
		"bus": bus,
		"bridge": bridge,
	}


func _cleanup_fixture(fixture: Dictionary) -> void:
	TestFixtures.cleanup_node(fixture.get("bridge", null))
	TestFixtures.cleanup_node(fixture.get("bus", null))
	TestFixtures.cleanup_node(fixture.get("vfx", null))
	TestFixtures.cleanup_node(fixture.get("bf", null))


func _card(card_id: int, card_name: String, effect_id: String) -> Dictionary:
	return {
		"id": card_id,
		"card_name": card_name,
		"effect_id": effect_id,
	}


func _emit_success(fixture: Dictionary, card_data: Dictionary, cell: Vector2i, region_id: int) -> void:
	fixture.bus.emit_card_play_succeeded(int(card_data.id), card_data, {
		"success": true,
		"card_name": card_data.card_name,
		"target_cell": cell,
		"target_region_id": region_id,
		"effect_id": card_data.effect_id,
	})


func _test_four_card_effects_trigger_vfx() -> void:
	var fixture = _make_fixture()
	var cases: Array = [
		_card(1001, "前线加固", "fortify_border"),
		_card(1002, "校准射击", "calibrated_shot"),
		_card(1003, "民心起伏", "morale_fluctuation"),
		_card(1004, "拓荒信标", "pioneer_beacon_lite"),
	]
	for i in range(cases.size()):
		var before: int = fixture.vfx.get_active_effects_for_test().size()
		_emit_success(fixture, cases[i], Vector2i(5 + i, 5), 1)
		var after: int = fixture.vfx.get_active_effects_for_test().size()
		_assert.gt(after, before, "effect bridge: card %d should add a visible vfx effect" % int(cases[i].id))
	_cleanup_fixture(fixture)


func _test_missing_vfx_layer_no_crash() -> void:
	var bus = FeedbackBusScript.new()
	get_root().add_child(bus)
	var bridge = EffectVisualBridgeScript.new()
	get_root().add_child(bridge)
	bridge.setup(bus, null)
	bus.emit_card_play_succeeded(1001, _card(1001, "前线加固", "fortify_border"), {
		"success": true,
		"target_cell": Vector2i(5, 5),
		"target_region_id": -1,
	})
	_assert.that(true, "effect bridge: missing vfx layer should not crash")
	TestFixtures.cleanup_node(bridge)
	TestFixtures.cleanup_node(bus)
