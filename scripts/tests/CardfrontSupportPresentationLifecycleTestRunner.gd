extends SceneTree

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const SupportIdsScript = preload("res://scripts/cardfront/support/CardfrontSupportIds.gd")
const DefaultMapScript = preload("res://scripts/cardfront/maps/maps/DefaultDuelMap.gd")
const AuthorityScript = preload("res://scripts/cardfront/support/CardfrontSupportDeploymentAuthority.gd")
const LayerScript = preload(
	"res://scripts/cardfront/support/presentation/CardfrontSupportPresentationLayer3D.gd"
)
const ViewStateScript = preload(
	"res://scripts/cardfront/support/presentation/SupportPresentationViewState.gd"
)

var _assert: TestAssert
var _signal_count: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontSupportPresentationLifecycleTest] Checking stable visual lifecycle")
	await process_frame

	var authority = AuthorityScript.new()
	_assert.that(authority.setup(DefaultMapScript.make(Vector2i(40, 40))), "support presentation lifecycle: real map authority builds")
	_test_authority_projection(authority)
	await _test_visual_lifecycle(authority)

	_assert.report("[CardfrontSupportPresentationLifecycleTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_authority_projection(authority) -> void:
	var snapshots: Array = authority.presentation_snapshots()
	_assert.eq(snapshots.size(), 7, "support presentation lifecycle: all authored support IDs project")
	_assert.eq(_ids(snapshots), _sorted(SupportIdsScript.DEFAULT_DUEL_ALL), "support presentation lifecycle: identity is stable support_id")
	var player_core: Dictionary = _snapshot_by_id(snapshots, SupportIdsScript.CORE_PLAYER)
	var neutral_support: Dictionary = _snapshot_by_id(snapshots, SupportIdsScript.SUPPORT_LEFT_SOUTH)
	_assert.eq(player_core.derived_view_state, ViewStateScript.ACTIVE, "support presentation lifecycle: player Core starts Active")
	_assert.eq(neutral_support.derived_view_state, ViewStateScript.DISABLED_NEUTRAL, "support presentation lifecycle: non-Core begins Neutral/Disabled")
	_assert.that(not player_core.has("region_id"), "support presentation lifecycle: runtime region_id is not visual identity")

	authority.presentation_snapshots_changed.connect(_on_snapshots_changed)
	_assert.that(authority.set_support_state(SupportIdsScript.SUPPORT_LEFT_SOUTH, RulesScript.PLAYER_FACTION, true), "support presentation lifecycle: state change applies")
	_assert.eq(_signal_count, 1, "support presentation lifecycle: state revision emits one presentation update")
	var online: Dictionary = _snapshot_by_id(authority.presentation_snapshots(), SupportIdsScript.SUPPORT_LEFT_SOUTH)
	_assert.eq(online.derived_view_state, ViewStateScript.ACTIVE, "support presentation lifecycle: connected claimed Support becomes Active")


func _test_visual_lifecycle(authority) -> void:
	var layer = LayerScript.new()
	get_root().add_child(layer)
	_assert.that(layer.setup(Callable(self, "_cell_to_world")), "support presentation lifecycle: coordinate seam binds")
	var snapshots: Array = authority.presentation_snapshots()
	layer.sync_snapshots(snapshots)
	_assert.eq(layer.get_visual_count(), 7, "support presentation lifecycle: one visual per support_id")
	_assert.eq(layer.visual_create_count, 7, "support presentation lifecycle: initial sync creates exactly once")
	_assert.eq(layer.presentation_update_count, 7, "support presentation lifecycle: initial sync updates each visual once")

	var visual = layer.get_visual(SupportIdsScript.SUPPORT_LEFT_SOUTH)
	_assert.that(visual != null, "support presentation lifecycle: stable support visual is addressable")
	if visual != null:
		var original_instance_id: int = visual.get_instance_id()
		_assert.eq(visual.position, _cell_to_world(Vector2i(7, 30), 0.18), "support presentation lifecycle: authored anchor uses shared coordinate seam")
		_assert.that(not visual.has_collision_nodes(), "support presentation lifecycle: visual has no collision authority")
		_assert.that(visual.get_node_or_null("GroundMark") != null, "support presentation lifecycle: low ground mark exists")
		_assert.that(visual.get_node_or_null("SmallFlag") != null, "support presentation lifecycle: small flag exists")
		_assert.that(visual.get_node_or_null("StatusLabel") != null, "support presentation lifecycle: readable status label exists")
		_assert.eq(visual.get_node("StatusLabel").text, "在线", "support presentation lifecycle: Active is explicitly labeled")
		_assert.that(visual.get_node_or_null("CaptureProgressBack") != null, "support presentation lifecycle: compact progress exists")
		var capturing: Dictionary = _snapshot_by_id(snapshots, SupportIdsScript.SUPPORT_LEFT_SOUTH).duplicate(true)
		capturing["capture_side"] = RulesScript.AI_FACTION
		capturing["capture_progress_normalized"] = 0.5
		capturing["derived_view_state"] = ViewStateScript.CAPTURING
		_assert.that(visual.apply_snapshot(capturing), "support presentation lifecycle: Capturing snapshot applies without runtime access")
		_assert.that(visual.get_node("CaptureProgressBack").visible, "support presentation lifecycle: Capturing reveals compact progress")
		_assert.that(visual.get_node("CaptureProgressFill").visible, "support presentation lifecycle: positive progress reveals fill")
		_assert.eq(visual.get_node("StatusLabel").text, "占领 50%", "support presentation lifecycle: Capturing exposes normalized progress")
		_assert.between(visual.get_node("CaptureProgressFill").scale.x, 0.49, 0.51, "support presentation lifecycle: fill scale projects normalized progress")
		var active: Dictionary = capturing.duplicate(true)
		active["capture_progress_normalized"] = 0.0
		active["derived_view_state"] = ViewStateScript.ACTIVE
		visual.apply_snapshot(active)
		_assert.that(not visual.get_node("CaptureProgressBack").visible, "support presentation lifecycle: Active hides capture progress")

		layer.sync_snapshots(snapshots)
		_assert.eq(layer.visual_create_count, 7, "support presentation lifecycle: repeated sync does not recreate")
		_assert.eq(layer.presentation_update_count, 14, "support presentation lifecycle: repeated sync refreshes existing visual projections")
		_assert.eq(layer.get_visual(SupportIdsScript.SUPPORT_LEFT_SOUTH).get_instance_id(), original_instance_id, "support presentation lifecycle: instance identity survives updates")

		# Real downstream state changes must update the existing visual instance. Before
		# this regression, sync_snapshots only applied data while creating a visual,
		# leaving live Active/Offline transitions stale on screen.
		authority.set_support_state(SupportIdsScript.SUPPORT_LEFT_NORTH, RulesScript.PLAYER_FACTION, true)
		layer.sync_snapshots(authority.presentation_snapshots())
		var front_visual = layer.get_visual(SupportIdsScript.SUPPORT_LEFT_NORTH)
		_assert.eq(str(front_visual.last_snapshot.derived_view_state), ViewStateScript.ACTIVE, "support presentation lifecycle: connected front Support renders Active")
		authority.set_operational(SupportIdsScript.SUPPORT_LEFT_SOUTH, false)
		layer.sync_snapshots(authority.presentation_snapshots())
		_assert.eq(str(front_visual.last_snapshot.derived_view_state), ViewStateScript.CAPTURED_OFFLINE, "support presentation lifecycle: severed front Support refreshes to CapturedOffline")
		_assert.eq(front_visual.get_node("StatusLabel").text, "离线", "support presentation lifecycle: CapturedOffline cannot be mistaken for Active")
		_assert.eq(front_visual.get_instance_id(), layer.get_visual(SupportIdsScript.SUPPORT_LEFT_NORTH).get_instance_id(), "support presentation lifecycle: Offline refresh preserves visual identity")

		var authority_before_visual: Dictionary = authority.debug_snapshot()
		front_visual.scale = Vector3(1.05, 1.05, 1.05)
		front_visual.visible = false
		front_visual.visible = true
		_assert.eq(authority.debug_snapshot(), authority_before_visual, "support presentation lifecycle: visual scale/visibility animation cannot mutate Claim or graph truth")
		authority.set_operational(SupportIdsScript.SUPPORT_LEFT_SOUTH, true)

	var reduced: Array = snapshots.duplicate(true)
	reduced = reduced.filter(func(snapshot): return str(snapshot.support_id) != SupportIdsScript.SUPPORT_CENTER)
	layer.sync_snapshots(reduced)
	_assert.eq(layer.get_visual_count(), 6, "support presentation lifecycle: missing stable ID disposes one visual")
	_assert.eq(layer.visual_dispose_count, 1, "support presentation lifecycle: teardown count is auditable")
	layer.clear_visuals()
	_assert.eq(layer.get_visual_count(), 0, "support presentation lifecycle: map teardown clears cache")
	_assert.eq(layer.visual_dispose_count, 7, "support presentation lifecycle: each live visual disposes once")
	layer.queue_free()
	await process_frame


func _cell_to_world(cell: Vector2i, height: float) -> Vector3:
	return Vector3(float(cell.x) * 1.18 + 3.0, height, float(cell.y) * 1.24 - 2.0)


func _on_snapshots_changed(_snapshots: Array) -> void:
	_signal_count += 1


func _snapshot_by_id(snapshots: Array, support_id: String) -> Dictionary:
	for raw_snapshot in snapshots:
		var snapshot: Dictionary = raw_snapshot as Dictionary
		if str(snapshot.get("support_id", "")) == support_id:
			return snapshot
	return {}


func _ids(snapshots: Array) -> Array:
	var result: Array = []
	for raw_snapshot in snapshots:
		result.append(str((raw_snapshot as Dictionary).get("support_id", "")))
	return _sorted(result)


func _sorted(values: Array) -> Array:
	var result: Array = values.duplicate()
	result.sort()
	return result
