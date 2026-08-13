extends Node
class_name CardfrontRoundDirector

signal phase_changed(previous_phase, next_phase)
signal countdown_updated(time_remaining, round_number, player_state)
signal draft_opened(player_offer, ai_offer, timeout_seconds, round_number)
signal draft_time_updated(time_remaining, timeout_seconds)
signal strongholds_sampled(status_snapshot)
signal gates_sampled(snapshot)
signal choice_locked(owner_id, upgrade_id, automatic)
signal choices_revealed(player_definition, ai_definition, resolution_results)
signal volley_launched(plans, issued_intents)
signal director_stopped

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const MatchPhaseScript = preload("res://scripts/cardfront/run/CardfrontMatchPhase.gd")
const MatchPhaseControllerScript = preload("res://scripts/cardfront/run/CardfrontMatchPhaseController.gd")
const RunStateScript = preload("res://scripts/cardfront/run/CardfrontFactionRunState.gd")
const DraftSystemScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeDraftSystem.gd")
const DraftOfferContextScript = preload("res://scripts/cardfront/draft/CardfrontDraftOfferContext.gd")
const UpgradeResolverScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeResolver.gd")
const VolleyResolverScript = preload("res://scripts/cardfront/volley/CardfrontVolleyResolver.gd")
const AiCommanderScript = preload("res://scripts/cardfront/ai/CardfrontAiCommander.gd")
const AiObservationBuilderScript = preload("res://scripts/cardfront/ai/CardfrontAiObservationBuilder.gd")
const LaneAllocationScript = preload("res://scripts/cardfront/volley/CardfrontLaneAllocation.gd")
const CommandPointSystemScript = preload("res://scripts/cardfront/run/CardfrontCommandPointSystem.gd")
const TuningScript = preload("res://scripts/cardfront/run/CardfrontRunTuning.gd")
const HeroRegistryScript = preload("res://scripts/cardfront/heroes/CardfrontHeroRegistry.gd")

const BATTLE_INTERVAL: float = TuningScript.AIM_SECONDS
const FIRST_DRAFT_COUNTDOWN: float = TuningScript.FIRST_AIM_SECONDS
const DRAFT_TIMEOUT: float = TuningScript.DRAFT_SECONDS
const REVEAL_DURATION: float = TuningScript.REVEAL_SECONDS
const VALUE_PLANNING_MAX_ROUNDS: int = 34

var fire_director = null
var turrets: Dictionary = {}
var direction_controller = null
var stronghold_system = null
var territory_defense_system = null
var gate_connectivity_system = null
var battlefield_entity_runtime = null
var hero_assignments: Dictionary = {}
var phase_controller = MatchPhaseControllerScript.new()
var run_states: Dictionary = {}
var current_offers: Dictionary = {}
var current_plans: Dictionary = {}
var last_resolution_results: Dictionary = {}
var current_stronghold_status: Dictionary = {}
var current_gate_snapshot: Dictionary = {}
var round_number: int = 0
var active: bool = false

var _draft_system = DraftSystemScript.new()
var _upgrade_resolver = UpgradeResolverScript.new()
var _volley_resolver = VolleyResolverScript.new()
var _ai_commander = AiCommanderScript.new()
var command_points = CommandPointSystemScript.new()
var _reveal_remaining: float = 0.0
var _resolution_started: bool = false
var _draft_pause_owned: bool = false


func _init() -> void:
	name = "CardfrontRoundDirector"
	process_mode = Node.PROCESS_MODE_ALWAYS


