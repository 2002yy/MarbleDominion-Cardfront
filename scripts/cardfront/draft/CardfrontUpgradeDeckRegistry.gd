extends RefCounted
class_name CardfrontUpgradeDeckRegistry

const UpgradeManifestScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeManifest.gd")

const DECK_CORE_TACTICS: String = "core_tactics"
const DECK_FORTIFICATION_CORPS: String = "fortification_corps"
const DECK_BARRAGE_CONTROL: String = "barrage_control"

const DEFAULT_DECK_ID: String = DECK_CORE_TACTICS
const DECK_SIZE: int = 8

const DEFINITIONS: Dictionary = {
	DECK_CORE_TACTICS: {
		"id": DECK_CORE_TACTICS,
		"name": "基础战术",
		"description": "完整基础牌池，兼顾齐射、成长、防守与抽牌。",
		"upgrade_ids": [
			"volley_plus_5",
			"volley_x2",
			"attack_level_plus_1",
			"defense_cap_plus_1",
			"frontline_repair",
			"armor_piercing",
			"rarity_plus_1",
			"echo_next_choice",
		],
	},
	DECK_FORTIFICATION_CORPS: {
		"id": DECK_FORTIFICATION_CORPS,
		"name": "筑垒工兵",
		"description": "围绕攻城弹、桥头工事、修复、防御上限和长期选品成长形成阵地构筑。",
		"upgrade_ids": [
			"volley_plus_5",
			"volley_x2",
			"attack_level_plus_1",
			"defense_cap_plus_1",
			"frontline_repair",
			"rarity_plus_1",
			"siege_calibration",
			"bridgehead_prefabs",
		],
	},
	DECK_BARRAGE_CONTROL: {
		"id": DECK_BARRAGE_CONTROL,
		"name": "弹幕压制",
		"description": "围绕压制弹、齐射节奏、穿甲和抽牌成长形成路线控制构筑。",
		"upgrade_ids": [
			"volley_plus_5",
			"volley_x2",
			"attack_level_plus_1",
			"armor_piercing",
			"rarity_plus_1",
			"echo_next_choice",
			"suppression_screen",
			"frontline_repair",
		],
	},
}


static func get_deck_ids() -> Array:
	var ids: Array = DEFINITIONS.keys()
	ids.sort()
	return ids


static func has_deck(deck_id: String) -> bool:
	return DEFINITIONS.has(str(deck_id))


static func sanitize_deck_id(deck_id: String, fallback_id: String = DEFAULT_DECK_ID) -> String:
	var requested: String = str(deck_id)
	if has_deck(requested):
		return requested
	return str(fallback_id) if has_deck(fallback_id) else DEFAULT_DECK_ID


static func get_definition(deck_id: String) -> Dictionary:
	return (DEFINITIONS.get(sanitize_deck_id(deck_id), {}) as Dictionary).duplicate(true)


static func get_upgrade_ids(deck_id: String) -> Array:
	return (get_definition(deck_id).get("upgrade_ids", []) as Array).duplicate()


static func recommended_for_hero(hero_id: String) -> String:
	match str(hero_id):
		"fortification_engineer":
			return DECK_FORTIFICATION_CORPS
		"rapid_gunner":
			return DECK_BARRAGE_CONTROL
		_:
			return DECK_CORE_TACTICS


static func validate_all() -> Array:
	var errors: Array = []
	for deck_id in get_deck_ids():
		var definition: Dictionary = DEFINITIONS[str(deck_id)] as Dictionary
		if str(definition.get("id", "")) != str(deck_id):
			errors.append("deck_id_mismatch:%s" % str(deck_id))
		if str(definition.get("name", "")) == "":
			errors.append("deck_missing_name:%s" % str(deck_id))
		if str(definition.get("description", "")) == "":
			errors.append("deck_missing_description:%s" % str(deck_id))
		var upgrade_ids: Array = definition.get("upgrade_ids", []) as Array
		if upgrade_ids.size() != DECK_SIZE:
			errors.append("deck_size_mismatch:%s:%d" % [str(deck_id), upgrade_ids.size()])
		var unique: Dictionary = {}
		for raw_upgrade_id in upgrade_ids:
			var upgrade_id: String = str(raw_upgrade_id)
			if unique.has(upgrade_id):
				errors.append("deck_duplicate_card:%s:%s" % [str(deck_id), upgrade_id])
			unique[upgrade_id] = true
			if not UpgradeManifestScript.has_upgrade(upgrade_id):
				errors.append("deck_unknown_card:%s:%s" % [str(deck_id), upgrade_id])
	return errors
