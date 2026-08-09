extends SceneTree

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const StateScript = preload("res://scripts/cardfront/support/DeploymentSupportState.gd")
const MachineScript = preload("res://scripts/cardfront/support/capture/SupportCaptureStateMachine.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontSupportCaptureStateMachineTest] Checking pure transitions")
	await process_frame

	_test_nobody_grace_then_decay()
	_test_player_only_and_ai_only_progress()
	_test_both_sides_contested_pause()
	_test_operational_enemy_blocks_takeover()
	_test_capture_completion_changes_claim_without_online_grant()
	_test_suppressed_and_reconnect_statuses()

	_assert.report("[CardfrontSupportCaptureStateMachineTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _state(overrides: Dictionary = {}) -> Dictionary:
	var value: Dictionary = {
		"support_id": "support_test",
		"claim_owner": RulesScript.NEUTRAL_OWNER,
		"operational": false,
		"capture_side": RulesScript.PLAYER_FACTION,
		"capture_progress": 0.5,
		"capture_idle_seconds": 0.0,
		"network_connected": false,
		"contested": false,
	}
	value.merge(overrides, true)
	return value


func _assert_close(actual: float, expected: float, label: String) -> void:
	_assert.that(absf(actual - expected) < 0.0001, "%s (actual %.4f, expected %.4f)" % [label, actual, expected])


func _test_nobody_grace_then_decay() -> void:
	var during_grace: Dictionary = MachineScript.step(_state(), 0.0, 0.0, 1.5)
	_assert_close(float(during_grace.capture_progress), 0.5, "state machine: nobody holds progress during grace")
	_assert_close(float(during_grace.capture_idle_seconds), 1.5, "state machine: idle time accumulates")
	var after_grace: Dictionary = MachineScript.step(during_grace, 0.0, 0.0, 1.5)
	_assert_close(float(after_grace.capture_progress), 0.475, "state machine: only post-grace time decays")
	var cleared: Dictionary = MachineScript.step(_state({"capture_progress": 0.01, "capture_idle_seconds": 2.0}), 0.0, 0.0, 1.0)
	_assert_close(float(cleared.capture_progress), 0.0, "state machine: idle decay reaches zero")
	_assert.eq(int(cleared.capture_side), RulesScript.NEUTRAL_OWNER, "state machine: zero progress clears capture side")


func _test_player_only_and_ai_only_progress() -> void:
	var player: Dictionary = MachineScript.step(_state({"capture_progress": 0.0, "capture_side": RulesScript.NEUTRAL_OWNER}), 1.0, 0.0, 1.0)
	_assert.eq(int(player.capture_side), RulesScript.PLAYER_FACTION, "state machine: player-only selects player side")
	_assert_close(float(player.capture_progress), 0.1, "state machine: player-only advances")
	var ai: Dictionary = MachineScript.step(_state({"capture_progress": 0.0, "capture_side": RulesScript.NEUTRAL_OWNER}), 0.0, 2.0, 1.0)
	_assert.eq(int(ai.capture_side), RulesScript.AI_FACTION, "state machine: AI-only selects AI side")
	_assert_close(float(ai.capture_progress), 0.2, "state machine: AI-only advances by resolved power")


func _test_both_sides_contested_pause() -> void:
	var contested: Dictionary = MachineScript.step(_state({"capture_idle_seconds": 1.0}), 1.0, 1.0, 5.0)
	_assert.that(bool(contested.contested), "state machine: both sides mark contested")
	_assert_close(float(contested.capture_progress), 0.5, "state machine: contested freezes progress")
	_assert_close(float(contested.capture_idle_seconds), 0.0, "state machine: contested does not run idle decay")


func _test_operational_enemy_blocks_takeover() -> void:
	var blocked: Dictionary = MachineScript.step(_state({"claim_owner": RulesScript.AI_FACTION, "operational": true, "capture_progress": 0.0}), 3.0, 0.0, 5.0)
	_assert_close(float(blocked.capture_progress), 0.0, "state machine: operational enemy blocks takeover")
	_assert.eq(int(blocked.claim_owner), RulesScript.AI_FACTION, "state machine: blocked takeover preserves claim")


func _test_capture_completion_changes_claim_without_online_grant() -> void:
	var completed: Dictionary = MachineScript.step(_state({"claim_owner": RulesScript.AI_FACTION, "operational": false, "capture_progress": 0.95}), 1.0, 0.0, 1.0)
	_assert.that(bool(completed.capture_completed), "state machine: completion is reported")
	_assert.that(bool(completed.claim_changed), "state machine: claim change is reported")
	_assert.eq(int(completed.previous_claim_owner), RulesScript.AI_FACTION, "state machine: previous owner is auditable")
	_assert.eq(int(completed.claim_owner), RulesScript.PLAYER_FACTION, "state machine: completion changes claim")
	_assert.that(not bool(completed.operational), "state machine: completion does not grant operational recovery")
	_assert.that(not bool(completed.network_connected), "state machine: completion invalidates stale connectivity")


func _test_suppressed_and_reconnect_statuses() -> void:
	var support = StateScript.new()
	support.setup("support_test", RulesScript.PLAYER_FACTION, false)
	support.set_network_connected(true)
	_assert.eq(support.derived_gameplay_status_for(RulesScript.PLAYER_FACTION), StateScript.STATUS_DISABLED, "state machine contract: suppressed support is not Online")
	_assert.that(not support.can_contribute_deployment_for(RulesScript.PLAYER_FACTION), "state machine contract: suppressed support cannot deploy")
	support.set_operational(true)
	support.set_network_connected(false)
	_assert.eq(support.derived_gameplay_status_for(RulesScript.PLAYER_FACTION), StateScript.STATUS_CAPTURED_OFFLINE, "state machine contract: claimed disconnected support is CapturedOffline")
	support.set_network_connected(true)
	_assert.eq(support.derived_gameplay_status_for(RulesScript.PLAYER_FACTION), StateScript.STATUS_ONLINE, "state machine contract: reconnect restores Online without recapture")
	_assert.eq(support.claim_owner, RulesScript.PLAYER_FACTION, "state machine contract: reconnect preserves claim")
