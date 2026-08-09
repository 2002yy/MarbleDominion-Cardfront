extends SceneTree

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const InitializerScript = preload("res://scripts/cardfront/CardfrontBattlefieldInitializer.gd")
const DefaultMapScript = preload("res://scripts/cardfront/maps/maps/DefaultDuelMap.gd")
const SupportIdsScript = preload("res://scripts/cardfront/support/CardfrontSupportIds.gd")
const RuntimeScript = preload("res://scripts/cardfront/entities/CardfrontBattlefieldEntityLiveRuntime.gd")
const FootprintsScript = preload("res://scripts/cardfront/support/capture/SupportCaptureFootprints.gd")
const OccupancyScript = preload("res://scripts/cardfront/support/capture/SupportCaptureOccupancyAdapter.gd")
const AggregatorScript = preload("res://scripts/cardfront/support/capture/SupportCaptureAggregator.gd")
const MachineScript = preload("res://scripts/cardfront/support/capture/SupportCaptureStateMachine.gd")

var _assert: TestAssert
var _battlefield: Battlefield
var _runtime
var _definition: Dictionary
var _support: Dictionary
var _footprint: Array[Vector2i]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontSupportCaptureTerritoryPrototypeTest] Running default-map territory-gated prototype")
	await _setup_fixture()

	_test_authored_representative_support()
	_test_existing_owned_movement_reaches_footprint_after_territory_advance()
	_test_opponent_presence_contests()
	_test_zero_control_alone_cannot_claim()

	_assert.report("[CardfrontSupportCaptureTerritoryPrototypeTest]")
	TestFixtures.cleanup_node(_battlefield)
	quit(0 if _assert.failures.is_empty() else 1)


func _setup_fixture() -> void:
	_battlefield = Battlefield.new()
	_battlefield.configure(40)
	get_root().add_child(_battlefield)
	await process_frame
	_assert.that(bool(InitializerScript.configure_duel(_battlefield).configured), "territory prototype: real duel ownership initializes")
	_definition = DefaultMapScript.make(Vector2i(40, 40))
	_support = _support_by_id(_definition.deployment_supports, SupportIdsScript.SUPPORT_LEFT_SOUTH)
	_footprint = FootprintsScript.cells_for_profile(
		str(_support.capture_profile_id),
		_support.anchor_cell as Vector2i,
		_battlefield.grid_extent
	)
	_runtime = RuntimeScript.new()
	_battlefield.add_child(_runtime)
	_assert.that(_runtime.setup(_battlefield, _definition), "territory prototype: real entity runtime initializes")


func _test_authored_representative_support() -> void:
	var anchor: Vector2i = _support.anchor_cell as Vector2i
	_assert.eq(str(_support.support_id), SupportIdsScript.SUPPORT_LEFT_SOUTH, "territory prototype: representative uses stable support_id")
	_assert.eq(anchor, Vector2i(7, 30), "territory prototype: default_duel authored anchor is current evidence")
	_assert.eq(str(_support.capture_profile_id), FootprintsScript.PROFILE_SUPPORT_CAPTURE_V1, "territory prototype: authored capture profile resolves footprint")
	_assert.eq(_footprint.size(), 5, "territory prototype: v1 footprint is bounded cross around anchor")
	_assert.that(_footprint.has(anchor + Vector2i.DOWN), "territory prototype: player-side legal approach cell is in footprint")


func _test_existing_owned_movement_reaches_footprint_after_territory_advance() -> void:
	var anchor: Vector2i = _support.anchor_cell as Vector2i
	var start: Vector2i = anchor + Vector2i(0, 2)
	var approach: Vector2i = anchor + Vector2i.DOWN
	var scout = _runtime.registry.spawn_creature("prototype_scout", "scout_unit", RulesScript.PLAYER_FACTION, start, 2)
	_assert.that(scout != null, "territory prototype: control Creature enters real registry")
	_assert.eq(int(_battlefield.owners[start.x][start.y]), RulesScript.PLAYER_FACTION, "territory prototype: start cell is existing player territory")
	_assert.eq(int(_battlefield.owners[approach.x][approach.y]), RulesScript.NEUTRAL_OWNER, "territory prototype: approach starts neutral")
	var blocked_step: Vector2i = _runtime._next_owned_step_toward(RulesScript.PLAYER_FACTION, start, anchor)
	_assert.eq(blocked_step, start, "territory prototype: existing movement refuses neutral approach")
	_assert.eq(OccupancyScript.extract(_runtime.registry, _footprint).size(), 0, "territory prototype: Creature outside footprint contributes nothing")

	_assert.eq(_battlefield.apply_owner_change(approach, RulesScript.PLAYER_FACTION, "support_prototype_territory_pressure"), "OWNER_CHANGED", "territory prototype: existing territory authority opens legal approach")
	var legal_step: Vector2i = _runtime._next_owned_step_toward(RulesScript.PLAYER_FACTION, start, anchor)
	_assert.eq(legal_step, approach, "territory prototype: unchanged movement selects newly owned approach")
	_assert.that(_runtime.registry.move_entity(scout.entity_id, legal_step), "territory prototype: registry applies legal Creature move")

	var contributors: Array = OccupancyScript.extract(_runtime.registry, _footprint)
	_assert.eq(contributors.size(), 1, "territory prototype: moved Creature is extracted inside footprint")
	var player_power: Dictionary = AggregatorScript.aggregate(_for_owner(contributors, RulesScript.PLAYER_FACTION))
	_assert.eq(float(player_power.resolved_capture_power), 2.0, "territory prototype: Scout resolves control power from centralized profile")
	var transition: Dictionary = MachineScript.step({
		"support_id": str(_support.support_id),
		"claim_owner": RulesScript.AI_FACTION,
		"operational": false,
		"capture_side": RulesScript.NEUTRAL_OWNER,
		"capture_progress": 0.0,
	}, float(player_power.resolved_capture_power), 0.0, 5.0)
	_assert.that(bool(transition.capture_completed), "territory prototype: legal footprint control completes Claim")
	_assert.eq(int(transition.claim_owner), RulesScript.PLAYER_FACTION, "territory prototype: Claim transfers after control progress")


