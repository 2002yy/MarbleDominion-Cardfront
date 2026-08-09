extends SceneTree

const Rules = preload("res://scripts/cardfront/CardfrontRules.gd")
const DefaultMapScript = preload("res://scripts/cardfront/maps/maps/DefaultDuelMap.gd")
const Ids = preload("res://scripts/cardfront/support/CardfrontSupportIds.gd")
const QueryScript = preload("res://scripts/cardfront/deployment/DeploymentQuery.gd")
const ResultScript = preload("res://scripts/cardfront/deployment/DeploymentResult.gd")
const RuleTypeScript = preload("res://scripts/cardfront/deployment/DeploymentRuleType.gd")
const DeploymentRulesScript = preload("res://scripts/cardfront/deployment/DeploymentRules.gd")
const ContextScript = preload("res://scripts/cardfront/deployment/DeploymentSupportContext.gd")
const GeometryScript = preload("res://scripts/cardfront/deployment/DeploymentGeometry.gd")

var _assert: TestAssert
var _battlefield: Battlefield
var _map_definition: Dictionary


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontDeploymentDirectionalZoneTest] Checking frozen rear rectangle")
	await _setup_fixture()

	_test_frozen_dimensions()
	_test_player_and_ai_directions()
	_test_lateral_and_depth_bounds()
	_test_offline_requested_support_fails()
	_test_overlap_tie_break()
	_test_core_fallback_survives_online_supports()

	_assert.report("[CardfrontDeploymentDirectionalZoneTest]")
	TestFixtures.cleanup_node(_battlefield)
	quit(0 if _assert.failures.is_empty() else 1)


func _setup_fixture() -> void:
	_battlefield = Battlefield.new()
	_battlefield.configure(40)
	get_root().add_child(_battlefield)
	await process_frame
	_map_definition = DefaultMapScript.make(Vector2i(40, 40))


func _test_frozen_dimensions() -> void:
	_assert.eq(GeometryScript.dimensions(Vector2i(40, 40)), {"lateral_half_width_cells": 3, "rear_depth_cells": 4}, "directional zone: 40x40 frozen dimensions")
	_assert.eq(GeometryScript.dimensions(Vector2i(40, 60)), {"lateral_half_width_cells": 3, "rear_depth_cells": 4}, "directional zone: min axis controls 40x60")
	_assert.eq(GeometryScript.dimensions(Vector2i(50, 50)), {"lateral_half_width_cells": 4, "rear_depth_cells": 5}, "directional zone: 50x50 frozen dimensions")


func _test_player_and_ai_directions() -> void:
	var anchor := Vector2i(7, 30)
	var player_context: Dictionary = ContextScript.with_online_supports(_map_definition, Rules.PLAYER_FACTION, [Ids.SUPPORT_LEFT_SOUTH])
	_set_owner(anchor + Vector2i.DOWN, Rules.PLAYER_FACTION)
	_set_owner(anchor + Vector2i.UP, Rules.PLAYER_FACTION)
	var player_rear = _evaluate(Rules.PLAYER_FACTION, anchor + Vector2i.DOWN, player_context, Ids.SUPPORT_LEFT_SOUTH)
	_assert.that(player_rear.allowed, "directional zone: player rear cell allowed")
	_assert.eq(player_rear.source_kind, ResultScript.SOURCE_SUPPORT, "directional zone: player resolves Support source")
	_assert.eq(player_rear.resolved_support_id, Ids.SUPPORT_LEFT_SOUTH, "directional zone: stable Support source ID")
	var player_front = _evaluate(Rules.PLAYER_FACTION, anchor + Vector2i.UP, player_context, Ids.SUPPORT_LEFT_SOUTH)
	_assert.eq(player_front.reason, DeploymentRulesScript.REASON_WRONG_DEPLOY_DIRECTION, "directional zone: player forward cell rejected")

	var ai_context: Dictionary = ContextScript.with_online_supports(_map_definition, Rules.AI_FACTION, [Ids.SUPPORT_LEFT_SOUTH])
	_set_owner(anchor + Vector2i.UP, Rules.AI_FACTION)
	var ai_rear = _evaluate(Rules.AI_FACTION, anchor + Vector2i.UP, ai_context, Ids.SUPPORT_LEFT_SOUTH)
	_assert.that(ai_rear.allowed, "directional zone: AI rear direction is opposite player")


