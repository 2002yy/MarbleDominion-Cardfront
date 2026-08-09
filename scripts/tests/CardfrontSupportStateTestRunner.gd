extends SceneTree

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const SupportIdsScript = preload("res://scripts/cardfront/support/CardfrontSupportIds.gd")
const SupportStateScript = preload("res://scripts/cardfront/support/DeploymentSupportState.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontSupportStateTest] Checking runtime truth table")
	await process_frame

	_test_truth_table()
	_test_online_is_derived()
	_test_snapshot_excludes_derived_cache()
	_test_restore_requires_connectivity_rebuild()

	_assert.report("[CardfrontSupportStateTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_truth_table() -> void:
	var state = _make_state(CardfrontRulesScript.PLAYER_FACTION, true, true)
	_assert.eq(state.derived_gameplay_status_for(CardfrontRulesScript.PLAYER_FACTION), SupportStateScript.STATUS_ONLINE, "support state: own operational connected is Online")
	_assert.that(state.can_contribute_deployment_for(CardfrontRulesScript.PLAYER_FACTION), "support state: Online can contribute deployment")

	state.set_network_connected(false)
	_assert.eq(state.derived_gameplay_status_for(CardfrontRulesScript.PLAYER_FACTION), SupportStateScript.STATUS_CAPTURED_OFFLINE, "support state: own operational disconnected is CapturedOffline")
	_assert.that(not state.can_contribute_deployment_for(CardfrontRulesScript.PLAYER_FACTION), "support state: disconnected cannot deploy")

	state.set_operational(false)
	state.set_network_connected(true)
	_assert.eq(state.derived_gameplay_status_for(CardfrontRulesScript.PLAYER_FACTION), SupportStateScript.STATUS_DISABLED, "support state: own non-operational is Disabled regardless of cache")
	_assert.that(not state.can_contribute_deployment_for(CardfrontRulesScript.PLAYER_FACTION), "support state: disabled cannot deploy")

	state.set_claim_owner(CardfrontRulesScript.NEUTRAL_OWNER)
	_assert.eq(state.derived_gameplay_status_for(CardfrontRulesScript.PLAYER_FACTION), SupportStateScript.STATUS_NOT_OWNED, "support state: neutral is not owned")

	state.set_claim_owner(CardfrontRulesScript.AI_FACTION)
	state.set_operational(true)
	state.set_network_connected(true)
	_assert.eq(state.derived_gameplay_status_for(CardfrontRulesScript.PLAYER_FACTION), SupportStateScript.STATUS_NOT_OWNED, "support state: enemy Online is not ours")
	_assert.eq(state.derived_gameplay_status_for(CardfrontRulesScript.AI_FACTION), SupportStateScript.STATUS_ONLINE, "support state: enemy owner sees its own Online state")


func _test_online_is_derived() -> void:
	var state = _make_state(CardfrontRulesScript.PLAYER_FACTION, true, true)
	_assert.that(not "online" in state, "support state: Online must not be an independently writable field")
	state.set_operational(false)
	_assert.that(not state.is_online_for(CardfrontRulesScript.PLAYER_FACTION), "support state: operational mutation immediately changes derived Online")
	state.set_operational(true)
	state.set_claim_owner(CardfrontRulesScript.AI_FACTION)
	_assert.that(not state.is_online_for(CardfrontRulesScript.PLAYER_FACTION), "support state: claim mutation immediately changes derived Online")


func _test_snapshot_excludes_derived_cache() -> void:
	var state = _make_state(CardfrontRulesScript.PLAYER_FACTION, true, true)
	state.set_contested(true)
	state.capture_side = CardfrontRulesScript.AI_FACTION
	state.capture_progress = 0.4
	var saved: Dictionary = state.snapshot()
	_assert.eq(str(saved.support_id), SupportIdsScript.SUPPORT_CENTER, "support snapshot: stable ID persists")
	_assert.eq(int(saved.claim_owner), CardfrontRulesScript.PLAYER_FACTION, "support snapshot: Claim persists")
	_assert.that(not saved.has("network_connected"), "support snapshot: graph-derived connectivity is not persistent truth")
	_assert.that(not saved.has("online"), "support snapshot: derived Online is not persisted")
	_assert.that(not saved.has("contested"), "support snapshot: occupancy-derived contesting is not persisted")


func _test_restore_requires_connectivity_rebuild() -> void:
	var restored = SupportStateScript.new()
	restored.restore_persistent({
		"support_id": SupportIdsScript.SUPPORT_LEFT_NORTH,
		"claim_owner": CardfrontRulesScript.PLAYER_FACTION,
		"operational": true,
		"capture_side": CardfrontRulesScript.AI_FACTION,
		"capture_progress": 0.25,
		"network_connected": true,
		"online": true,
		"contested": true,
	})
	_assert.eq(restored.support_id, SupportIdsScript.SUPPORT_LEFT_NORTH, "support restore: stable ID restores")
	_assert.eq(restored.capture_progress, 0.25, "support restore: persistent capture progress restores")
	_assert.that(not restored.network_connected, "support restore: serialized connectivity is ignored pending graph rebuild")
	_assert.that(not restored.contested, "support restore: serialized contested flag is ignored pending occupancy rebuild")
	_assert.that(not restored.is_online_for(CardfrontRulesScript.PLAYER_FACTION), "support restore: cannot become Online before graph rebuild")


func _make_state(owner_id: int, is_operational: bool, is_connected: bool):
	var state = SupportStateScript.new()
	state.setup(SupportIdsScript.SUPPORT_CENTER, owner_id, is_operational)
	state.set_network_connected(is_connected)
	return state
