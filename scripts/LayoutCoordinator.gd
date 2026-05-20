extends RefCounted
class_name LayoutCoordinator

const TURRET_MARGIN: float = 16.0
const SAFE_MARGIN: float = 10.0
const SIDE_BUTTON_WIDTH: float = 96.0
const SIDE_BUTTON_HEIGHT: float = 42.0
const SIDE_MARGIN: float = 10.0
const SIDE_GAP: float = 6.0
const CHAMBER_TOP_TURRET_GAP: float = 18.0
const CHAMBER_BOTTOM_TURRET_GAP: float = 8.0
const FPS_BG_SIZE: Vector2 = Vector2(714.0, 30.0)
const FPS_LABEL_SIZE: Vector2 = Vector2(702.0, 24.0)
const EVENT_LABEL_SIZE: Vector2 = Vector2(332.0, 24.0)

static func get_cell_size(grid_size: int) -> float:
	match grid_size:
		10:
			return 34.0
		20:
			return 22.0
		30:
			return 16.0
		40:
			return 13.0
		50:
			return 11.0
		60:
			return 9.0
		_:
			return 13.0

static func get_chamber_base_size() -> Vector2:
	return Vector2(115.0, 286.0)

static func calculate_layout(grid_size: int, viewport_size: Vector2, is_mobile: bool = false) -> Dictionary:
	var cell_size: float = get_cell_size(grid_size)
	var profile := LayoutProfiles.get_profile(grid_size)
	var map_pixel_size: float = float(grid_size) * cell_size
	var bf_x: float = (viewport_size.x - map_pixel_size) * 0.5
	var bf_y: float = profile.get("map_y", 96.0)
	var bf_rect := Rect2(Vector2(bf_x, bf_y), Vector2(map_pixel_size, map_pixel_size))

	var turret_positions := _calculate_turret_positions(bf_rect)

	var chamber_base_size := get_chamber_base_size()
	var chamber_scale: float = profile.get("chamber_scale", 0.80)
	var chamber_size := chamber_base_size * chamber_scale
	var chamber_gap: float = profile.get("chamber_gap", 10.0)
	var chamber_positions := _calculate_chamber_positions(bf_rect, turret_positions, chamber_size, chamber_gap)
	# Blend profile manual Y values with calculated positions:
	# profile values have been hand-tuned per grid size; only override if
	# they would cause the chamber to overlap the battlefield vertically.
	var profile_top_y: float = profile.get("left_chamber_y_top", chamber_positions[GameConfig.Faction.BLUE].y)
	var profile_bottom_y: float = profile.get("left_chamber_y_bottom", chamber_positions[GameConfig.Faction.GREEN].y)
	var calc_top_y: float = chamber_positions[GameConfig.Faction.BLUE].y
	var calc_bottom_y: float = chamber_positions[GameConfig.Faction.GREEN].y
	var top_y: float = minf(profile_top_y, calc_top_y)
	var bottom_y: float = maxf(profile_bottom_y, calc_bottom_y)
	chamber_positions[GameConfig.Faction.BLUE] = Vector2(chamber_positions[GameConfig.Faction.BLUE].x, top_y)
	chamber_positions[GameConfig.Faction.RED] = Vector2(chamber_positions[GameConfig.Faction.RED].x, top_y)
	chamber_positions[GameConfig.Faction.GREEN] = Vector2(chamber_positions[GameConfig.Faction.GREEN].x, bottom_y)
	chamber_positions[GameConfig.Faction.YELLOW] = Vector2(chamber_positions[GameConfig.Faction.YELLOW].x, bottom_y)

	var button_size: Vector2 = profile.get("button_size", Vector2(88.0, 46.0))
	if is_mobile:
		button_size += Vector2(16.0, 10.0)
	var button_gap: float = profile.get("button_gap", 11.0) + (4.0 if is_mobile else 0.0)
	var add_ball_button_positions := _calculate_add_ball_positions(chamber_positions, chamber_size, button_size, button_gap, viewport_size)

	var side_button_size: Vector2 = Vector2(114.0, 46.0) if is_mobile else Vector2(SIDE_BUTTON_WIDTH, SIDE_BUTTON_HEIGHT)
	var side_x: float = viewport_size.x - side_button_size.x - SIDE_MARGIN
	var side_button_positions := _calculate_side_buttons(side_x, side_button_size)

	var hud_positions := _calculate_hud_positions(viewport_size, profile, is_mobile, side_button_positions, side_button_size)
	var roulette_stage_rect := _calculate_roulette(grid_size, viewport_size, is_mobile, bf_rect)
	var start_menu_layout := _calculate_start_menu_layout(viewport_size, is_mobile)

	return {
		"viewport_size": viewport_size,
		"grid_size": grid_size,
		"is_mobile": is_mobile,
		"cell_size": cell_size,
		"safe_margin": SAFE_MARGIN,
		"battlefield_rect": bf_rect,
		"turret_positions": turret_positions,
		"chamber_positions": chamber_positions,
		"chamber_size": chamber_size,
		"add_ball_positions": add_ball_button_positions,
		"add_ball_button_positions": add_ball_button_positions,
		"add_ball_button_size": button_size,
		"side_button_positions": side_button_positions,
		"side_button_size": side_button_size,
		"hud_positions": hud_positions,
		"roulette_stage_rect": roulette_stage_rect,
		"start_menu_layout": start_menu_layout,
	}

