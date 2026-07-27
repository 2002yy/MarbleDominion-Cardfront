extends RefCounted
class_name CardfrontAiUpgradePolicy

const UpgradeManifestScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeManifest.gd")
const ValuePolicyScript = preload("res://scripts/cardfront/run/CardfrontUpgradeValuePolicy.gd")

var last_ranked_evaluations: Array = []


func choose(
	offer: Array,
	run_state = null,
	context: Dictionary = {},
	valuation_mode: String = ValuePolicyScript.MODE_MARGINAL
) -> Dictionary:
	var offer_ids: Array = []
	var definitions_by_id: Dictionary = {}
	for raw_definition in offer:
		if not (raw_definition is Dictionary):
			continue
		var definition: Dictionary = raw_definition as Dictionary
		var upgrade_id: String = str(definition.get("id", ""))
		if upgrade_id == "":
			continue
		offer_ids.append(upgrade_id)
		definitions_by_id[upgrade_id] = definition
	var chosen_id: String = choose_id(offer_ids, run_state, context, valuation_mode)
	if chosen_id == "" or not definitions_by_id.has(chosen_id):
		return {}
	return (definitions_by_id[chosen_id] as Dictionary).duplicate(true)


func choose_id(
	offer_ids: Array,
	run_state = null,
	context: Dictionary = {},
	valuation_mode: String = ValuePolicyScript.MODE_MARGINAL
) -> String:
	last_ranked_evaluations = rank_ids(offer_ids, run_state, context, valuation_mode)
	if last_ranked_evaluations.is_empty():
		return ""
	return str((last_ranked_evaluations[0] as Dictionary).get("upgrade_id", ""))


func rank_ids(
	offer_ids: Array,
	run_state = null,
	context: Dictionary = {},
	valuation_mode: String = ValuePolicyScript.MODE_MARGINAL
) -> Array:
	var ranked: Array = []
	for index in range(offer_ids.size()):
		var upgrade_id: String = str(offer_ids[index])
		if not UpgradeManifestScript.has_upgrade(upgrade_id):
			continue
		var evaluation: Dictionary = ValuePolicyScript.evaluate(
			upgrade_id,
			run_state,
			context,
			valuation_mode
		)
		if not bool(evaluation.get("eligible", false)):
			continue
		evaluation["offer_index"] = index
		evaluation["tie_broken_score"] = float(evaluation.get("score", -INF)) - float(index) * 0.001
		ranked.append(evaluation)
	ranked.sort_custom(_sort_evaluations)
	return ranked


func evaluate_id(
	upgrade_id: String,
	run_state = null,
	context: Dictionary = {},
	valuation_mode: String = ValuePolicyScript.MODE_MARGINAL
) -> Dictionary:
	return ValuePolicyScript.evaluate(upgrade_id, run_state, context, valuation_mode)


func get_last_ranked_evaluations() -> Array:
	return last_ranked_evaluations.duplicate(true)


func _score(definition: Dictionary, run_state, context: Dictionary = {}) -> float:
	return _score_id(str(definition.get("id", "")), run_state, context)


func _score_id(upgrade_id: String, run_state, context: Dictionary = {}) -> float:
	return float(ValuePolicyScript.evaluate(upgrade_id, run_state, context).get("score", -INF))


func _sort_evaluations(left: Dictionary, right: Dictionary) -> bool:
	var left_score: float = float(left.get("tie_broken_score", -INF))
	var right_score: float = float(right.get("tie_broken_score", -INF))
	if absf(left_score - right_score) < 0.000001:
		return int(left.get("offer_index", 0)) < int(right.get("offer_index", 0))
	return left_score > right_score
