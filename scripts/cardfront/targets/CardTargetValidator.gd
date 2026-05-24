extends RefCounted
class_name CardTargetValidator

const CardPlayResultScript = preload("res://scripts/cardfront/cards/CardPlayResult.gd")
const CardTargetRuleRegistryScript = preload("res://scripts/cardfront/targets/CardTargetRuleRegistry.gd")

var registry = null
var context: Dictionary = {}


func _init() -> void:
	registry = CardTargetRuleRegistryScript.new()


func setup(new_context: Dictionary, new_registry = null) -> void:
	context = new_context.duplicate(false)
	if new_registry != null:
		registry = new_registry


func register(target_type: String, rule) -> void:
	registry.register(target_type, rule)


func validate(req, card):
	var target_type: String = str(card.target_type)
	var rule = registry.get_rule(target_type)
	if rule == null:
		return CardPlayResultScript.fail(CardPlayResultScript.REASON_INVALID_TARGET, card.card_name)
	return rule.validate(req, card, context)


func has_target_rule(target_type: String) -> bool:
	return registry.has_rule(str(target_type))


func get_registered_target_types() -> Array:
	return registry.get_registered_target_types()