func setup(
	new_fire_director,
	new_turrets: Dictionary,
	new_direction_controller = null,
	new_stronghold_system = null,
	new_hero_assignments: Dictionary = {},
	new_gate_connectivity_system = null
) -> bool:
	fire_director = new_fire_director
	turrets = new_turrets.duplicate(false)
	direction_controller = new_direction_controller
	stronghold_system = new_stronghold_system
	gate_connectivity_system = new_gate_connectivity_system
	if fire_director == null or not is_instance_valid(fire_director):
		return false
	for owner_id in RulesScript.get_duel_factions():
		if not turrets.has(owner_id) or turrets[owner_id] == null or not is_instance_valid(turrets[owner_id]):
			return false

	hero_assignments.clear()
	for owner_id in RulesScript.get_duel_factions():
		var fallback_hero_id: String = (
			HeroRegistryScript.DEFAULT_PLAYER_HERO_ID
			if int(owner_id) == RulesScript.PLAYER_FACTION
			else HeroRegistryScript.DEFAULT_AI_HERO_ID
		)
		hero_assignments[int(owner_id)] = HeroRegistryScript.sanitize_hero_id(
			str(new_hero_assignments.get(int(owner_id), fallback_hero_id)),
			fallback_hero_id
		)

	run_states.clear()
	for owner_id in RulesScript.get_duel_factions():
		var state = RunStateScript.new()
		state.setup_from_hero(int(owner_id), str(hero_assignments[int(owner_id)]))
		run_states[int(owner_id)] = state
		var turret = turrets.get(int(owner_id), null)
		if turret != null and is_instance_valid(turret) and turret.has_method("configure_health_pool"):
			turret.configure_health_pool(int(state.command_chamber_health), true)
	_ai_commander.set_hero(str(hero_assignments.get(RulesScript.AI_FACTION, "")))
	command_points.setup(RulesScript.get_duel_factions())

	var phase_callable := Callable(self, "_on_phase_changed")
	if not phase_controller.phase_changed.is_connected(phase_callable):
		phase_controller.phase_changed.connect(phase_callable)
	var timeout_callable := Callable(self, "_on_draft_timeout")
	if not phase_controller.draft_timeout_reached.is_connected(timeout_callable):
		phase_controller.draft_timeout_reached.connect(timeout_callable)

	phase_controller.setup(RulesScript.get_duel_factions(), BATTLE_INTERVAL, DRAFT_TIMEOUT)
	phase_controller.time_remaining = FIRST_DRAFT_COUNTDOWN
	_draft_system.randomize_seed()
	fire_director.set_process(false)
	active = true
	set_process(true)
	return true


func _process(delta: float) -> void:
	if not active:
		return
	if _has_destroyed_turret():
		stop()
		return

	match phase_controller.phase:
		MatchPhaseScript.BATTLE_COUNTDOWN:
			if get_tree() != null and get_tree().paused:
				return
			phase_controller.tick(delta)
			countdown_updated.emit(
				phase_controller.time_remaining,
				round_number,
				get_run_state(RulesScript.PLAYER_FACTION)
			)
		MatchPhaseScript.DRAFT_PAUSED:
			phase_controller.tick(delta)
			draft_time_updated.emit(phase_controller.time_remaining, phase_controller.draft_timeout)
			if phase_controller.has_all_choices():
				_begin_resolution()
		MatchPhaseScript.RESOLVE_CHOICES:
			_reveal_remaining = maxf(0.0, _reveal_remaining - maxf(0.0, delta))
			if _reveal_remaining <= 0.0:
				_launch_resolved_volleys()


func select_player_upgrade(upgrade_id: String) -> bool:
	if not active or phase_controller.phase != MatchPhaseScript.DRAFT_PAUSED:
		return false
	if not _offer_contains(RulesScript.PLAYER_FACTION, upgrade_id):
		return false
	if not phase_controller.select_upgrade(RulesScript.PLAYER_FACTION, upgrade_id):
		return false
	choice_locked.emit(RulesScript.PLAYER_FACTION, str(upgrade_id), false)
	if phase_controller.has_all_choices():
		_begin_resolution()
	return true


func is_draft_active() -> bool:
	return phase_controller.phase in [MatchPhaseScript.DRAFT_PAUSED, MatchPhaseScript.RESOLVE_CHOICES]


func get_run_state(owner_id: int):
	return run_states.get(int(owner_id), null)


func get_phase() -> String:
	return str(phase_controller.phase)


func get_player_offer() -> Array:
	return (current_offers.get(RulesScript.PLAYER_FACTION, []) as Array).duplicate(true)


func get_ai_offer() -> Array:
	return (current_offers.get(RulesScript.AI_FACTION, []) as Array).duplicate(true)


func get_stronghold_status(owner_id: int) -> Dictionary:
	return (current_stronghold_status.get(int(owner_id), {}) as Dictionary).duplicate(true)


func get_upgrade_value_context(owner_id: int) -> Dictionary:
	return AiObservationBuilderScript.valuation_context(get_ai_observation(owner_id))


