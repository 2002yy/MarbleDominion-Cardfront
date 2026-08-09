extends RefCounted
class_name FrontlineDeploymentTargetRule

const CardPlayResultScript = preload("res://scripts/cardfront/cards/CardPlayResult.gd")
const DeploymentQueryScript = preload("res://scripts/cardfront/deployment/DeploymentQuery.gd")
const DeploymentRulesScript = preload("res://scripts/cardfront/deployment/DeploymentRules.gd")
const DeploymentRuleTypeScript = preload("res://scripts/cardfront/deployment/DeploymentRuleType.gd")


func validate(req, card, context: Dictionary):
	var battlefield = context.get("battlefield", null)
	if battlefield == null:
		return CardPlayResultScript.fail(CardPlayResultScript.REASON_MISSING_SYSTEM, card.card_name)
	var deployment_context: Dictionary = _current_deployment_context(context, int(req.owner_id))
	var query = DeploymentQueryScript.new()
	query.owner_id = int(req.owner_id)
	query.cell = req.target_cell
	query.region_id = int(req.target_region_id)
	query.rule_type = DeploymentRuleTypeScript.SUPPORT_NETWORK
	query.requested_support_id = str(card.params.get("requested_support_id", ""))
	query.spawn_profile_id = str(card.params.get("deployment_profile_id", ""))
	query.support_network_context = deployment_context
	var result = DeploymentRulesScript.evaluate(context.get("region_map", null), battlefield, query)
	if not result.allowed:
		return CardPlayResultScript.fail(CardPlayResultScript.REASON_INVALID_TARGET, card.card_name, str(result.reason))
	var allowed = CardPlayResultScript.ok(card.card_name)
	allowed.authority_reason = str(result.reason)
	return allowed


static func _current_deployment_context(context: Dictionary, owner_id: int) -> Dictionary:
	var provider = context.get("deployment_context_provider", null)
	if provider is Callable and (provider as Callable).is_valid():
		var value = (provider as Callable).call(owner_id)
		return (value as Dictionary).duplicate(true) if value is Dictionary else {}
	var value = context.get("deployment_context", {})
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}
