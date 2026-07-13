extends RefCounted
class_name CardfrontMatchFlowText

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")


static func objective_text() -> String:
	return "\u76ee\u6807 %d%%" % CardfrontRulesScript.CAPTURE_TARGET_PERCENT


static func remaining_time_text(game_elapsed_time: float) -> String:
	var remaining: float = maxf(0.0, CardfrontRulesScript.MATCH_DURATION_SECONDS - game_elapsed_time)
	return "\u5269\u4f59 %s" % RuntimeHudController.format_time_text(remaining)


static func opening_hint_text() -> String:
	return "\u4e89\u593a\u4e94\u4e2a\u636e\u70b9 \u00b7 \u5168\u56fe\u5360\u9886\u8fbe\u5230 %d%% \u83b7\u80dc" % CardfrontRulesScript.CAPTURE_TARGET_PERCENT


static func score_percentages(owner_counts: Dictionary, total_cells: int) -> Dictionary:
	var player_count: int = int(owner_counts.get(CardfrontRulesScript.PLAYER_FACTION, 0))
	var ai_count: int = int(owner_counts.get(CardfrontRulesScript.AI_FACTION, 0))
	var neutral_count: int = int(owner_counts.get(CardfrontRulesScript.NEUTRAL_OWNER, 0))
	var safe_total: int = total_cells
	if safe_total <= 0:
		safe_total = player_count + ai_count + neutral_count
	safe_total = maxi(1, safe_total)
	return {
		"player": int(round(float(player_count) * 100.0 / float(safe_total))),
		"ai": int(round(float(ai_count) * 100.0 / float(safe_total))),
		"neutral": int(round(float(neutral_count) * 100.0 / float(safe_total))),
	}


static func score_summary(owner_counts: Dictionary, total_cells: int) -> String:
	var percentages: Dictionary = score_percentages(owner_counts, total_cells)
	return "\u73a9\u5bb6 %d%%   AI %d%%   \u4e2d\u7acb %d%%" % [
		int(percentages.get("player", 0)),
		int(percentages.get("ai", 0)),
		int(percentages.get("neutral", 0)),
	]


static func result_reason(time_expired: bool) -> String:
	if time_expired:
		return "8 \u5206\u949f\u7ed3\u7b97\uff1a\u5360\u9886\u66f4\u591a\u7684\u4e00\u65b9\u83b7\u80dc"
	return "\u5df2\u8fbe\u5230 %d%% \u5168\u56fe\u5360\u9886\u76ee\u6807" % CardfrontRulesScript.CAPTURE_TARGET_PERCENT