static func _calculate_turret_positions(bf_rect: Rect2) -> Dictionary:
	var size := bf_rect.size.x
	var m := TURRET_MARGIN
	return {
		GameConfig.Faction.BLUE: bf_rect.position + Vector2(m, m),
		GameConfig.Faction.RED: bf_rect.position + Vector2(size - m, m),
		GameConfig.Faction.GREEN: bf_rect.position + Vector2(m, size - m),
		GameConfig.Faction.YELLOW: bf_rect.position + Vector2(size - m, size - m),
	}

static func _calculate_chamber_positions(bf_rect: Rect2, turret_positions: Dictionary, chamber_size: Vector2, chamber_gap: float) -> Dictionary:
	var blue_turret: Vector2 = turret_positions.get(GameConfig.Faction.BLUE, Vector2.ZERO)
	var red_turret: Vector2 = turret_positions.get(GameConfig.Faction.RED, Vector2.ZERO)
	var green_turret: Vector2 = turret_positions.get(GameConfig.Faction.GREEN, Vector2.ZERO)
	var _yellow_turret: Vector2 = turret_positions.get(GameConfig.Faction.YELLOW, Vector2.ZERO)

	var left_x: float = blue_turret.x - chamber_size.x - chamber_gap
	var bf_left: float = bf_rect.position.x
	if left_x + chamber_size.x > bf_left - chamber_gap:
		left_x = bf_left - chamber_gap - chamber_size.x
	if left_x < SIDE_MARGIN:
		left_x = SIDE_MARGIN

	var right_x: float = red_turret.x + chamber_gap
	var bf_right: float = bf_rect.position.x + bf_rect.size.x
	if right_x < bf_right + chamber_gap:
		right_x = bf_right + chamber_gap

	var top_y: float = blue_turret.y - CHAMBER_TOP_TURRET_GAP
	var bottom_y: float = green_turret.y - chamber_size.y - CHAMBER_BOTTOM_TURRET_GAP

	return {
		GameConfig.Faction.BLUE: Vector2(left_x, top_y),
		GameConfig.Faction.RED: Vector2(right_x, top_y),
		GameConfig.Faction.GREEN: Vector2(left_x, bottom_y),
		GameConfig.Faction.YELLOW: Vector2(right_x, bottom_y),
	}

static func _calculate_add_ball_positions(chamber_positions: Dictionary, chamber_size: Vector2, button_size: Vector2, button_gap: float, viewport_size: Vector2) -> Dictionary:
	var result: Dictionary = {}
	for faction_id in chamber_positions.keys():
		var chamber_pos: Vector2 = chamber_positions[faction_id]
		var y_pos: float = chamber_pos.y + chamber_size.y * 0.5 - button_size.y * 0.5
		var x_pos: float
		if faction_id == GameConfig.Faction.BLUE or faction_id == GameConfig.Faction.GREEN:
			x_pos = chamber_pos.x - button_size.x - button_gap
		else:
			x_pos = chamber_pos.x + chamber_size.x + button_gap
		x_pos = clampf(x_pos, SAFE_MARGIN, viewport_size.x - button_size.x - SAFE_MARGIN)
		y_pos = clampf(y_pos, 64.0, viewport_size.y - button_size.y - 12.0)
		result[faction_id] = Vector2(x_pos, y_pos)
	return result

static func _calculate_side_buttons(side_x: float, side_button_size: Vector2) -> Dictionary:
	return {
		"settings": Vector2(side_x, 84.0),
		"pause": Vector2(side_x, 84.0 + side_button_size.y + SIDE_GAP),
		"exit": Vector2(side_x, 84.0 + (side_button_size.y + SIDE_GAP) * 2.0),
	}

