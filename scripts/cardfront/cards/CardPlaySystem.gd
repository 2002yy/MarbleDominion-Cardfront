extends RefCounted

const CardCatalogScript = preload("res://scripts/cardfront/cards/CardCatalog.gd")
const CardPlayRequestScript = preload("res://scripts/cardfront/cards/CardPlayRequest.gd")
const CardPlayResultScript = preload("res://scripts/cardfront/cards/CardPlayResult.gd")
const CardHandStateScript = preload("res://scripts/cardfront/cards/CardHandState.gd")
const CardTargetTypeScript = preload("res://scripts/cardfront/cards/CardTargetType.gd")
const DeploymentRulesScript = preload("res://scripts/cardfront/deployment/DeploymentRules.gd")
const FortifyRulesScript = preload("res://scripts/cardfront/fortify/FortifyRules.gd")
const FortifyTargetSelectorScript = preload("res://scripts/cardfront/fortify/FortifyTargetSelector.gd")
const RegionMoraleRulesScript = preload("res://scripts/cardfront/morale/RegionMoraleRules.gd")
const PioneerBeaconLiteEffectScript = preload("res://scripts/cardfront/effects/PioneerBeaconLiteEffect.gd")

const CALIBRATED_SHOT_BIAS_DURATION: float = 6.0

var catalog = null
var hand = null
var resource_states: Dictionary = {}
var region_map = null
var battlefield = null
var fortify_layer = null
var morale_system = null
var region_overlay = null
var target_bias_system = null
var effect_registry: Dictionary = {}


func _init() -> void:
	catalog = CardCatalogScript.new()
	hand = CardHandStateScript.new()
	hand.initialize_fixed_hand(catalog.get_default_hand_ids())
	_register_default_effects()


func setup(new_resource_states: Dictionary, new_region_map, new_battlefield, new_fortify_layer, new_morale_system, new_region_overlay, new_target_bias_system = null) -> void:
	resource_states = new_resource_states.duplicate(false)
	region_map = new_region_map
	battlefield = new_battlefield
	fortify_layer = new_fortify_layer
	morale_system = new_morale_system
	region_overlay = new_region_overlay
	target_bias_system = new_target_bias_system


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
	var effect_id: String = str(card.effect_id)
	if effect_registry.has(effect_id):
		var handler: Callable = effect_registry[effect_id]
		return handler.call(req, card)
	return CardPlayResultScript.fail(CardPlayResultScript.REASON_STUB, card.card_name)


func register_effect_handler(effect_id: String, handler: Callable) -> void:
	if effect_id.is_empty() or not handler.is_valid():
		return
	effect_registry[str(effect_id)] = handler


func has_effect_handler(effect_id: String) -> bool:
	return effect_registry.has(str(effect_id))


func get_registered_effect_ids() -> Array:
	var ids: Array = effect_registry.keys()
	ids.sort()
	return ids


func _register_default_effects() -> void:
	effect_registry.clear()
	register_effect_handler("fortify_border", Callable(self, "_resolve_fortify_border"))
	register_effect_handler("calibrated_shot", Callable(self, "_resolve_calibrated_shot"))
	register_effect_handler("morale_fluctuation", Callable(self, "_resolve_morale_fluctuation"))
	register_effect_handler("pioneer_beacon_lite", Callable(self, "_resolve_pioneer_beacon_lite"))


func _resolve_fortify_border(req, card):
	if fortify_layer == null:
		return CardPlayResultScript.fail(CardPlayResultScript.REASON_MISSING_SYSTEM, card.card_name)

	var cell: Vector2i = req.target_cell
	fortify_layer.add_fortify_stack(cell, FortifyRulesScript.DEFAULT_FORTIFY_STACKS)

	if region_overlay != null and is_instance_valid(region_overlay) and region_overlay.has_method("mark_dirty"):
		region_overlay.mark_dirty()

	return CardPlayResultScript.ok(card.card_name)


func _resolve_calibrated_shot(req, card):
	if target_bias_system == null or not target_bias_system.has_method("apply_region_bias"):
		return CardPlayResultScript.fail(CardPlayResultScript.REASON_MISSING_SYSTEM, card.card_name)

	var applied: bool = bool(target_bias_system.apply_region_bias(
		int(req.owner_id),
		int(req.target_region_id),
		CALIBRATED_SHOT_BIAS_DURATION
	))
	if not applied:
		return CardPlayResultScript.fail(CardPlayResultScript.REASON_INVALID_TARGET, card.card_name)

	return CardPlayResultScript.ok(card.card_name)


func _resolve_morale_fluctuation(req, card):
	if morale_system == null or not morale_system.has_method("apply_morale"):
		return CardPlayResultScript.fail(CardPlayResultScript.REASON_MISSING_SYSTEM, card.card_name)

	var applied: bool = bool(morale_system.apply_morale(
		int(req.target_region_id),
		int(req.owner_id),
		RegionMoraleRulesScript.SUPPORT_PLAYER
	))
	if not applied:
		return CardPlayResultScript.fail(CardPlayResultScript.REASON_INVALID_TARGET, card.card_name)

	return CardPlayResultScript.ok(card.card_name)


func _resolve_pioneer_beacon_lite(req, card):
	var effect_result: Dictionary = PioneerBeaconLiteEffectScript.apply(region_map, battlefield, int(req.owner_id), req.target_cell)
	if not bool(effect_result.get("success", false)):
		var reason: String = str(effect_result.get("reason", PioneerBeaconLiteEffectScript.REASON_INVALID_TARGET))
		if reason == PioneerBeaconLiteEffectScript.REASON_MISSING_SYSTEM:
			return CardPlayResultScript.fail(CardPlayResultScript.REASON_MISSING_SYSTEM, card.card_name)
		return CardPlayResultScript.fail(CardPlayResultScript.REASON_INVALID_TARGET, card.card_name)

	if region_overlay != null and is_instance_valid(region_overlay) and region_overlay.has_method("mark_dirty"):
		region_overlay.mark_dirty()

	return CardPlayResultScript.ok(card.card_name)


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
