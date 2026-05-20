extends RefCounted

const CardCatalogScript = preload("res://scripts/cardfront/cards/CardCatalog.gd")
const CardPlayRequestScript = preload("res://scripts/cardfront/cards/CardPlayRequest.gd")
const CardPlayResultScript = preload("res://scripts/cardfront/cards/CardPlayResult.gd")
const CardHandStateScript = preload("res://scripts/cardfront/cards/CardHandState.gd")
const CardTargetTypeScript = preload("res://scripts/cardfront/cards/CardTargetType.gd")
const DeploymentRulesScript = preload("res://scripts/cardfront/deployment/DeploymentRules.gd")
const CardEffectResolverScript = preload("res://scripts/cardfront/effects/CardEffectResolver.gd")
const FortifyBorderEffectScript = preload("res://scripts/cardfront/effects/effects/FortifyBorderEffect.gd")
const CalibratedShotEffectScript = preload("res://scripts/cardfront/effects/effects/CalibratedShotEffect.gd")
const MoraleFluctuationEffectScript = preload("res://scripts/cardfront/effects/effects/MoraleFluctuationEffect.gd")
const PioneerBeaconLiteEffectScript = preload("res://scripts/cardfront/effects/effects/PioneerBeaconLiteEffect.gd")

var catalog = null
var hand = null
var resource_states: Dictionary = {}
var region_map = null
var battlefield = null
var fortify_layer = null
var morale_system = null
var region_overlay = null
var target_bias_system = null
var effect_resolver = null


func _init() -> void:
	catalog = CardCatalogScript.new()
	hand = CardHandStateScript.new()
	hand.initialize_fixed_hand(catalog.get_default_hand_ids())
	effect_resolver = CardEffectResolverScript.new()
	_register_default_effects()


func setup(new_resource_states: Dictionary, new_region_map, new_battlefield, new_fortify_layer, new_morale_system, new_region_overlay, new_target_bias_system = null) -> void:
	resource_states = new_resource_states.duplicate(false)
	region_map = new_region_map
	battlefield = new_battlefield
	fortify_layer = new_fortify_layer
	morale_system = new_morale_system
	region_overlay = new_region_overlay
	target_bias_system = new_target_bias_system
	effect_resolver.setup(_build_effect_context())


func can_play(req):
	if req == null:
		return CardPlayResultScript.fail(CardPlayResultScript.REASON_UNKNOWN_CARD)

	var card_id: int = int(req.card_id)
	var card = catalog.get_card(card_id)
	if card == null:
		return CardPlayResultScript.fail(CardPlayResultScript.REASON_UNKNOWN_CARD)

	if not hand.can_play_card(card_id):
		return CardPlayResultScript.fail(CardPlayResultScript.REASON_CARD_ALREADY_USED, card.card_name)

	var state = resource_states.get(int(req.owner_id), null)
	if state == null:
		return CardPlayResultScript.fail(CardPlayResultScript.REASON_INSUFFICIENT_RESOURCES, card.card_name)

	if not state.can_pay(card.energy_cost, card.parts_cost):
		return CardPlayResultScript.fail(CardPlayResultScript.REASON_INSUFFICIENT_RESOURCES, card.card_name)

	var target_result = _validate_target(req, card)
	if not target_result.success:
		return target_result

	return CardPlayResultScript.ok(card.card_name, card.energy_cost, card.parts_cost)


func play(req):
	var check = can_play(req)
	if not check.success:
		return check

	var card_id: int = int(req.card_id)
	var card = catalog.get_card(card_id)
	var state = resource_states.get(int(req.owner_id), null)

	state.pay(card.energy_cost, card.parts_cost)
	hand.mark_used(card_id)

	var effect_result = _resolve_effect(req, card)
	if not effect_result.success:
		state.add_energy(card.energy_cost)
		state.add_parts(card.parts_cost)
		hand.used_card_ids[int(card_id)] = false
		return effect_result

	return CardPlayResultScript.ok(card.card_name, card.energy_cost, card.parts_cost)


func _validate_target(req, card):
	match card.target_type:
		CardTargetTypeScript.OWNED_BORDER:
			if battlefield == null or region_map == null:
				return CardPlayResultScript.fail(CardPlayResultScript.REASON_MISSING_SYSTEM, card.card_name)
			if not DeploymentRulesScript.is_owned_border(region_map, battlefield, req.target_cell, req.owner_id):
				return CardPlayResultScript.fail(CardPlayResultScript.REASON_INVALID_TARGET, card.card_name)
		CardTargetTypeScript.ENEMY_REGION, CardTargetTypeScript.OWNED_REGION:
			if req.target_region_id < 0:
				return CardPlayResultScript.fail(CardPlayResultScript.REASON_INVALID_TARGET, card.card_name)
			if region_map == null or not region_map.has_method("get_region_cells"):
				return CardPlayResultScript.fail(CardPlayResultScript.REASON_MISSING_SYSTEM, card.card_name)
			if not _is_valid_region_id(int(req.target_region_id)):
				return CardPlayResultScript.fail(CardPlayResultScript.REASON_INVALID_TARGET, card.card_name)
	return CardPlayResultScript.ok(card.card_name)


func _resolve_effect(req, card):
	return effect_resolver.resolve(req, card)


func register_effect(effect_id: String, effect) -> void:
	effect_resolver.register(effect_id, effect)


func has_effect_handler(effect_id: String) -> bool:
	return effect_resolver.has_effect(str(effect_id))


func get_registered_effect_ids() -> Array:
	return effect_resolver.get_registered_effect_ids()


func _register_default_effects() -> void:
	register_effect("fortify_border", FortifyBorderEffectScript.new())
	register_effect("calibrated_shot", CalibratedShotEffectScript.new())
	register_effect("morale_fluctuation", MoraleFluctuationEffectScript.new())
	register_effect("pioneer_beacon_lite", PioneerBeaconLiteEffectScript.new())


func _build_effect_context() -> Dictionary:
	return {
		"region_map": region_map,
		"battlefield": battlefield,
		"fortify_layer": fortify_layer,
		"morale_system": morale_system,
		"region_overlay": region_overlay,
		"target_bias_system": target_bias_system,
	}


func _is_valid_region_id(region_id: int) -> bool:
	if region_map == null or not region_map.has_method("get_region_cells"):
		return false
	return not region_map.get_region_cells(int(region_id)).is_empty()


func get_hand_card_data() -> Array:
	var result = []
	for id in hand.card_ids:
		var card = catalog.get_card(int(id))
		if card != null:
			var copy: Dictionary = card.snapshot()
			copy["used"] = hand.is_used(int(id))
			copy["available"] = hand.can_play_card(int(id))
			result.append(copy)
	return result


func get_available_card_data() -> Array:
	var result = []
	for id in hand.get_available_card_ids():
		var card = catalog.get_card(int(id))
		if card != null:
			result.append(card.snapshot())
	return result
