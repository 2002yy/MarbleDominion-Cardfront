extends RefCounted
class_name CardfrontProjectileType

const STANDARD: String = "standard"
const SIEGE: String = "siege"
const SUPPRESSION: String = "suppression"

const SEGMENT_SPECIAL: String = "special"
const SEGMENT_STANDARD: String = "standard"

const ALL_TYPES: Array[String] = [STANDARD, SIEGE, SUPPRESSION]

# Composition control is a visible tradeoff, not hidden hero compensation.
# Pure-standard volleys hold one route especially well. A suppression opener
# gives up chamber access for stronger route occupation; the following standard
# segment remains slightly less precise, but is no longer crippled by the opener.
const PURE_STANDARD_FOLLOWTHROUGH_MULTIPLIER: float = 1.08
const SUPPRESSION_FOLLOWTHROUGH_MULTIPLIER: float = 0.94
const PURE_STANDARD_SPREAD_MULTIPLIER: float = 0.90
const SUPPRESSION_STANDARD_SPREAD_MULTIPLIER: float = 1.08


static func sanitize(projectile_type: String) -> String:
	var safe_type: String = str(projectile_type)
	return safe_type if safe_type in ALL_TYPES else STANDARD


static func is_special(projectile_type: String) -> bool:
	return sanitize(projectile_type) != STANDARD


static func segment_id(projectile_type: String) -> String:
	return SEGMENT_SPECIAL if is_special(projectile_type) else SEGMENT_STANDARD


static func validate_mix(mix: Dictionary, expected_count: int) -> Array:
	var errors: Array = []
	var total: int = 0
	for projectile_type in ALL_TYPES:
		var count: int = int(mix.get(projectile_type, 0))
		if count < 0:
			errors.append("negative_projectile_count:%s" % projectile_type)
		total += maxi(0, count)
	for raw_key in mix.keys():
		if str(raw_key) not in ALL_TYPES:
			errors.append("unknown_projectile_type:%s" % str(raw_key))
	if total != maxi(0, int(expected_count)):
		errors.append("projectile_mix_count_mismatch:%d:%d" % [total, maxi(0, int(expected_count))])
	return errors


static func build_sequence(
	base_mix: Dictionary,
	bonus_standard_shots: int,
	multiplier: int,
	max_count: int
) -> Array:
	# x2 copies only the hero's base typed projectile group. Reinforcement shots are
	# appended afterwards, so +5 can never create or duplicate special projectiles.
	var base_group: Array = []
	append_type(base_group, SUPPRESSION, maxi(0, int(base_mix.get(SUPPRESSION, 0))))
	append_type(base_group, SIEGE, maxi(0, int(base_mix.get(SIEGE, 0))))
	append_type(base_group, STANDARD, maxi(0, int(base_mix.get(STANDARD, 0))))
	if base_group.is_empty():
		base_group.append(STANDARD)

	var result: Array = []
	for _repeat in range(maxi(1, int(multiplier))):
		result.append_array(base_group)
	append_standard(result, maxi(0, int(bonus_standard_shots)))
	if max_count > 0 and result.size() > max_count:
		result.resize(max_count)
	return segment_sequence(result)


static func segment_sequence(sequence: Array) -> Array:
	# A volley is planned as two visible sub-intents: special projectiles establish
	# the route first, then standard projectiles exploit the opening.
	var special: Array = []
	var standard: Array = []
	for raw_type in sequence:
		var projectile_type: String = sanitize(str(raw_type))
		if is_special(projectile_type):
			special.append(projectile_type)
		else:
			standard.append(projectile_type)
	var result: Array = []
	result.append_array(special)
	result.append_array(standard)
	return result


static func split_segments(sequence: Array) -> Dictionary:
	var segmented: Array = segment_sequence(sequence)
	var special: Array = []
	var standard: Array = []
	for projectile_type in segmented:
		if is_special(str(projectile_type)):
			special.append(sanitize(str(projectile_type)))
		else:
			standard.append(STANDARD)
	return {
		SEGMENT_SPECIAL: special,
		SEGMENT_STANDARD: standard,
	}


