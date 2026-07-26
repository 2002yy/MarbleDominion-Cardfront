extends RefCounted
class_name WinConditionEvaluator

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const StrongholdRulesScript = preload("res://scripts/cardfront/strongholds/CardfrontStrongholdRules.gd")

const CARDFRONT_CHAMBER_WEIGHT: float = 50.0
const CARDFRONT_TERRITORY_WEIGHT: float = 35.0
const CARDFRONT_STRONGHOLD_WEIGHT: float = 15.0
const SCORE_TIE_EPSILON: float = 0.01


static func _result(
	ended: bool,
	winner: int,
	draw: bool,
	sub_text: String,
	reason: String,
	details: Dictionary = {}
) -> Dictionary:
	var result: Dictionary = {
		"ended": ended,
		"winner": winner,
		"draw": draw,
		"sub_text": sub_text,
		"reason": reason,
	}
	result.merge(details, true)
	return result

static func evaluate_basic(turrets: Dictionary) -> Dictionary:
	var alive_ids: Array = []
	for faction_id in turrets.keys():
		var turret = turrets[faction_id]
		if turret != null and is_instance_valid(turret) and not turret.is_destroyed:
			alive_ids.append(faction_id)

	if alive_ids.size() == 1:
		return _result(true, int(alive_ids[0]), false, "终局", "basic")
	if alive_ids.size() == 0:
		return _result(true, -1, true, "终局", "basic")
	return _result(false, -1, false, "", "basic")

static func evaluate_occupation(owner_counts: Dictionary, total_cells: int, target_percent: int) -> Dictionary:
	var best_id: int = -1
	var best_count: int = -1
	var tied: bool = false
	var total: int = 0
	for faction_id in [GameConfig.Faction.BLUE, GameConfig.Faction.RED, GameConfig.Faction.GREEN, GameConfig.Faction.YELLOW]:
		var count: int = int(owner_counts.get(faction_id, 0))
		total += count
		if count > best_count:
			best_count = count
			best_id = int(faction_id)
			tied = false
		elif count == best_count:
			tied = true

	if total <= 0 or tied:
		return _result(false, -1, false, "", "occupation")

	if total_cells <= 0:
		total_cells = total

	if best_count * 100 >= total_cells * target_percent:
		return _result(true, best_id, false, "占领达成", "occupation")
	return _result(false, -1, false, "", "occupation")

static func evaluate_timed(owner_counts: Dictionary, time_expired: bool) -> Dictionary:
	if not time_expired:
		return _result(false, -1, false, "", "timed")

	var best_id: int = -1
	var best_count: int = -1
	var tied: bool = false
	for faction_id in [GameConfig.Faction.BLUE, GameConfig.Faction.RED, GameConfig.Faction.GREEN, GameConfig.Faction.YELLOW]:
		var count: int = int(owner_counts.get(faction_id, 0))
		if count > best_count:
			best_count = count
			best_id = int(faction_id)
			tied = false
		elif count == best_count:
			tied = true
	if tied or best_id == -1:
		return _result(true, -1, true, "时间到", "timed")
	return _result(true, best_id, false, "时间到", "timed")

static func evaluate_cardfront(
	owner_counts: Dictionary,
	total_cells: int,
	time_expired: bool,
	turrets: Dictionary = {},
	stronghold_snapshot: Dictionary = {}
) -> Dictionary:
	var player_count: int = int(owner_counts.get(CardfrontRulesScript.PLAYER_FACTION, 0))
	var ai_count: int = int(owner_counts.get(CardfrontRulesScript.AI_FACTION, 0))
	var neutral_count: int = int(owner_counts.get(CardfrontRulesScript.NEUTRAL_OWNER, 0))
	if total_cells <= 0:
		total_cells = player_count + ai_count + neutral_count
	if total_cells <= 0:
		return _result(false, -1, false, "", "cardfront")

	if not turrets.is_empty():
		var chamber_result: Dictionary = evaluate_basic(turrets)
		if bool(chamber_result.get("ended", false)):
			if bool(chamber_result.get("draw", false)):
				return _result(true, -1, true, "\u53cc\u65b9\u63a7\u5236\u8231\u540c\u65f6\u88ab\u6467\u6bc1", "command_chamber")
			return _result(
				true,
				int(chamber_result.get("winner", -1)),
				false,
				"\u654c\u65b9\u63a7\u5236\u8231\u5df2\u88ab\u6467\u6bc1",
				"command_chamber"
			)

	if not time_expired:
		return _result(false, -1, false, "", "cardfront")
	var score_breakdown: Dictionary = _cardfront_timeout_scores(
		owner_counts,
		total_cells,
		turrets,
		stronghold_snapshot
	)
	var player_score: float = float((score_breakdown.player as Dictionary).total)
	var ai_score: float = float((score_breakdown.ai as Dictionary).total)
	var score_text: String = "时间结束：综合评分 玩家 %.1f / AI %.1f" % [player_score, ai_score]
	if absf(player_score - ai_score) <= SCORE_TIE_EPSILON:
		return _result(
			true,
			-1,
			true,
			score_text,
			"cardfront_timeout",
			{"score_breakdown": score_breakdown}
		)
	var winner: int = (
		CardfrontRulesScript.PLAYER_FACTION
		if player_score > ai_score
		else CardfrontRulesScript.AI_FACTION
	)
	return _result(
		true,
		winner,
		false,
		score_text,
		"cardfront_timeout",
		{"score_breakdown": score_breakdown}
	)


