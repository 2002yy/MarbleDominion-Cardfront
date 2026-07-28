extends SceneTree

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const HeroRegistryScript = preload("res://scripts/cardfront/heroes/CardfrontHeroRegistry.gd")
const DeckRegistryScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeDeckRegistry.gd")
const DraftSystemScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeDraftSystem.gd")
const ManifestScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeManifest.gd")
const ResolverScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeResolver.gd")
const RunStateScript = preload("res://scripts/cardfront/run/CardfrontFactionRunState.gd")
const AiPolicyScript = preload("res://scripts/cardfront/run/CardfrontAiUpgradePolicy.gd")
const VolleyResolverScript = preload("res://scripts/cardfront/volley/CardfrontVolleyResolver.gd")
const ProjectileTypeScript = preload("res://scripts/cardfront/volley/CardfrontProjectileType.gd")
const DeckSimulatorScript = preload("res://scripts/cardfront/simulation/CardfrontB1DeckMatchSimulator.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontUpgradeDeckTest] Starting selectable deck and tactical card tests")
	await process_frame
	_test_deck_contracts()
	_test_default_pool_exposes_formal_conversions()
	_test_candidate_decks_filter_offers()
	_test_typed_conversion_effects()
	_test_entity_upgrade_state()
	_test_deck_aware_ai_values()
	_test_candidate_simulator_uses_decks()
	_assert.report("[CardfrontUpgradeDeckTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_deck_contracts() -> void:
	_assert.eq(ManifestScript.validate_all(), [], "decks: all eighteen card definitions should validate")
	_assert.eq(DeckRegistryScript.validate_all(), [], "decks: all three bounded decks should validate")
	_assert.eq(ManifestScript.CORE_UPGRADE_IDS.size(), 8, "decks: historical audit baseline should contain eight cards")
	_assert.eq(ManifestScript.get_upgrade_ids().size(), 18, "decks: formal live pool should contain eighteen cards")
	_assert.eq(ManifestScript.get_all_upgrade_ids().size(), 18, "decks: catalog should contain only implemented cards")
	for deck_id in DeckRegistryScript.get_deck_ids():
		var deck_size: int = DeckRegistryScript.get_upgrade_ids(str(deck_id)).size()
		_assert.that(deck_size >= DeckRegistryScript.MIN_DECK_SIZE and deck_size <= DeckRegistryScript.MAX_DECK_SIZE, "decks: every deck should stay inside the supported size range")


func _test_default_pool_exposes_formal_conversions() -> void:
	var state = _hero_state(HeroRegistryScript.HERO_BALANCED_COMMANDER)
	var draft = DraftSystemScript.new()
	var seen: Dictionary = {}
	for seed_value in range(1, 161):
		draft.set_seed(seed_value)
		for upgrade_id in _offer_ids(draft.draw_three(state)):
			seen[str(upgrade_id)] = true
			_assert.that(upgrade_id in ManifestScript.get_upgrade_ids(), "decks: default state must stay inside the formal live pool")
	_assert.that(seen.has(ManifestScript.UPGRADE_SIEGE_CALIBRATION), "decks: default live pool should expose siege formation")
	_assert.that(seen.has(ManifestScript.UPGRADE_SUPPRESSION_SCREEN), "decks: default live pool should expose suppression formation")
	_assert.that(seen.has(ManifestScript.UPGRADE_REPAIR_UNITS), "decks: default live pool should expose repair units")
	_assert.that(seen.has(ManifestScript.UPGRADE_FIRE_CONTROL_BEACON), "decks: default live pool should expose fire-control beacon")
	_assert.that(seen.has(ManifestScript.UPGRADE_ARMORED_GUARD), "decks: default live pool should expose armored guard")
	_assert.that(seen.has(ManifestScript.UPGRADE_SAPPER_UNIT), "decks: default live pool should expose sapper unit")
	_assert.that(seen.has(ManifestScript.UPGRADE_GATE_COLOSSUS), "decks: default live pool should expose gate colossus")


func _test_candidate_decks_filter_offers() -> void:
	var state = _hero_state(HeroRegistryScript.HERO_FORTIFICATION_ENGINEER)
	var draft = DraftSystemScript.new()
	state.set_deck_id(DeckRegistryScript.DECK_FORTIFICATION_CORPS)
	var fortification_seen: Dictionary = {}
	for seed_value in range(1, 81):
		draft.set_seed(seed_value)
		for upgrade_id in _offer_ids(draft.draw_three(state)):
			fortification_seen[upgrade_id] = true
			_assert.that(upgrade_id in DeckRegistryScript.get_upgrade_ids(state.deck_id), "decks: fortification offer must stay inside its deck")
	_assert.that(fortification_seen.has(ManifestScript.UPGRADE_SIEGE_CALIBRATION), "decks: fortification deck should expose siege grouping")
	_assert.that(fortification_seen.has(ManifestScript.UPGRADE_HEAVY_CHARGE), "decks: fortification deck should expose heavy charge")
	_assert.that(fortification_seen.has(ManifestScript.UPGRADE_INTERCEPTOR_TOWER), "decks: fortification deck should expose interceptor tower")
	_assert.that(fortification_seen.has(ManifestScript.UPGRADE_ARMORED_GUARD), "decks: fortification deck should expose armored guard")
	_assert.that(fortification_seen.has(ManifestScript.UPGRADE_SAPPER_UNIT), "decks: fortification deck should expose sapper unit")
	_assert.that(fortification_seen.has(ManifestScript.UPGRADE_GATE_COLOSSUS), "decks: fortification deck should expose gate colossus")

	state.set_deck_id(DeckRegistryScript.DECK_BARRAGE_CONTROL)
	var barrage_seen: Dictionary = {}
	for seed_value in range(81, 161):
		draft.set_seed(seed_value)
		for upgrade_id in _offer_ids(draft.draw_three(state)):
			barrage_seen[upgrade_id] = true
			_assert.that(upgrade_id in DeckRegistryScript.get_upgrade_ids(state.deck_id), "decks: barrage offer must stay inside its deck")
	_assert.that(barrage_seen.has(ManifestScript.UPGRADE_SUPPRESSION_SCREEN), "decks: barrage deck should expose the approved suppression route card")
	_assert.that(not barrage_seen.has(ManifestScript.UPGRADE_SIEGE_CALIBRATION), "decks: gunner deck should not borrow the Engineer siege conversion")


func _test_typed_conversion_effects() -> void:
	var resolver = ResolverScript.new()
	var volley_resolver = VolleyResolverScript.new()
	var engineer = _hero_state(HeroRegistryScript.HERO_FORTIFICATION_ENGINEER)
	_assert.that(bool(resolver.resolve(engineer, ManifestScript.UPGRADE_SIEGE_CALIBRATION).get("success", false)), "decks: siege grouping should resolve")
	var engineer_plan = volley_resolver.build_and_consume(engineer)
	_assert.eq(int(engineer_plan.projectile_counts.get(ProjectileTypeScript.SIEGE, 0)), 3, "decks: Engineer should fire three siege shots after grouping")
	_assert.eq(int(engineer_plan.projectile_counts.get(ProjectileTypeScript.STANDARD, 0)), 2, "decks: siege grouping should convert exactly two standard shots")

	var reinforced = _hero_state(HeroRegistryScript.HERO_FORTIFICATION_ENGINEER)
	resolver.resolve(reinforced, ManifestScript.UPGRADE_VOLLEY_PLUS_5)
	var reinforced_plan = volley_resolver.build_and_consume(reinforced)
	_assert.eq(int(reinforced_plan.projectile_counts.get(ProjectileTypeScript.STANDARD, 0)), 9, "decks: +5 should add only standard shots")
	_assert.eq(int(reinforced_plan.projectile_counts.get(ProjectileTypeScript.SIEGE, 0)), 1, "decks: +5 should not duplicate the Engineer siege shot")

	var gunner = _hero_state(HeroRegistryScript.HERO_RAPID_GUNNER)
	resolver.resolve(gunner, ManifestScript.UPGRADE_SUPPRESSION_SCREEN)
	var gunner_plan = volley_resolver.build_and_consume(gunner)
	_assert.eq(int(gunner_plan.projectile_counts.get(ProjectileTypeScript.SUPPRESSION, 0)), 3, "decks: suppression formation should convert two standard shots")
	_assert.eq(int(gunner_plan.projectile_counts.get(ProjectileTypeScript.STANDARD, 0)), 4, "decks: suppression formation should preserve total projectile count")
	_assert.gt(ProjectileTypeScript.territory_pressure_for_sequence(gunner_plan.projectile_sequence), 7.0, "decks: suppression formation should create visible route pressure")


func _test_entity_upgrade_state() -> void:
	var state = _hero_state(HeroRegistryScript.HERO_FORTIFICATION_ENGINEER)
	var resolver = ResolverScript.new()
	_assert.that(bool(resolver.resolve(state, ManifestScript.UPGRADE_REPAIR_UNITS).get("success", false)), "decks: repair units should resolve")
	_assert.eq(state.pending_entity_actions.size(), 1, "decks: repair units should queue one summon action")
	_assert.that(bool(resolver.resolve(state, ManifestScript.UPGRADE_ARMORED_GUARD).get("success", false)), "decks: armored guard should resolve")
	_assert.eq(state.pending_entity_actions.size(), 2, "decks: armored guard should queue one summon action")
	_assert.that(bool(resolver.resolve(state, ManifestScript.UPGRADE_SAPPER_UNIT).get("success", false)), "decks: sapper unit should resolve")
	_assert.eq(state.pending_entity_actions.size(), 3, "decks: sapper unit should queue one summon action")
	_assert.that(bool(resolver.resolve(state, ManifestScript.UPGRADE_GATE_COLOSSUS).get("success", false)), "decks: gate colossus should resolve")
	_assert.eq(state.pending_entity_actions.size(), 4, "decks: gate colossus should queue one summon action")
	_assert.that(state.neutral_creature_summoned, "decks: gate colossus should become once-per-faction immediately")
	_assert.that(bool(resolver.resolve(state, ManifestScript.UPGRADE_BUILDING_VOLLEY).get("success", false)), "decks: building volley should resolve")
	_assert.eq(state.building_volley_level, 1, "decks: building volley should gain one permanent level")
	_assert.that(bool(resolver.resolve(state, ManifestScript.UPGRADE_HEAVY_CHARGE).get("success", false)), "decks: heavy charge should resolve")
	_assert.that(not state.heavy_charge_spec.is_empty(), "decks: heavy charge should arm the next volley")


func _test_deck_aware_ai_values() -> void:
	var policy = AiPolicyScript.new()
	var engineer = _hero_state(HeroRegistryScript.HERO_FORTIFICATION_ENGINEER)
	engineer.set_deck_id(DeckRegistryScript.DECK_FORTIFICATION_CORPS)

	var defended_route: Dictionary = _base_context()
	defended_route["enemy_defense_points"] = 24
	defended_route["enemy_defense_contact_chance"] = 0.20
	defended_route["siege_defense_contact_chance"] = 0.75
	defended_route["estimated_chamber_hit_chance"] = 0.50
	defended_route["expected_frontline_captures"] = 3.0
	defended_route["repairable_frontline_cells"] = 6
	defended_route["route_pressure"] = 2.5
	var siege: Dictionary = policy.evaluate_id(ManifestScript.UPGRADE_SIEGE_CALIBRATION, engineer, defended_route)
	defended_route["enemy_defense_tower_count"] = 2
	var heavy_charge: Dictionary = policy.evaluate_id(ManifestScript.UPGRADE_HEAVY_CHARGE, engineer, defended_route)
	var armored_guard: Dictionary = policy.evaluate_id(ManifestScript.UPGRADE_ARMORED_GUARD, engineer, defended_route)
	var sapper: Dictionary = policy.evaluate_id(ManifestScript.UPGRADE_SAPPER_UNIT, engineer, defended_route)
	var colossus: Dictionary = policy.evaluate_id(ManifestScript.UPGRADE_GATE_COLOSSUS, engineer, defended_route)
	var plus_five: Dictionary = policy.evaluate_id(ManifestScript.UPGRADE_VOLLEY_PLUS_5, engineer, defended_route)
	_assert.gt(float(siege.get("score", 0.0)), float(plus_five.get("score", 0.0)), "decks AI: targeted siege should beat flat shots at a high-confidence defended bottleneck")
	_assert.gt(float(siege.get("expected_pierced_contacts", 0.0)), 0.0, "decks AI: siege conversion should expose expected pierced contacts")
	_assert.gt(float(heavy_charge.get("score", 0.0)), 0.0, "decks AI: heavy charge should gain value against enemy towers")
	_assert.gt(float(armored_guard.get("score", 0.0)), 0.0, "decks AI: armored guard should gain persistent route-block value")
	_assert.gt(float(sapper.get("score", 0.0)), float(armored_guard.get("score", 0.0)), "decks AI: sapper should gain extra value against defended enemy towers")
	_assert.gt(float(colossus.get("score", 0.0)), 0.0, "decks AI: gate colossus should have strategic comeback value")
	var trailing_context: Dictionary = defended_route.duplicate(true)
	trailing_context["own_health_ratio"] = 0.30
	trailing_context["enemy_health_ratio"] = 0.80
	var leading_context: Dictionary = defended_route.duplicate(true)
	leading_context["own_health_ratio"] = 0.80
	leading_context["enemy_health_ratio"] = 0.30
	var trailing_colossus: Dictionary = policy.evaluate_id(ManifestScript.UPGRADE_GATE_COLOSSUS, engineer, trailing_context)
	var leading_colossus: Dictionary = policy.evaluate_id(ManifestScript.UPGRADE_GATE_COLOSSUS, engineer, leading_context)
	_assert.gt(float(trailing_colossus.get("score", 0.0)), float(leading_colossus.get("score", 0.0)), "decks AI: neutral colossus should be valued more as a comeback tool")

	var dense_random_defense: Dictionary = defended_route.duplicate(true)
	dense_random_defense["enemy_defense_contact_chance"] = 0.65
	var armor: Dictionary = policy.evaluate_id(ManifestScript.UPGRADE_ARMOR_PIERCING, engineer, dense_random_defense)
	var dense_plus_five: Dictionary = policy.evaluate_id(ManifestScript.UPGRADE_VOLLEY_PLUS_5, engineer, dense_random_defense)
	_assert.gt(float(armor.get("score", 0.0)), float(dense_plus_five.get("score", 0.0)), "decks AI: armor piercing should become rational only with dense generic defense contacts")

	var saturated: Dictionary = defended_route.duplicate(true)
	saturated["repairable_frontline_cells"] = 0
	saturated["owned_cell_count"] = 18
	saturated["defended_cell_count"] = 18
	var defense_cap: Dictionary = policy.evaluate_id(ManifestScript.UPGRADE_DEFENSE_CAP_PLUS_1, engineer, saturated)
	var saturated_plus_five: Dictionary = policy.evaluate_id(ManifestScript.UPGRADE_VOLLEY_PLUS_5, engineer, saturated)
	_assert.gt(float(defense_cap.get("score", 0.0)), float(saturated_plus_five.get("score", 0.0)), "decks AI: defense cap should become rational when a complete line is already saturated")

	var no_towers: Dictionary = defended_route.duplicate(true)
	no_towers["enemy_defense_tower_count"] = 0
	var untargeted_heavy: Dictionary = policy.evaluate_id(ManifestScript.UPGRADE_HEAVY_CHARGE, engineer, no_towers)
	_assert.that(float(heavy_charge.get("score", 0.0)) > float(untargeted_heavy.get("score", 0.0)), "decks AI: heavy charge should respond to enemy tower count")

	var gunner = _hero_state(HeroRegistryScript.HERO_RAPID_GUNNER)
	gunner.set_deck_id(DeckRegistryScript.DECK_BARRAGE_CONTROL)
	var calm: Dictionary = _base_context()
	calm["route_pressure"] = 0.6
	var pressured: Dictionary = _base_context()
	pressured["route_pressure"] = 2.0
	var suppression_calm: Dictionary = policy.evaluate_id(ManifestScript.UPGRADE_SUPPRESSION_SCREEN, gunner, calm)
	var suppression_pressured: Dictionary = policy.evaluate_id(ManifestScript.UPGRADE_SUPPRESSION_SCREEN, gunner, pressured)
	var gunner_plus_five: Dictionary = policy.evaluate_id(ManifestScript.UPGRADE_VOLLEY_PLUS_5, gunner, pressured)
	_assert.gt(float(suppression_pressured.get("score", 0.0)), float(suppression_calm.get("score", 0.0)), "decks AI: suppression should remain route-context sensitive")
	_assert.gt(float(suppression_pressured.get("score", 0.0)), float(gunner_plus_five.get("score", 0.0)), "decks AI: suppression should beat flat shots under high route pressure")

	var balanced = _hero_state(HeroRegistryScript.HERO_BALANCED_COMMANDER)
	var early: Dictionary = _base_context()
	early["rounds_remaining"] = 18
	var rarity: Dictionary = policy.evaluate_id(ManifestScript.UPGRADE_RARITY_PLUS_1, balanced, early)
	var balanced_plus_five: Dictionary = policy.evaluate_id(ManifestScript.UPGRADE_VOLLEY_PLUS_5, balanced, early)
	_assert.gt(float(rarity.get("score", 0.0)), float(balanced_plus_five.get("score", 0.0)), "decks AI: rarity growth should beat flat shots in a long early-game horizon")

	engineer.record_upgrade(ManifestScript.UPGRADE_SIEGE_CALIBRATION, 2)
	var repeated: Dictionary = policy.evaluate_id(ManifestScript.UPGRADE_SIEGE_CALIBRATION, engineer, defended_route)
	_assert.eq(float(repeated.get("build_repeat_multiplier", 0.0)), 0.8, "decks AI: repeated identical cards should receive a visible diversity penalty")
	var synergistic = _hero_state(HeroRegistryScript.HERO_FORTIFICATION_ENGINEER)
	synergistic.set_deck_id(DeckRegistryScript.DECK_FORTIFICATION_CORPS)
	synergistic.record_upgrade(ManifestScript.UPGRADE_ARMOR_PIERCING)
	var synergy: Dictionary = policy.evaluate_id(ManifestScript.UPGRADE_SIEGE_CALIBRATION, synergistic, defended_route)
	_assert.gt(float(synergy.get("build_synergy_multiplier", 1.0)), 1.0, "decks AI: matching siege and anti-fortify tags should receive synergy value")


func _test_candidate_simulator_uses_decks() -> void:
	var simulator = DeckSimulatorScript.new()
	var result: Dictionary = simulator.simulate_with_decks(
		HeroRegistryScript.HERO_FORTIFICATION_ENGINEER,
		HeroRegistryScript.HERO_RAPID_GUNNER,
		"default_duel",
		0,
		29,
		DeckRegistryScript.DECK_FORTIFICATION_CORPS,
		DeckRegistryScript.DECK_BARRAGE_CONTROL
	)
	_assert.that(bool(result.get("success", false)), "decks simulator: mixed-deck B1 match should complete")
	_assert.eq(str(result.get("deck_a", "")), DeckRegistryScript.DECK_FORTIFICATION_CORPS, "decks simulator: slot A deck should be disclosed")
	_assert.eq(str(result.get("deck_b", "")), DeckRegistryScript.DECK_BARRAGE_CONTROL, "decks simulator: slot B deck should be disclosed")
	_assert.eq(int((result.get("metrics", {}) as Dictionary).get("invalid_offers", -1)), 0, "decks simulator: candidate decks should produce valid offers")


func _hero_state(hero_id: String):
	var state = RunStateScript.new()
	state.setup_from_hero(RulesScript.PLAYER_FACTION, hero_id)
	return state


func _offer_ids(offer: Array) -> Array:
	var result: Array = []
	for raw_definition in offer:
		if raw_definition is Dictionary:
			result.append(str((raw_definition as Dictionary).get("id", "")))
	return result


func _base_context() -> Dictionary:
	return {
		"round_number": 1,
		"rounds_remaining": 18,
		"estimated_chamber_hit_chance": 0.17,
		"enemy_defense_contact_chance": 0.20,
		"enemy_defense_points": 12,
		"repairable_frontline_cells": 4,
		"owned_cell_count": 18,
		"defended_cell_count": 12,
		"own_health_ratio": 1.0,
		"enemy_health_ratio": 1.0,
		"route_pressure": 1.0,
		"future_offer_size": 3,
		"expected_frontline_captures": 1.5,
		"enemy_defense_tower_count": 0,
	}
