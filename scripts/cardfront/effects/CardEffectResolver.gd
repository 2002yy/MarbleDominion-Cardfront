extends RefCounted

const CardEffectRegistryScript = preload("res://scripts/cardfront/effects/CardEffectRegistry.gd")
const CardPlayResultScript = preload("res://scripts/cardfront/cards/CardPlayResult.gd")

var registry = null
var context: Dictionary = {}


func _init() -> void:
	registry = CardEffectRegistryScript.new()


func setup(new_context: Dictionary, new_registry = null) -> void:
	context = new_context.duplicate(false)
	if new_registry != null:
		registry = new_registry


func register(effect_id: String, effect) -> void:
	registry.register(effect_id, effect)


func resolve(req, card):
	var effect_id: String = str(card.effect_id)
	var effect = registry.get_effect(effect_id)
	if effect == null:
		return CardPlayResultScript.fail(CardPlayResultScript.REASON_STUB, card.card_name)
	return effect.resolve(req, card, context)


func has_effect(effect_id: String) -> bool:
	return registry.has_effect(effect_id)


func get_registered_effect_ids() -> Array:
	return registry.get_registered_effect_ids()