func get_ai_observation(owner_id: int) -> Dictionary:
	var safe_owner_id: int = int(owner_id)
	var opponent_id: int = _opponent_id(safe_owner_id)
	var own_defense: Dictionary = {}
	var enemy_defense: Dictionary = {}
	if territory_defense_system != null and is_instance_valid(territory_defense_system):
		if territory_defense_system.has_method("get_owner_defense_snapshot"):
			own_defense = territory_defense_system.get_owner_defense_snapshot(safe_owner_id, "frontline")
			enemy_defense = territory_defense_system.get_owner_defense_snapshot(opponent_id, "frontline")
	var enemy_owned_cells: int = maxi(1, int(enemy_defense.get("owned_cell_count", 1)))
	var enemy_defended_ratio: float = clampf(
		float(enemy_defense.get("defended_cell_count", 0)) / float(enemy_owned_cells),
		0.0,
		1.0
	)
	var enemy_cap: int = maxi(1, int(enemy_defense.get("cap", 1)))
	var own_state = get_run_state(safe_owner_id)
	var enemy_state = get_run_state(opponent_id)
	var public_source: Dictionary = {
		"round_number": maxi(1, round_number),
		"rounds_remaining": maxi(1, VALUE_PLANNING_MAX_ROUNDS - maxi(1, round_number) + 1),
		"pre_multiplier_shot_bonus": 0,
		"post_multiplier_shot_bonus": 0,
		"temporary_attack_level_bonus": 0,
		"estimated_chamber_hit_chance": 0.17,
		"enemy_defense_contact_chance": clampf(
			0.06 + enemy_defended_ratio * 0.28 + float(enemy_cap) * 0.025,
			0.05,
			0.55
		),
		"enemy_defense_points": maxi(0, int(enemy_defense.get("total_defense_points", 0))),
		"repairable_frontline_cells": mini(6, maxi(0, int(own_defense.get("repairable_frontline_cells", 0)))),
		"owned_cell_count": maxi(0, int(own_defense.get("owned_cell_count", 18))),
		"defended_cell_count": maxi(0, int(own_defense.get("defended_cell_count", 0))),
		"own_health_ratio": _turret_health_ratio(safe_owner_id),
		"enemy_health_ratio": _turret_health_ratio(opponent_id),
		"route_pressure": clampf(0.85 + enemy_defended_ratio * 0.50, 0.5, 1.5),
		"future_offer_size": DraftSystemScript.DEFAULT_OFFER_SIZE,
		"enemy_defense_tower_count": int(enemy_state.owned_defense_tower_count) if enemy_state != null else 0,
	}
	var own_source: Dictionary = AiObservationBuilderScript.project_own_state(own_state)
	own_source["pre_multiplier_shot_bonus"] = 0
	own_source["post_multiplier_shot_bonus"] = 0
	own_source["temporary_attack_level_bonus"] = 0
	own_source["future_offer_size"] = DraftSystemScript.DEFAULT_OFFER_SIZE
	return AiObservationBuilderScript.build(public_source, own_source, [])


func get_last_ai_value_report() -> Array:
	return _ai_commander.get_last_ranked_evaluations()


func set_seed_for_tests(seed_value: int) -> void:
	_draft_system.set_seed(seed_value)


func set_territory_defense_system(system) -> void:
	territory_defense_system = system


func set_battlefield_entity_runtime(runtime) -> void:
	battlefield_entity_runtime = runtime


func force_open_draft_for_test() -> void:
	if phase_controller.phase != MatchPhaseScript.BATTLE_COUNTDOWN:
		return
	phase_controller.time_remaining = 0.0
	phase_controller.tick(0.0)


func complete_reveal_for_test() -> void:
	if phase_controller.phase != MatchPhaseScript.RESOLVE_CHOICES:
		return
	_reveal_remaining = 0.0
	_launch_resolved_volleys()


func stop() -> void:
	if not active:
		return
	active = false
	set_process(false)
	_set_draft_pause(false)
	_set_direction_input_enabled(false)
	director_stopped.emit()


func _on_phase_changed(previous_phase: String, next_phase: String) -> void:
	phase_changed.emit(previous_phase, next_phase)
	if next_phase == MatchPhaseScript.DRAFT_PAUSED:
		_open_draft()


