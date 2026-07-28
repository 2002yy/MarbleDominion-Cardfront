extends RefCounted
class_name CardfrontUpgradeManifest

const RARITY_COMMON: String = "common"
const RARITY_UNCOMMON: String = "uncommon"
const RARITY_RARE: String = "rare"

const UPGRADE_VOLLEY_PLUS_5: String = "volley_plus_5"
const UPGRADE_VOLLEY_X2: String = "volley_x2"
const UPGRADE_ATTACK_LEVEL_PLUS_1: String = "attack_level_plus_1"
const UPGRADE_DEFENSE_CAP_PLUS_1: String = "defense_cap_plus_1"
const UPGRADE_FRONTLINE_REPAIR: String = "frontline_repair"
const UPGRADE_ARMOR_PIERCING: String = "armor_piercing"
const UPGRADE_RARITY_PLUS_1: String = "rarity_plus_1"
const UPGRADE_ECHO_NEXT_CHOICE: String = "echo_next_choice"
const UPGRADE_SIEGE_CALIBRATION: String = "siege_calibration"
const UPGRADE_SUPPRESSION_SCREEN: String = "suppression_screen"
const UPGRADE_REPAIR_UNITS: String = "repair_units"
const UPGRADE_FIRE_CONTROL_BEACON: String = "fire_control_beacon"
const UPGRADE_INTERCEPTOR_TOWER: String = "interceptor_tower"
const UPGRADE_BUILDING_VOLLEY: String = "building_volley"
const UPGRADE_HEAVY_CHARGE: String = "heavy_charge"
const UPGRADE_ARMORED_GUARD: String = "armored_guard"
const UPGRADE_SAPPER_UNIT: String = "sapper_unit"
const UPGRADE_GATE_COLOSSUS: String = "gate_colossus"

# Historical A/B0 baseline. Keep this list available for audit fixtures.
const CORE_UPGRADE_IDS: Array[String] = [
	UPGRADE_VOLLEY_PLUS_5,
	UPGRADE_VOLLEY_X2,
	UPGRADE_ATTACK_LEVEL_PLUS_1,
	UPGRADE_DEFENSE_CAP_PLUS_1,
	UPGRADE_FRONTLINE_REPAIR,
	UPGRADE_ARMOR_PIERCING,
	UPGRADE_RARITY_PLUS_1,
	UPGRADE_ECHO_NEXT_CHOICE,
]

const FORMAL_UPGRADE_IDS: Array[String] = [
	UPGRADE_VOLLEY_PLUS_5,
	UPGRADE_VOLLEY_X2,
	UPGRADE_ATTACK_LEVEL_PLUS_1,
	UPGRADE_DEFENSE_CAP_PLUS_1,
	UPGRADE_FRONTLINE_REPAIR,
	UPGRADE_ARMOR_PIERCING,
	UPGRADE_RARITY_PLUS_1,
	UPGRADE_ECHO_NEXT_CHOICE,
	UPGRADE_SIEGE_CALIBRATION,
	UPGRADE_SUPPRESSION_SCREEN,
	UPGRADE_REPAIR_UNITS,
	UPGRADE_FIRE_CONTROL_BEACON,
	UPGRADE_INTERCEPTOR_TOWER,
	UPGRADE_BUILDING_VOLLEY,
	UPGRADE_HEAVY_CHARGE,
	UPGRADE_ARMORED_GUARD,
	UPGRADE_SAPPER_UNIT,
	UPGRADE_GATE_COLOSSUS,
]

