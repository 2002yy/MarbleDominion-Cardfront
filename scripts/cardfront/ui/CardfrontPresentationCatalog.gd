extends RefCounted
class_name CardfrontPresentationCatalog

const HEROES: Dictionary = {
	"balanced_commander": {
		"display_name": "均衡指挥官",
		"short_name": "指挥官",
		"role": "灵活构筑",
		"trait": "适配各种强化，转型最稳定",
		"accent": Color(0.20, 0.66, 0.86),
	},
	"rapid_gunner": {
		"display_name": "连射炮手",
		"short_name": "炮手",
		"role": "齐射压制",
		"trait": "基础弹量更高，擅长倍增与路线压制",
		"accent": Color(0.95, 0.55, 0.18),
	},
	"fortification_engineer": {
		"display_name": "筑垒工程师",
		"short_name": "工程师",
		"role": "阵地防守",
		"trait": "控制舱更坚固，接触前线预筑防御",
		"accent": Color(0.44, 0.76, 0.39),
	},
}

const MAPS: Dictionary = {
	"default_duel": {
		"display_name": "双桥绿野",
		"subtitle": "标准战场",
		"description": "两条对称路线与五座据点，适合熟悉基础推进。",
		"accent": Color(0.49, 0.68, 0.28),
	},
	"cross_resource": {
		"display_name": "交错工坊",
		"subtitle": "快速争夺",
		"description": "资源据点交错分布，换线与抢先手更重要。",
		"accent": Color(0.88, 0.58, 0.22),
	},
	"central_lab": {
		"display_name": "中央实验场",
		"subtitle": "阵地攻防",
		"description": "中央实验室扩大，桥头防守与后期构筑更强。",
		"accent": Color(0.55, 0.47, 0.78),
	},
}


static func hero(hero_id: String) -> Dictionary:
	return (HEROES.get(hero_id, HEROES["balanced_commander"]) as Dictionary).duplicate(true)


static func map(map_id: String) -> Dictionary:
	return (MAPS.get(map_id, MAPS["default_duel"]) as Dictionary).duplicate(true)
