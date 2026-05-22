extends RefCounted
class_name CardfrontFeedbackText

const REASON_LABELS := {
	"success": "出牌成功",
	"invalid_target": "目标无效：请选择亮起的格子或区域。",
	"not_enough_resource": "资源不足：能量或零件不够。",
	"insufficient_resources": "资源不足：能量或零件不够。",
	"card_already_used": "这张卡本轮已经使用。",
	"used": "这张卡本轮已经使用。",
	"missing_system": "系统暂不可用：缺少运行时模块。",
	"missing_card_system": "系统暂不可用：缺少卡牌系统。",
	"play_returned_null": "出牌失败：没有收到执行结果。",
	"unknown_card": "未知卡牌。",
	"no_card_selected": "请先选择一张卡牌。",
	"stub": "该效果还未接入。",
}

const TYPE_LABELS := {
	"fortify": "加固",
	"calibrated_shot": "校准射击",
	"morale_fluctuation": "民心",
	"pioneer_beacon": "拓荒信标",
}

const TARGET_LABELS := {
	"owned_border": "己方边界格",
	"enemy_region": "敌方控制区域",
	"owned_region": "己方控制区域",
}

const EFFECT_SUMMARIES := {
	"fortify_border": "在己方边界格建立临时防护，延缓区域被夺取。",
	"calibrated_shot": "校准一个敌方区域，让火力更明确地压向该区域。",
	"morale_fluctuation": "提升己方区域的民心波动，强化区域控制节奏。",
	"pioneer_beacon_lite": "在己方边界放置信标，推动相邻中立格转化。",
}


static func reason_to_text(reason: String, card_name: String = "") -> String:
	var base: String = str(REASON_LABELS.get(str(reason), "出牌失败：%s" % str(reason)))
	if card_name == "":
		return base
	return "%s：%s" % [str(card_name), base]


static func success_to_text(card_name: String) -> String:
	if card_name == "":
		return "出牌成功。"
	return "%s 生效。" % str(card_name)


static func card_type_to_text(card_type: String) -> String:
	return str(TYPE_LABELS.get(str(card_type), str(card_type)))


static func target_type_to_text(target_type: String) -> String:
	return str(TARGET_LABELS.get(str(target_type), str(target_type)))


static func effect_summary(effect_id: String) -> String:
	return str(EFFECT_SUMMARIES.get(str(effect_id), "执行该卡牌的当前效果。"))
