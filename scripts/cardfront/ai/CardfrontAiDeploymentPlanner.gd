extends RefCounted
class_name CardfrontAiDeploymentPlanner

const DeploymentQueryScript = preload("res://scripts/cardfront/deployment/DeploymentQuery.gd")
const DeploymentRulesScript = preload("res://scripts/cardfront/deployment/DeploymentRules.gd")
const DeploymentRuleTypeScript = preload("res://scripts/cardfront/deployment/DeploymentRuleType.gd")

var region_map = null
var battlefield = null
var deployment_context_provider = null


func setup(new_region_map, new_battlefield, new_deployment_context_provider) -> void:
	region_map = new_region_map
	battlefield = new_battlefield
	deployment_context_provider = new_deployment_context_provider


func evaluate_cell(owner_id: int, cell: Vector2i, requested_support_id: String = "", spawn_profile_id: String = ""):
	return _evaluate_with_context(owner_id, cell, requested_support_id, spawn_profile_id, _current_context(owner_id))


func legal_cells(owner_id: int, candidates: Array, requested_support_id: String = "", spawn_profile_id: String = "") -> Array[Vector2i]:
	var context: Dictionary = _current_context(owner_id)
	var legal: Array[Vector2i] = []
	for raw_cell in candidates:
		if not raw_cell is Vector2i:
			continue
		var cell: Vector2i = raw_cell as Vector2i
		if _evaluate_with_context(owner_id, cell, requested_support_id, spawn_profile_id, context).allowed:
			legal.append(cell)
	legal.sort_custom(func(left: Vector2i, right: Vector2i): return left.x < right.x if left.x != right.x else left.y < right.y)
	return legal


func _evaluate_with_context(owner_id: int, cell: Vector2i, requested_support_id: String, spawn_profile_id: String, context: Dictionary):
	var query = DeploymentQueryScript.new()
	query.owner_id = owner_id
	query.cell = cell
	query.rule_type = DeploymentRuleTypeScript.SUPPORT_NETWORK
	query.requested_support_id = requested_support_id
	query.spawn_profile_id = spawn_profile_id
	query.support_network_context = context
	return DeploymentRulesScript.evaluate(region_map, battlefield, query)


func _current_context(owner_id: int) -> Dictionary:
	if deployment_context_provider is Callable and (deployment_context_provider as Callable).is_valid():
		var value = (deployment_context_provider as Callable).call(owner_id)
		return (value as Dictionary).duplicate(true) if value is Dictionary else {}
	return {}
