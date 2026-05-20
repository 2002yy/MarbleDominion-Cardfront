extends RefCounted
class_name GameHudView

static func create_dynamic_ui(_owner, ui_canvas: CanvasLayer, current_layout: Dictionary, view_size: Vector2, mobile_mode: bool) -> Dictionary:
	ui_canvas.name = "UICanvas"
	ui_canvas.process_mode = Node.PROCESS_MODE_ALWAYS

	var top_panel_w: float = current_layout.get("top_panel_w", 810.0)
	var top_panel_h: float = current_layout.get("top_panel_h", 90.0)
	if mobile_mode:
		top_panel_w = minf(top_panel_w, 660.0)
		top_panel_h = 98.0

	var top_panel := UIFactory.make_panel_shell(Vector2((view_size.x - top_panel_w) * 0.5, 8.0), Vector2(top_panel_w, top_panel_h), Color(0.93, 0.96, 1.0, 0.98))
	ui_canvas.add_child(top_panel)
	top_panel.add_child(UIFactory.make_fill_rect(Vector2(4.0, 4.0), top_panel.size - Vector2(8.0, 8.0), Color(0.06, 0.09, 0.15, 0.98)))
	top_panel.add_child(UIFactory.make_fill_rect(Vector2(12.0, 4.0), Vector2(top_panel.size.x - 24.0, 2.0), Color(0.98, 0.76, 0.18, 0.55)))
	top_panel.add_child(UIFactory.make_fill_rect(Vector2(10.0, 6.0), Vector2(top_panel.size.x - 20.0, 22.0), Color(0.03, 0.05, 0.09, 0.96)))

	var leader_label := UIFactory.make_outline_label(Vector2(16.0, 4.0), Vector2(176.0, 24.0), "", 14 if mobile_mode else 15, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 2)
	top_panel.add_child(leader_label)

	var timer_label := UIFactory.make_outline_label(Vector2((top_panel.size.x - 110.0) * 0.5, 1.0), Vector2(110.0, 26.0), "00:00", 18 if mobile_mode else 20, Color(1.0, 0.96, 0.72), HORIZONTAL_ALIGNMENT_CENTER, 3)
	top_panel.add_child(timer_label)

	var stage_label := UIFactory.make_outline_label(Vector2(top_panel.size.x - 182.0, 4.0), Vector2(168.0, 24.0), "", 13 if mobile_mode else 15, Color(0.82, 0.92, 1.0), HORIZONTAL_ALIGNMENT_RIGHT, 2)
	top_panel.add_child(stage_label)

	var bar_h: float = current_layout.get("bar_h", 36.0)
	var bar_bg := UIFactory.make_panel_shell(Vector2(18.0, 31.0), Vector2(top_panel.size.x - 36.0, bar_h), Color(0.90, 0.94, 1.0, 0.95))
	top_panel.add_child(bar_bg)

	var bar_inner := UIFactory.make_fill_rect(Vector2(3.0, 3.0), Vector2(bar_bg.size.x - 6.0, bar_bg.size.y - 6.0), Color(0.03, 0.05, 0.09, 0.84))
	bar_bg.add_child(bar_inner)
	var top_bar_total_width: float = bar_inner.size.x

	var top_bar_segments: Dictionary = {}
	var top_bar_labels: Dictionary = {}
	var top_bar_name_labels: Dictionary = {}
	var x_offset: float = 3.0
	for faction_id in [GameConfig.Faction.BLUE, GameConfig.Faction.RED, GameConfig.Faction.GREEN, GameConfig.Faction.YELLOW]:
		var segment := UIFactory.make_panel_shell(Vector2(x_offset, 3.0), Vector2(top_bar_total_width * 0.25, bar_inner.size.y), Color(0.90, 0.94, 1.0, 0.90))
		bar_bg.add_child(segment)
		top_bar_segments[faction_id] = segment

		var fill := UIFactory.make_fill_rect(Vector2(2.0, 2.0), Vector2(segment.size.x - 4.0, segment.size.y - 4.0), GameConfig.faction_color(faction_id))
		fill.name = "Fill"
		segment.add_child(fill)

		var gloss := UIFactory.make_fill_rect(Vector2(2.0, 2.0), Vector2(segment.size.x - 4.0, maxf(5.0, (segment.size.y - 4.0) * 0.42)), Color(1.0, 1.0, 1.0, 0.14))
		gloss.name = "Gloss"
		segment.add_child(gloss)

		var bottom_shadow := UIFactory.make_fill_rect(Vector2(2.0, maxf(4.0, segment.size.y - 8.0)), Vector2(segment.size.x - 4.0, 4.0), Color(0.0, 0.0, 0.0, 0.16))
		bottom_shadow.name = "BottomShadow"
		segment.add_child(bottom_shadow)

		var name_label := UIFactory.make_outline_label(Vector2(6.0, 2.0), Vector2(74.0, 14.0), "", 10 if mobile_mode else 12, GameConfig.faction_color(faction_id).lightened(0.56), HORIZONTAL_ALIGNMENT_LEFT, 2)
		segment.add_child(name_label)
		top_bar_name_labels[faction_id] = name_label

		var value_label := UIFactory.make_outline_label(Vector2(0.0, -1.0), Vector2(segment.size.x, segment.size.y), "0%", 18 if mobile_mode else 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 3)
		value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER as VerticalAlignment
		segment.add_child(value_label)
		top_bar_labels[faction_id] = value_label

		if faction_id != GameConfig.Faction.YELLOW:
			var separator := UIFactory.make_fill_rect(Vector2(segment.size.x - 2.0, 0.0), Vector2(2.0, segment.size.y), Color(1.0, 1.0, 1.0, 0.16))
			separator.name = "Separator"
			segment.add_child(separator)

		x_offset += segment.size.x

	var badge = load("res://scripts/HudBadge.gd").new()
	badge.position = Vector2(top_panel.size.x * 0.5 - 118.0, 60.0)
	badge.size = Vector2(28.0, 28.0)
	top_panel.add_child(badge)

	var game_title_label := UIFactory.make_outline_label(Vector2(0.0, 64.0), Vector2(top_panel.size.x, 28.0), "领土战争", 24 if mobile_mode else int(current_layout.get("title_font", 31)), Color(1.0, 0.95, 0.72), HORIZONTAL_ALIGNMENT_CENTER, 5)
	top_panel.add_child(game_title_label)

	if not mobile_mode:
		var palette_label := UIFactory.make_outline_label(
			Vector2(top_panel.size.x - 166.0, 66.0),
			Vector2(152.0, 22.0),
			"配色：%s" % GameConfig.get_palette_name(),
			int(current_layout.get("palette_font", 16)),
			Color(0.88, 0.92, 1.0),
			HORIZONTAL_ALIGNMENT_RIGHT,
			1
		)
		top_panel.add_child(palette_label)

	var fps_bg := UIFactory.make_fill_rect(current_layout.get("fps_bg_pos", Vector2(396.0, 652.0)), current_layout.get("fps_bg_size", Vector2(714.0, 30.0)), Color(0.0, 0.0, 0.0, 0.42 if not mobile_mode else 0.20))
	fps_bg.process_mode = Node.PROCESS_MODE_ALWAYS
	fps_bg.visible = not mobile_mode
	ui_canvas.add_child(fps_bg)

	return {
		"ui_canvas": ui_canvas,
		"top_bar_segments": top_bar_segments,
		"top_bar_labels": top_bar_labels,
		"top_bar_name_labels": top_bar_name_labels,
		"top_bar_total_width": top_bar_total_width,
		"game_title_label": game_title_label,
		"leader_label": leader_label,
		"timer_label": timer_label,
		"stage_label": stage_label,
	}

