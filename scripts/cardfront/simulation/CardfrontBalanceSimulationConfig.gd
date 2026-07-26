extends RefCounted
class_name CardfrontBalanceSimulationConfig

const GRID_SIZE: int = 40
const MAX_ROUNDS: int = 34
const FULL_SEEDS_PER_CASE: int = 1000

const SIMULATION_MODE_HISTORICAL_COMPENSATED: String = "historical_compensated"
const SIMULATION_MODE_PARITY_UNCOMPENSATED: String = "parity_uncompensated"
const DEFAULT_SIMULATION_MODE: String = SIMULATION_MODE_HISTORICAL_COMPENSATED
const HISTORICAL_RESOLVED_ATTACK_LEVEL_CAP: int = 3
const PARITY_RESOLVED_ATTACK_LEVEL_CAP: int = 4

const AGGREGATE_WIN_RATE_MIN: float = 47.0
const AGGREGATE_WIN_RATE_MAX: float = 53.0
const MATCHUP_WIN_RATE_MIN: float = 43.0
const MATCHUP_WIN_RATE_MAX: float = 57.0
const MIRROR_BLUE_RATE_MIN: float = 49.0
const MIRROR_BLUE_RATE_MAX: float = 51.0

const MEDIAN_ROUND_MIN: float = 16.0
const MEDIAN_ROUND_MAX: float = 22.0
const P90_ROUND_MAX: float = 34.0
const TIMEOUT_RATE_MIN: float = 10.0
const TIMEOUT_RATE_MAX: float = 25.0
const FIRST_STRONGHOLD_MIN: float = 4.0
const FIRST_STRONGHOLD_MAX: float = 8.0

const DEFAULT_MAP_PROFILE: Dictionary = {
	"chamber_hit_chance": 0.255,
	"average_cells_crossed": 19.0,
	"defense_contact_chance": 0.13,
	"territory_pressure": 1.0,
	"stronghold_tempo": 0,
}


static func sanitize_simulation_mode(raw_mode: String) -> String:
	var mode: String = str(raw_mode)
	if mode == SIMULATION_MODE_PARITY_UNCOMPENSATED:
		return SIMULATION_MODE_PARITY_UNCOMPENSATED
	return SIMULATION_MODE_HISTORICAL_COMPENSATED


static func uses_hidden_hit_compensation(raw_mode: String) -> bool:
	return sanitize_simulation_mode(raw_mode) == SIMULATION_MODE_HISTORICAL_COMPENSATED


static func resolved_attack_level_cap(raw_mode: String) -> int:
	if sanitize_simulation_mode(raw_mode) == SIMULATION_MODE_PARITY_UNCOMPENSATED:
		return PARITY_RESOLVED_ATTACK_LEVEL_CAP
	return HISTORICAL_RESOLVED_ATTACK_LEVEL_CAP


static func sanitize_map_profile(raw_profile: Dictionary) -> Dictionary:
	var profile: Dictionary = DEFAULT_MAP_PROFILE.duplicate(true)
	profile.merge(raw_profile, true)
	profile["chamber_hit_chance"] = clampf(float(profile["chamber_hit_chance"]), 0.05, 0.75)
	profile["average_cells_crossed"] = clampf(float(profile["average_cells_crossed"]), 4.0, 40.0)
	profile["defense_contact_chance"] = clampf(float(profile["defense_contact_chance"]), 0.0, 0.75)
	profile["territory_pressure"] = clampf(float(profile["territory_pressure"]), 0.25, 3.0)
	profile["stronghold_tempo"] = clampi(int(profile["stronghold_tempo"]), -2, 2)
	return profile


static func rate_in_range(rate: float, minimum: float, maximum: float) -> bool:
	return rate >= minimum and rate <= maximum