static func _turret_health(turret) -> int:
	if turret == null or not is_instance_valid(turret):
		return 0
	return maxi(0, int(turret.get("health")))


static func _cardfront_timeout_scores(
	owner_counts: Dictionary,
	total_cells: int,
	turrets: Dictionary,
	stronghold_snapshot: Dictionary
) -> Dictionary:
	var player_count: int = maxi(0, int(owner_counts.get(CardfrontRulesScript.PLAYER_FACTION, 0)))
	var ai_count: int = maxi(0, int(owner_counts.get(CardfrontRulesScript.AI_FACTION, 0)))
	var neutral_count: int = maxi(0, int(owner_counts.get(CardfrontRulesScript.NEUTRAL_OWNER, 0)))
	var safe_total: int = total_cells
	if safe_total <= 0:
		safe_total = player_count + ai_count + neutral_count
	safe_total = maxi(1, safe_total)
	return {
		"weights": {
			"chamber": CARDFRONT_CHAMBER_WEIGHT,
			"territory": CARDFRONT_TERRITORY_WEIGHT,
			"strongholds": CARDFRONT_STRONGHOLD_WEIGHT,
		},
		"player": _owner_timeout_score(
			CardfrontRulesScript.PLAYER_FACTION,
			player_count,
			safe_total,
			turrets,
			stronghold_snapshot
		),
		"ai": _owner_timeout_score(
			CardfrontRulesScript.AI_FACTION,
			ai_count,
			safe_total,
			turrets,
			stronghold_snapshot
		),
	}


static func _owner_timeout_score(
	owner_id: int,
	owner_count: int,
	total_cells: int,
	turrets: Dictionary,
	stronghold_snapshot: Dictionary
) -> Dictionary:
	var health_ratio: float = _turret_health_ratio(turrets.get(owner_id, null))
	var territory_ratio: float = clampf(float(owner_count) / float(maxi(1, total_cells)), 0.0, 1.0)
	var stronghold_count: int = _owner_stronghold_count(stronghold_snapshot, owner_id)
	var stronghold_ratio: float = clampf(
		float(stronghold_count) / float(StrongholdRulesScript.STRONGHOLD_TYPE_COUNT),
		0.0,
		1.0
	)
	var chamber_score: float = health_ratio * CARDFRONT_CHAMBER_WEIGHT
	var territory_score: float = territory_ratio * CARDFRONT_TERRITORY_WEIGHT
	var stronghold_score: float = stronghold_ratio * CARDFRONT_STRONGHOLD_WEIGHT
	return {
		"total": chamber_score + territory_score + stronghold_score,
		"chamber": chamber_score,
		"territory": territory_score,
		"strongholds": stronghold_score,
		"health_percent": health_ratio * 100.0,
		"territory_percent": territory_ratio * 100.0,
		"stronghold_count": stronghold_count,
	}


static func _turret_health_ratio(turret) -> float:
	if turret == null or not is_instance_valid(turret):
		return 0.0
	var current_health: int = _turret_health(turret)
	var raw_max_health = turret.get("max_health")
	var max_health: int = (
		maxi(1, int(raw_max_health))
		if raw_max_health is int or raw_max_health is float
		else maxi(1, current_health)
	)
	return clampf(float(current_health) / float(max_health), 0.0, 1.0)


static func _owner_stronghold_count(snapshot: Dictionary, owner_id: int) -> int:
	var owner_bonus: Dictionary = snapshot.get(owner_id, {}) as Dictionary
	var active_types: Array = owner_bonus.get("active_types", []) as Array
	var unique_types: Dictionary = {}
	for region_type in active_types:
		if StrongholdRulesScript.is_stronghold_type(str(region_type)):
			unique_types[str(region_type)] = true
	return mini(unique_types.size(), StrongholdRulesScript.STRONGHOLD_TYPE_COUNT)


static func evaluate(
	mode_name: String,
	turrets: Dictionary,
	owner_counts: Dictionary,
	total_cells: int,
	time_expired: bool,
	stronghold_snapshot: Dictionary = {}
) -> Dictionary:
	match mode_name:
		GameConfig.GAME_MODE_BASIC:
			return evaluate_basic(turrets)
		GameConfig.GAME_MODE_OCCUPATION:
			return evaluate_occupation(owner_counts, maxi(total_cells, 1), GameConfig.get_occupation_target_percent())
		GameConfig.GAME_MODE_TIMED:
			return evaluate_timed(owner_counts, time_expired)
		GameConfig.GAME_MODE_WILD:
			return evaluate_basic(turrets)
		GameConfig.GAME_MODE_CARDFRONT:
			return evaluate_cardfront(owner_counts, total_cells, time_expired, turrets, stronghold_snapshot)
	return _result(false, -1, false, "", "")