static func append_standard(sequence: Array, amount: int, max_count: int = -1) -> void:
	append_type(sequence, STANDARD, amount, max_count)


static func append_type(sequence: Array, projectile_type: String, amount: int, max_count: int = -1) -> void:
	var safe_type: String = sanitize(projectile_type)
	for _index in range(maxi(0, int(amount))):
		if max_count > 0 and sequence.size() >= max_count:
			break
		sequence.append(safe_type)


static func convert_standard(sequence: Array, target_type: String, amount: int) -> int:
	var safe_target: String = sanitize(target_type)
	if safe_target == STANDARD or amount <= 0:
		return 0
	var converted: int = 0
	for index in range(sequence.size()):
		if converted >= amount:
			break
		if sanitize(str(sequence[index])) != STANDARD:
			continue
		sequence[index] = safe_target
		converted += 1
	return converted


static func apply_conversions(sequence: Array, conversions: Dictionary) -> Dictionary:
	var applied: Dictionary = {}
	for projectile_type in [SIEGE, SUPPRESSION]:
		var converted: int = convert_standard(sequence, projectile_type, maxi(0, int(conversions.get(projectile_type, 0))))
		applied[projectile_type] = converted
	return applied


static func count_types(sequence: Array) -> Dictionary:
	var counts: Dictionary = {
		STANDARD: 0,
		SIEGE: 0,
		SUPPRESSION: 0,
	}
	for raw_type in sequence:
		var projectile_type: String = sanitize(str(raw_type))
		counts[projectile_type] = int(counts[projectile_type]) + 1
	return counts


static func standard_followthrough_multiplier(sequence: Array) -> float:
	var counts: Dictionary = count_types(sequence)
	if int(counts.get(SUPPRESSION, 0)) > 0:
		return SUPPRESSION_FOLLOWTHROUGH_MULTIPLIER
	if int(counts.get(SIEGE, 0)) <= 0:
		return PURE_STANDARD_FOLLOWTHROUGH_MULTIPLIER
	return 1.0


static func volley_spread_multiplier(sequence: Array) -> float:
	var counts: Dictionary = count_types(sequence)
	if int(counts.get(SUPPRESSION, 0)) > 0:
		return SUPPRESSION_STANDARD_SPREAD_MULTIPLIER
	if int(counts.get(SIEGE, 0)) <= 0:
		return PURE_STANDARD_SPREAD_MULTIPLIER
	return 1.0


static func direct_damage_units(projectile_type: String) -> float:
	match sanitize(projectile_type):
		SIEGE:
			return 2.0
		SUPPRESSION:
			return 0.0
		_:
			return 1.0


static func direct_damage_units_for_sequence(sequence: Array) -> float:
	var total: float = 0.0
	for raw_type in sequence:
		total += direct_damage_units(str(raw_type))
	return total


static func territory_pressure_units(projectile_type: String) -> float:
	match sanitize(projectile_type):
		SUPPRESSION:
			# Suppression cannot damage the chamber, so it must earn its slot through
			# visible route occupation. One shot is worth more than one standard
			# territory contact, while still trading away all direct damage.
			return 1.42
		SIEGE:
			return 0.90
		_:
			return 1.0


static func territory_pressure_for_sequence(sequence: Array) -> float:
	var followthrough: float = standard_followthrough_multiplier(sequence)
	var total: float = 0.0
	for raw_type in sequence:
		var projectile_type: String = sanitize(str(raw_type))
		var units: float = territory_pressure_units(projectile_type)
		if projectile_type == STANDARD:
			units *= followthrough
		total += units
	return total


static func defense_pierce_layers(projectile_type: String) -> int:
	return 1 if sanitize(projectile_type) == SIEGE else 0


static func chamber_damage_multiplier(projectile_type: String) -> int:
	match sanitize(projectile_type):
		SIEGE:
			return 2
		SUPPRESSION:
			return 0
		_:
			return 1
