extends RefCounted
class_name CardfrontUpgradeManifest

const RARITY_COMMON: String = "common"
const RARITY_UNCOMMON: String = "uncommon"
const RARITY_RARE: String = "rare"

const UPGRADE_VOLLEY_PLUS_5: String = "volley_plus_5"
const UPGRADE_VOLLEY_X2: String = "volley_x2"
const UPGRADE_PROJECTILE_POWER_PLUS_1: String = "projectile_power_plus_1"
const UPGRADE_DEFENSE_CAP_PLUS_1: String = "defense_cap_plus_1"
const UPGRADE_RARITY_PLUS_1: String = "rarity_plus_1"
const UPGRADE_MIRROR_NEXT_CHOICE: String = "mirror_next_choice"

const DEFINITIONS := {
	UPGRADE_VOLLEY_PLUS_5: {
		"id": UPGRADE_VOLLEY_PLUS_5,
		"name": "增援齐射",
		"symbol": "+5",
		"rarity": RARITY_COMMON,
		"category": "next_volley",
		"effect_id": "add_next_volley",
		"params": {"amount": 5},
		"description": "下一次齐射增加 5 发",
	},
	UPGRADE_VOLLEY_X2: {
		"id": UPGRADE_VOLLEY_X2,
		"name": "双倍齐射",
		"symbol": "x2",
		"rarity": RARITY_UNCOMMON,
		"category": "next_volley",
		"effect_id": "multiply_next_volley",
		"params": {"multiplier": 2},
		"description": "下一次齐射数量翻倍",
	},
	UPGRADE_PROJECTILE_POWER_PLUS_1: {
		"id": UPGRADE_PROJECTILE_POWER_PLUS_1,
		"name": "强化弹头",
		"symbol": "+1",
		"rarity": RARITY_COMMON,
		"category": "run_growth",
		"effect_id": "increase_projectile_power",
		"params": {"amount": 1},
		"description": "本局子弹破坏力永久增加 1",
	},
	UPGRADE_DEFENSE_CAP_PLUS_1: {
		"id": UPGRADE_DEFENSE_CAP_PLUS_1,
		"name": "加厚阵地",
		"symbol": "+1",
		"rarity": RARITY_COMMON,
		"category": "run_growth",
		"effect_id": "increase_defense_cap",
		"params": {"amount": 1},
		"description": "本局地图防守值上限永久增加 1",
	},
	UPGRADE_RARITY_PLUS_1: {
		"id": UPGRADE_RARITY_PLUS_1,
		"name": "稀有预感",
		"symbol": "UP",
		"rarity": RARITY_UNCOMMON,
		"category": "draft_growth",
		"effect_id": "increase_rarity",
		"params": {"amount": 1},
		"description": "本局后续抽取的高稀有强化概率提高",
	},
	UPGRADE_MIRROR_NEXT_CHOICE: {
		"id": UPGRADE_MIRROR_NEXT_CHOICE,
		"name": "镜像回声",
		"symbol": "x2",
		"rarity": RARITY_RARE,
		"category": "draft_growth",
		"effect_id": "duplicate_next_choice",
		"params": {},
		"description": "下一次选择的强化完整结算两次",
	},
}

const REQUIRED_PARAMS := {
	"add_next_volley": ["amount"],
	"multiply_next_volley": ["multiplier"],
	"increase_projectile_power": ["amount"],
	"increase_defense_cap": ["amount"],
	"increase_rarity": ["amount"],
	"duplicate_next_choice": [],
}


static func get_upgrade_ids() -> Array:
	var ids: Array = DEFINITIONS.keys()
	ids.sort()
	return ids


static func get_definition(upgrade_id: String) -> Dictionary:
	return (DEFINITIONS.get(str(upgrade_id), {}) as Dictionary).duplicate(true)


static func has_upgrade(upgrade_id: String) -> bool:
	return DEFINITIONS.has(str(upgrade_id))


static func is_rarity_valid(rarity: String) -> bool:
	return str(rarity) in [RARITY_COMMON, RARITY_UNCOMMON, RARITY_RARE]


static func validate_all() -> Array:
	var errors: Array = []
	for upgrade_id in get_upgrade_ids():
		var definition: Dictionary = DEFINITIONS[str(upgrade_id)]
		if str(definition.get("id", "")) != str(upgrade_id):
			errors.append("id_mismatch:%s" % str(upgrade_id))
		if str(definition.get("name", "")) == "":
			errors.append("missing_name:%s" % str(upgrade_id))
		if str(definition.get("symbol", "")) == "":
			errors.append("missing_symbol:%s" % str(upgrade_id))
		if str(definition.get("description", "")) == "":
			errors.append("missing_description:%s" % str(upgrade_id))
		if not is_rarity_valid(str(definition.get("rarity", ""))):
			errors.append("invalid_rarity:%s" % str(upgrade_id))
		var effect_id: String = str(definition.get("effect_id", ""))
		if not REQUIRED_PARAMS.has(effect_id):
			errors.append("unknown_effect:%s:%s" % [str(upgrade_id), effect_id])
			continue
		var params: Dictionary = definition.get("params", {}) as Dictionary
		for required_param in REQUIRED_PARAMS[effect_id]:
			if not params.has(str(required_param)):
				errors.append("missing_param:%s:%s" % [str(upgrade_id), str(required_param)])
	return errors
