extends RefCounted
class_name RuntimeHudController

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")

static var performance_visible: bool = true

static func set_performance_visible(value: bool) -> void:
	performance_visible = value

static func format_time_text(seconds: float) -> String:
	var total_seconds: int = maxi(0, int(floor(seconds)))
	var mm: int = floori(float(total_seconds) / 60.0)
	var ss: int = total_seconds % 60
	return "%02d:%02d" % [mm, ss]

static func current_stage_name(game_elapsed_time: float) -> String:
	var mode_name: String = GameConfig.get_game_mode_name()
	if mode_name == GameConfig.GAME_MODE_OCCUPATION:
		return "占领目标 %d%%" % GameConfig.get_occupation_target_percent()
	if mode_name == GameConfig.GAME_MODE_TIMED:
		var remain: float = maxf(0.0, GameConfig.get_time_limit_seconds() - game_elapsed_time)
		return "限时 %s" % format_time_text(remain)
	if mode_name == GameConfig.GAME_MODE_WILD:
		return "狂野 x3 / 上限 %d" % GameConfig.get_max_pending_count()
	if mode_name == GameConfig.GAME_MODE_CARDFRONT:
		var remain: float = maxf(0.0, CardfrontRulesScript.MATCH_DURATION_SECONDS - game_elapsed_time)
		return "卡牌前线 %s" % format_time_text(remain)

	if game_elapsed_time < 120.0:
		return "前期扩张"
	if game_elapsed_time < 300.0:
		return "中期翻倍加速"
	return "终局狂暴"

static func get_active_bullet_count(bullet_container) -> int:
	if bullet_container == null or not is_instance_valid(bullet_container):
		return 0
	if bullet_container.has_method("get_active_count"):
		return int(bullet_container.get_active_count())
	return bullet_container.get_child_count()

static func get_burst_queue_count(turrets: Dictionary) -> int:
	var total: int = 0
	for turret in turrets.values():
		if turret != null and is_instance_valid(turret):
			total += int(turret.get("burst_remaining"))
	return total

static func get_pressure_label(active_count: int, burst_queue: int) -> String:
	var fps: int = floori(Engine.get_frames_per_second())
	if active_count >= GameConfig.get_force_simple_threshold():
		return "极高"
	if active_count >= GameConfig.get_high_pressure_threshold():
		return "高"
	if active_count >= GameConfig.get_mid_pressure_threshold():
		return "中"
	if burst_queue >= 1024:
		return "队列高"
	if burst_queue >= 256:
		return "队列中"
	if fps > 0 and fps < 24:
		return "帧低"
	return "低"

static func get_perf_debug_text(bullet_container, battlefield, selected_grid_size: int, turrets: Dictionary = {}) -> String:
	if not performance_visible:
		return ""
	var active_count: int = get_active_bullet_count(bullet_container)
	var max_active: int = GameConfig.get_max_active_bullets()
	var burst_queue: int = get_burst_queue_count(turrets)
	var grid_value: int = battlefield.grid_size if battlefield != null and is_instance_valid(battlefield) else selected_grid_size
	var redraw_text: String = "--/s"
	var spawn_per_second: int = 0
	var capture_per_second: int = 0
	var trail_segments: int = 0
	var draw_calls: int = -1
	var visible_canvas_items_estimate: int = -1
	var trail_pressure_level: String = "none"
	var trail_degrade_reason: String = "none"

	if battlefield != null and is_instance_valid(battlefield):
		if battlefield.has_method("get_debug_metrics"):
			var battlefield_metrics: Dictionary = battlefield.get_debug_metrics()
			capture_per_second = int(battlefield_metrics.get("cell_changes_per_second", 0))
			redraw_text = "%d/s" % int(battlefield_metrics.get("redraw_calls_per_second", 0))

	if bullet_container != null and is_instance_valid(bullet_container) and bullet_container.has_method("get_debug_metrics"):
		var bullet_metrics: Dictionary = bullet_container.get_debug_metrics()
		spawn_per_second = int(bullet_metrics.get("spawned_bullets_per_second", 0))
		trail_segments = int(bullet_metrics.get("trail_segments_estimate", 0))
		draw_calls = int(bullet_metrics.get("draw_calls", -1))
		visible_canvas_items_estimate = int(bullet_metrics.get("visible_canvas_items_estimate", -1))
		trail_pressure_level = str(bullet_metrics.get("trail_pressure_level", "none"))
		trail_degrade_reason = str(bullet_metrics.get("trail_degrade_reason", "none"))

	return "FPS %d | 子弹 %d/%d | 队列 %d | 生成 %d/s | 占领 %d/s | 轨迹 %d | 绘制 %d | 画布 %d | 地图 %dx%d | 战场 %s | 压力 %s/%s" % [
		floori(Engine.get_frames_per_second()),
		active_count,
		max_active,
		burst_queue,
		spawn_per_second,
		capture_per_second,
		trail_segments,
		draw_calls,
		visible_canvas_items_estimate,
		grid_value,
		grid_value,
		redraw_text,
		trail_pressure_level,
		trail_degrade_reason,
	]