const DEFINITIONS := {
	UPGRADE_VOLLEY_PLUS_5: {
		"id": UPGRADE_VOLLEY_PLUS_5,
		"name": "增援齐射",
		"symbol": "+5",
		"rarity": RARITY_COMMON,
		"category": "next_volley",
		"tags": ["volley", "standard", "tempo"],
		"effect_id": "add_next_volley",
		"params": {"amount": 5},
		"description": "下一次齐射增加 5 发标准弹；不产生特殊弹，也不被双倍齐射复制",
	},
	UPGRADE_VOLLEY_X2: {
		"id": UPGRADE_VOLLEY_X2,
		"name": "双倍齐射",
		"symbol": "x2",
		"rarity": RARITY_UNCOMMON,
		"category": "next_volley",
		"tags": ["volley", "typed_group", "combo"],
		"effect_id": "multiply_next_volley",
		"params": {"multiplier": 2},
		"description": "下一次齐射复制英雄基础弹组，包含基础攻城弹或压制弹",
	},
	UPGRADE_ATTACK_LEVEL_PLUS_1: {
		"id": UPGRADE_ATTACK_LEVEL_PLUS_1,
		"name": "攻击训练",
		"symbol": "+25%",
		"rarity": RARITY_UNCOMMON,
		"category": "run_growth",
		"tags": ["chamber", "growth"],
		"effect_id": "increase_attack_level",
		"params": {"amount": 1},
		"description": "本局可伤害控制舱的弹丸伤害永久提高 25%，最多 3 级",
	},
	UPGRADE_DEFENSE_CAP_PLUS_1: {
		"id": UPGRADE_DEFENSE_CAP_PLUS_1,
		"name": "加厚阵地",
		"symbol": "+1",
		"rarity": RARITY_COMMON,
		"category": "run_growth",
		"tags": ["fortify", "growth"],
		"effect_id": "increase_defense_cap",
		"params": {"amount": 1},
		"description": "本局地图防守值上限永久增加 1，不自动补满",
	},
	UPGRADE_FRONTLINE_REPAIR: {
		"id": UPGRADE_FRONTLINE_REPAIR,
		"name": "前线修复",
		"symbol": "+6",
		"rarity": RARITY_COMMON,
		"category": "territory",
		"tags": ["fortify", "frontline", "repair"],
		"effect_id": "repair_territory",
		"params": {"amount": 6, "zone": "frontline"},
		"description": "为前线领土恢复共 6 层防守，每轮每格最多恢复 1 层；工程师额外恢复 2 层",
	},
	UPGRADE_ARMOR_PIERCING: {
		"id": UPGRADE_ARMOR_PIERCING,
		"name": "穿甲轨迹",
		"symbol": "AP6",
		"rarity": RARITY_UNCOMMON,
		"category": "next_volley",
		"tags": ["volley", "anti_fortify", "siege"],
		"effect_id": "add_armor_pierce",
		"params": {"contacts": 6},
		"description": "下一次齐射前 6 次防守接触忽略 1 层防守",
	},
	UPGRADE_RARITY_PLUS_1: {
		"id": UPGRADE_RARITY_PLUS_1,
		"name": "稀有预感",
		"symbol": "UP",
		"rarity": RARITY_UNCOMMON,
		"category": "draft_growth",
		"tags": ["draft", "growth"],
		"effect_id": "increase_rarity",
		"params": {"amount": 1},
		"description": "本局后续抽取的高稀有强化概率提高",
	},
	UPGRADE_ECHO_NEXT_CHOICE: {
		"id": UPGRADE_ECHO_NEXT_CHOICE,
		"name": "延迟回响",
		"symbol": "ECHO",
		"rarity": RARITY_RARE,
		"category": "draft_growth",
		"tags": ["draft", "combo"],
		"effect_id": "echo_next_choice",
		"params": {},
		"description": "下一次选择结算一次，并在再下一轮额外重放一次",
	},
	UPGRADE_SIEGE_CALIBRATION: {
		"id": UPGRADE_SIEGE_CALIBRATION,
		"name": "攻城编组",
		"symbol": "SIEGE2",
		"rarity": RARITY_UNCOMMON,
		"category": "next_volley",
		"tags": ["volley", "siege", "anti_fortify", "chamber"],
		"effect_id": "convert_next_volley",
		"params": {"projectile_type": "siege", "amount": 2},
		"description": "下一次齐射将最多 2 发标准弹转换为攻城弹，并编入特殊弹段优先发射",
	},
	UPGRADE_SUPPRESSION_SCREEN: {
		"id": UPGRADE_SUPPRESSION_SCREEN,
		"name": "压制编队",
		"symbol": "SUP2",
		"rarity": RARITY_UNCOMMON,
		"category": "next_volley",
		"tags": ["volley", "suppression", "territory", "route"],
		"effect_id": "convert_next_volley",
		"params": {"projectile_type": "suppression", "amount": 2},
		"description": "下一次齐射将最多 2 发标准弹转换为压制弹，强化占格与路线压力但不能伤害控制舱",
	},
	UPGRADE_REPAIR_UNITS: {
		"id": UPGRADE_REPAIR_UNITS,
		"name": "维修单位",
		"symbol": "2xBOT",
		"rarity": RARITY_COMMON,
		"category": "entity",
		"tags": ["creature", "repair", "frontline", "fortify"],
		"effect_id": "queue_entity_action",
		"params": {"action": "summon_repair_units", "amount": 2},
		"display_stats": "×2 · HP 1 · 持续 3 回合",
		"description": "召唤 2 只维修单位；每只持续 3 回合，移动到受损前线并修复 1 层防守",
	},
	UPGRADE_FIRE_CONTROL_BEACON: {
		"id": UPGRADE_FIRE_CONTROL_BEACON,
		"name": "火控信标",
		"symbol": "GUIDE",
		"rarity": RARITY_UNCOMMON,
		"category": "building",
		"tags": ["tower", "guidance", "route", "building"],
		"effect_id": "queue_entity_action",
		"params": {"action": "build_or_upgrade_tower", "tower_id": "fire_control_beacon"},
		"display_stats": "HP 5 · L1–3 · 引导 6/8/10",
		"description": "在路线塔位建造火控信标；重复选择升级，引导数量依次为 6、8、10 发",
	},
	UPGRADE_INTERCEPTOR_TOWER: {
		"id": UPGRADE_INTERCEPTOR_TOWER,
		"name": "拦截塔",
		"symbol": "BLOCK",
		"rarity": RARITY_UNCOMMON,
		"category": "building",
		"tags": ["tower", "intercept", "defense", "building"],
		"effect_id": "queue_entity_action",
		"params": {"action": "build_or_upgrade_tower", "tower_id": "interceptor_tower"},
		"display_stats": "HP 4 · L1–3 · 拦截 2/3/3",
		"description": "在路线塔位建造拦截塔；每轮拦截标准弹数量依次为 2、3、3，三级耗尽额度后反击 1 发",
	},
	UPGRADE_BUILDING_VOLLEY: {
		"id": UPGRADE_BUILDING_VOLLEY,
		"name": "建筑齐射",
		"symbol": "TOWER+",
		"rarity": RARITY_RARE,
		"category": "building_growth",
		"tags": ["tower", "volley", "building", "growth"],
		"effect_id": "increase_building_volley",
		"params": {"amount": 1},
		"description": "每座正常供电的己方塔每轮沿所在路线发射标准弹；每塔依次为 2、3、4 发",
	},
	UPGRADE_HEAVY_CHARGE: {
		"id": UPGRADE_HEAVY_CHARGE,
		"name": "重型装药",
		"symbol": "BLAST",
		"rarity": RARITY_RARE,
		"category": "next_volley",
		"tags": ["explosion", "tower", "siege", "anti_building"],
		"effect_id": "arm_heavy_charge",
		"params": {
			"center_bonus": 1,
			"entity_radius": 2,
			"entity_damage": 1,
			"defense_radius": 1,
			"defense_damage": 1,
		},
		"description": "下一轮首次命中敌塔时爆炸：中心塔额外受 1 伤害，半径 2 内敌方实体受 1 伤害，半径 1 内敌方格失去 1 层防守",
	},
	UPGRADE_ARMORED_GUARD: {
		"id": UPGRADE_ARMORED_GUARD,
		"name": "装甲护卫",
		"symbol": "GUARD4",
		"rarity": RARITY_UNCOMMON,
		"category": "entity",
		"tags": ["creature", "armored", "frontline", "gate", "defense"],
		"effect_id": "queue_entity_action",
		"params": {"action": "summon_armored_guard", "amount": 1},
		"display_stats": "×1 · HP 4 · 永久",
		"description": "召唤 1 名 4 生命装甲护卫；每轮移动 1 格并驻守最近闸门入口或争夺前线，持续至被击毁",
	},
	UPGRADE_SAPPER_UNIT: {
		"id": UPGRADE_SAPPER_UNIT,
		"name": "掘城单位",
		"symbol": "SAP3",
		"rarity": RARITY_UNCOMMON,
		"category": "entity",
		"tags": ["creature", "armored", "siege", "tower", "anti_fortify"],
		"effect_id": "queue_entity_action",
		"params": {"action": "summon_sapper_unit", "amount": 1},
		"display_stats": "×1 · HP 3 · 命中后自爆",
		"description": "召唤 1 名 3 生命装甲掘城单位；优先炸敌塔 3 点，其次拆除目标格最多 2 层防守，对控制舱仅造成 1 点，结算后自毁",
	},
	UPGRADE_GATE_COLOSSUS: {
		"id": UPGRADE_GATE_COLOSSUS,
		"name": "唤醒闸门巨像",
		"symbol": "GOLEM6",
		"rarity": RARITY_RARE,
		"category": "neutral_entity",
		"tags": ["creature", "neutral", "armored", "gate", "comeback"],
		"effect_id": "queue_entity_action",
		"params": {"action": "summon_gate_colossus", "amount": 1},
		"display_stats": "中立 · HP 6 · 占 2 槽",
		"description": "从中央闸门唤醒 1 只 6 生命中立巨像；它占 2 格容量并攻击当前领土领先方，双方弹丸都能伤害它，每方整局限一次",
	},
}

