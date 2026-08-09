extends SceneTree

const QueryScript = preload("res://scripts/cardfront/deployment/DeploymentQuery.gd")
const ResultScript = preload("res://scripts/cardfront/deployment/DeploymentResult.gd")
const RuleTypeScript = preload("res://scripts/cardfront/deployment/DeploymentRuleType.gd")
const RulesScript = preload("res://scripts/cardfront/deployment/DeploymentRules.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontDeploymentContractTest] Checking extended query/result seam")
	await process_frame

	_test_query_context_is_explicit()
	_test_result_source_is_explicit()
	_test_reason_codes_are_centralized()
	_test_unconfigured_support_rule_fails_closed()

	_assert.report("[CardfrontDeploymentContractTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_query_context_is_explicit() -> void:
	var query = QueryScript.new()
	_assert.that("owner_id" in query and "cell" in query and "rule_type" in query, "deployment contract: legacy query fields remain")
	_assert.that("requested_support_id" in query, "deployment contract: optional stable Support request is explicit")
	_assert.that("spawn_profile_id" in query, "deployment contract: spawn/deploy profile is explicit")
	_assert.that(query.support_network_context is Dictionary, "deployment contract: immutable network context seam is explicit")
	_assert.that(not "network_connected" in query, "deployment contract: query does not own derived connectivity truth")
	_assert.that(RuleTypeScript.is_valid(RuleTypeScript.SUPPORT_NETWORK), "deployment contract: Support network rule type is registered")


func _test_result_source_is_explicit() -> void:
	var result = ResultScript.new()
	_assert.that("allowed" in result and "reason" in result, "deployment contract: legacy result fields remain")
	_assert.that("resolved_support_id" in result, "deployment contract: resolved stable Support is explicit")
	_assert.that("source_kind" in result, "deployment contract: Core/Support source kind is explicit")
	_assert.that("debug_explanation" in result, "deployment contract: deterministic explanation seam is explicit")
	_assert.eq(ResultScript.SOURCE_CORE, "core", "deployment contract: Core source constant")
	_assert.eq(ResultScript.SOURCE_SUPPORT, "support", "deployment contract: Support source constant")


func _test_reason_codes_are_centralized() -> void:
	_assert.eq(RulesScript.REASON_SUPPORT_NOT_CLAIMED, "support_not_claimed", "deployment contract: not-claimed reason")
	_assert.eq(RulesScript.REASON_SUPPORT_OFFLINE, "support_offline", "deployment contract: offline reason")
	_assert.eq(RulesScript.REASON_SUPPORT_DISCONNECTED, "support_disconnected", "deployment contract: disconnected reason")
	_assert.eq(RulesScript.REASON_OUTSIDE_DEPLOYMENT_ZONE, "outside_deployment_zone", "deployment contract: outside-zone reason")
	_assert.eq(RulesScript.REASON_WRONG_DEPLOY_DIRECTION, "wrong_deploy_direction", "deployment contract: direction reason")
	_assert.eq(RulesScript.REASON_NO_VALID_DEPLOYMENT_SOURCE, "no_valid_deployment_source", "deployment contract: no-source reason")


func _test_unconfigured_support_rule_fails_closed() -> void:
	var query = QueryScript.new()
	query.rule_type = RuleTypeScript.SUPPORT_NETWORK
	var result = RulesScript.evaluate(null, null, query)
	_assert.that(not result.allowed, "deployment contract: missing Support context never allows")
	_assert.eq(result.reason, RulesScript.REASON_NO_VALID_DEPLOYMENT_SOURCE, "deployment contract: missing Support context explains no source")
	_assert.eq(result.source_kind, ResultScript.SOURCE_NONE, "deployment contract: denied result has no source")
	_assert.eq(result.debug_explanation, RulesScript.REASON_NO_VALID_DEPLOYMENT_SOURCE, "deployment contract: denied result has deterministic explanation")
