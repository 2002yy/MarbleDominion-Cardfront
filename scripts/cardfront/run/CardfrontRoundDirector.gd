extends Node
class_name CardfrontRoundDirector

signal phase_changed(previous_phase, next_phase)
signal countdown_updated(time_remaining, round_number, player_state)
signal draft_opened(player_offer, ai_offer, timeout_seconds, round_number)
signal draft_time_updated(time_remaining, timeout_seconds)
signal strongholds_sampled(bonuses)
signal choice_locked(owner_id, upgrade_id, automatic)
signal choices_revealed(player_definition, ai_definition, resolution_results)
signal volley_launched(plans, issued_intents)
signal director_stopped

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const MatchPhaseScript = preload("res://scripts/cardfront/run/CardfrontMatchPhase.gd")
const MatchPhaseControllerScript = preload("res://scripts/cardfront/run/CardfrontMatchPhaseController.gd")
const RunStateScript = preload("res://scripts/cardfront/run/CardfrontFactionRunState.gd")
const DraftSystemScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeDraftSystem.gd")
const UpgradeResolverScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeResolver.gd")
const VolleyResolverScript = preload("res://scripts/cardfront/volley/CardfrontVolleyResolver.gd")
const AiUpgradePolicyScript = preload("res://scripts/cardfront/run/CardfrontAiUpgradePolicy.gd")
const TuningScript = preload("res://scripts/cardfront/run/CardfrontRunTuning.gd")
const HeroRegistryScript = preload("res://scripts/cardfront/heroes/CardfrontHeroRegistry.gd")

const BATTLE_INTERVAL: float = TuningScript.AIM_SECONDS
const FIRST_DRAFT_COUNTDOWN: float = TuningScript.FIRST_AIM_SECONDS
const DRAFT_TIMEOUT: float = TuningScript.DRAFT_SECONDS
const REVEAL_DURATION: float = TuningScript.REVEAL_SECONDS

var fire_director = null
var turrets: Dictionary = {}
var direction_controller = null
var stronghold_system = null
var territory_defense_system = null
var hero_assignments: Dictionary = {}
var phase_controller = MatchPhaseControllerScript.new()
var run_states: Dictionary = {}
var current_offers: Dictionary = {}
var current_plans: Dictionary = {}
var last_resolution_results: Dictionary = {}
var current_stronghold_bonuses: Dictionary = {}
var round_number: int = 0
var active: bool = false

var _draft_system = DraftSystemScript.new()
var _upgrade_resolver = UpgradeResolverScript.new()
var _volley_resolver = VolleyResolverScript.new()
var _ai_policy = AiUpgradePolicyScript.new()
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
	new_hero_assignments: Dictionary = {}
) -> bool:
	fire_director = new_fire_director
	turrets = new_turrets.duplicate(false)
	direction_controller = new_direction_controller
	stronghold_system = new_stronghold_system
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


func get_stronghold_bonus(owner_id: int) -> Dictionary:
	return (current_stronghold_bonuses.get(int(owner_id), {}) as Dictionary).duplicate(true)


func set_seed_for_tests(seed_value: int) -> void:
	_draft_system.set_seed(seed_value)


func set_territory_defense_system(system) -> void:
	territory_defense_system = system


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
	current_stronghold_bonuses = _sample_strongholds()
	current_offers = {
		RulesScript.PLAYER_FACTION: _draft_system.draw_three(
			get_run_state(RulesScript.PLAYER_FACTION),
			_guarantees_uncommon(RulesScript.PLAYER_FACTION)
		),
		RulesScript.AI_FACTION: _draft_system.draw_three(
			get_run_state(RulesScript.AI_FACTION),
			_guarantees_uncommon(RulesScript.AI_FACTION)
		),
	}
	var ai_choice: Dictionary = _ai_policy.choose(get_ai_offer(), get_run_state(RulesScript.AI_FACTION))
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
		var fallback: Dictionary = _draft_system.choose_timeout_fallback(offer)
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
		var plan = _volley_resolver.build_and_consume(run_state)
		if stronghold_system != null and is_instance_valid(stronghold_system):
			stronghold_system.apply_to_volley_plan(int(owner_id), plan, current_stronghold_bonuses)
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
		var intent = null
		if fire_director.has_method("issue_volley"):
			intent = fire_director.issue_volley(
				int(owner_id),
				int(plan.shot_count),
				int(plan.projectile_power),
				int(plan.chamber_damage_quarters),
				int(plan.armor_pierce_contacts)
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
	var sampled: Dictionary = stronghold_system.sample_bonuses()
	strongholds_sampled.emit(sampled.duplicate(true))
	return sampled


func _guarantees_uncommon(owner_id: int) -> bool:
	var bonus: Dictionary = current_stronghold_bonuses.get(int(owner_id), {}) as Dictionary
	return bool(bonus.get("guarantee_uncommon", false))


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
