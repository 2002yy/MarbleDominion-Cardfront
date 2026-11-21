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
	_test_fortify_stacks_roundtrip()
	_test_v03_field_defaults()
	_test_v03_roundtrip()

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
		"current_gate_snapshot",
		"current_offers",
		"entity_snapshot",
		"faction_run_states",
		"fortify_stacks",
		"hero_assignments",
		"match_phase",
		"round_active",
		"round_number",
		"schema_version",
		"support_states",
		"territory_defense_state",
	], "snapshot schema: keys should stay explicit and stable")
	_assert.that(payload.get("schema_version") is String, "snapshot schema: schema_version should be a string")
	_assert.that(payload.get("fortify_stacks") is Array, "snapshot schema: fortify_stacks should be an array")
	_assert.that(payload.get("faction_run_states") is Dictionary, "snapshot schema: faction_run_states should be a dictionary")
	_assert.that(payload.get("match_phase") is Dictionary, "snapshot schema: match_phase should be a dictionary")
	_assert.that(payload.get("round_number") is int, "snapshot schema: round_number should be an int")
	_assert.that(payload.get("round_active") is bool, "snapshot schema: round_active should be a bool")
	_assert.that(payload.get("hero_assignments") is Dictionary, "snapshot schema: hero_assignments should be a dictionary")
	_assert.that(payload.get("current_offers") is Dictionary, "snapshot schema: current_offers should be a dictionary")
	_assert.that(payload.get("current_gate_snapshot") is Dictionary, "snapshot schema: current_gate_snapshot should be a dictionary")
	_assert.that(payload.get("entity_snapshot") is Dictionary, "snapshot schema: entity_snapshot should be a dictionary")
	_assert.that(payload.get("territory_defense_state") is Dictionary, "snapshot schema: territory_defense_state should be a dictionary")
	_assert.that(payload.get("support_states") is Dictionary, "snapshot schema: support_states should be a dictionary")


func _test_partial_payload_uses_defaults() -> void:
	var snap = CardfrontRuntimeSnapshotScript.from_dict({})
	var payload: Dictionary = snap.to_dict()

	_assert.eq(payload.get("fortify_stacks"), [], "snapshot defaults: missing fortify_stacks should become empty array")
	for retired_key in ["resource_states", "used_card_ids", "morale_effects", "target_bias_state", "devices"]:
		_assert.that(not payload.has(retired_key), "snapshot defaults: retired data should not be serialized: %s" % retired_key)


func _test_fortify_stacks_roundtrip() -> void:
	var fortify_stacks: Array = [{"cell": Vector2i(3, 4), "stacks": 2}]
	var payload: Dictionary = CardfrontRuntimeSnapshotScript.from_dict({
		"fortify_stacks": fortify_stacks,
		"resource_states": {1: {"energy": 12}},
		"used_card_ids": [1002],
	}).to_dict()
	_assert.eq(payload.get("fortify_stacks"), fortify_stacks, "snapshot: live territory fortification still roundtrips")
	_assert.that(not payload.has("resource_states") and not payload.has("used_card_ids"), "snapshot: retired card economy is not re-emitted")


func _test_v03_field_defaults() -> void:
	var snap = CardfrontRuntimeSnapshotScript.from_dict({})
	var payload: Dictionary = snap.to_dict()

	_assert.eq(payload.get("faction_run_states"), {}, "v03 defaults: faction_run_states should default to empty dict")
	_assert.eq(payload.get("match_phase"), {}, "v03 defaults: match_phase should default to empty dict")
	_assert.eq(int(payload.get("round_number", -1)), 0, "v03 defaults: round_number should default to 0")
	_assert.eq(bool(payload.get("round_active", true)), false, "v03 defaults: round_active should default to false")
	_assert.eq(payload.get("hero_assignments"), {}, "v03 defaults: hero_assignments should default to empty dict")
	_assert.eq(payload.get("current_offers"), {}, "v03 defaults: current_offers should default to empty dict")
	_assert.eq(payload.get("entity_snapshot"), {}, "v03 defaults: entity_snapshot should default to empty dict")
	_assert.eq(payload.get("territory_defense_state"), {}, "v03 defaults: territory_defense_state should default to empty dict")
	_assert.eq(payload.get("support_states"), {}, "support defaults: support_states should default to empty dict")


func _test_v03_roundtrip() -> void:
	var source: Dictionary = {
		"schema_version": "2.0",
		"fortify_stacks": [],
		"faction_run_states": {
			1: {"owner_id": 1, "hero_id": "balanced_commander", "attack_level": 2},
			2: {"owner_id": 2, "hero_id": "rapid_gunner", "attack_level": 1},
		},
		"match_phase": {"phase": "battle_countdown", "time_remaining": 5.3},
		"round_number": 7,
		"round_active": true,
		"hero_assignments": {1: "balanced_commander", 2: "rapid_gunner"},
		"current_offers": {1: [{"id": "reinforced_volley"}, {"id": "double_volley"}]},
		"current_stronghold_bonuses": {1: {"shot_count_bonus": 3}},
		"current_gate_snapshot": {0: {"state": "open", "openness": 1.0}},
		"entity_snapshot": {"entities": [], "building_slots": {}},
		"territory_defense_state": {"owner_caps": {1: 2, 2: 1}, "defense_initialized": true},
		"support_states": {},
	}
	var payload: Dictionary = CardfrontRuntimeSnapshotScript.from_dict(source).to_dict()

	_assert.eq(int(payload.get("round_number", 0)), 7, "v03 roundtrip: round_number should be preserved")
	_assert.eq(bool(payload.get("round_active", false)), true, "v03 roundtrip: round_active should be preserved")
	_assert.eq(payload.get("hero_assignments"), {1: "balanced_commander", 2: "rapid_gunner"}, "v03 roundtrip: hero_assignments should be preserved")
	_assert.eq(payload.get("round_number"), 7, "v03 roundtrip: round_number exact match")
	_assert.that(not payload.has("current_stronghold_bonuses"), "v03 compatibility: retired Stronghold reward payload is ignored and not re-emitted")
