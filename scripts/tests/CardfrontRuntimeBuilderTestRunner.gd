extends SceneTree

const CardfrontModeScript = preload("res://scripts/cardfront/CardfrontMode.gd")
const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const CardfrontRuntimeBuilderScript = preload("res://scripts/cardfront/runtime/CardfrontRuntimeBuilder.gd")
const CardfrontRuntimeRefsScript = preload("res://scripts/cardfront/runtime/CardfrontRuntimeRefs.gd")
const CardfrontSystemRegistryScript = preload("res://scripts/cardfront/runtime/CardfrontSystemRegistry.gd")
const GameRuntimeContextScript = preload("res://scripts/GameRuntimeContext.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontRuntimeBuilderTest] Starting Cardfront runtime builder tests")
	await process_frame

	_test_runtime_refs_payload_filters_status_keys()
	_test_system_registry_applies_result_aliases()
	await _test_core_builder_creates_runtime_refs()
	await _flush()

	GameConfig.reset_runtime_defaults()
	_assert.report("[CardfrontRuntimeBuilderTest]")
	if _assert.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _flush() -> void:
	await process_frame
	await process_frame


func _test_runtime_refs_payload_filters_status_keys() -> void:
	var refs = CardfrontRuntimeRefsScript.new()
	refs.merge_result({
		"configured": true,
		"reason": "ignored",
		"stage": "ignored",
		"card_system": "card-fixture",
	})
	_assert.that(not refs.has_ref("configured"), "runtime refs: should not store configured flag")
	_assert.that(not refs.has_ref("reason"), "runtime refs: should not store failure reason")
	_assert.eq(refs.get_ref("card_system"), "card-fixture", "runtime refs: should keep runtime payload values")


func _test_system_registry_applies_result_aliases() -> void:
	var registry = CardfrontSystemRegistryScript.new()
	var runtime = GameRuntimeContextScript.new()
	var region_fixture = RefCounted.new()
	var ok: bool = registry.record_result("fixture", {
		"configured": true,
		"region_map": region_fixture,
		"device_overlay": "device-overlay-fixture",
		"vfx_layer": "vfx-fixture",
	})
	registry.apply_to(runtime)

	_assert.that(ok, "system registry: configured result should record")
	_assert.eq(runtime.region_map, region_fixture, "system registry: direct refs should apply to runtime")
	_assert.eq(runtime.device_overlay_layer, "device-overlay-fixture", "system registry: device_overlay should map to device_overlay_layer")
	_assert.eq(runtime.cardfront_vfx_layer, "vfx-fixture", "system registry: vfx_layer should map to cardfront_vfx_layer")

	var failed: bool = registry.record_result("missing", {"configured": false, "reason": "nope"})
	_assert.that(not failed, "system registry: failed result should not record")
	_assert.eq(registry.failure_snapshot().size(), 1, "system registry: failed result should be tracked")


func _test_core_builder_creates_runtime_refs() -> void:
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_CARDFRONT)
	var game_layer = Node2D.new()
	get_root().add_child(game_layer)

	var battlefield = Battlefield.new()
	battlefield.configure(40)
	game_layer.add_child(battlefield)
	var battlefield_setup: Dictionary = CardfrontModeScript.configure_battlefield(battlefield)
	_assert.that(bool(battlefield_setup.get("configured", false)), "runtime builder: battlefield fixture should configure")

	var runtime = GameRuntimeContextScript.new()
	runtime.battlefield = battlefield

	var builder = CardfrontRuntimeBuilderScript.new()
	var yield_callable := Callable(self, "_on_builder_yield_tick")
	var result: Dictionary = builder.build_core_systems(game_layer, runtime, yield_callable)

	_assert.that(bool(result.get("configured", false)), "runtime builder: core systems should build")
	_assert.that(runtime.region_map != null, "runtime builder: should set region_map")
	_assert.that(runtime.region_overlay != null and is_instance_valid(runtime.region_overlay), "runtime builder: should set region overlay")
	_assert.that(runtime.economy_system != null and is_instance_valid(runtime.economy_system), "runtime builder: should set economy system")
	_assert.that(runtime.resource_states.has(CardfrontRulesScript.PLAYER_FACTION), "runtime builder: should create player resources")
	_assert.that(runtime.resource_states.has(CardfrontRulesScript.AI_FACTION), "runtime builder: should create AI resources")
	_assert.that(runtime.morale_system != null and is_instance_valid(runtime.morale_system), "runtime builder: should set morale system")
	_assert.that(runtime.fortify_layer != null, "runtime builder: should set fortify layer")
	_assert.that(runtime.target_bias_system != null and is_instance_valid(runtime.target_bias_system), "runtime builder: should set target bias")
	_assert.that(runtime.card_system != null, "runtime builder: should set card system")
	_assert.eq(runtime.card_system.target_bias_system, runtime.target_bias_system, "runtime builder: card system should receive target bias")
	_assert.that(runtime.economy_system.yield_tick.is_connected(yield_callable), "runtime builder: should connect yield tick callback")

	game_layer.queue_free()
	await _flush()


func _on_builder_yield_tick(_owner_id: int, _yield_data: Dictionary) -> void:
	pass