func _test_lateral_and_depth_bounds() -> void:
	var anchor := Vector2i(7, 30)
	var context: Dictionary = ContextScript.with_online_supports(_map_definition, Rules.PLAYER_FACTION, [Ids.SUPPORT_LEFT_SOUTH])
	for cell in [anchor + Vector2i(3, 4), anchor + Vector2i(-3, 0)]:
		_set_owner(cell, Rules.PLAYER_FACTION)
		_assert.that(_evaluate(Rules.PLAYER_FACTION, cell, context, Ids.SUPPORT_LEFT_SOUTH).allowed, "directional zone: inclusive lateral/rear boundary %s" % cell)
	for cell in [anchor + Vector2i(4, 0), anchor + Vector2i(0, 5)]:
		_set_owner(cell, Rules.PLAYER_FACTION)
		_assert.eq(_evaluate(Rules.PLAYER_FACTION, cell, context, Ids.SUPPORT_LEFT_SOUTH).reason, DeploymentRulesScript.REASON_OUTSIDE_DEPLOYMENT_ZONE, "directional zone: beyond bound rejected %s" % cell)


func _test_offline_requested_support_fails() -> void:
	var context: Dictionary = ContextScript.core_only(_map_definition, Rules.PLAYER_FACTION)
	var result = _evaluate(Rules.PLAYER_FACTION, Vector2i(7, 31), context, Ids.SUPPORT_LEFT_SOUTH)
	_assert.eq(result.reason, DeploymentRulesScript.REASON_SUPPORT_OFFLINE, "directional zone: requested authored but offline Support fails explicitly")


func _test_overlap_tie_break() -> void:
	var target := Vector2i(10, 10)
	_set_owner(target, Rules.PLAYER_FACTION)
	var context: Dictionary = ContextScript.core_only(_map_definition, Rules.PLAYER_FACTION)
	context.known_support_ids = ["support_a", "support_z", Ids.CORE_PLAYER]
	context.online_support_ids = ["support_a", "support_z"]
	context.support_sources = [
		{"support_id": "support_z", "anchor_cell": Vector2i(9, 9), "forward": Vector2i.UP, "profile_id": GeometryScript.PROFILE_DIRECTIONAL_REAR_RECT_V1},
		{"support_id": "support_a", "anchor_cell": Vector2i(11, 9), "forward": Vector2i.UP, "profile_id": GeometryScript.PROFILE_DIRECTIONAL_REAR_RECT_V1},
	]
	var equal_distance = _evaluate(Rules.PLAYER_FACTION, target, context)
	_assert.eq(equal_distance.resolved_support_id, "support_a", "directional zone: equal-distance overlap uses lexical support_id")
	context.support_sources[0].anchor_cell = Vector2i(10, 9)
	var nearest = _evaluate(Rules.PLAYER_FACTION, target, context)
	_assert.eq(nearest.resolved_support_id, "support_z", "directional zone: overlap prefers nearer anchor before lexical ID")


func _test_core_fallback_survives_online_supports() -> void:
	var context: Dictionary = ContextScript.with_online_supports(_map_definition, Rules.PLAYER_FACTION, [Ids.SUPPORT_LEFT_SOUTH])
	var core_cell := Vector2i(0, 39)
	_set_owner(core_cell, Rules.PLAYER_FACTION)
	var result = _evaluate(Rules.PLAYER_FACTION, core_cell, context)
	_assert.that(result.allowed, "directional zone: Online Support does not remove Core fallback")
	_assert.eq(result.source_kind, ResultScript.SOURCE_CORE, "directional zone: Core remains resolved source")


func _evaluate(side: int, cell: Vector2i, context: Dictionary, requested_support_id: String = ""):
	var query = QueryScript.new()
	query.owner_id = side
	query.cell = cell
	query.rule_type = RuleTypeScript.SUPPORT_NETWORK
	query.requested_support_id = requested_support_id
	query.support_network_context = context
	return DeploymentRulesScript.evaluate(null, _battlefield, query)


func _set_owner(cell: Vector2i, owner_id: int) -> void:
	_battlefield.owners[cell.x][cell.y] = owner_id