static func update_meta(timer_label, stage_label, leader_label, current_score_counts: Dictionary, game_elapsed_time: float) -> void:
	if timer_label != null and is_instance_valid(timer_label):
		timer_label.text = format_time_text(game_elapsed_time)
	if stage_label != null and is_instance_valid(stage_label):
		stage_label.text = current_stage_name(game_elapsed_time)
	if leader_label != null and is_instance_valid(leader_label):
		var tracked_owner_ids: Array = _score_owner_ids()
		var total: int = 0
		var best_count: int = -1
		for owner_id in tracked_owner_ids:
			var c: int = int(current_score_counts.get(owner_id, 0))
			total += c
			if owner_id != CardfrontRulesScript.NEUTRAL_OWNER:
				best_count = maxi(best_count, c)

		var leaders: Array = []
		for owner_id in tracked_owner_ids:
			if owner_id != CardfrontRulesScript.NEUTRAL_OWNER and int(current_score_counts.get(owner_id, 0)) == best_count:
				leaders.append(owner_id)

		var percent: int = 0
		if total > 0:
			percent = int(round(float(best_count) * 100.0 / float(total)))

		if leaders.size() == 1:
			var leader_id: int = int(leaders[0])
			leader_label.text = "领先：%s %d%%" % [_owner_display_name(leader_id), percent]
			leader_label.add_theme_color_override("font_color", _owner_display_color(leader_id).lightened(0.42))
		else:
			leader_label.text = "并列：%d%%" % percent
			leader_label.add_theme_color_override("font_color", Color(0.92, 0.88, 0.72))