static func create_runtime_ui(owner, game_layer: Node, _battlefield, current_layout: Dictionary, view_size: Vector2, mobile_mode: bool) -> Dictionary:
	var ui_canvas := CanvasLayer.new()
	ui_canvas.name = "UICanvas"
	ui_canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	game_layer.add_child(ui_canvas)

	var top_panel_w: float = current_layout.get("top_panel_w", 810.0)
	var top_panel_h: float = current_layout.get("top_panel_h", 90.0)
	if mobile_mode:
		top_panel_w = minf(top_panel_w, 660.0)
		top_panel_h = 98.0

	var top_panel := UIFactory.make_panel_shell(Vector2((view_size.x - top_panel_w) * 0.5, 8.0), Vector2(top_panel_w, top_panel_h), Color(0.93, 0.96, 1.0, 0.98))
	ui_canvas.add_child(top_panel)
	top_panel.add_child(UIFactory.make_fill_rect(Vector2(4.0, 4.0), top_panel.size - Vector2(8.0, 8.0), Color(0.06, 0.09, 0.15, 0.98)))
	top_panel.add_child(UIFactory.make_fill_rect(Vector2(12.0, 4.0), Vector2(top_panel.size.x - 24.0, 2.0), Color(0.98, 0.76, 0.18, 0.55)))
	top_panel.add_child(UIFactory.make_fill_rect(Vector2(10.0, 6.0), Vector2(top_panel.size.x - 20.0, 22.0), Color(0.03, 0.05, 0.09, 0.96)))

	var leader_label := UIFactory.make_outline_label(Vector2(16.0, 4.0), Vector2(176.0, 24.0), "", 14 if mobile_mode else 15, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 2)
	top_panel.add_child(leader_label)

	var timer_label := UIFactory.make_outline_label(Vector2((top_panel.size.x - 110.0) * 0.5, 1.0), Vector2(110.0, 26.0), "00:00", 18 if mobile_mode else 20, Color(1.0, 0.96, 0.72), HORIZONTAL_ALIGNMENT_CENTER, 3)
	top_panel.add_child(timer_label)

	var stage_label := UIFactory.make_outline_label(Vector2(top_panel.size.x - 182.0, 4.0), Vector2(168.0, 24.0), "", 13 if mobile_mode else 15, Color(0.82, 0.92, 1.0), HORIZONTAL_ALIGNMENT_RIGHT, 2)
	top_panel.add_child(stage_label)

	var bar_h: float = current_layout.get("bar_h", 36.0)
	var bar_bg := UIFactory.make_panel_shell(Vector2(18.0, 31.0), Vector2(top_panel.size.x - 36.0, bar_h), Color(0.90, 0.94, 1.0, 0.95))
	top_panel.add_child(bar_bg)

	var bar_inner := UIFactory.make_fill_rect(Vector2(3.0, 3.0), Vector2(bar_bg.size.x - 6.0, bar_bg.size.y - 6.0), Color(0.03, 0.05, 0.09, 0.84))
	bar_bg.add_child(bar_inner)
	var top_bar_total_width: float = bar_inner.size.x

	var top_bar_segments: Dictionary = {}
	var top_bar_labels: Dictionary = {}
	var top_bar_name_labels: Dictionary = {}
	var x_offset: float = 3.0
	for faction_id in [GameConfig.Faction.BLUE, GameConfig.Faction.RED, GameConfig.Faction.GREEN, GameConfig.Faction.YELLOW]:
		var segment := UIFactory.make_panel_shell(Vector2(x_offset, 3.0), Vector2(top_bar_total_width * 0.25, bar_inner.size.y), Color(0.90, 0.94, 1.0, 0.90))
		bar_bg.add_child(segment)
		top_bar_segments[faction_id] = segment

		var fill := UIFactory.make_fill_rect(Vector2(2.0, 2.0), Vector2(segment.size.x - 4.0, segment.size.y - 4.0), GameConfig.faction_color(faction_id))
		fill.name = "Fill"
		segment.add_child(fill)

		var gloss := UIFactory.make_fill_rect(Vector2(2.0, 2.0), Vector2(segment.size.x - 4.0, maxf(5.0, (segment.size.y - 4.0) * 0.42)), Color(1.0, 1.0, 1.0, 0.14))
		gloss.name = "Gloss"
		segment.add_child(gloss)

		var bottom_shadow := UIFactory.make_fill_rect(Vector2(2.0, maxf(4.0, segment.size.y - 8.0)), Vector2(segment.size.x - 4.0, 4.0), Color(0.0, 0.0, 0.0, 0.16))
		bottom_shadow.name = "BottomShadow"
		segment.add_child(bottom_shadow)

		var name_label := UIFactory.make_outline_label(Vector2(6.0, 2.0), Vector2(74.0, 14.0), "", 10 if mobile_mode else 12, GameConfig.faction_color(faction_id).lightened(0.56), HORIZONTAL_ALIGNMENT_LEFT, 2)
		segment.add_child(name_label)
		top_bar_name_labels[faction_id] = name_label

		var value_label := UIFactory.make_outline_label(Vector2(0.0, -1.0), Vector2(segment.size.x, segment.size.y), "0%", 18 if mobile_mode else 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 3)
		value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER as VerticalAlignment
		segment.add_child(value_label)
		top_bar_labels[faction_id] = value_label

		if faction_id != GameConfig.Faction.YELLOW:
			var separator := UIFactory.make_fill_rect(Vector2(segment.size.x - 2.0, 0.0), Vector2(2.0, segment.size.y), Color(1.0, 1.0, 1.0, 0.16))
			separator.name = "Separator"
			segment.add_child(separator)

		x_offset += segment.size.x

	var badge = load("res://scripts/HudBadge.gd").new()
	badge.position = Vector2(top_panel.size.x * 0.5 - 118.0, 60.0)
	badge.size = Vector2(28.0, 28.0)
	top_panel.add_child(badge)

	var game_title_label := UIFactory.make_outline_label(Vector2(0.0, 64.0), Vector2(top_panel.size.x, 28.0), "领土战争", 24 if mobile_mode else int(current_layout.get("title_font", 31)), Color(1.0, 0.95, 0.72), HORIZONTAL_ALIGNMENT_CENTER, 5)
	top_panel.add_child(game_title_label)

	if not mobile_mode:
		var palette_label := UIFactory.make_outline_label(
			Vector2(top_panel.size.x - 166.0, 66.0),
			Vector2(152.0, 22.0),
			"配色：%s" % GameConfig.get_palette_name(),
			int(current_layout.get("palette_font", 16)),
			Color(0.88, 0.92, 1.0),
			HORIZONTAL_ALIGNMENT_RIGHT,
			1
		)
		top_panel.add_child(palette_label)

	var side_button_size: Vector2 = Vector2(114.0, 46.0) if mobile_mode else Vector2(96.0, 42.0)
	var side_margin: float = 18.0 if not mobile_mode else 12.0
	var side_x: float = view_size.x - side_button_size.x - side_margin
	var side_gap: float = 8.0

	var settings_button := UIFactory.make_action_button(Vector2(side_x, 84.0), side_button_size, "设置", Color(0.34, 0.34, 0.54))
	settings_button.pressed.connect(Callable(owner, "_toggle_settings_panel"))
	ui_canvas.add_child(settings_button)

	var pause_button := UIFactory.make_action_button(Vector2(side_x, settings_button.position.y + side_button_size.y + side_gap), side_button_size, "暂停", Color(0.24, 0.52, 0.92))
	pause_button.pressed.connect(Callable(owner, "_toggle_pause"))
	ui_canvas.add_child(pause_button)

	var exit_button := UIFactory.make_action_button(Vector2(side_x, pause_button.position.y + side_button_size.y + side_gap), side_button_size, "退出", Color(0.62, 0.24, 0.22))
	exit_button.pressed.connect(Callable(owner, "_save_and_exit_to_menu"))
	ui_canvas.add_child(exit_button)

	var settings_panel_size: Vector2 = Vector2(286.0, 96.0) if not mobile_mode else Vector2(278.0, 92.0)
	var settings_panel_x: float = clampf(side_x - settings_panel_size.x + side_button_size.x, 10.0, view_size.x - settings_panel_size.x - 10.0)
	var settings_panel := UIFactory.make_panel_shell(Vector2(settings_panel_x, exit_button.position.y + side_button_size.y + 10.0), settings_panel_size, Color(0.94, 0.97, 1.0, 0.96))
	settings_panel.visible = false
	settings_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	ui_canvas.add_child(settings_panel)
	settings_panel.add_child(UIFactory.make_fill_rect(Vector2(4.0, 4.0), settings_panel.size - Vector2(8.0, 8.0), Color(0.06, 0.09, 0.15, 0.96)))

	var settings_label := Label.new()
	settings_label.position = Vector2(12.0, 10.0)
	settings_label.size = settings_panel.size - Vector2(24.0, 20.0)
	settings_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART as TextServer.AutowrapMode
	settings_label.text = "画质：%s\n布局：%s\n说明：手机使用大按钮布局，电脑保留更多 HUD 信息。" % [
		GameConfig.get_quality_name(),
		"手机横屏" if mobile_mode else "电脑",
	]
	settings_label.add_theme_font_size_override("font_size", 14 if mobile_mode else 15)
	settings_label.add_theme_color_override("font_color", Color(0.88, 0.92, 1.0))
	settings_panel.add_child(settings_label)

	var pause_overlay: Control = _create_pause_overlay(owner, view_size)
	ui_canvas.add_child(pause_overlay)

	var winner_label := UIFactory.make_outline_label(Vector2(0.0, current_layout.get("winner_y", 648.0)), Vector2(view_size.x, 34.0), "", 28, Color(1.0, 0.94, 0.22), HORIZONTAL_ALIGNMENT_CENTER, 5)
	ui_canvas.add_child(winner_label)

	var fps_bg := UIFactory.make_fill_rect(current_layout.get("fps_bg_pos", Vector2(396.0, 652.0)), current_layout.get("fps_bg_size", Vector2(714.0, 30.0)), Color(0.0, 0.0, 0.0, 0.42 if not mobile_mode else 0.20))
	fps_bg.process_mode = Node.PROCESS_MODE_ALWAYS
	fps_bg.visible = not mobile_mode
	ui_canvas.add_child(fps_bg)

	var fps_label := UIFactory.make_outline_label(
		current_layout.get("fps_label_pos", Vector2(402.0, 649.0)),
		current_layout.get("fps_label_size", Vector2(702.0, 24.0)),
		"FPS -- | 子弹 -- | 队列 -- | 画质 -- | 地图 -- | 战场 -- | 压力 --",
		13,
		Color(0.72, 1.0, 0.72),
		HORIZONTAL_ALIGNMENT_RIGHT,
		3
	)
	fps_label.process_mode = Node.PROCESS_MODE_ALWAYS
	fps_label.visible = not mobile_mode
	ui_canvas.add_child(fps_label)

	var event_label_size: Vector2 = Vector2(332.0, 24.0) if not mobile_mode else Vector2(260.0, 22.0)
	var event_label_pos: Vector2 = Vector2(
		fps_label.position.x + fps_label.size.x - event_label_size.x,
		fps_label.position.y - event_label_size.y - 4.0
	)
	if mobile_mode:
		event_label_pos = Vector2(view_size.x - event_label_size.x - 12.0, view_size.y - 84.0)

	var event_label := UIFactory.make_outline_label(
		event_label_pos,
		event_label_size,
		"事件：无 | 下次 00:00",
		13 if mobile_mode else 14,
		Color(1.0, 0.94, 0.68),
		HORIZONTAL_ALIGNMENT_RIGHT,
		3
	)
	event_label.process_mode = Node.PROCESS_MODE_ALWAYS
	ui_canvas.add_child(event_label)

	return {
		"ui_canvas": ui_canvas,
		"top_bar_segments": top_bar_segments,
		"top_bar_labels": top_bar_labels,
		"top_bar_name_labels": top_bar_name_labels,
		"top_bar_total_width": top_bar_total_width,
		"winner_label": winner_label,
		"game_title_label": game_title_label,
		"pause_overlay": pause_overlay,
		"pause_button": pause_button,
		"exit_button": exit_button,
		"fps_label": fps_label,
		"settings_button": settings_button,
		"settings_panel": settings_panel,
		"leader_label": leader_label,
		"timer_label": timer_label,
		"stage_label": stage_label,
		"event_label": event_label,
	}

