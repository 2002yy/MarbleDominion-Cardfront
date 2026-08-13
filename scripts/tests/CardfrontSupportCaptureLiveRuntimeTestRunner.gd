extends SceneTree

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const SupportIdsScript = preload("res://scripts/cardfront/support/CardfrontSupportIds.gd")
const FootprintsScript = preload("res://scripts/cardfront/support/capture/SupportCaptureFootprints.gd")
const SuppressionFootprintsScript = preload("res://scripts/cardfront/support/capture/SupportSuppressionFootprints.gd")
const DeploymentRulesScript = preload("res://scripts/cardfront/deployment/DeploymentRules.gd")
const DeploymentQueryScript = preload("res://scripts/cardfront/deployment/DeploymentQuery.gd")
const DeploymentRuleTypeScript = preload("res://scripts/cardfront/deployment/DeploymentRuleType.gd")
const ViewStateScript = preload("res://scripts/cardfront/support/presentation/SupportPresentationViewState.gd")
const SnapshotScript = preload("res://scripts/cardfront/save/CardfrontRuntimeSnapshot.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontSupportCaptureLiveRuntimeTest] Checking real Main capture cutover")
	var main = await _start_main()
	var battlefield = main.runtime.battlefield
	var entity_runtime = battlefield.get_node_or_null("CardfrontBattlefieldEntityRuntime")
	var capture_runtime = battlefield.get_meta("cardfront_support_capture_runtime", null)
	var authority = battlefield.get_meta("cardfront_support_deployment_authority", null)
	_assert.that(entity_runtime != null, "live capture: entity runtime exists")
	_assert.that(capture_runtime != null, "live capture: separate Support capture runtime exists")
	_assert.that(authority != null, "live capture: deployment authority exists")
	if entity_runtime == null or capture_runtime == null or authority == null:
		_cleanup(main)
		return
	capture_runtime.set_process(false)

	var definition: Dictionary = _definition_by_id(
		capture_runtime.map_definition.deployment_supports,
		SupportIdsScript.SUPPORT_LEFT_SOUTH
	)
	var anchor: Vector2i = definition.anchor_cell
	var footprint: Array[Vector2i] = FootprintsScript.cells_for_profile(
		str(definition.capture_profile_id),
		anchor,
		battlefield.grid_extent
	)
	var suppression_footprint: Array[Vector2i] = SuppressionFootprintsScript.cells_for_profile(
		str(definition.suppression_profile_id),
		anchor,
		battlefield.grid_extent
	)
	_assert.eq(suppression_footprint, footprint, "live capture: v1 authored suppression and capture footprints are equal but resolved by separate profiles")
	for cell in footprint:
		battlefield.apply_owner_change(cell, RulesScript.PLAYER_FACTION, "live_support_test")
	var scout = entity_runtime.registry.spawn_creature(
		"live_capture_scout",
		"scout_unit",
		RulesScript.PLAYER_FACTION,
		anchor,
		1
	)
	_assert.that(scout != null, "live capture: control unit enters authored footprint")
	capture_runtime.step(5.0)

	var state: Dictionary = capture_runtime.public_state(SupportIdsScript.SUPPORT_LEFT_SOUTH)
	_assert.eq(int(state.claim_owner), RulesScript.PLAYER_FACTION, "live capture: real runtime completes Claim")
	_assert.that(bool(state.operational), "live capture: 100 percent local territory recovers operational state")
	_assert.that(bool(state.network_connected), "live capture: rear Support reconnects to real Core topology")
	_assert.that(SupportIdsScript.SUPPORT_LEFT_SOUTH in authority.deployment_context(RulesScript.PLAYER_FACTION).online_support_ids, "live capture: Online result reaches deployment authority")
	var visual_snapshot: Dictionary = _snapshot_by_id(authority.presentation_snapshots(), SupportIdsScript.SUPPORT_LEFT_SOUTH)
	_assert.eq(str(visual_snapshot.derived_view_state), ViewStateScript.ACTIVE, "live capture: presentation projects Active")

	var legal_cell: Vector2i = anchor + Vector2i.DOWN
	var query = DeploymentQueryScript.new()
	query.owner_id = RulesScript.PLAYER_FACTION
	query.cell = legal_cell
	query.rule_type = DeploymentRuleTypeScript.SUPPORT_NETWORK
	query.requested_support_id = SupportIdsScript.SUPPORT_LEFT_SOUTH
	query.support_network_context = authority.deployment_context(RulesScript.PLAYER_FACTION)
	_assert.that(DeploymentRulesScript.evaluate(null, battlefield, query).allowed, "live capture: directional deployment becomes legal through the captured Support")

	# Cut the local territory below 40 percent without touching projectile capture authority.
	for index in range(suppression_footprint.size()):
		if index >= 1:
			battlefield.apply_owner_change(suppression_footprint[index], RulesScript.AI_FACTION, "live_support_test_suppress")
	capture_runtime.step(0.0)
	state = capture_runtime.public_state(SupportIdsScript.SUPPORT_LEFT_SOUTH)
	_assert.that(not bool(state.operational), "live capture: frozen local-share threshold suppresses the Support")
	_assert.that(SupportIdsScript.SUPPORT_LEFT_SOUTH not in authority.deployment_context(RulesScript.PLAYER_FACTION).online_support_ids, "live capture: suppressed Support is removed from deployment authority")
	_assert.that(entity_runtime.registry.get_entity("live_capture_scout") == scout, "live capture: Support loss does not delete existing units")
	visual_snapshot = _snapshot_by_id(authority.presentation_snapshots(), SupportIdsScript.SUPPORT_LEFT_SOUTH)
	_assert.eq(str(visual_snapshot.derived_view_state), ViewStateScript.DISABLED_NEUTRAL, "live capture: suppressed state reaches UI projection")

	# Snapshot/restore stores authoritative Support state and rebuilds derived connectivity.
	var saved = SnapshotScript.capture(main.runtime).to_dict()
	_assert.that(saved.support_states.has(SupportIdsScript.SUPPORT_LEFT_SOUTH), "live capture save: formal runtime snapshot captures Support state")
	for cell in footprint:
		battlefield.apply_owner_change(cell, RulesScript.PLAYER_FACTION, "live_support_test_recover")
	SnapshotScript.apply_to_runtime(main.runtime, saved)
	state = capture_runtime.public_state(SupportIdsScript.SUPPORT_LEFT_SOUTH)
	_assert.that(not bool(state.operational), "live capture restore: saved authoritative suppression state restores")
	_assert.that(not bool(state.network_connected), "live capture restore: derived connectivity rebuild does not trust a stale Online bit")
	capture_runtime.step(0.0)
	state = capture_runtime.public_state(SupportIdsScript.SUPPORT_LEFT_SOUTH)
	_assert.that(bool(state.operational) and bool(state.network_connected), "live capture: restored Claim automatically recovers Online after territory reconnect")

	_cleanup(main)
	_assert.report("[CardfrontSupportCaptureLiveRuntimeTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _start_main():
	GameConfig.reset_runtime_defaults()
	paused = false
	var main = load("res://scenes/Main.tscn").instantiate()
	get_root().add_child(main)
	await process_frame
	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_size = 40
	main._start_game(40, true, false)
	await process_frame
	await process_frame
	return main


func _definition_by_id(definitions: Array, support_id: String) -> Dictionary:
	for raw_definition in definitions:
		var definition: Dictionary = raw_definition as Dictionary
		if str(definition.get("support_id", "")) == support_id:
			return definition
	return {}


func _snapshot_by_id(snapshots: Array, support_id: String) -> Dictionary:
	for raw_snapshot in snapshots:
		var snapshot: Dictionary = raw_snapshot as Dictionary
		if str(snapshot.get("support_id", "")) == support_id:
			return snapshot
	return {}


func _cleanup(main) -> void:
	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)