func _test_opponent_presence_contests() -> void:
	var anchor: Vector2i = _support.anchor_cell as Vector2i
	var ai_start: Vector2i = anchor + Vector2i.UP
	_battlefield.apply_owner_change(ai_start, RulesScript.AI_FACTION, "support_prototype_ai_territory")
	_battlefield.apply_owner_change(anchor, RulesScript.AI_FACTION, "support_prototype_ai_territory")
	var ai_unit = _runtime.registry.spawn_creature("prototype_ai_repair", "repair_unit", RulesScript.AI_FACTION, ai_start, 2)
	var ai_step: Vector2i = _runtime._next_owned_step_toward(RulesScript.AI_FACTION, ai_start, anchor)
	_assert.eq(ai_step, anchor, "territory prototype: opponent also enters through owned territory")
	_assert.that(_runtime.registry.move_entity(ai_unit.entity_id, ai_step), "territory prototype: opponent move enters footprint")
	var contributors: Array = OccupancyScript.extract(_runtime.registry, _footprint)
	var player_power: float = float(AggregatorScript.aggregate(_for_owner(contributors, RulesScript.PLAYER_FACTION)).resolved_capture_power)
	var ai_power: float = float(AggregatorScript.aggregate(_for_owner(contributors, RulesScript.AI_FACTION)).resolved_capture_power)
	var contested: Dictionary = MachineScript.step({
		"support_id": str(_support.support_id),
		"claim_owner": RulesScript.AI_FACTION,
		"operational": false,
		"capture_side": RulesScript.PLAYER_FACTION,
		"capture_progress": 0.4,
	}, player_power, ai_power, 5.0)
	_assert.that(player_power > 0.0 and ai_power > 0.0, "territory prototype: both sides resolve positive power")
	_assert.that(bool(contested.contested), "territory prototype: opposing footprint presence contests")
	_assert.eq(float(contested.capture_progress), 0.4, "territory prototype: contest freezes progress")


func _test_zero_control_alone_cannot_claim() -> void:
	_runtime.registry.clear()
	var cell: Vector2i = (_support.anchor_cell as Vector2i) + Vector2i.DOWN
	_runtime.registry.spawn_creature("prototype_zero_control", "gate_colossus", RulesScript.PLAYER_FACTION, cell, 8)
	var contributors: Array = OccupancyScript.extract(_runtime.registry, _footprint)
	var result: Dictionary = AggregatorScript.aggregate(_for_owner(contributors, RulesScript.PLAYER_FACTION))
	_assert.eq(contributors.size(), 1, "territory prototype: zero-control Creature remains auditable")
	_assert.eq(float(result.resolved_capture_power), 0.0, "territory prototype: zero-control Creature resolves no capture power")
	var transition: Dictionary = MachineScript.step({
		"support_id": str(_support.support_id),
		"claim_owner": RulesScript.AI_FACTION,
		"operational": false,
		"capture_progress": 0.0,
	}, float(result.resolved_capture_power), 0.0, 10.0)
	_assert.eq(int(transition.claim_owner), RulesScript.AI_FACTION, "territory prototype: zero-control Creature alone cannot change Claim")
	_assert.eq(float(transition.capture_progress), 0.0, "territory prototype: zero-control Creature alone cannot advance")


func _support_by_id(definitions: Array, support_id: String) -> Dictionary:
	for definition in definitions:
		if str((definition as Dictionary).get("support_id", "")) == support_id:
			return (definition as Dictionary).duplicate(true)
	return {}


func _for_owner(contributors: Array, owner_id: int) -> Array:
	return contributors.filter(func(value): return int(value.owner_id) == owner_id)
