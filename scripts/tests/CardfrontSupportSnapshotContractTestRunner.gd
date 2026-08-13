extends SceneTree

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const SupportIdsScript = preload("res://scripts/cardfront/support/CardfrontSupportIds.gd")
const StateScript = preload("res://scripts/cardfront/support/DeploymentSupportState.gd")
const CodecScript = preload("res://scripts/cardfront/support/SupportStateSnapshotCodec.gd")
const RuntimeSnapshotScript = preload("res://scripts/cardfront/save/CardfrontRuntimeSnapshot.gd")
const DefaultMapScript = preload("res://scripts/cardfront/maps/maps/DefaultDuelMap.gd")
const AuthorityScript = preload("res://scripts/cardfront/support/CardfrontSupportDeploymentAuthority.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontSupportSnapshotContractTest] Checking persistent authority boundary")
	await process_frame

	_test_authoritative_fields_roundtrip()
	_test_derived_fields_are_discarded()
	_test_restored_authority_rebuilds_connectivity()
	_test_runtime_snapshot_additive_compatibility()
	_test_legacy_stronghold_data_does_not_infer_support_state()

	_assert.report("[CardfrontSupportSnapshotContractTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_authoritative_fields_roundtrip() -> void:
	var state = StateScript.new()
	state.setup(SupportIdsScript.SUPPORT_CENTER, RulesScript.PLAYER_FACTION, true, RulesScript.AI_FACTION, 0.35)
	state.set_network_connected(true)
	state.set_contested(true)
	var encoded: Dictionary = CodecScript.encode({state.support_id: state})
	var saved: Dictionary = encoded[SupportIdsScript.SUPPORT_CENTER]
	_assert.eq(saved.keys().size(), 5, "support snapshot: exact persistent field count")
	_assert.eq(str(saved.support_id), SupportIdsScript.SUPPORT_CENTER, "support snapshot: stable support_id persists")
	_assert.eq(int(saved.claim_owner), RulesScript.PLAYER_FACTION, "support snapshot: Claim persists")
	_assert.that(bool(saved.operational), "support snapshot: operational truth persists")
	_assert.eq(int(saved.capture_side), RulesScript.AI_FACTION, "support snapshot: transient capture side persists by explicit contract")
	_assert.eq(float(saved.capture_progress), 0.35, "support snapshot: transient capture progress persists by explicit contract")

	var decoded: Dictionary = CodecScript.decode(encoded)
	var restored = decoded[SupportIdsScript.SUPPORT_CENTER]
	_assert.eq(restored.support_id, SupportIdsScript.SUPPORT_CENTER, "support snapshot: stable identity restores")
	_assert.eq(restored.claim_owner, RulesScript.PLAYER_FACTION, "support snapshot: Claim restores")
	_assert.eq(restored.capture_progress, 0.35, "support snapshot: progress restores")


func _test_derived_fields_are_discarded() -> void:
	var normalized: Dictionary = CodecScript.normalize_persistent({
		SupportIdsScript.SUPPORT_LEFT_NORTH: {
			"support_id": SupportIdsScript.SUPPORT_LEFT_NORTH,
			"claim_owner": RulesScript.PLAYER_FACTION,
			"operational": true,
			"capture_side": RulesScript.NEUTRAL_OWNER,
			"capture_progress": 0.0,
			"network_connected": true,
			"contested": true,
			"online": true,
			"visual_state": "online_glow",
			"capture_idle_seconds": 1.5,
		}
	})
	var saved: Dictionary = normalized[SupportIdsScript.SUPPORT_LEFT_NORTH]
	for forbidden_key in ["network_connected", "contested", "online", "visual_state", "capture_idle_seconds"]:
		_assert.that(not saved.has(forbidden_key), "support snapshot: excludes derived/runtime field %s" % forbidden_key)
	var restored = CodecScript.decode(normalized)[SupportIdsScript.SUPPORT_LEFT_NORTH]
	_assert.that(not restored.network_connected, "support snapshot: restore requires graph connectivity rebuild")
	_assert.that(not restored.contested, "support snapshot: restore requires occupancy rebuild")
	_assert.that(not restored.is_online_for(RulesScript.PLAYER_FACTION), "support snapshot: restore cannot trust serialized Online")


func _test_restored_authority_rebuilds_connectivity() -> void:
	var rear = StateScript.new()
	rear.setup(SupportIdsScript.SUPPORT_LEFT_SOUTH, RulesScript.PLAYER_FACTION, true)
	rear.set_network_connected(false)
	var front = StateScript.new()
	front.setup(SupportIdsScript.SUPPORT_LEFT_NORTH, RulesScript.PLAYER_FACTION, true, RulesScript.AI_FACTION, 0.4)
	front.set_network_connected(false)
	var restored_states: Dictionary = CodecScript.decode(CodecScript.encode({
		rear.support_id: rear,
		front.support_id: front,
	}))

	var authority = AuthorityScript.new()
	_assert.that(authority.setup(DefaultMapScript.make(Vector2i(40, 40))), "support snapshot rehydrate: real topology configures")
	for support_id in restored_states.keys():
		var restored = restored_states[support_id]
		authority.set_support_state(str(support_id), int(restored.claim_owner), bool(restored.operational))
	var rebuilt: Dictionary = authority.deployment_context(RulesScript.PLAYER_FACTION)
	_assert.that(SupportIdsScript.SUPPORT_LEFT_SOUTH in rebuilt.online_support_ids, "support snapshot rehydrate: restored rear Claim reconnects from Core")
	_assert.that(SupportIdsScript.SUPPORT_LEFT_NORTH in rebuilt.online_support_ids, "support snapshot rehydrate: restored front Claim reconnects through restored rear")

	var isolated_authority = AuthorityScript.new()
	_assert.that(isolated_authority.setup(DefaultMapScript.make(Vector2i(40, 40))), "support snapshot rehydrate: isolated topology configures")
	isolated_authority.set_support_state(
		SupportIdsScript.SUPPORT_LEFT_NORTH,
		RulesScript.PLAYER_FACTION,
		true
	)
	var isolated: Dictionary = isolated_authority.deployment_context(RulesScript.PLAYER_FACTION)
	_assert.that(SupportIdsScript.SUPPORT_LEFT_NORTH not in isolated.online_support_ids, "support snapshot rehydrate: CapturedOffline Claim remains denied without a restored Core path")


func _test_runtime_snapshot_additive_compatibility() -> void:
	var support_record: Dictionary = {
		"support_id": SupportIdsScript.SUPPORT_RIGHT_SOUTH,
		"claim_owner": RulesScript.AI_FACTION,
		"operational": false,
		"capture_side": RulesScript.PLAYER_FACTION,
		"capture_progress": 0.6,
	}
	var restored = RuntimeSnapshotScript.from_dict({
		"schema_version": "2.0",
		"support_states": {SupportIdsScript.SUPPORT_RIGHT_SOUTH: support_record},
	})
	var payload: Dictionary = restored.to_dict()
	_assert.eq(payload.support_states[SupportIdsScript.SUPPORT_RIGHT_SOUTH], support_record, "runtime snapshot: support state roundtrips additively")
	_assert.eq(str(payload.schema_version), "2.0", "runtime snapshot: additive field preserves compatible schema version")


func _test_legacy_stronghold_data_does_not_infer_support_state() -> void:
	var legacy_bonuses: Dictionary = {RulesScript.PLAYER_FACTION: {"shot_count_bonus": 3}}
	var payload: Dictionary = RuntimeSnapshotScript.from_dict({
		"schema_version": "2.0",
		"current_stronghold_bonuses": legacy_bonuses,
	}).to_dict()
	_assert.that(not payload.has("current_stronghold_bonuses"), "support snapshot: retired Stronghold reward field is ignored and not re-emitted")
	_assert.eq(payload.support_states, {}, "support snapshot: legacy Stronghold data never migrates implicitly into Support state")