static func _calculate_hud_positions(
	viewport_size: Vector2,
	profile: Dictionary,
	is_mobile: bool,
	side_button_positions: Dictionary,
	side_button_size: Vector2
) -> Dictionary:
	var top_panel_w: float = float(profile.get("top_panel_w", 710.0))
	var top_panel_h: float = float(profile.get("top_panel_h", 90.0))
	if is_mobile:
		top_panel_w = minf(top_panel_w, 660.0)
		top_panel_h = 98.0

	var top_panel_rect := Rect2(Vector2((viewport_size.x - top_panel_w) * 0.5, 8.0), Vector2(top_panel_w, top_panel_h))
	var leader_label_rect := Rect2(top_panel_rect.position + Vector2(16.0, 4.0), Vector2(176.0, 24.0))
	var timer_label_rect := Rect2(top_panel_rect.position + Vector2((top_panel_rect.size.x - 110.0) * 0.5, 1.0), Vector2(110.0, 26.0))
	var stage_label_rect := Rect2(top_panel_rect.position + Vector2(top_panel_rect.size.x - 182.0, 4.0), Vector2(168.0, 24.0))
	var bar_bg_rect := Rect2(top_panel_rect.position + Vector2(18.0, 31.0), Vector2(top_panel_rect.size.x - 36.0, float(profile.get("bar_h", 36.0))))
	var bar_inner_rect := Rect2(bar_bg_rect.position + Vector2(3.0, 3.0), bar_bg_rect.size - Vector2(6.0, 6.0))
	var badge_rect := Rect2(top_panel_rect.position + Vector2(top_panel_rect.size.x * 0.5 - 118.0, 60.0), Vector2(28.0, 28.0))
	var title_rect := Rect2(top_panel_rect.position + Vector2(0.0, top_panel_rect.size.y - 26.0), Vector2(top_panel_rect.size.x, 28.0))
	var palette_rect := Rect2(top_panel_rect.position + Vector2(top_panel_rect.size.x - 166.0, 66.0), Vector2(152.0, 22.0))
	var winner_label_rect := Rect2(Vector2(0.0, float(profile.get("winner_y", 666.0))), Vector2(viewport_size.x, 34.0))

	var fps_bg_rect := Rect2(Vector2(viewport_size.x - FPS_BG_SIZE.x - SAFE_MARGIN, viewport_size.y - FPS_BG_SIZE.y - 38.0), FPS_BG_SIZE)
	var fps_label_rect := Rect2(Vector2(fps_bg_rect.position.x + 6.0, fps_bg_rect.position.y - 3.0), FPS_LABEL_SIZE)

	var event_label_size: Vector2 = Vector2(260.0, 22.0) if is_mobile else EVENT_LABEL_SIZE
	var event_label_pos := Vector2(
		fps_label_rect.position.x + fps_label_rect.size.x - event_label_size.x,
		fps_label_rect.position.y - event_label_size.y - 4.0
	)
	if is_mobile:
		event_label_pos = Vector2(viewport_size.x - event_label_size.x - 12.0, viewport_size.y - 84.0)
	var event_label_rect := Rect2(event_label_pos, event_label_size)

	var bottom_hud_rect := Rect2(
		Vector2(minf(fps_bg_rect.position.x, event_label_rect.position.x), minf(event_label_rect.position.y, fps_bg_rect.position.y)),
		Vector2(
			maxf(fps_bg_rect.position.x + fps_bg_rect.size.x, event_label_rect.position.x + event_label_rect.size.x) - minf(fps_bg_rect.position.x, event_label_rect.position.x),
			maxf(fps_bg_rect.position.y + fps_bg_rect.size.y, event_label_rect.position.y + event_label_rect.size.y) - minf(event_label_rect.position.y, fps_bg_rect.position.y)
		)
	)

	var settings_panel_size: Vector2 = Vector2(278.0, 92.0) if is_mobile else Vector2(286.0, 96.0)
	var exit_button_pos: Vector2 = side_button_positions.get("exit", Vector2.ZERO)
	var settings_panel_x: float = clampf(
		exit_button_pos.x - settings_panel_size.x + side_button_size.x,
		SAFE_MARGIN,
		viewport_size.x - settings_panel_size.x - SAFE_MARGIN
	)
	var settings_panel_rect := Rect2(
		Vector2(settings_panel_x, exit_button_pos.y + side_button_size.y + 10.0),
		settings_panel_size
	)

	return {
		"top_panel_rect": top_panel_rect,
		"leader_label_rect": leader_label_rect,
		"timer_label_rect": timer_label_rect,
		"stage_label_rect": stage_label_rect,
		"bar_bg_rect": bar_bg_rect,
		"bar_inner_rect": bar_inner_rect,
		"badge_rect": badge_rect,
		"title_rect": title_rect,
		"palette_rect": palette_rect,
		"winner_label_rect": winner_label_rect,
		"fps_bg_rect": fps_bg_rect,
		"fps_label_rect": fps_label_rect,
		"event_label_rect": event_label_rect,
		"bottom_hud_rect": bottom_hud_rect,
		"settings_panel_rect": settings_panel_rect,
	}

