extends RefCounted
class_name CardfrontCombatReadabilityProfile

const ProjectileTypeScript = preload("res://scripts/cardfront/volley/CardfrontProjectileType.gd")

const FIRE_CONTROL_BEACON: String = "fire_control_beacon"
const INTERCEPTOR_TOWER: String = "interceptor_tower"


static func projectile_spec(projectile_type: String, faction_color: Color) -> Dictionary:
	match ProjectileTypeScript.sanitize(projectile_type):
		ProjectileTypeScript.SIEGE:
			return {
				"color": faction_color.lerp(Color(1.0, 0.50, 0.08), 0.78),
				"radius": 0.62,
				"trail_length": 1.45,
				"trail_width": 0.24,
				"emission": 1.05,
				"shape": "heavy",
			}
		ProjectileTypeScript.SUPPRESSION:
			return {
				"color": faction_color.lerp(Color(0.12, 0.92, 1.0), 0.80),
				"radius": 0.46,
				"trail_length": 2.15,
				"trail_width": 0.16,
				"emission": 1.30,
				"shape": "disc",
			}
		_:
			return {
				"color": faction_color.lightened(0.18),
				"radius": 0.42,
				"trail_length": 1.05,
				"trail_width": 0.12,
				"emission": 0.82,
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
			return "%s  引导%d" % [level_text, maxi(0, int(entity.guidance_remaining))]
		return "%s  拦截%d" % [level_text, maxi(0, int(entity.intercepts_remaining))]
	var names: Dictionary = {
		"repair_unit": "维修",
		"armored_guard": "护卫",
		"sapper_unit": "掘城",
		"scout_unit": "侦察",
		"gate_colossus": "中立巨像",
	}
	return str(names.get(str(entity.creature_id), "单位"))


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
