extends RefCounted
class_name CardfrontArenaLayout

const GridExtentScript = preload("res://scripts/GridExtent.gd")
const TARGET_MAP_PIXELS: float = 520.0
const MIN_CELL_SIZE: int = 8
const MAX_CELL_SIZE: int = 18
const MAP_TOP: float = 76.0
const ARENA_VIEW_TOP: float = 72.0
const ARENA_VIEW_BOTTOM_MARGIN: float = 32.0
const SIDE_GUTTER: float = 12.0
const TURRET_OVERHANG_MIN: float = 8.0
const AIM_PANEL_SIZE: Vector2 = Vector2(196.0, 62.0)


static func apply_to(base_layout: Dictionary, grid_extent_value, viewport_size: Vector2) -> Dictionary:
	var layout: Dictionary = base_layout.duplicate(true)
	var extent := GridExtentScript.normalize(grid_extent_value)
	var available_map_height: float = maxf(320.0, viewport_size.y - MAP_TOP - 92.0)
	var available_map_width: float = maxf(320.0, viewport_size.x - 420.0)
	var target_map_height: float = minf(TARGET_MAP_PIXELS, available_map_height)
	var target_map_width: float = minf(TARGET_MAP_PIXELS, available_map_width)
	var cell_size: int = clampi(
		floori(minf(target_map_width / float(extent.x), target_map_height / float(extent.y))),
		MIN_CELL_SIZE,
		MAX_CELL_SIZE
	)
	var map_pixels := Vector2(extent) * float(cell_size)
	var map_position := Vector2(
		floorf((viewport_size.x - map_pixels.x) * 0.5),
		clampf(MAP_TOP, 72.0, maxf(72.0, viewport_size.y - map_pixels.y - 64.0))
	)
	var battlefield_rect := Rect2(map_position, map_pixels)
	var arena_view_top: float = minf(ARENA_VIEW_TOP, maxf(0.0, viewport_size.y * 0.16))
	var arena_view_rect := Rect2(
		Vector2(0.0, arena_view_top),
		Vector2(viewport_size.x, maxf(320.0, viewport_size.y - arena_view_top - ARENA_VIEW_BOTTOM_MARGIN))
	)
	var turret_overhang: float = maxf(TURRET_OVERHANG_MIN, float(cell_size) * 0.72)
	var center_x: float = battlefield_rect.get_center().x
	var player_turret := Vector2(center_x, battlefield_rect.end.y + turret_overhang)
	var ai_turret := Vector2(center_x, battlefield_rect.position.y - turret_overhang)
	var left_gutter_width: float = maxf(220.0, battlefield_rect.position.x - SIDE_GUTTER * 2.0)
	var aim_panel_position := Vector2(
		SIDE_GUTTER,
		clampf(battlefield_rect.end.y - AIM_PANEL_SIZE.y - 10.0, 230.0, viewport_size.y - AIM_PANEL_SIZE.y - 18.0)
	)

	layout["cardfront_arena"] = true
	layout["grid_extent"] = GridExtentScript.to_array(extent)
	layout["arena_composition"] = "open_dual_bridge"
	layout["arena_vertical_scale"] = 1.0
	layout["turrets_outside_battlefield"] = true
	layout["battlefield_cell_size"] = cell_size
	layout["battlefield_rect"] = battlefield_rect
	layout["arena_view_rect"] = arena_view_rect
	layout["turret_positions"] = {
		GameConfig.Faction.BLUE: player_turret,
		GameConfig.Faction.RED: ai_turret,
	}
	layout["turret_center_angles"] = {
		GameConfig.Faction.BLUE: -PI * 0.5,
		GameConfig.Faction.RED: PI * 0.5,
	}
	layout["turret_sweep_amplitudes"] = {
		GameConfig.Faction.BLUE: deg_to_rad(58.0),
		GameConfig.Faction.RED: deg_to_rad(50.0),
	}
	layout["command_chamber_positions"] = {
		GameConfig.Faction.BLUE: player_turret,
		GameConfig.Faction.RED: ai_turret,
	}
	layout["aim_control_rect"] = Rect2(
		aim_panel_position,
		Vector2(minf(AIM_PANEL_SIZE.x, left_gutter_width), AIM_PANEL_SIZE.y)
	)
	layout["arena_floor_rect"] = arena_view_rect
	return layout


static func is_arena_layout(layout: Dictionary) -> bool:
	return bool(layout.get("cardfront_arena", false))