static func update_top_bar(counts: Dictionary, top_bar_segments: Dictionary, top_bar_labels: Dictionary, top_bar_name_labels: Dictionary, top_bar_total_width: float, is_mobile_layout: bool) -> void:
	if top_bar_segments.size() == 0:
		return

	var segment_owner_map: Dictionary = _segment_owner_map()
	var visible_segments: Array = []
	for segment_id in [GameConfig.Faction.BLUE, GameConfig.Faction.RED, GameConfig.Faction.GREEN, GameConfig.Faction.YELLOW]:
		if segment_owner_map.get(segment_id, null) != null:
			visible_segments.append(segment_id)

	var total: int = 0
	for owner_id in _score_owner_ids():
		total += int(counts.get(owner_id, 0))
	if total <= 0:
		total = 1

	var running_x: float = 3.0
	for faction_id in [GameConfig.Faction.BLUE, GameConfig.Faction.RED, GameConfig.Faction.GREEN, GameConfig.Faction.YELLOW]:
		var segment: Panel = top_bar_segments[faction_id] as Panel
		var owner_id = segment_owner_map.get(faction_id, null)
		if owner_id == null:
			segment.visible = false
			if top_bar_labels.has(faction_id):
				(top_bar_labels[faction_id] as Label).visible = false
			if top_bar_name_labels.has(faction_id):
				(top_bar_name_labels[faction_id] as Label).visible = false
			continue

		segment.visible = true
		var ratio: float = float(counts.get(owner_id, 0)) / float(total)
		var p: int = int(round(ratio * 100.0))
		var seg_w: float = top_bar_total_width * ratio
		if faction_id == visible_segments.back():
			seg_w = maxf(50.0, top_bar_total_width + 3.0 - running_x)
		segment.position.x = running_x
		segment.size.x = maxf(50.0, seg_w)

		var fill: ColorRect = segment.get_node("Fill") as ColorRect
		fill.size = Vector2(maxf(4.0, segment.size.x - 4.0), segment.size.y - 4.0)
		fill.color = _owner_display_color(owner_id)
		var gloss: ColorRect = segment.get_node("Gloss") as ColorRect
		gloss.size = Vector2(maxf(4.0, segment.size.x - 4.0), maxf(5.0, (segment.size.y - 4.0) * 0.42))
		var bottom_shadow: ColorRect = segment.get_node("BottomShadow") as ColorRect
		bottom_shadow.position = Vector2(2.0, maxf(4.0, segment.size.y - 8.0))
		bottom_shadow.size = Vector2(maxf(4.0, segment.size.x - 4.0), 4.0)
		if segment.has_node("Separator"):
			var sep: ColorRect = segment.get_node("Separator") as ColorRect
			sep.position = Vector2(segment.size.x - 2.0, 0.0)
			sep.size = Vector2(2.0, segment.size.y)

		var value_label: Label = top_bar_labels[faction_id] as Label
		var name_label: Label = top_bar_name_labels[faction_id] as Label
		value_label.visible = true
		name_label.visible = true
		value_label.text = "%d%%" % p
		name_label.text = _owner_display_name(owner_id)
		name_label.add_theme_color_override("font_color", _owner_display_color(owner_id).lightened(0.45))
		name_label.visible = true

		if segment.size.x < 110.0:
			name_label.position = Vector2(0, 1)
			name_label.size = Vector2(segment.size.x, 12)
			name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER as HorizontalAlignment
			name_label.add_theme_font_size_override("font_size", 9 if is_mobile_layout else 11)

			value_label.position = Vector2(0, 10)
			value_label.size = Vector2(segment.size.x, 20)
			value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER as HorizontalAlignment
			value_label.add_theme_font_size_override("font_size", 15 if is_mobile_layout else 18)
		else:
			name_label.position = Vector2(6, 2)
			name_label.size = Vector2(segment.size.x - 12.0, 14)
			name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT as HorizontalAlignment
			name_label.add_theme_font_size_override("font_size", 10 if is_mobile_layout else 12)

			value_label.position = Vector2(0, -1)
			value_label.size = Vector2(segment.size.x, segment.size.y)
			value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER as HorizontalAlignment
			value_label.add_theme_font_size_override("font_size", 18 if is_mobile_layout else 22)

		running_x += segment.size.x

static func _score_owner_ids() -> Array:
	if GameConfig.get_game_mode_name() == GameConfig.GAME_MODE_CARDFRONT:
		return CardfrontRulesScript.get_score_owner_ids()
	return [GameConfig.Faction.BLUE, GameConfig.Faction.RED, GameConfig.Faction.GREEN, GameConfig.Faction.YELLOW]

static func _segment_owner_map() -> Dictionary:
	if GameConfig.get_game_mode_name() == GameConfig.GAME_MODE_CARDFRONT:
		return {
			GameConfig.Faction.BLUE: CardfrontRulesScript.PLAYER_FACTION,
			GameConfig.Faction.RED: CardfrontRulesScript.AI_FACTION,
			GameConfig.Faction.GREEN: CardfrontRulesScript.NEUTRAL_OWNER,
			GameConfig.Faction.YELLOW: null,
		}
	return {
		GameConfig.Faction.BLUE: GameConfig.Faction.BLUE,
		GameConfig.Faction.RED: GameConfig.Faction.RED,
		GameConfig.Faction.GREEN: GameConfig.Faction.GREEN,
		GameConfig.Faction.YELLOW: GameConfig.Faction.YELLOW,
	}

static func _owner_display_name(owner_id: int) -> String:
	if GameConfig.get_game_mode_name() == GameConfig.GAME_MODE_CARDFRONT:
		return CardfrontRulesScript.owner_display_name(owner_id)
	return GameConfig.faction_name(owner_id)

static func _owner_display_color(owner_id: int) -> Color:
	if GameConfig.get_game_mode_name() == GameConfig.GAME_MODE_CARDFRONT:
		return CardfrontRulesScript.owner_color(owner_id)
	return GameConfig.faction_color(owner_id)
