extends RefCounted
class_name CardfrontMode

const Rules = preload("res://scripts/cardfront/CardfrontRules.gd")
const BattlefieldInitializer = preload("res://scripts/cardfront/CardfrontBattlefieldInitializer.gd")


static func is_selected(mode_name: String) -> bool:
	return Rules.is_cardfront_mode(mode_name)


static func is_active() -> bool:
	return is_selected(GameConfig.get_game_mode_name())


static func get_active_factions() -> Array:
	return Rules.get_duel_factions()


static func get_match_duration_seconds() -> float:
	return Rules.MATCH_DURATION_SECONDS


static func configure_battlefield(battlefield) -> Dictionary:
	var result: Dictionary = BattlefieldInitializer.configure_duel(battlefield)
	if not bool(result.get("configured", false)):
		return result
	result.merge({
		"configured": true,
		"mode_name": GameConfig.GAME_MODE_CARDFRONT,
		"active_factions": get_active_factions(),
		"match_duration_seconds": get_match_duration_seconds(),
		"capture_target_percent": Rules.CAPTURE_TARGET_PERCENT,
	}, true)
	return result