func _open_draft() -> void:
	round_number += 1
	_resolution_started = false
	current_plans.clear()
	last_resolution_results.clear()
	current_stronghold_status = _sample_strongholds()
	current_gate_snapshot = _sample_gates()
	if battlefield_entity_runtime != null and is_instance_valid(battlefield_entity_runtime):
		battlefield_entity_runtime.prepare_draft(run_states)
	var player_context = DraftOfferContextScript.create(
		RulesScript.PLAYER_FACTION,
		get_run_state(RulesScript.PLAYER_FACTION)
	)
	var ai_context = DraftOfferContextScript.create(
		RulesScript.AI_FACTION,
		get_run_state(RulesScript.AI_FACTION)
	)
	current_offers = {
		RulesScript.PLAYER_FACTION: _draft_system.draw_offer_for_context(
			player_context,
			DraftSystemScript.DEFAULT_OFFER_SIZE
		),
		RulesScript.AI_FACTION: _draft_system.draw_offer_for_context(
			ai_context,
			DraftSystemScript.DEFAULT_OFFER_SIZE
		),
	}
	var ai_choice: Dictionary = _ai_commander.choose(
		get_ai_offer(),
		get_run_state(RulesScript.AI_FACTION),
		get_upgrade_value_context(RulesScript.AI_FACTION)
	)
	var ai_choice_id: String = str(ai_choice.get("id", ""))
	if ai_choice_id != "" and phase_controller.select_upgrade(RulesScript.AI_FACTION, ai_choice_id):
		choice_locked.emit(RulesScript.AI_FACTION, ai_choice_id, true)
	_set_direction_input_enabled(false)
	_set_draft_pause(true)
	draft_opened.emit(get_player_offer(), get_ai_offer(), phase_controller.draft_timeout, round_number)
	draft_time_updated.emit(phase_controller.time_remaining, phase_controller.draft_timeout)


func _on_draft_timeout() -> void:
	for owner_id in phase_controller.get_missing_owner_ids():
		var offer: Array = current_offers.get(int(owner_id), []) as Array
		var fallback: Dictionary = _draft_system.choose_timeout_fallback(offer, int(owner_id))
		var fallback_id: String = str(fallback.get("id", ""))
		if fallback_id != "" and phase_controller.select_upgrade(int(owner_id), fallback_id):
			choice_locked.emit(int(owner_id), fallback_id, true)
	if phase_controller.has_all_choices():
		_begin_resolution()


func _begin_resolution() -> void:
	if _resolution_started or not phase_controller.has_all_choices():
		return
	if not phase_controller.begin_resolve():
		return
	_resolution_started = true
	for owner_id in RulesScript.get_duel_factions():
		var upgrade_id: String = phase_controller.get_selected_upgrade_id(int(owner_id))
		var run_state = get_run_state(int(owner_id))
		last_resolution_results[int(owner_id)] = _upgrade_resolver.resolve(run_state, upgrade_id)
		if territory_defense_system != null and is_instance_valid(territory_defense_system):
			var repaired_points: int = territory_defense_system.apply_pending_repair(int(owner_id), run_state)
			last_resolution_results[int(owner_id)]["repaired_points"] = repaired_points
		if battlefield_entity_runtime != null and is_instance_valid(battlefield_entity_runtime):
			last_resolution_results[int(owner_id)]["entity_actions"] = (
				battlefield_entity_runtime.apply_pending_upgrade_actions(int(owner_id), run_state)
			)
		var plan = _volley_resolver.build_and_consume(run_state)
		if battlefield_entity_runtime != null and is_instance_valid(battlefield_entity_runtime):
			battlefield_entity_runtime.decorate_volley_plan(int(owner_id), plan)
		if int(owner_id) == RulesScript.PLAYER_FACTION and direction_controller != null and is_instance_valid(direction_controller):
			var lane_allocs: Array = direction_controller.get_lane_allocations(int(plan.shot_count))
			if not lane_allocs.is_empty():
				plan.lane_allocations = lane_allocs
		current_plans[int(owner_id)] = plan
	var player_definition: Dictionary = _definition_for_choice(RulesScript.PLAYER_FACTION)
	var ai_definition: Dictionary = _definition_for_choice(RulesScript.AI_FACTION)
	_reveal_remaining = REVEAL_DURATION
	choices_revealed.emit(player_definition, ai_definition, last_resolution_results.duplicate(true))