static func _create_pause_overlay(owner, view_size: Vector2) -> Control:
	var pause_overlay := Control.new()
	pause_overlay.position = Vector2.ZERO
	pause_overlay.size = view_size
	pause_overlay.visible = false
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_overlay.add_child(UIFactory.make_fill_rect(Vector2.ZERO, pause_overlay.size, Color(0.0, 0.0, 0.0, 0.35)))

	var pause_panel := UIFactory.make_panel_shell(Vector2((view_size.x - 260.0) * 0.5, (view_size.y - 140.0) * 0.5), Vector2(260.0, 140.0), Color(0.94, 0.97, 1.0, 0.96))
	pause_overlay.add_child(pause_panel)
	pause_panel.add_child(UIFactory.make_outline_label(Vector2(0.0, 22.0), Vector2(260.0, 34.0), "已暂停", 28, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 2))
	pause_panel.add_child(UIFactory.make_outline_label(Vector2(18.0, 66.0), Vector2(224.0, 20.0), "当前进度已保存，可以继续或退出。", 15, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 1))

	var resume_button := UIFactory.make_action_button(Vector2(22.0, 94.0), Vector2(96.0, 36.0), "继续", Color(0.24, 0.52, 0.92))
	resume_button.pressed.connect(Callable(owner, "_toggle_pause"))
	pause_panel.add_child(resume_button)

	var save_exit_button := UIFactory.make_action_button(Vector2(134.0, 94.0), Vector2(104.0, 36.0), "保存退出", Color(0.62, 0.24, 0.22))
	save_exit_button.pressed.connect(Callable(owner, "_save_and_exit_to_menu"))
	pause_panel.add_child(save_exit_button)

	return pause_overlay

