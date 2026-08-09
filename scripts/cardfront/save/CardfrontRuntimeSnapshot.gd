extends RefCounted
class_name CardfrontRuntimeSnapshot

const SCHEMA_VERSION: String = "2.0"
const SupportStateCodecScript = preload("res://scripts/cardfront/support/SupportStateSnapshotCodec.gd")

# v0.2 legacy fields (kept for backward compatibility tests)
var resource_states: Dictionary = {}
var used_card_ids: Array = []
var fortify_stacks: Array = []
var morale_effects: Array = []
var target_bias_state: Dictionary = {}
var devices: Array = []

# v0.3 fields
var faction_run_states: Dictionary = {}
var match_phase: Dictionary = {}
var round_number: int = 0
var round_active: bool = false
var hero_assignments: Dictionary = {}
var current_offers: Dictionary = {}
var current_stronghold_bonuses: Dictionary = {}
var current_gate_snapshot: Dictionary = {}
var entity_snapshot: Dictionary = {}
var territory_defense_state: Dictionary = {}
var support_states: Dictionary = {}


func to_dict() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"resource_states": resource_states,
		"used_card_ids": used_card_ids,
		"fortify_stacks": fortify_stacks,
		"morale_effects": morale_effects,
		"target_bias_state": target_bias_state,
		"devices": devices,
		"faction_run_states": faction_run_states,
		"match_phase": match_phase,
		"round_number": round_number,
		"round_active": round_active,
		"hero_assignments": hero_assignments,
		"current_offers": current_offers,
		"current_stronghold_bonuses": current_stronghold_bonuses,
		"current_gate_snapshot": current_gate_snapshot,
		"entity_snapshot": entity_snapshot,
		"territory_defense_state": territory_defense_state,
		"support_states": SupportStateCodecScript.normalize_persistent(support_states),
	}


static func from_dict(data: Dictionary):
	var snap = load("res://scripts/cardfront/save/CardfrontRuntimeSnapshot.gd").new()
	snap.resource_states = data.get("resource_states", {})
	snap.used_card_ids = data.get("used_card_ids", [])
	snap.fortify_stacks = data.get("fortify_stacks", [])
	snap.morale_effects = data.get("morale_effects", [])
	snap.target_bias_state = data.get("target_bias_state", {})
	snap.devices = data.get("devices", [])
	snap.faction_run_states = data.get("faction_run_states", {})
	snap.match_phase = data.get("match_phase", {})
	snap.round_number = int(data.get("round_number", 0))
	snap.round_active = bool(data.get("round_active", false))
	snap.hero_assignments = data.get("hero_assignments", {})
	snap.current_offers = data.get("current_offers", {})
	snap.current_stronghold_bonuses = data.get("current_stronghold_bonuses", {})
	snap.current_gate_snapshot = data.get("current_gate_snapshot", {})
	snap.entity_snapshot = data.get("entity_snapshot", {})
	snap.territory_defense_state = data.get("territory_defense_state", {})
	snap.support_states = SupportStateCodecScript.normalize_persistent(data.get("support_states", {}))
	return snap


static func capture(runtime) -> RefCounted:
	var snap = load("res://scripts/cardfront/save/CardfrontRuntimeSnapshot.gd").new()
	if runtime == null:
		return snap
	var round_director = runtime.round_director
	if round_director == null:
		return snap
	snap.round_number = int(round_director.round_number)
	snap.round_active = bool(round_director.active)
	snap.hero_assignments = round_director.hero_assignments.duplicate(true) if round_director.hero_assignments else {}
	var run_states: Dictionary = round_director.run_states if round_director.run_states else {}
	for owner_id in run_states:
		var run_state = run_states[owner_id]
		if run_state != null and run_state.has_method("snapshot"):
			snap.faction_run_states[int(owner_id)] = run_state.snapshot()
	if round_director.phase_controller != null and round_director.phase_controller.has_method("snapshot"):
		snap.match_phase = round_director.phase_controller.snapshot()
	snap.current_offers = _serialize_offers(round_director.current_offers)
	snap.current_stronghold_bonuses = (round_director.current_stronghold_bonuses if round_director.current_stronghold_bonuses else {}).duplicate(true)
	snap.current_gate_snapshot = (round_director.current_gate_snapshot if round_director.current_gate_snapshot else {}).duplicate(true)
	if runtime.battlefield != null:
		var entity_runtime = runtime.battlefield.get_node_or_null("CardfrontBattlefieldEntityRuntime")
		if entity_runtime != null and entity_runtime.has_method("snapshot"):
			snap.entity_snapshot = entity_runtime.snapshot()
	var defense_system = runtime.territory_defense_system
	if defense_system != null:
		snap.territory_defense_state = _capture_defense_state(defense_system)
	var fortify_layer = runtime.fortify_layer
	if fortify_layer != null and fortify_layer.has_method("get_stacks_array"):
		snap.fortify_stacks = fortify_layer.get_stacks_array()
	return snap


