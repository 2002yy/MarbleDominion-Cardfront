extends RefCounted
class_name StartMenuView

static func create(owner, view_size: Vector2, save_summaries: Array, current_layout: Dictionary = {}) -> Dictionary:
	owner.selected_save_slot = clampi(int(owner.selected_save_slot), 1, owner.SAVE_SLOT_COUNT)
	owner.selected_grid_size = LayoutProfiles.sanitize_grid_size(int(owner.selected_grid_size))

	var menu_layout: Dictionary = current_layout.get("start_menu_layout", LayoutCoordinator.calculate_layout(40, view_size, false).get("start_menu_layout", {}))
	var default_panel_size := Vector2(840.0, 684.0)
	var default_panel_pos := Vector2(
		(view_size.x - default_panel_size.x) * 0.5,
		(view_size.y - default_panel_size.y) * 0.5
	)

	var menu_layer := CanvasLayer.new()
	menu_layer.name = "MenuLayer"
	owner.add_child(menu_layer)

	var shade := ColorRect.new()
	var shade_rect: Rect2 = menu_layout.get("shade_rect", Rect2(Vector2.ZERO, view_size))
	shade.color = Color(0.02, 0.03, 0.05, 0.88)
	shade.position = shade_rect.position
	shade.size = shade_rect.size
	menu_layer.add_child(shade)

	var panel := Panel.new()
	var root_panel_rect: Rect2 = menu_layout.get("root_panel_rect", Rect2(default_panel_pos, default_panel_size))
	panel.position = root_panel_rect.position
	panel.size = root_panel_rect.size
	panel.self_modulate = Color(0.98, 0.99, 1.0, 0.96)
	menu_layer.add_child(panel)

	var panel_bg := ColorRect.new()
	panel_bg.position = Vector2(8.0, 8.0)
	panel_bg.size = panel.size - Vector2(16.0, 16.0)
	panel_bg.color = Color(0.08, 0.12, 0.18, 0.97)
	panel.add_child(panel_bg)

	var main_vbox := VBoxContainer.new()
	main_vbox.position = Vector2(18.0, 10.0)
	main_vbox.size = panel.size - Vector2(36.0, 20.0)
	main_vbox.add_theme_constant_override("separation", 4)
	panel.add_child(main_vbox)

	var title := _make_label("领土战争", 44, Color(1.0, 0.95, 0.72), HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.06))
	title.add_theme_constant_override("outline_size", 7)
	title.custom_minimum_size = Vector2(0.0, 56.0)
	main_vbox.add_child(title)

	var subtitle := _make_label("四控制仓 · 四角炮台 · 领土争夺", 18, Color(0.84, 0.92, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
	subtitle.custom_minimum_size = Vector2(0.0, 24.0)
	main_vbox.add_child(subtitle)

	var mobile_hint := _make_label("电脑 / 安卓均可游玩 · 手机建议横屏", 15, Color(0.74, 0.86, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
	mobile_hint.custom_minimum_size = Vector2(0.0, 22.0)
	main_vbox.add_child(mobile_hint)

	var preview_container := Control.new()
	preview_container.name = "PreviewContainer"
	preview_container.clip_contents = true
	preview_container.custom_minimum_size = menu_layout.get("preview_size", Vector2(0.0, 170.0))
	main_vbox.add_child(preview_container)

	var chamber_preview := Node2D.new()
	chamber_preview.name = "ChamberPreview"
	chamber_preview.scale = menu_layout.get("preview_scale", Vector2(0.40, 0.40))
	chamber_preview.position = menu_layout.get("preview_center", Vector2(402.0, 78.0))
	preview_container.add_child(chamber_preview)

	var decor = preload("res://scripts/MenuDecor.gd").new()
	decor.position = Vector2.ZERO
	decor.scale = Vector2.ONE
	chamber_preview.add_child(decor)

	var config_panel := Panel.new()
	config_panel.custom_minimum_size = Vector2(0.0, 126.0)
	config_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(config_panel)

	var cfg_bg := ColorRect.new()
	cfg_bg.position = Vector2(8.0, 6.0)
	cfg_bg.size = Vector2(panel.size.x - 62.0, 124.0)
	cfg_bg.color = Color(0.12, 0.16, 0.23)
	config_panel.add_child(cfg_bg)

	var config_vbox := VBoxContainer.new()
	config_vbox.position = Vector2(12.0, 8.0)
	config_vbox.add_theme_constant_override("separation", 4)
	config_panel.add_child(config_vbox)

	var mode_tip_label: Label = null
	var config_row1 := HBoxContainer.new()
	config_row1.add_theme_constant_override("separation", 12)
	config_vbox.add_child(config_row1)

	var size_option := OptionButton.new()
	for gs in [10, 20, 30, 40, 50, 60]:
		size_option.add_item("%d × %d" % [gs, gs], gs)
	for i in range(size_option.item_count):
		if size_option.get_item_id(i) == owner.selected_grid_size:
			size_option.select(i)
			break
	size_option.item_selected.connect(func(index: int) -> void:
		owner.selected_grid_size = size_option.get_item_id(index)
		owner._save_menu_preferences()
	)
	config_row1.add_child(_make_option_row("地图大小", size_option))

	var mode_option := OptionButton.new()
	for mode_name in GameConfig.get_game_mode_names():
		mode_option.add_item(mode_name)
	for i in range(mode_option.item_count):
		if mode_option.get_item_text(i) == owner.selected_game_mode_name:
			mode_option.select(i)
			break
	mode_option.item_selected.connect(func(index: int) -> void:
		owner.selected_game_mode_name = mode_option.get_item_text(index)
		_update_fallback_mode_tip(mode_tip_label, owner)
		mode_tip_label.text = StartMenu.build_mode_tip_text(owner.selected_game_mode_name, owner.selected_time_limit_minutes)
		owner._save_menu_preferences()
	)
	config_row1.add_child(_make_option_row("游戏模式", mode_option))

	var quality_option := OptionButton.new()
	for quality_name in GameConfig.get_quality_names():
		quality_option.add_item(quality_name)
	for i in range(quality_option.item_count):
		if quality_option.get_item_text(i) == owner.selected_quality_name:
			quality_option.select(i)
			break
	quality_option.item_selected.connect(func(index: int) -> void:
		owner.selected_quality_name = quality_option.get_item_text(index)
		owner._save_menu_preferences()
	)
	config_row1.add_child(_make_option_row("画质", quality_option))

	var time_spin := SpinBox.new()
	time_spin.min_value = GameConfig.TIMED_MODE_MIN_MINUTES
	time_spin.max_value = GameConfig.TIMED_MODE_MAX_MINUTES
	time_spin.step = 1.0
	time_spin.value = float(owner.selected_time_limit_minutes)
	time_spin.tooltip_text = "限时模式分钟数，范围 5~15 分钟。"
	time_spin.value_changed.connect(func(value: float) -> void:
		owner.selected_time_limit_minutes = clampi(int(round(value)), GameConfig.TIMED_MODE_MIN_MINUTES, GameConfig.TIMED_MODE_MAX_MINUTES)
		_update_fallback_mode_tip(mode_tip_label, owner)
		mode_tip_label.text = StartMenu.build_mode_tip_text(owner.selected_game_mode_name, owner.selected_time_limit_minutes)
		owner._save_menu_preferences()
	)
	config_row1.add_child(_make_option_row("限时", time_spin))

	var config_row2 := HBoxContainer.new()
	config_row2.add_theme_constant_override("separation", 12)
	config_vbox.add_child(config_row2)

	var palette_option := OptionButton.new()
	palette_option.add_item("默认随机")
	for palette_name in GameConfig.get_palette_names():
		palette_option.add_item(palette_name)
	for i in range(palette_option.item_count):
		if palette_option.get_item_text(i) == owner.selected_palette_name:
			palette_option.select(i)
			break
	palette_option.item_selected.connect(func(index: int) -> void:
		owner.selected_palette_name = palette_option.get_item_text(index)
		owner._save_menu_preferences()
	)
	config_row2.add_child(_make_option_row("配色方案", palette_option))

	var start_button := Button.new()
	start_button.text = StartMenu.build_start_button_label(owner.selected_save_slot, owner._has_save_file(owner.selected_save_slot))
	start_button.custom_minimum_size = Vector2(140.0, 32.0)
	start_button.add_theme_font_size_override("font_size", 15)
	start_button.add_theme_color_override("font_color", Color.WHITE)
	start_button.self_modulate = Color(0.22, 0.60, 1.0)
	start_button.pressed.connect(func() -> void:
		owner._save_menu_preferences()
		owner._start_game(owner.selected_grid_size)
	)
	config_row2.add_child(start_button)

	var reset_btn := Button.new()
	reset_btn.text = "恢复默认"
	reset_btn.tooltip_text = "重置为默认设置"
	reset_btn.custom_minimum_size = Vector2(90.0, 32.0)
	reset_btn.self_modulate = Color(0.22, 0.22, 0.32, 0.85)
	reset_btn.pressed.connect(func() -> void:
		owner.reset_menu_preferences()
	)
	config_row2.add_child(reset_btn)

	mode_tip_label = Label.new()
	mode_tip_label.custom_minimum_size = Vector2(0.0, 32.0)
	mode_tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART as TextServer.AutowrapMode
	mode_tip_label.add_theme_font_size_override("font_size", 13)
	mode_tip_label.add_theme_color_override("font_color", Color(0.82, 0.90, 1.0))
	_update_fallback_mode_tip(mode_tip_label, owner)
	mode_tip_label.text = StartMenu.build_mode_tip_text(owner.selected_game_mode_name, owner.selected_time_limit_minutes)
	config_vbox.add_child(mode_tip_label)

	var save_panel := Panel.new()
	save_panel.custom_minimum_size = Vector2(0.0, 136.0)
	main_vbox.add_child(save_panel)

	var save_bg := ColorRect.new()
	save_bg.position = Vector2(8.0, 6.0)
	save_bg.size = Vector2(panel.size.x - 62.0, 136.0)
	save_bg.color = Color(0.10, 0.14, 0.20)
	save_panel.add_child(save_bg)

	var save_vbox := VBoxContainer.new()
	save_vbox.position = Vector2(12.0, 8.0)
	save_vbox.add_theme_constant_override("separation", 4)
	save_panel.add_child(save_vbox)

	var save_title := _make_label("选择存档槽（暂停 / 退出会保存到当前槽）", 14, Color(0.84, 0.92, 1.0), HORIZONTAL_ALIGNMENT_LEFT)
	save_title.custom_minimum_size = Vector2(0.0, 22.0)
	save_vbox.add_child(save_title)

	var slot_grid := GridContainer.new()
	slot_grid.columns = 3
	slot_grid.custom_minimum_size = Vector2(0.0, 80.0)
	slot_grid.add_theme_constant_override("h_separation", 8)
	slot_grid.add_theme_constant_override("v_separation", 6)
	save_vbox.add_child(slot_grid)

	var save_slot_buttons: Dictionary = {}
	for summary in save_summaries:
		if not (summary is Dictionary):
			continue
		var slot: int = int(summary.get("slot", 1))
		var btn := Button.new()
		btn.name = "SlotButton_%d" % slot
		btn.custom_minimum_size = Vector2(200.0, 34.0)
		btn.text = _build_slot_label(slot, summary)
		btn.clip_text = true
		btn.tooltip_text = str(summary.get("detail", "点击选择此槽"))
		btn.add_theme_font_size_override("font_size", 13)
		btn.add_theme_color_override("font_color", Color.WHITE)
		btn.self_modulate = Color(0.28, 0.54, 0.88) if slot == owner.selected_save_slot else Color(0.16, 0.22, 0.32)
		var captured_slot: int = slot
		btn.pressed.connect(func() -> void:
			owner._select_save_slot(captured_slot)
		)
		slot_grid.add_child(btn)
		save_slot_buttons[slot] = btn

	var continue_button := Button.new()
	continue_button.text = "读取槽%d" % owner.selected_save_slot
	continue_button.custom_minimum_size = Vector2(0.0, 36.0)
	continue_button.add_theme_font_size_override("font_size", 18)
	continue_button.add_theme_color_override("font_color", Color.WHITE)
	continue_button.self_modulate = Color(0.20, 0.66, 0.42)
	continue_button.disabled = not owner._has_save_file(owner.selected_save_slot)
	continue_button.pressed.connect(Callable(owner, "_continue_saved_game"))
	main_vbox.add_child(continue_button)

	var menu_status_label := Label.new()
	menu_status_label.text = "当前存档槽：%d" % owner.selected_save_slot
	menu_status_label.custom_minimum_size = Vector2(0.0, 22.0)
	menu_status_label.text = StartMenu.build_status_label(owner.selected_save_slot, owner._has_save_file(owner.selected_save_slot))
	menu_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER as HorizontalAlignment
	menu_status_label.add_theme_font_size_override("font_size", 15)
	menu_status_label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.44))
	menu_status_label.add_theme_color_override("font_outline_color", Color.BLACK)
	menu_status_label.add_theme_constant_override("outline_size", 2)
	main_vbox.add_child(menu_status_label)

	return {
		"menu_layer": menu_layer,
		"menu_title_label": title,
		"menu_start_button": start_button,
		"menu_continue_button": continue_button,
		"menu_save_slot_buttons": save_slot_buttons,
		"menu_status_label": menu_status_label,
	}


static func _make_label(text_value: String, font_size: int, color: Color, halign: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = halign as HorizontalAlignment
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


static func _make_option_row(label_text: String, control: Control) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var lbl := _make_label(label_text, 17, Color.WHITE)
	lbl.custom_minimum_size = Vector2(74.0, 24.0)
	box.add_child(lbl)
	control.custom_minimum_size = Vector2(110.0, 28.0)
	box.add_child(control)
	return box


static func _compact_slot_title(title_text: String) -> String:
	var compact_text: String = title_text
	compact_text = compact_text.replace("基础模式", "基础")
	compact_text = compact_text.replace("占领模式", "占领")
	compact_text = compact_text.replace("限时模式", "限时")
	compact_text = compact_text.replace("狂野模式", "狂野")
	compact_text = compact_text.replace("卡牌前线", "卡前")
	compact_text = compact_text.replace(GameConfig.GAME_MODE_BASIC, "基础")
	compact_text = compact_text.replace(GameConfig.GAME_MODE_OCCUPATION, "占领")
	compact_text = compact_text.replace(GameConfig.GAME_MODE_TIMED, "限时")
	compact_text = compact_text.replace(GameConfig.GAME_MODE_WILD, "狂野")
	compact_text = compact_text.replace(GameConfig.GAME_MODE_CARDFRONT, "卡前")
	return compact_text


static func _build_slot_label(slot: int, summary: Dictionary) -> String:
	if not bool(summary.get("has_data", false)):
		return "槽%d｜空" % slot
	var title_text: String = _compact_slot_title(str(summary.get("title", "")))
	if title_text == "":
		return "槽%d｜空" % slot
	return "槽%d｜%s" % [slot, title_text]


static func _update_fallback_mode_tip(tip_label: Label, owner) -> void:
	match owner.selected_game_mode_name:
		GameConfig.GAME_MODE_BASIC:
			tip_label.text = "基础：消灭所有对手炮台即获胜"
		GameConfig.GAME_MODE_OCCUPATION:
			tip_label.text = "占领：达到 75% 胜利　限时：5~15 分钟结算　狂野：全局 ×3，事件更频繁"
		GameConfig.GAME_MODE_TIMED:
			tip_label.text = "限时：%d 分钟倒计时结束，领地最多方获胜" % owner.selected_time_limit_minutes
		GameConfig.GAME_MODE_WILD:
			tip_label.text = "狂野：全局 ×3 倍率，单次上限更高，事件更频繁"
		GameConfig.GAME_MODE_CARDFRONT:
			tip_label.text = "卡牌前线：玩家 vs AI，8 分钟结算，70% 占领压制"
		_:
			tip_label.text = ""
