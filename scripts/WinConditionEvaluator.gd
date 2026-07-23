extends RefCounted
class_name WinConditionEvaluator

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")

static func _result(ended: bool, winner: int, draw: bool, sub_text: String, reason: String) -> Dictionary:
	return {"ended": ended, "winner": winner, "draw": draw, "sub_text": sub_text, "reason": reason}

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

static func evaluate_cardfront(owner_counts: Dictionary, total_cells: int, time_expired: bool, turrets: Dictionary = {}) -> Dictionary:
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
	if not turrets.is_empty():
		var player_health: int = _turret_health(turrets.get(CardfrontRulesScript.PLAYER_FACTION, null))
		var ai_health: int = _turret_health(turrets.get(CardfrontRulesScript.AI_FACTION, null))
		if player_health != ai_health:
			var health_winner: int = CardfrontRulesScript.PLAYER_FACTION if player_health > ai_health else CardfrontRulesScript.AI_FACTION
			return _result(true, health_winner, false, "\u65f6\u95f4\u7ed3\u675f\uff1a\u63a7\u5236\u8231\u5269\u4f59\u8010\u4e45\u66f4\u9ad8", "cardfront_timeout")
	if player_count == ai_count:
		return _result(true, -1, true, "\u65f6\u95f4\u7ed3\u675f\uff1a\u63a7\u5236\u8231\u4e0e\u9886\u571f\u5747\u6301\u5e73", "cardfront_timeout")
	if player_count > ai_count:
		return _result(true, CardfrontRulesScript.PLAYER_FACTION, false, "\u65f6\u95f4\u7ed3\u675f\uff1a\u9886\u571f\u5360\u4f18", "cardfront_timeout")
	return _result(true, CardfrontRulesScript.AI_FACTION, false, "\u65f6\u95f4\u7ed3\u675f\uff1a\u9886\u571f\u5360\u4f18", "cardfront_timeout")


static func _turret_health(turret) -> int:
	if turret == null or not is_instance_valid(turret):
		return 0
	return maxi(0, int(turret.get("health")))

static func evaluate(mode_name: String, turrets: Dictionary, owner_counts: Dictionary, total_cells: int, time_expired: bool) -> Dictionary:
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
			return evaluate_cardfront(owner_counts, total_cells, time_expired, turrets)
	return _result(false, -1, false, "", "")
