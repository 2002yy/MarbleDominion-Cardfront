extends SceneTree

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const ContributorScript = preload("res://scripts/cardfront/support/capture/SupportCaptureContributor.gd")
const AggregatorScript = preload("res://scripts/cardfront/support/capture/SupportCaptureAggregator.gd")
const TuningScript = preload("res://scripts/cardfront/support/capture/SupportCaptureTuning.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontSupportCaptureAggregatorTest] Checking diminishing aggregation")
	await process_frame

	_test_empty_and_zero_weight()
	_test_second_contributor_still_helps()
	_test_third_plus_is_non_linear()
	_test_large_swarm_is_bounded()
	_test_order_is_deterministic()

	_assert.report("[CardfrontSupportCaptureAggregatorTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _contributor(entity_id: String, weight: float, eligible: bool = true):
	var contributor = ContributorScript.new()
	contributor.setup(entity_id, RulesScript.PLAYER_FACTION, "test", weight, Vector2i.ZERO, eligible)
	return contributor


func _assert_close(actual: float, expected: float, label: String) -> void:
	_assert.that(absf(actual - expected) < 0.0001, "%s (actual %.4f, expected %.4f)" % [label, actual, expected])


func _test_empty_and_zero_weight() -> void:
	var result: Dictionary = AggregatorScript.aggregate([
		_contributor("zero", 0.0),
		_contributor("ineligible", 5.0, false),
		null,
	])
	_assert_close(float(result.raw_weight), 0.0, "aggregator: zero/ineligible raw weight")
	_assert_close(float(result.resolved_capture_power), 0.0, "aggregator: zero/ineligible resolved power")
	_assert.eq(int(result.contributor_count), 0, "aggregator: zero/ineligible contributors are excluded")
	_assert.that(not bool(result.capped_or_diminished), "aggregator: empty result is not diminished")


func _test_second_contributor_still_helps() -> void:
	var one: Dictionary = AggregatorScript.aggregate([_contributor("one", 1.0)])
	var two: Dictionary = AggregatorScript.aggregate([_contributor("one", 1.0), _contributor("two", 1.0)])
	_assert_close(float(one.resolved_capture_power), 1.0, "aggregator: first contributor uses full weight")
	_assert_close(float(two.resolved_capture_power), 1.6, "aggregator: second contributor uses centralized multiplier")
	_assert.that(float(two.resolved_capture_power) > float(one.resolved_capture_power), "aggregator: second contributor helps")
	_assert.that(bool(two.capped_or_diminished), "aggregator: multiple contributors report diminishing")


func _test_third_plus_is_non_linear() -> void:
	var two: Dictionary = AggregatorScript.aggregate([_contributor("one", 1.0), _contributor("two", 1.0)])
	var three: Dictionary = AggregatorScript.aggregate([_contributor("one", 1.0), _contributor("two", 1.0), _contributor("three", 1.0)])
	var four: Dictionary = AggregatorScript.aggregate([_contributor("one", 1.0), _contributor("two", 1.0), _contributor("three", 1.0), _contributor("four", 1.0)])
	_assert_close(float(three.resolved_capture_power), 1.85, "aggregator: third contributor is diminished")
	_assert_close(float(four.resolved_capture_power), 1.975, "aggregator: fourth contributor decays again")
	_assert.that(float(four.resolved_capture_power) - float(three.resolved_capture_power) < float(three.resolved_capture_power) - float(two.resolved_capture_power), "aggregator: third-plus marginal value is non-linear")


func _test_large_swarm_is_bounded() -> void:
	var swarm: Array = []
	for index in 100:
		swarm.append(_contributor("swarm_%d" % index, 2.0))
	var result: Dictionary = AggregatorScript.aggregate(swarm)
	_assert_close(float(result.raw_weight), 200.0, "aggregator: raw weight remains auditable")
	_assert_close(float(result.resolved_capture_power), TuningScript.MAX_CAPTURE_POWER, "aggregator: large swarm hits hard cap")
	_assert.eq(int(result.contributor_count), 100, "aggregator: contributor count remains auditable")
	_assert.that(bool(result.capped_or_diminished), "aggregator: capped swarm is flagged")


func _test_order_is_deterministic() -> void:
	var forward: Dictionary = AggregatorScript.aggregate([_contributor("light", 2.0), _contributor("heavy", 0.5), _contributor("standard", 1.0)])
	var reverse: Dictionary = AggregatorScript.aggregate([_contributor("standard", 1.0), _contributor("heavy", 0.5), _contributor("light", 2.0)])
	_assert_close(float(forward.resolved_capture_power), float(reverse.resolved_capture_power), "aggregator: input order does not change result")
