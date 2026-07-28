extends Node2D
class_name CardfrontEntityDebugLayer

const BattlefieldEntityScript = preload("res://scripts/cardfront/entities/CardfrontBattlefieldEntity.gd")

var battlefield = null
var registry = null
var show_building_slots: bool = true
var show_collision_shapes: bool = true
var show_health_bars: bool = true


func setup(new_battlefield, new_registry) -> void:
	battlefield = new_battlefield
	registry = new_registry
	z_index = 23
	queue_redraw()


func mark_dirty() -> void:
	queue_redraw()


func _draw() -> void:
	if battlefield == null or registry == null:
		return
	var cell_size: float = float(battlefield.cell_size)
	if show_building_slots:
		for slot in registry.building_slots.values():
			var cell: Vector2i = slot.get("cell", Vector2i.ZERO) as Vector2i
			var rect := Rect2(Vector2(cell) * cell_size, Vector2.ONE * cell_size)
			var occupied: bool = str(slot.get("entity_id", "")) != ""
			var fill := Color(0.72, 0.82, 1.0, 0.12 if not occupied else 0.20)
			draw_rect(rect.grow(-cell_size * 0.12), fill, true)
			draw_rect(
				rect.grow(-cell_size * 0.12),
				Color(0.86, 0.92, 1.0, 0.55),
				false,
				1.2
			)
	for entity in registry.entities_by_id.values():
		if entity == null or not entity.is_alive():
			continue
		var center := (Vector2(entity.cell) + Vector2(0.5, 0.5)) * cell_size
		var owner_color: Color = _owner_color(int(entity.owner_id))
		if show_collision_shapes:
			match str(entity.entity_kind):
				BattlefieldEntityScript.KIND_CREATURE:
					var scale_factor: float = 1.22 if int(entity.size_slots) >= 2 else 1.0
					draw_arc(
						center,
						cell_size * 0.32 * scale_factor,
						0.0,
						TAU,
						18,
						owner_color,
						1.3
					)
				BattlefieldEntityScript.KIND_DEFENSE_TOWER:
					var half := Vector2.ONE * cell_size * 0.30
					draw_rect(Rect2(center - half, half * 2.0), owner_color, false, 1.3)
		if show_health_bars:
			var hp_ratio: float = clampf(
				float(entity.hp) / float(maxi(1, int(entity.max_hp))),
				0.0,
				1.0
			)
			var bar_width: float = cell_size * 0.70
			var bar_pos := center + Vector2(-bar_width * 0.5, cell_size * 0.35)
			draw_rect(
				Rect2(bar_pos, Vector2(bar_width, 2.0)),
				Color(0.05, 0.05, 0.05, 0.86),
				true
			)
			draw_rect(
				Rect2(bar_pos, Vector2(bar_width * hp_ratio, 2.0)),
				owner_color.lightened(0.18),
				true
			)


func _owner_color(owner_id: int) -> Color:
	if owner_id >= GameConfig.Faction.BLUE and owner_id <= GameConfig.Faction.YELLOW:
		return GameConfig.faction_color(owner_id)
	return Color(0.70, 0.72, 0.76, 0.95)