func _launch_resolved_volleys() -> void:
	if phase_controller.phase != MatchPhaseScript.RESOLVE_CHOICES:
		return
	if not phase_controller.begin_launch():
		return
	_set_draft_pause(false)
	_set_direction_input_enabled(true)
	var issued_intents: Dictionary = {}
	for owner_id in RulesScript.get_duel_factions():
		var plan = current_plans.get(int(owner_id), null)
		if plan == null:
			continue
		plan.heavy_charge_pool = {
			"remaining": 1 if not plan.heavy_charge_spec.is_empty() else 0,
			"spec": plan.heavy_charge_spec.duplicate(true),
		}
		var intent = null
		if not plan.lane_allocations.is_empty() and fire_director.has_method("issue_lane_volley"):
			LaneAllocationScript.split_sequence(plan.projectile_sequence, plan.lane_allocations)
			for lane_alloc in plan.lane_allocations:
				var lane_intent = fire_director.issue_lane_volley(
					int(owner_id),
					int(lane_alloc.shot_count),
					float(lane_alloc.angle),
					int(plan.projectile_power),
					int(plan.chamber_damage_quarters),
					int(plan.armor_pierce_contacts),
					lane_alloc.projectile_sequence,
					plan.heavy_charge_pool
				)
				if intent == null:
					intent = lane_intent
		elif fire_director.has_method("issue_volley"):
			intent = fire_director.issue_volley(
				int(owner_id),
				int(plan.shot_count),
				int(plan.projectile_power),
				int(plan.chamber_damage_quarters),
				int(plan.armor_pierce_contacts),
				plan.projectile_sequence,
				plan.heavy_charge_pool
			)
		issued_intents[int(owner_id)] = intent
	volley_launched.emit(current_plans.duplicate(false), issued_intents)
	phase_controller.complete_launch()
	_resolution_started = false


func _definition_for_choice(owner_id: int) -> Dictionary:
	var selected_id: String = phase_controller.get_selected_upgrade_id(owner_id)
	for raw_definition in current_offers.get(owner_id, []):
		if raw_definition is Dictionary and str((raw_definition as Dictionary).get("id", "")) == selected_id:
			return (raw_definition as Dictionary).duplicate(true)
	return {}


func _offer_contains(owner_id: int, upgrade_id: String) -> bool:
	for raw_definition in current_offers.get(int(owner_id), []):
		if raw_definition is Dictionary and str((raw_definition as Dictionary).get("id", "")) == str(upgrade_id):
			return true
	return false


func _sample_strongholds() -> Dictionary:
	if stronghold_system == null or not is_instance_valid(stronghold_system):
		var empty: Dictionary = {}
		for owner_id in RulesScript.get_duel_factions():
			empty[int(owner_id)] = {}
		strongholds_sampled.emit(empty.duplicate(true))
		return empty
	var sampled: Dictionary = stronghold_system.sample_status()
	strongholds_sampled.emit(sampled.duplicate(true))
	return sampled


func _sample_gates() -> Dictionary:
	if gate_connectivity_system == null or not is_instance_valid(gate_connectivity_system):
		gates_sampled.emit({})
		return {}
	var sampled: Dictionary = gate_connectivity_system.sample_and_lock(round_number)
	gates_sampled.emit(sampled.duplicate(true))
	return sampled


func _opponent_id(owner_id: int) -> int:
	return RulesScript.AI_FACTION if int(owner_id) == RulesScript.PLAYER_FACTION else RulesScript.PLAYER_FACTION


func _turret_health_ratio(owner_id: int) -> float:
	var turret = turrets.get(int(owner_id), null)
	if turret == null or not is_instance_valid(turret):
		return 1.0
	return clampf(float(turret.health) / float(maxi(1, int(turret.max_health))), 0.0, 1.0)


func _set_draft_pause(paused: bool) -> void:
	var tree := get_tree()
	if tree == null:
		return
	if paused:
		_draft_pause_owned = not tree.paused
		tree.paused = true
	elif _draft_pause_owned:
		tree.paused = false
		_draft_pause_owned = false


func _set_direction_input_enabled(enabled: bool) -> void:
	if direction_controller == null or not is_instance_valid(direction_controller):
		return
	direction_controller.set_process_unhandled_input(enabled)


func _has_destroyed_turret() -> bool:
	for turret in turrets.values():
		if turret != null and is_instance_valid(turret) and bool(turret.is_destroyed):
			return true
	return false
