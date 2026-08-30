extends RefCounted
class_name CardfrontCombatReadabilityProfile

const ProjectileTypeScript = preload("res://scripts/cardfront/volley/CardfrontProjectileType.gd")

const FIRE_CONTROL_BEACON: String = "fire_control_beacon"
const INTERCEPTOR_TOWER: String = "interceptor_tower"


static func projectile_spec(projectile_type: String, faction_color: Color) -> Dictionary:
	match ProjectileTypeScript.sanitize(projectile_type):
		ProjectileTypeScript.SIEGE:
			return {
				"body_color": Color(0.38, 0.30, 0.22),
				"rim_color": faction_color,
				"trail_color": faction_color,
				"radius": 0.62,
				"shape_scale": Vector3(1.10, 0.94, 0.82),
				"trail_length": 1.45,
				"trail_width": 0.24,
				"emission": 0.30,
				"rim_emission": 1.20,
				"rim_alpha": 0.82,
				"rim_scale": 1.18,
				"shape": "heavy",
			}
		ProjectileTypeScript.SUPPRESSION:
			return {
				"body_color": Color(0.50, 0.56, 0.58),
				"rim_color": faction_color,
				"trail_color": faction_color,
				"radius": 0.46,
				"shape_scale": Vector3(1.22, 0.72, 0.55),
				"trail_length": 2.15,
				"trail_width": 0.16,
				"emission": 0.45,
				"rim_emission": 1.40,
				"rim_alpha": 0.82,
				"rim_scale": 1.18,
				"shape": "disc",
			}
		_:
			return {
				"body_color": faction_color.lightened(0.22),
				"rim_color": faction_color,
				"trail_color": faction_color,
				"radius": 0.42,
				"shape_scale": Vector3.ONE,
				"trail_length": 1.05,
				"trail_width": 0.12,
				"emission": 0.72,
				"rim_emission": 0.90,
				"rim_alpha": 0.82,
				"rim_scale": 1.18,
				"shape": "round",
			}


static func entity_status_text(entity) -> String:
	if entity == null:
		return ""
	if str(entity.entity_kind) == "defense_tower":
		if not bool(entity.powered):
			return "断电"
		var level_text: String = "%d级" % maxi(1, int(entity.tower_level))
		if str(entity.tower_id) == FIRE_CONTROL_BEACON:
			return "%s 信标·引导%d发" % [level_text, maxi(0, int(entity.guidance_remaining))]
		return "%s 拦截·拦%d发" % [level_text, maxi(0, int(entity.intercepts_remaining))]
	var names: Dictionary = {
		"repair_unit": "维修",
		"armored_guard": "护卫",
		"sapper_unit": "掘城",
		"scout_unit": "侦察·修正弹道",
		"gate_colossus": "中立巨像·攻双方",
	}
	var role_text := str(names.get(str(entity.creature_id), "单位"))
	var action_feedback := str(entity.metadata.get("action_feedback", ""))
	return "%s·%s" % [role_text, action_feedback] if action_feedback != "" else role_text


static func entity_description(entity) -> String:
	if entity == null:
		return ""
	if str(entity.entity_kind) == "defense_tower":
		if str(entity.tower_id) == FIRE_CONTROL_BEACON:
			return "火控信标：引导己方标准弹飞向敌方，等级越高引导越多"
		return "拦截塔：拦截敌方标准弹，等级越高拦截越多，3级反击1发"
	var descs: Dictionary = {
		"repair_unit": "修复单位：自动寻找受损前线格并修复1层防御",
		"armored_guard": "装甲护卫：移动到前线阻挡敌方弹体，标准弹弹开",
		"sapper_unit": "掘城单位：穿越桥门爆破敌方塔/防御/控制舱，用后自毁",
		"scout_unit": "侦察单位：由信标维护，微调附近标准弹弹道",
		"gate_colossus": "闸门巨像：中立单位，攻击当前领土领先方",
	}
	return str(descs.get(str(entity.creature_id), "战场单位"))


static func hp_ratio(entity) -> float:
	if entity == null:
		return 0.0
	return clampf(float(entity.hp) / float(maxi(1, int(entity.max_hp))), 0.0, 1.0)


static func tower_shape(tower_id: String) -> String:
	return "beacon" if str(tower_id) == FIRE_CONTROL_BEACON else "interceptor"


static func stable_slot_offset(entity_id: String) -> Vector3:
	var offsets: Array[Vector2] = [
		Vector2(-0.42, -0.28),
		Vector2(0.42, 0.28),
		Vector2(-0.42, 0.28),
		Vector2(0.42, -0.28),
		Vector2.ZERO,
	]
	var slot: int = absi(str(entity_id).hash()) % offsets.size()
	var offset: Vector2 = offsets[slot]
	return Vector3(offset.x, 0.0, offset.y)
