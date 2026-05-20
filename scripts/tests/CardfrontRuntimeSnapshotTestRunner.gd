extends SceneTree

const CardfrontRuntimeSnapshotScript = preload("res://scripts/cardfront/save/CardfrontRuntimeSnapshot.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontRuntimeSnapshotTest] Starting Cardfront save schema audit tests")
	await process_frame

	_test_default_schema_shape()
	_test_partial_payload_uses_defaults()
	_test_roundtrip_preserves_current_fields()

	_assert.report("[CardfrontRuntimeSnapshotTest]")
	if _assert.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _test_default_schema_shape() -> void:
	var snap = CardfrontRuntimeSnapshotScript.new()
	var payload: Dictionary = snap.to_dict()
	var keys: Array = payload.keys()
	keys.sort()

	_assert.eq(keys, [
		"devices",
		"fortify_stacks",
		"morale_effects",
		"resource_states",
		"target_bias_state",
		"used_card_ids",
	], "snapshot schema: keys should stay explicit and stable")
	_assert.that(payload.get("resource_states") is Dictionary, "snapshot schema: resource_states should be a dictionary")
	_assert.that(payload.get("used_card_ids") is Array, "snapshot schema: used_card_ids should be an array")
	_assert.that(payload.get("fortify_stacks") is Array, "snapshot schema: fortify_stacks should be an array")
	_assert.that(payload.get("morale_effects") is Array, "snapshot schema: morale_effects should be an array")
	_assert.that(payload.get("target_bias_state") is Dictionary, "snapshot schema: target_bias_state should be a dictionary")
	_assert.that(payload.get("devices") is Array, "snapshot schema: devices should be an array")


func _test_partial_payload_uses_defaults() -> void:
	var snap = CardfrontRuntimeSnapshotScript.from_dict({
		"resource_states": {1: {"energy": 7, "parts": 3}},
		"used_card_ids": [1001, 1004],
	})
	var payload: Dictionary = snap.to_dict()

	_assert.eq(payload.get("resource_states"), {1: {"energy": 7, "parts": 3}}, "snapshot defaults: resource_states should be preserved")
	_assert.eq(payload.get("used_card_ids"), [1001, 1004], "snapshot defaults: used card ids should be preserved")
	_assert.eq(payload.get("fortify_stacks"), [], "snapshot defaults: missing fortify_stacks should become empty array")
	_assert.eq(payload.get("morale_effects"), [], "snapshot defaults: missing morale_effects should become empty array")
	_assert.eq(payload.get("target_bias_state"), {}, "snapshot defaults: missing target_bias_state should become empty dictionary")
	_assert.eq(payload.get("devices"), [], "snapshot defaults: missing devices should become empty array")


func _test_roundtrip_preserves_current_fields() -> void:
	var source: Dictionary = {
		"resource_states": {
			1: {"energy": 12, "parts": 4},
			2: {"energy": 5, "parts": 9},
		},
		"used_card_ids": [1002],
		"fortify_stacks": [{"cell": Vector2i(3, 4), "stacks": 2}],
		"morale_effects": [{"region_id": 6, "owner_id": 1, "mode": "support_player"}],
		"target_bias_state": {1: {6: 4.5}},
		"devices": [{"type": "absorber_core", "cell": Vector2i(5, 6), "owner_id": 1}],
	}
	var payload: Dictionary = CardfrontRuntimeSnapshotScript.from_dict(source).to_dict()

	_assert.eq(payload, source, "snapshot roundtrip: current Cardfront fields should remain unchanged")
