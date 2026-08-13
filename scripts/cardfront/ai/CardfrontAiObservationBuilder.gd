extends RefCounted
class_name CardfrontAiObservationBuilder

const PUBLIC_BATTLE_STATE: String = "public_battle_state"
const OWN_PRIVATE_STATE: String = "own_private_state"
const OBSERVED_ENEMY_HISTORY: String = "observed_enemy_history"

# P0-10A2-A5: these lists are the schema. Unknown future source fields are
# invisible until they are explicitly reviewed and added here.
const PUBLIC_BATTLE_FIELDS: Array[String] = [
	"round_number",
	"rounds_remaining",
	"phase",
	"own_command_chamber_health",
	"enemy_command_chamber_health",
	"own_health_ratio",
	"enemy_health_ratio",
	"own_territory_count",
	"enemy_territory_count",
	"owned_cell_count",
	"defended_cell_count",
	"repairable_frontline_cells",
	"enemy_defense_points",
	"enemy_defense_contact_chance",
	"siege_defense_contact_chance",
	"estimated_chamber_hit_chance",
	"route_pressure",
	"expected_frontline_captures",
	"enemy_defense_tower_count",
	"support_views",
	"battlefield_entities",
	"gate_states",
	"bridge_states",
	"revealed_card_history",
]

const OWN_PRIVATE_FIELDS: Array[String] = [
	"hero_id",
	"deck_id",
	"command_points",
	"legal_actions",
	"base_volley_count",
	"base_projectile_mix",
	"frontline_repair_bonus",
	"captured_frontline_defense",
	"next_volley_bonus",
	"next_volley_multiplier",
	"next_volley_armor_pierce_contacts",
	"next_volley_conversions",
	"attack_level",
	"territory_defense_cap",
	"rarity_level",
	"echo_next_choice_armed",
	"queued_echo_upgrade_id",
	"pending_repair_points",
	"owned_creature_count",
	"owned_defense_tower_count",
	"tower_levels",
	"building_volley_level",
	"neutral_creature_summoned",
	"selected_upgrade_levels",
	"applied_upgrade_counts",
	"pre_multiplier_shot_bonus",
	"post_multiplier_shot_bonus",
	"temporary_attack_level_bonus",
	"future_offer_size",
]

const OBSERVED_EVENT_FIELDS: Array[String] = [
	"event_type",
	"round_number",
	"owner_id",
	"card_id",
	"action_id",
	"support_id",
	"cell",
	"route_id",
]

const SUPPORT_VIEW_FIELDS: Array[String] = [
	"support_id", "owner_id", "claimed_owner_id", "operational", "online", "network_connected", "suppressed",
]
const BATTLEFIELD_ENTITY_FIELDS: Array[String] = [
	"entity_id", "owner_id", "entity_type", "cell", "level", "active",
]
const GATE_STATE_FIELDS: Array[String] = [
	"gate_id", "open", "locked", "owner_id",
]
const BRIDGE_STATE_FIELDS: Array[String] = [
	"bridge_id", "from_cell", "to_cell", "open", "blocked",
]
const REVEALED_CARD_FIELDS: Array[String] = [
	"round_number", "owner_id", "card_id",
]

const STRING_VALUE_MAP_FIELDS: Array[String] = [
	"base_projectile_mix",
	"next_volley_conversions",
	"tower_levels",
	"selected_upgrade_levels",
	"applied_upgrade_counts",
]

const VALUATION_PUBLIC_FIELDS: Array[String] = [
	"round_number", "rounds_remaining", "estimated_chamber_hit_chance",
	"enemy_defense_contact_chance", "siege_defense_contact_chance",
	"enemy_defense_points", "repairable_frontline_cells", "owned_cell_count",
	"defended_cell_count", "own_health_ratio", "enemy_health_ratio",
	"route_pressure", "expected_frontline_captures", "enemy_defense_tower_count",
]
const VALUATION_OWN_FIELDS: Array[String] = [
	"pre_multiplier_shot_bonus", "post_multiplier_shot_bonus",
	"temporary_attack_level_bonus", "future_offer_size",
]

const FORBIDDEN_FIELD_NAMES: Array[String] = [
	"player_offer",
	"current_player_offer",
	"player_unrevealed_choice",
	"future_offer",
	"rng",
	"rng_state",
	"seed",
	"hidden_route_tendency_score",
	"hidden_tactical_instruction",
	"scene_tree",
	"node",
	"runtime_object",
	"round_director",
	"player_run_state",
	"run_state",
	"callback",
	"callbacks",
]

static var _build_count_for_test: int = 0


static func build(
	public_source: Dictionary = {},
	own_source: Dictionary = {},
	history_source: Array = []
) -> Dictionary:
	if OS.has_feature("editor"):
		_build_count_for_test += 1
	return {
		PUBLIC_BATTLE_STATE: _project_fields(public_source, PUBLIC_BATTLE_FIELDS),
		OWN_PRIVATE_STATE: _project_fields(own_source, OWN_PRIVATE_FIELDS),
		OBSERVED_ENEMY_HISTORY: _project_history(history_source),
	}


static func reset_build_count_for_test() -> void:
	_build_count_for_test = 0


static func get_build_count_for_test() -> int:
	return _build_count_for_test


static func project_own_state(state) -> Dictionary:
	var source: Dictionary = {}
	if state == null:
		return source
	for field_name in OWN_PRIVATE_FIELDS:
		var value = _read_source_value(state, field_name)
		if value != null:
			source[field_name] = value
	return _project_fields(source, OWN_PRIVATE_FIELDS)


