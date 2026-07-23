extends RefCounted
class_name CardfrontMatchFlowText

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")


static func objective_text() -> String:
	return "\u76ee\u6807\uff1a\u6467\u6bc1\u654c\u65b9\u63a7\u5236\u8231"


static func remaining_time_text(game_elapsed_time: float) -> String:
	var remaining: float = maxf(0.0, CardfrontRulesScript.MATCH_DURATION_SECONDS - game_elapsed_time)
	return "\u5269\u4f59 %s" % RuntimeHudController.format_time_text(remaining)


static func opening_hint_text() -> String:
	return "\u8c03\u6574\u65b9\u5411 \u00b7 \u4e09\u9009\u4e00\u5f3a\u5316 \u00b7 \u81ea\u52a8\u9f50\u5c04 \u00b7 \u6467\u6bc1\u654c\u65b9\u63a7\u5236\u8231"


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
		return "\u65f6\u95f4\u7ed3\u675f\uff1a\u5148\u6bd4\u63a7\u5236\u8231\u8010\u4e45\uff0c\u518d\u6bd4\u9886\u571f"
	return "\u654c\u65b9\u63a7\u5236\u8231\u5df2\u88ab\u6467\u6bc1"
