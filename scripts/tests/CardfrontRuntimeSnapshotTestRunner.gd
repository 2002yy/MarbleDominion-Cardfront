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
	_test_roundtrip_preserves_v02_fields()
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
		"current_stronghold_bonuses",
		"devices",
		"entity_snapshot",
		"faction_run_states",
		"fortify_stacks",
		"hero_assignments",
		"match_phase",
		"morale_effects",
		"resource_states",
		"round_active",
		"round_number",
		"schema_version",
		"target_bias_state",
		"territory_defense_state",
		"used_card_ids",
	], "snapshot schema: keys should stay explicit and stable")
	_assert.that(payload.get("schema_version") is String, "snapshot schema: schema_version should be a string")
	_assert.that(payload.get("resource_states") is Dictionary, "snapshot schema: resource_states should be a dictionary")
	_assert.that(payload.get("used_card_ids") is Array, "snapshot schema: used_card_ids should be an array")
	_assert.that(payload.get("fortify_stacks") is Array, "snapshot schema: fortify_stacks should be an array")
	_assert.that(payload.get("morale_effects") is Array, "snapshot schema: morale_effects should be an array")
	_assert.that(payload.get("target_bias_state") is Dictionary, "snapshot schema: target_bias_state should be a dictionary")
	_assert.that(payload.get("devices") is Array, "snapshot schema: devices should be an array")
	_assert.that(payload.get("faction_run_states") is Dictionary, "snapshot schema: faction_run_states should be a dictionary")
	_assert.that(payload.get("match_phase") is Dictionary, "snapshot schema: match_phase should be a dictionary")
	_assert.that(payload.get("round_number") is int, "snapshot schema: round_number should be an int")
	_assert.that(payload.get("round_active") is bool, "snapshot schema: round_active should be a bool")
	_assert.that(payload.get("hero_assignments") is Dictionary, "snapshot schema: hero_assignments should be a dictionary")
	_assert.that(payload.get("current_offers") is Dictionary, "snapshot schema: current_offers should be a dictionary")
	_assert.that(payload.get("current_stronghold_bonuses") is Dictionary, "snapshot schema: current_stronghold_bonuses should be a dictionary")
	_assert.that(payload.get("current_gate_snapshot") is Dictionary, "snapshot schema: current_gate_snapshot should be a dictionary")
	_assert.that(payload.get("entity_snapshot") is Dictionary, "snapshot schema: entity_snapshot should be a dictionary")
	_assert.that(payload.get("territory_defense_state") is Dictionary, "snapshot schema: territory_defense_state should be a dictionary")


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


func _test_roundtrip_preserves_v02_fields() -> void:
	var source: Dictionary = {
		"schema_version": "2.0",
		"resource_states": {
			1: {"energy": 12, "parts": 4},
			2: {"energy": 5, "parts": 9},
		},
		"used_card_ids": [1002],
		"fortify_stacks": [{"cell": Vector2i(3, 4), "stacks": 2}],
		"morale_effects": [{"region_id": 6, "owner_id": 1, "mode": "support_player"}],
		"target_bias_state": {1: {6: 4.5}},
		"devices": [{"type": "absorber_core", "cell": Vector2i(5, 6), "owner_id": 1}],
		"faction_run_states": {},
		"match_phase": {},
		"round_number": 0,
		"round_active": false,
		"hero_assignments": {},
		"current_offers": {},
		"current_stronghold_bonuses": {},
		"current_gate_snapshot": {},
		"entity_snapshot": {},
		"territory_defense_state": {},
	}
	var payload: Dictionary = CardfrontRuntimeSnapshotScript.from_dict(source).to_dict()

	_assert.eq(payload, source, "snapshot roundtrip: v0.2 fields should remain unchanged")


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


func _test_v03_roundtrip() -> void:
	var source: Dictionary = {
		"schema_version": "2.0",
		"resource_states": {},
		"used_card_ids": [],
		"fortify_stacks": [],
		"morale_effects": [],
		"target_bias_state": {},
		"devices": [],
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
	}
	var payload: Dictionary = CardfrontRuntimeSnapshotScript.from_dict(source).to_dict()

	_assert.eq(int(payload.get("round_number", 0)), 7, "v03 roundtrip: round_number should be preserved")
	_assert.eq(bool(payload.get("round_active", false)), true, "v03 roundtrip: round_active should be preserved")
	_assert.eq(payload.get("hero_assignments"), {1: "balanced_commander", 2: "rapid_gunner"}, "v03 roundtrip: hero_assignments should be preserved")
	_assert.eq(payload.get("round_number"), 7, "v03 roundtrip: round_number exact match")