static func valuation_context(observation: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	var public_state: Dictionary = observation.get(PUBLIC_BATTLE_STATE, {}) as Dictionary
	var own_state: Dictionary = observation.get(OWN_PRIVATE_STATE, {}) as Dictionary
	for field_name in VALUATION_PUBLIC_FIELDS:
		if public_state.has(field_name):
			result[field_name] = public_state[field_name]
	for field_name in VALUATION_OWN_FIELDS:
		if own_state.has(field_name):
			result[field_name] = own_state[field_name]
	return result


static func is_pure_observation(observation) -> bool:
	return bool(_copy_pure_value(observation).get("accepted", false))


static func _read_source_value(source, field_name: String):
	if source is Dictionary:
		return (source as Dictionary).get(field_name)
	return source.get(field_name)


static func _project_fields(source: Dictionary, allowed_fields: Array[String]) -> Dictionary:
	var projected: Dictionary = {}
	for field_name in allowed_fields:
		if not source.has(field_name):
			continue
		var copy_result: Dictionary = _project_field_value(field_name, source[field_name])
		if bool(copy_result.get("accepted", false)):
			projected[field_name] = copy_result.get("value")
	return projected


static func _project_field_value(field_name: String, value) -> Dictionary:
	match field_name:
		"support_views":
			return _project_record_array(value, SUPPORT_VIEW_FIELDS)
		"battlefield_entities":
			return _project_record_array(value, BATTLEFIELD_ENTITY_FIELDS)
		"gate_states":
			return _project_record_collection(value, GATE_STATE_FIELDS)
		"bridge_states":
			return _project_record_collection(value, BRIDGE_STATE_FIELDS)
		"revealed_card_history":
			return _project_record_array(value, REVEALED_CARD_FIELDS)
		"legal_actions":
			return _copy_primitive_array(value)
	if field_name in STRING_VALUE_MAP_FIELDS:
		return _copy_string_value_map(value)
	return _copy_pure_value(value)


static func _project_record_array(value, allowed_fields: Array[String]) -> Dictionary:
	if not (value is Array):
		return {"accepted": false}
	var projected: Array = []
	for raw_record in value as Array:
		if not (raw_record is Dictionary):
			return {"accepted": false}
		projected.append(_project_fields(raw_record as Dictionary, allowed_fields))
	return {"accepted": true, "value": projected}


static func _project_record_collection(value, allowed_fields: Array[String]) -> Dictionary:
	if value is Array:
		return _project_record_array(value, allowed_fields)
	if not (value is Dictionary):
		return {"accepted": false}
	var projected: Dictionary = {}
	for raw_key in (value as Dictionary).keys():
		if typeof(raw_key) not in [TYPE_STRING, TYPE_STRING_NAME]:
			return {"accepted": false}
		var raw_record = (value as Dictionary)[raw_key]
		if not (raw_record is Dictionary):
			return {"accepted": false}
		projected[str(raw_key)] = _project_fields(raw_record as Dictionary, allowed_fields)
	return {"accepted": true, "value": projected}


static func _copy_primitive_array(value) -> Dictionary:
	if not (value is Array):
		return {"accepted": false}
	var copied: Array = []
	for item in value as Array:
		if typeof(item) not in [TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING, TYPE_STRING_NAME, TYPE_VECTOR2, TYPE_VECTOR2I]:
			return {"accepted": false}
		copied.append(item)
	return {"accepted": true, "value": copied}


static func _copy_string_value_map(value) -> Dictionary:
	if not (value is Dictionary):
		return {"accepted": false}
	var copied: Dictionary = {}
	for raw_key in (value as Dictionary).keys():
		if typeof(raw_key) not in [TYPE_STRING, TYPE_STRING_NAME]:
			return {"accepted": false}
		var item = (value as Dictionary)[raw_key]
		if typeof(item) not in [TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING, TYPE_STRING_NAME]:
			return {"accepted": false}
		copied[str(raw_key)] = item
	return {"accepted": true, "value": copied}


static func _project_history(source: Array) -> Array:
	var projected: Array = []
	for raw_event in source:
		if not (raw_event is Dictionary):
			continue
		projected.append(_project_fields(raw_event as Dictionary, OBSERVED_EVENT_FIELDS))
	return projected


static func _copy_pure_value(value) -> Dictionary:
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING, TYPE_STRING_NAME, TYPE_VECTOR2, TYPE_VECTOR2I:
			return {"accepted": true, "value": value}
		TYPE_ARRAY:
			var copied_array: Array = []
			for item in value as Array:
				var item_result: Dictionary = _copy_pure_value(item)
				if not bool(item_result.get("accepted", false)):
					return {"accepted": false}
				copied_array.append(item_result.get("value"))
			return {"accepted": true, "value": copied_array}
		TYPE_DICTIONARY:
			var copied_dictionary: Dictionary = {}
			for raw_key in (value as Dictionary).keys():
				if typeof(raw_key) not in [TYPE_STRING, TYPE_STRING_NAME]:
					return {"accepted": false}
				var key: String = str(raw_key)
				if key.to_snake_case() in FORBIDDEN_FIELD_NAMES:
					return {"accepted": false}
				var item_result: Dictionary = _copy_pure_value((value as Dictionary)[raw_key])
				if not bool(item_result.get("accepted", false)):
					return {"accepted": false}
				copied_dictionary[key] = item_result.get("value")
			return {"accepted": true, "value": copied_dictionary}
	return {"accepted": false}
