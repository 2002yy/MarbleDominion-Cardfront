extends SceneTree

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const SupportIdsScript = preload("res://scripts/cardfront/support/CardfrontSupportIds.gd")
const SnapshotBuilderScript = preload(
	"res://scripts/cardfront/support/presentation/SupportPresentationSnapshotBuilder.gd"
)
const ViewStateScript = preload(
	"res://scripts/cardfront/support/presentation/SupportPresentationViewState.gd"
)

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontSupportPresentationContractTest] Checking detached DTO and view states")
	await process_frame

	_test_detached_whitelist_snapshot()
	_test_identity_validation()
	_test_view_state_priority()
	_test_capture_progress_normalization()

	_assert.report("[CardfrontSupportPresentationContractTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_detached_whitelist_snapshot() -> void:
	var definition: Dictionary = _definition(SupportIdsScript.SUPPORT_CENTER)
	var runtime_marker := RefCounted.new()
	var public_state: Dictionary = _state({
		"graph": runtime_marker,
		"capture_controller": runtime_marker,
		"deployment_callback": Callable(self, "_run"),
	})
	var snapshot = SnapshotBuilderScript.build(definition, public_state, RulesScript.NEUTRAL_OWNER)
	_assert.that(snapshot != null, "presentation snapshot: valid sources build")
	if snapshot == null:
		return
	var projected: Dictionary = snapshot.to_dictionary()
	_assert.eq(projected.keys(), [
		"support_id",
		"anchor_cell",
		"claim_owner",
		"operational",
		"network_connected",
		"capture_side",
		"capture_progress_normalized",
		"contested",
		"derived_view_state",
	], "presentation snapshot: output is an explicit field whitelist")
	for forbidden_key in ["graph", "capture_controller", "deployment_callback", "set_owner", "set_connected"]:
		_assert.that(not projected.has(forbidden_key), "presentation snapshot: excludes %s" % forbidden_key)

	snapshot.support_id = "tampered"
	snapshot.anchor_cell = Vector2i(1, 1)
	snapshot.claim_owner = RulesScript.AI_FACTION
	_assert.eq(str(definition.support_id), SupportIdsScript.SUPPORT_CENTER, "presentation snapshot: mutation cannot change definition identity")
	_assert.eq(definition.anchor_cell, Vector2i(20, 20), "presentation snapshot: mutation cannot change authored anchor")
	_assert.eq(int(public_state.claim_owner), RulesScript.PLAYER_FACTION, "presentation snapshot: mutation cannot change gameplay owner")
	_assert.that(public_state.graph == runtime_marker, "presentation snapshot: source runtime marker remains outside DTO")


func _test_identity_validation() -> void:
	var definition: Dictionary = _definition(SupportIdsScript.SUPPORT_CENTER)
	_assert.that(
		SnapshotBuilderScript.build(definition, _state({"support_id": SupportIdsScript.SUPPORT_LEFT_SOUTH}), RulesScript.NEUTRAL_OWNER) == null,
		"presentation snapshot: mismatched stable IDs fail closed"
	)
	var missing_anchor: Dictionary = definition.duplicate(true)
	missing_anchor.erase("anchor_cell")
	_assert.that(
		SnapshotBuilderScript.build(missing_anchor, _state(), RulesScript.NEUTRAL_OWNER) == null,
		"presentation snapshot: missing authored anchor fails closed"
	)


func _test_view_state_priority() -> void:
	_assert_view_state(_state({"contested": true, "capture_progress": 0.7}), ViewStateScript.CONTESTED, "contested overrides progress")
	_assert_view_state(_state({"capture_side": RulesScript.AI_FACTION, "capture_progress": 0.2}), ViewStateScript.CAPTURING, "active takeover progress is Capturing")
	_assert_view_state(_state(), ViewStateScript.ACTIVE, "claimed operational connected is Active")
	_assert_view_state(_state({"network_connected": false}), ViewStateScript.CAPTURED_OFFLINE, "claimed operational disconnected is CapturedOffline")
	_assert_view_state(_state({"operational": false, "network_connected": false}), ViewStateScript.DISABLED_NEUTRAL, "suppressed claim is Disabled before connectivity styling")
	_assert_view_state(_state({"claim_owner": RulesScript.NEUTRAL_OWNER, "operational": true}), ViewStateScript.DISABLED_NEUTRAL, "neutral support is Disabled/Neutral")
	for view_state in ViewStateScript.ALL:
		_assert.that(ViewStateScript.is_valid(view_state), "view state: %s belongs to closed contract" % view_state)


func _test_capture_progress_normalization() -> void:
	var high = SnapshotBuilderScript.build(_definition(SupportIdsScript.SUPPORT_CENTER), _state({"capture_progress": 4.0}), RulesScript.NEUTRAL_OWNER)
	var low = SnapshotBuilderScript.build(_definition(SupportIdsScript.SUPPORT_CENTER), _state({"capture_progress": -2.0}), RulesScript.NEUTRAL_OWNER)
	_assert.eq(high.capture_progress_normalized, 1.0, "presentation snapshot: progress clamps high")
	_assert.eq(low.capture_progress_normalized, 0.0, "presentation snapshot: progress clamps low")


func _assert_view_state(public_state: Dictionary, expected: String, label: String) -> void:
	var snapshot = SnapshotBuilderScript.build(
		_definition(str(public_state.support_id)),
		public_state,
		RulesScript.NEUTRAL_OWNER
	)
	_assert.that(snapshot != null, "view state: %s builds" % label)
	if snapshot != null:
		_assert.eq(snapshot.derived_view_state, expected, "view state: %s" % label)


func _definition(support_id: String) -> Dictionary:
	return {
		"support_id": support_id,
		"anchor_cell": Vector2i(20, 20),
	}


func _state(overrides: Dictionary = {}) -> Dictionary:
	var result: Dictionary = {
		"support_id": SupportIdsScript.SUPPORT_CENTER,
		"claim_owner": RulesScript.PLAYER_FACTION,
		"operational": true,
		"network_connected": true,
		"capture_side": RulesScript.NEUTRAL_OWNER,
		"capture_progress": 0.0,
		"contested": false,
	}
	result.merge(overrides, true)
	return result
