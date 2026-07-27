extends RefCounted
class_name CardfrontProjectileType

const STANDARD: String = "standard"
const SIEGE: String = "siege"
const SUPPRESSION: String = "suppression"

const ALL_TYPES: Array[String] = [STANDARD, SIEGE, SUPPRESSION]


static func sanitize(projectile_type: String) -> String:
	var safe_type: String = str(projectile_type)
	return safe_type if safe_type in ALL_TYPES else STANDARD


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
	var group: Array = []
	_append_type(group, SIEGE, maxi(0, int(base_mix.get(SIEGE, 0))))
	_append_type(group, STANDARD, maxi(0, int(base_mix.get(STANDARD, 0))))
	_append_type(group, SUPPRESSION, maxi(0, int(base_mix.get(SUPPRESSION, 0))))
	_append_type(group, STANDARD, maxi(0, int(bonus_standard_shots)))
	if group.is_empty():
		group.append(STANDARD)
	var result: Array = []
	for _repeat in range(maxi(1, int(multiplier))):
		result.append_array(group)
	if max_count > 0 and result.size() > max_count:
		result.resize(max_count)
	return result


static func append_standard(sequence: Array, amount: int, max_count: int = -1) -> void:
	for _index in range(maxi(0, int(amount))):
		if max_count > 0 and sequence.size() >= max_count:
			break
		sequence.append(STANDARD)


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
			return 1.20
		SIEGE:
			return 0.90
		_:
			return 1.0


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


static func _append_type(target: Array, projectile_type: String, amount: int) -> void:
	for _index in range(maxi(0, amount)):
		target.append(projectile_type)