static func _calculate_roulette(grid_size: int, viewport_size: Vector2, is_mobile: bool, battlefield_rect: Rect2) -> Rect2:
	var compact: bool = grid_size >= 40
	var stage_size: Vector2 = Vector2(500.0, 182.0)
	if compact:
		stage_size = Vector2(448.0, 168.0)
	elif grid_size <= 20:
		stage_size = Vector2(540.0, 194.0)

	if is_mobile:
		stage_size = Vector2(minf(stage_size.x, 430.0), stage_size.y + 10.0)

	var stage_y: float = battlefield_rect.position.y - stage_size.y - 10.0
	stage_y = clampf(stage_y, 92.0, 126.0)
	return Rect2(Vector2((viewport_size.x - stage_size.x) * 0.5, stage_y), stage_size)

static func _calculate_start_menu_layout(viewport_size: Vector2, is_mobile: bool) -> Dictionary:
	var root_panel_size: Vector2 = Vector2(792.0, 660.0) if is_mobile else Vector2(840.0, 684.0)
	root_panel_size.x = minf(root_panel_size.x, viewport_size.x - 48.0)
	root_panel_size.y = minf(root_panel_size.y, viewport_size.y - 36.0)
	var vertical_offset: float = 6.0 if is_mobile else 8.0
	var root_panel_pos := Vector2(
		(viewport_size.x - root_panel_size.x) * 0.5,
		clampf((viewport_size.y - root_panel_size.y) * 0.5 + vertical_offset, 12.0, viewport_size.y - root_panel_size.y - 12.0)
	)
	var preview_size := Vector2(root_panel_size.x - 36.0, 192.0 if is_mobile else 224.0)
	var preview_center := Vector2(preview_size.x * 0.5, 90.0 if is_mobile else 102.0)

	var config_panel_rect := Rect2(Vector2(48.0, 364.0 if not is_mobile else 358.0), Vector2(root_panel_size.x - 96.0, 126.0))
	var save_panel_rect := Rect2(Vector2(48.0, 494.0 if not is_mobile else 488.0), Vector2(root_panel_size.x - 96.0, 136.0))
	var save_slot_container_rect := Rect2(Vector2(0.0, 32.0), Vector2(save_panel_rect.size.x, 40.0))
	var slot_button_size := Vector2(136.0, 36.0)
	var slot_gap: float = 8.0 if is_mobile else 8.0
	var slot_start_x: float = 14.0
	var slot_positions: Dictionary = {}
	for slot in range(1, 6):
		slot_positions[slot] = Vector2(slot_start_x + float(slot - 1) * (slot_button_size.x + slot_gap), 10.0)

	var continue_button_rect := Rect2(
		Vector2(root_panel_size.x - 192.0, 590.0 if not is_mobile else 582.0),
		Vector2(120.0, 36.0)
	)

	return {
		"shade_rect": Rect2(Vector2.ZERO, viewport_size),
		"root_panel_rect": Rect2(root_panel_pos, root_panel_size),
		"title_rect": Rect2(Vector2(150.0, 16.0), Vector2(root_panel_size.x - 300.0, 56.0)),
		"subtitle_rect": Rect2(Vector2(180.0, 72.0), Vector2(root_panel_size.x - 360.0, 24.0)),
		"mobile_hint_rect": Rect2(Vector2(180.0, 98.0), Vector2(root_panel_size.x - 360.0, 23.0)),
		"preview_position": Vector2(root_panel_size.x * 0.5, 250.0 if not is_mobile else 240.0),
		"preview_size": preview_size,
		"preview_center": preview_center,
		"preview_scale": Vector2(0.40, 0.40) if not is_mobile else Vector2(0.36, 0.36),
		"config_panel_rect": config_panel_rect,
		"save_panel_rect": save_panel_rect,
		"continue_button_rect": continue_button_rect,
		"status_rect": Rect2(Vector2(120.0, 626.0 if not is_mobile else 616.0), Vector2(root_panel_size.x - 240.0, 22.0)),
		"save_slot_container_rect": save_slot_container_rect,
		"save_slot_button_positions": slot_positions,
		"save_slot_button_size": slot_button_size,
	}