static func create_control_buttons(owner, game_layer: Node, chambers: Dictionary, current_layout: Dictionary, view_size: Vector2, mobile_mode: bool) -> Dictionary:
	var add_ball_buttons: Dictionary = {}
	var add_ball_button_base_positions: Dictionary = {}
	var canvas := CanvasLayer.new()
	canvas.name = "ControlButtons"
	game_layer.add_child(canvas)

	var energy_button_script = load("res://scripts/EnergyButton.gd")
	var layout_positions: Dictionary = current_layout.get("add_ball_button_positions", current_layout.get("add_ball_positions", {}))
	var layout_button_size: Vector2 = current_layout.get("add_ball_button_size", current_layout.get("button_size", Vector2(76.0, 46.0)))
	for faction_id in chambers.keys():
		var chamber = chambers[faction_id]
		var button = energy_button_script.new()
		var pos: Vector2 = chamber.global_position
		var scaled_w: float = chamber.chamber_size.x * chamber.scale.x
		var scaled_h: float = chamber.chamber_size.y * chamber.scale.y
		var button_size: Vector2 = layout_button_size
		var button_gap: float = current_layout.get("button_gap", 10.0) + (4.0 if mobile_mode else 0.0)
		button.size = button_size
		button.pivot_offset = button.size * 0.5
		button.faction_id = faction_id
		button.process_mode = Node.PROCESS_MODE_PAUSABLE

		if layout_positions.has(faction_id):
			button.position = layout_positions[faction_id]
		else:
			var y_pos: float = pos.y + scaled_h * 0.5 - button.size.y * 0.5
			if faction_id == GameConfig.Faction.BLUE or faction_id == GameConfig.Faction.GREEN:
				button.position = Vector2(pos.x - button.size.x - button_gap, y_pos)
			else:
				button.position = Vector2(pos.x + scaled_w + button_gap, y_pos)

			button.position.x = clampf(button.position.x, 10.0, view_size.x - button.size.x - 10.0)
			button.position.y = clampf(button.position.y, 64.0, view_size.y - button.size.y - 12.0)

		add_ball_button_base_positions[faction_id] = button.position
		button.display_text = "+球"
		button.text = ""
		button.pressed.connect(Callable(owner, "_add_ball_to_chamber").bind(faction_id))
		canvas.add_child(button)
		add_ball_buttons[faction_id] = button

	return {
		"add_ball_buttons": add_ball_buttons,
		"add_ball_button_base_positions": add_ball_button_base_positions,
	}

static func refresh_add_ball_button(faction_id: int, add_ball_buttons: Dictionary, chambers: Dictionary) -> void:
	if not add_ball_buttons.has(faction_id):
		return

	var button = add_ball_buttons[faction_id]
	var count: int = 0
	var damaged: bool = false
	var locked: bool = false
	var jammed: bool = false

	if chambers.has(faction_id):
		var chamber = chambers[faction_id]
		count = chamber.get_ball_count()
		damaged = chamber.is_damaged
		locked = chamber.is_locked
		jammed = chamber.has_method("get_jammed_time_left") and float(chamber.get_jammed_time_left()) > 0.0

	if damaged:
		button.set_button_status("damaged", "损坏")
	elif jammed:
		button.set_button_status("locked", "短路")
	elif locked:
		button.set_button_status("locked", "锁定")
	elif count >= GameConfig.MAX_CONTROL_BALLS_PER_CHAMBER:
		button.set_button_status("full", "已满")
	else:
		button.set_button_status("normal", "+球")

	button.self_modulate = GameConfig.faction_color(faction_id)
