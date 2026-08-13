extends SceneTree

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const DeploymentRulesScript = preload("res://scripts/cardfront/deployment/DeploymentRules.gd")
const DeploymentQueryScript = preload("res://scripts/cardfront/deployment/DeploymentQuery.gd")
const DeploymentRuleTypeScript = preload("res://scripts/cardfront/deployment/DeploymentRuleType.gd")
const ObservationBuilderScript = preload("res://scripts/cardfront/ai/CardfrontAiObservationBuilder.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontP0PerformanceCounterTest] Checking bounded authority counters")
	await process_frame

	DeploymentRulesScript.reset_evaluation_count_for_test()
	ObservationBuilderScript.reset_build_count_for_test()
	for _frame in 100:
		await process_frame
	_assert.eq(DeploymentRulesScript.get_evaluation_count_for_test(), 0, "P0 counters: 100 idle frames perform no deployment evaluation")
	_assert.eq(ObservationBuilderScript.get_build_count_for_test(), 0, "P0 counters: 100 idle frames build no AI observation")

	var query = DeploymentQueryScript.new()
	query.owner_id = RulesScript.PLAYER_FACTION
	query.cell = Vector2i.ZERO
	query.rule_type = DeploymentRuleTypeScript.OWNED_CELL
	DeploymentRulesScript.evaluate(null, null, query)
	_assert.eq(DeploymentRulesScript.get_evaluation_count_for_test(), 1, "P0 counters: one explicit deployment query increments exactly once")
	ObservationBuilderScript.build({"round_number": 1}, {"command_points": 2}, [])
	_assert.eq(ObservationBuilderScript.get_build_count_for_test(), 1, "P0 counters: one explicit AI projection increments exactly once")

	for _visual_frame in 100:
		var _hovered_cell := Vector2i(_visual_frame % 10, int(_visual_frame / 10))
		await process_frame
	_assert.eq(DeploymentRulesScript.get_evaluation_count_for_test(), 1, "P0 counters: hover/visual frames do not trigger deployment authority")
	_assert.eq(ObservationBuilderScript.get_build_count_for_test(), 1, "P0 counters: hover/visual frames do not rebuild AI observation")

	_assert.report("[CardfrontP0PerformanceCounterTest]")
	quit(0 if _assert.failures.is_empty() else 1)