const REQUIRED_PARAMS := {
	"add_next_volley": ["amount"],
	"multiply_next_volley": ["multiplier"],
	"increase_attack_level": ["amount"],
	"increase_defense_cap": ["amount"],
	"repair_territory": ["amount", "zone"],
	"add_armor_pierce": ["contacts"],
	"increase_rarity": ["amount"],
	"echo_next_choice": [],
	"convert_next_volley": ["projectile_type", "amount"],
	"queue_entity_action": ["action"],
	"increase_building_volley": ["amount"],
	"arm_heavy_charge": ["center_bonus", "entity_radius", "entity_damage", "defense_radius", "defense_damage"],
}


static func get_upgrade_ids() -> Array:
	return FORMAL_UPGRADE_IDS.duplicate()


static func get_all_upgrade_ids() -> Array:
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
	for upgrade_id in get_all_upgrade_ids():
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
		var tags: Array = definition.get("tags", []) as Array
		if tags.is_empty():
			errors.append("missing_tags:%s" % str(upgrade_id))
		var effect_id: String = str(definition.get("effect_id", ""))
		if not REQUIRED_PARAMS.has(effect_id):
			errors.append("unknown_effect:%s:%s" % [str(upgrade_id), effect_id])
			continue
		var params: Dictionary = definition.get("params", {}) as Dictionary
		for required_param in REQUIRED_PARAMS[effect_id]:
			if not params.has(str(required_param)):
				errors.append("missing_param:%s:%s" % [str(upgrade_id), str(required_param)])
	return errors