static func apply_to_runtime(runtime, data: Dictionary) -> void:
	if runtime == null or data.is_empty():
		return
	var round_director = runtime.round_director
	if round_director == null:
		return
	round_director.round_number = int(data.get("round_number", 0))
	round_director.active = bool(data.get("round_active", false))
	var saved_hero_assignments: Dictionary = data.get("hero_assignments", {})
	if not saved_hero_assignments.is_empty():
		round_director.hero_assignments = saved_hero_assignments.duplicate(true)
	var saved_run_states: Dictionary = data.get("faction_run_states", {})
	var RunStateScript = load("res://scripts/cardfront/run/CardfrontFactionRunState.gd")
	for owner_id in saved_run_states:
		var restored = RunStateScript.restore(saved_run_states[owner_id])
		round_director.run_states[int(owner_id)] = restored
	if round_director.phase_controller != null and round_director.phase_controller.has_method("restore"):
		round_director.phase_controller.restore(data.get("match_phase", {}))
	var saved_offers: Dictionary = data.get("current_offers", {})
	if not saved_offers.is_empty():
		round_director.current_offers = saved_offers.duplicate(true)
	var saved_bonuses: Dictionary = data.get("current_stronghold_bonuses", {})
	if not saved_bonuses.is_empty():
		round_director.current_stronghold_bonuses = saved_bonuses.duplicate(true)
	var saved_gates: Dictionary = data.get("current_gate_snapshot", {})
	if not saved_gates.is_empty():
		round_director.current_gate_snapshot = saved_gates.duplicate(true)
	if runtime.battlefield != null:
		var entity_runtime = runtime.battlefield.get_node_or_null("CardfrontBattlefieldEntityRuntime")
		if entity_runtime != null and entity_runtime.has_method("restore"):
			entity_runtime.restore(data.get("entity_snapshot", {}))
	var defense_system = runtime.territory_defense_system
	if defense_system != null:
		_apply_defense_state(defense_system, data.get("territory_defense_state", {}))
	var fortify_layer = runtime.fortify_layer
	if fortify_layer != null and fortify_layer.has_method("set_stacks_array"):
		fortify_layer.set_stacks_array(data.get("fortify_stacks", []))


static func _apply_defense_state(defense_system, data: Dictionary) -> void:
	if data.is_empty():
		return
	if "owner_caps" in defense_system:
		var saved_caps: Dictionary = data.get("owner_caps", {})
		defense_system.owner_caps = saved_caps.duplicate(true)
	if "_starting_defense_initialized" in defense_system:
		defense_system._starting_defense_initialized = bool(data.get("defense_initialized", false))


static func _serialize_offers(offers: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	if offers == null or offers.is_empty():
		return result
	for owner_id in offers:
		var offer_list = offers[owner_id]
		if offer_list == null:
			result[int(owner_id)] = []
			continue
		var serialized: Array = []
		for offer in offer_list:
			if offer is Dictionary:
				serialized.append(offer.duplicate(true))
			elif offer != null and offer.has_method("to_dict"):
				serialized.append(offer.to_dict())
			else:
				serialized.append(str(offer))
		result[int(owner_id)] = serialized
	return result


static func _capture_defense_state(defense_system) -> Dictionary:
	var result: Dictionary = {}
	if defense_system == null:
		return result
	if "owner_caps" in defense_system:
		result["owner_caps"] = defense_system.owner_caps.duplicate(true)
	if "starting_contact_front_cells" in defense_system:
		var cells: Dictionary = {}
		for owner_id in defense_system.starting_contact_front_cells:
			var cell_array: Array = defense_system.starting_contact_front_cells[owner_id]
			var serialized_cells: Array = []
			for cell in cell_array:
				serialized_cells.append([int(cell.x), int(cell.y)])
			cells[int(owner_id)] = serialized_cells
		result["starting_contact_front_cells"] = cells
	if "_starting_defense_initialized" in defense_system:
		result["defense_initialized"] = bool(defense_system._starting_defense_initialized)
	return result
