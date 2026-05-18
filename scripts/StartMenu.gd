extends CanvasLayer
class_name StartMenu

@onready var shade: ColorRect = get_node("Shade")
@onready var root_panel: Panel = get_node("RootPanel")
@onready var panel_bg: ColorRect = get_node("RootPanel/PanelBg")
@onready var title_label: Label = get_node("RootPanel/MainVBox/TitleLabel")
@onready var subtitle_label: Label = get_node("RootPanel/MainVBox/SubtitleLabel")
@onready var mobile_hint_label: Label = get_node("RootPanel/MainVBox/MobileHint")
@onready var preview_container: Control = get_node("RootPanel/MainVBox/PreviewContainer")
@onready var chamber_preview: Node2D = get_node("RootPanel/MainVBox/PreviewContainer/ChamberPreview")

@onready var size_option: OptionButton = get_node("RootPanel/MainVBox/ConfigPanel/ConfigVBox/ConfigRow1/SizeOptionBox/GridSizeOption")
@onready var mode_option: OptionButton = get_node("RootPanel/MainVBox/ConfigPanel/ConfigVBox/ConfigRow1/ModeOptionBox/ModeOption")
@onready var quality_option: OptionButton = get_node("RootPanel/MainVBox/ConfigPanel/ConfigVBox/ConfigRow1/QualityOptionBox/QualityOption")
@onready var time_spin: SpinBox = get_node("RootPanel/MainVBox/ConfigPanel/ConfigVBox/ConfigRow1/TimeOptionBox/TimeSpin")
@onready var palette_option: OptionButton = get_node("RootPanel/MainVBox/ConfigPanel/ConfigVBox/ConfigRow2/PaletteOptionBox/PaletteOption")
@onready var mode_tip_label: Label = get_node("RootPanel/MainVBox/ConfigPanel/ConfigVBox/ModeTipLabel")
@onready var start_button: Button = get_node("RootPanel/MainVBox/ConfigPanel/ConfigVBox/ConfigRow2/StartButton")
@onready var reset_button: Button = get_node("RootPanel/MainVBox/ConfigPanel/ConfigVBox/ConfigRow2/ResetDefaultsButton")

@onready var save_title: Label = get_node("RootPanel/MainVBox/SavePanel/SaveVBox/SaveTitle")
@onready var slot_grid: GridContainer = get_node("RootPanel/MainVBox/SavePanel/SaveVBox/SlotGrid")
@onready var continue_button: Button = get_node("RootPanel/MainVBox/ContinueButton")
@onready var menu_status_label: Label = get_node("RootPanel/MainVBox/MenuStatusLabel")

var _owner
var _menu_layout: Dictionary = {}


static func compact_slot_title(title_text: String) -> String:
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


static func build_slot_label(slot: int, summary: Dictionary, selected_save_slot: int = -1) -> String:
	var marker: String = "● " if slot == selected_save_slot else ""
	var state: String = str(summary.get("state", "empty"))
	if state == "empty":
		return "%s槽%d｜空" % [marker, slot]
	if state == "incompatible":
		return "%s槽%d｜不兼容" % [marker, slot]
	if state == "damaged":
		return "%s槽%d｜损坏" % [marker, slot]
	var title_text: String = compact_slot_title(str(summary.get("title", "")))
	if title_text == "":
		return "%s槽%d｜空" % [marker, slot]
	return "%s槽%d｜%s" % [marker, slot, title_text]


static func build_start_button_text(slot: int) -> String:
	return "新局覆盖槽%d" % slot


static func build_continue_button_text(slot: int) -> String:
	return "读取槽%d" % slot


static func build_status_text(slot: int) -> String:
	return "当前存档槽：%d" % slot


static func build_start_button_label(_slot: int, _has_save_data: bool = false) -> String:
	return "\u5f00\u59cb\u65b0\u6e38\u620f"


static func build_status_label(slot: int, has_save_data: bool) -> String:
	if has_save_data:
		return "\u5df2\u9009\u62e9\u5b58\u6863\u69fd %d\uff0c\u65b0\u6e38\u620f\u4f1a\u8986\u76d6\u8fd9\u91cc\u7684\u5b58\u6863" % slot
	return "\u5df2\u9009\u62e9\u7a7a\u5b58\u6863\u69fd %d\uff0c\u65b0\u6e38\u620f\u4f1a\u4fdd\u5b58\u5728\u8fd9\u91cc" % slot


static func build_mode_tip_text(mode_name: String, time_limit_minutes: int) -> String:
	match mode_name:
		GameConfig.GAME_MODE_BASIC:
			return "\u57fa\u7840\uff1a\u6d88\u706d\u6240\u6709\u5bf9\u624b\u70ae\u53f0\u5373\u53ef\u83b7\u80dc"
		GameConfig.GAME_MODE_OCCUPATION:
			return "\u5360\u9886\uff1a\u8fbe\u5230 75% \u9886\u571f\u5373\u53ef\u83b7\u80dc"
		GameConfig.GAME_MODE_TIMED:
			return "\u9650\u65f6\uff1a%d \u5206\u949f\u5012\u8ba1\u65f6\u7ed3\u675f\u540e\uff0c\u9886\u5730\u6700\u591a\u65b9\u83b7\u80dc" % time_limit_minutes
		GameConfig.GAME_MODE_WILD:
			return "\u72c2\u91ce\uff1a\u5168\u5c40 x3 \u500d\u7387\uff0c\u5355\u6b21\u4e0a\u9650\u66f4\u9ad8\uff0c\u4e8b\u4ef6\u66f4\u9891\u7e41"
		GameConfig.GAME_MODE_CARDFRONT:
			return "卡牌前线：玩家 vs AI，8 分钟结算，70% 占领压制"
		_:
			return ""


func get_parts() -> Dictionary:
	var slot_buttons: Dictionary = {}
	for i in range(5):
		var slot: int = i + 1
		var btn: Button = slot_grid.get_node_or_null("SlotButton_%d" % slot) as Button
		if btn != null:
			slot_buttons[slot] = btn
	return {
		"menu_layer": self,
		"menu_title_label": title_label,
		"menu_start_button": start_button,
		"menu_continue_button": continue_button,
		"menu_save_slot_buttons": slot_buttons,
		"menu_status_label": menu_status_label,
	}


func _refresh_mode_tip() -> void:
	mode_tip_label.text = StartMenu.build_mode_tip_text(
		_owner.selected_game_mode_name,
		_owner.selected_time_limit_minutes
	)


func _refresh_action_labels(has_selected_save: bool) -> void:
	start_button.text = StartMenu.build_start_button_label(_owner.selected_save_slot, has_selected_save)
	continue_button.text = StartMenu.build_continue_button_text(_owner.selected_save_slot)
	continue_button.disabled = not has_selected_save


func _refresh_menu_status_label(has_save_data: bool) -> void:
	menu_status_label.text = StartMenu.build_status_label(_owner.selected_save_slot, has_save_data)


func setup(p_owner, view_size: Vector2, save_summaries: Array, current_layout: Dictionary = {}) -> void:
	_owner = p_owner
	_owner.selected_save_slot = clampi(int(_owner.selected_save_slot), 1, _owner.SAVE_SLOT_COUNT)
	_owner.selected_grid_size = LayoutProfiles.sanitize_grid_size(int(_owner.selected_grid_size))
	_menu_layout = current_layout.get("start_menu_layout", {})

	_apply_layout(view_size)
	_init_options()
	_sync_options_from_owner()
	_init_decor()
	refresh_slots(save_summaries)
	menu_status_label.text = StartMenu.build_status_text(_owner.selected_save_slot)
	_refresh_menu_status_label(_owner._has_save_file(_owner.selected_save_slot))
	_connect_signals()


func refresh_slots(save_summaries: Array) -> void:
	_refresh_slots(save_summaries)


func refresh_save_slots(save_summaries: Array) -> void:
	refresh_slots(save_summaries)


func _apply_layout(view_size: Vector2) -> void:
	var default_panel_size := Vector2(840.0, 684.0)
	var default_panel_pos := Vector2(
		(view_size.x - default_panel_size.x) * 0.5,
		(view_size.y - default_panel_size.y) * 0.5
	)
	var layout: Dictionary = _menu_layout if not _menu_layout.is_empty() else LayoutCoordinator.calculate_layout(40, view_size, false).get("start_menu_layout", {})

	var shade_rect: Rect2 = layout.get("shade_rect", Rect2(Vector2.ZERO, view_size))
	shade.offset_left = shade_rect.position.x
	shade.offset_top = shade_rect.position.y
	shade.offset_right = shade_rect.position.x + shade_rect.size.x
	shade.offset_bottom = shade_rect.position.y + shade_rect.size.y
	shade.color = Color(0.02, 0.03, 0.05, 0.88)

	var root_panel_rect: Rect2 = layout.get("root_panel_rect", Rect2(default_panel_pos, default_panel_size))
	root_panel.position = root_panel_rect.position
	root_panel.size = root_panel_rect.size
	panel_bg.position = Vector2(8.0, 8.0)
	panel_bg.size = root_panel.size - Vector2(16.0, 16.0)

	preview_container.clip_contents = true
	preview_container.custom_minimum_size = layout.get("preview_size", Vector2(0.0, 170.0))
	var preview_scale: Vector2 = layout.get("preview_scale", Vector2(0.40, 0.40))
	chamber_preview.scale = preview_scale
	var preview_bounds: Vector2 = preview_container.size
	if preview_bounds.x <= 0.0 or preview_bounds.y <= 0.0:
		preview_bounds = preview_container.custom_minimum_size
	var preview_center: Vector2 = layout.get(
		"preview_center",
		Vector2(preview_bounds.x * 0.5, preview_bounds.y * 0.46)
	)
	chamber_preview.position = preview_center


func _init_options() -> void:
	if size_option.item_count == 0:
		for gs in [10, 20, 30, 40, 50, 60]:
			size_option.add_item("%d × %d" % [gs, gs], gs)

	if mode_option.item_count == 0:
		for mode_name in GameConfig.get_game_mode_names():
			mode_option.add_item(mode_name)

	if quality_option.item_count == 0:
		for quality_name in GameConfig.get_quality_names():
			quality_option.add_item(quality_name)

	if palette_option.item_count == 0:
		palette_option.add_item("默认随机")
		for palette_name in GameConfig.get_palette_names():
			palette_option.add_item(palette_name)


func _sync_options_from_owner() -> void:
	for i in range(size_option.item_count):
		if size_option.get_item_id(i) == _owner.selected_grid_size:
			size_option.select(i)
			break

	for i in range(mode_option.item_count):
		if mode_option.get_item_text(i) == _owner.selected_game_mode_name:
			mode_option.select(i)
			break

	for i in range(quality_option.item_count):
		if quality_option.get_item_text(i) == _owner.selected_quality_name:
			quality_option.select(i)
			break

	time_spin.value = float(_owner.selected_time_limit_minutes)

	for i in range(palette_option.item_count):
		if palette_option.get_item_text(i) == _owner.selected_palette_name:
			palette_option.select(i)
			break

	_update_reset_button_state()
	_update_mode_tip()
	_update_action_labels(_owner._has_save_file(_owner.selected_save_slot))
	_refresh_mode_tip()
	_refresh_action_labels(_owner._has_save_file(_owner.selected_save_slot))


func _is_default_config() -> bool:
	return _owner.selected_grid_size == 40 \
		and _owner.selected_game_mode_name == GameConfig.GAME_MODE_BASIC \
		and _owner.selected_quality_name == GameConfig.QUALITY_MEDIUM \
		and _owner.selected_palette_name == "默认随机" \
		and _owner.selected_time_limit_minutes == GameConfig.DEFAULT_TIMED_MODE_MINUTES


func _update_reset_button_state() -> void:
	if _is_default_config():
		reset_button.text = "已是默认"
		reset_button.disabled = true
		reset_button.self_modulate = Color(0.18, 0.20, 0.26, 0.55)
	else:
		reset_button.text = "恢复默认"
		reset_button.disabled = false
		reset_button.self_modulate = Color(0.28, 0.32, 0.46, 0.88)


func _update_mode_tip() -> void:
	match _owner.selected_game_mode_name:
		GameConfig.GAME_MODE_BASIC:
			mode_tip_label.text = "基础：消灭所有对手炮台即获胜"
		GameConfig.GAME_MODE_OCCUPATION:
			mode_tip_label.text = "占领：达到 75% 胜利　限时：5~15 分钟结算　狂野：全局 ×3，事件更频繁"
		GameConfig.GAME_MODE_TIMED:
			mode_tip_label.text = "限时：%d 分钟倒计时结束，领地最多方获胜" % _owner.selected_time_limit_minutes
		GameConfig.GAME_MODE_WILD:
			mode_tip_label.text = "狂野：全局 ×3 倍率，单次上限更高，事件更频繁"
		GameConfig.GAME_MODE_CARDFRONT:
			mode_tip_label.text = "卡牌前线：玩家 vs AI，8 分钟结算，70% 占领压制"
		_:
			mode_tip_label.text = ""


func _update_action_labels(has_selected_save: bool) -> void:
	start_button.text = StartMenu.build_start_button_text(_owner.selected_save_slot)
	continue_button.text = StartMenu.build_continue_button_text(_owner.selected_save_slot)
	continue_button.disabled = not has_selected_save


func _compact_mode_name(mode_name: String) -> String:
	match mode_name:
		"基础模式", GameConfig.GAME_MODE_BASIC:
			return "基础"
		"占领模式", GameConfig.GAME_MODE_OCCUPATION:
			return "占领"
		"限时模式", GameConfig.GAME_MODE_TIMED:
			return "限时"
		"狂野模式", GameConfig.GAME_MODE_WILD:
			return "狂野"
		"卡牌前线", GameConfig.GAME_MODE_CARDFRONT:
			return "卡前"
		_:
			return mode_name


func _compact_slot_title(title_text: String) -> String:
	return StartMenu.compact_slot_title(title_text)


func _build_slot_label(slot: int, summary: Dictionary) -> String:
	return StartMenu.build_slot_label(slot, summary, _owner.selected_save_slot)


func _init_decor() -> void:
	for child in chamber_preview.get_children():
		child.queue_free()

	var decor
	var preview_scene_path: String = "res://scenes/ui/PreviewScene.tscn"
	if ResourceLoader.exists(preview_scene_path):
		var preview_scene: PackedScene = load(preview_scene_path)
		decor = preview_scene.instantiate()
	else:
		decor = preload("res://scripts/MenuDecor.gd").new()
	decor.position = Vector2.ZERO
	decor.scale = Vector2.ONE
	chamber_preview.add_child(decor)


func _refresh_slots(save_summaries: Array) -> void:
	var selected_summary: Dictionary = {}
	for i in range(5):
		var slot: int = i + 1
		var btn: Button = slot_grid.get_node_or_null("SlotButton_%d" % slot) as Button
		if btn == null:
			continue

		var summary: Dictionary = {
			"slot": slot,
			"state": "empty",
			"has_data": false,
			"is_playable": false,
			"title": "空存档",
			"detail": "点击选择此槽",
		}
		for item in save_summaries:
			if item is Dictionary and int(item.get("slot", 0)) == slot:
				summary = item
				break

		if slot == _owner.selected_save_slot:
			selected_summary = summary

		btn.text = _build_slot_label(slot, summary)
		btn.tooltip_text = str(summary.get("detail", "点击选择此槽"))

		if slot == _owner.selected_save_slot:
			btn.self_modulate = Color(0.28, 0.54, 0.88)
		elif summary.get("is_playable", false):
			btn.self_modulate = Color(0.18, 0.46, 0.28)
		elif summary.get("has_data", false):
			btn.self_modulate = Color(0.28, 0.18, 0.16)
		else:
			btn.self_modulate = Color(0.16, 0.22, 0.32)

	_update_action_labels(selected_summary.get("is_playable", false))
	_refresh_action_labels(bool(selected_summary.get("is_playable", false)))
	_refresh_menu_status_label(bool(selected_summary.get("has_data", false)))


func _connect_signals() -> void:
	if not size_option.item_selected.is_connected(_on_size_option_selected):
		size_option.item_selected.connect(_on_size_option_selected)
	if not mode_option.item_selected.is_connected(_on_mode_option_selected):
		mode_option.item_selected.connect(_on_mode_option_selected)
	if not quality_option.item_selected.is_connected(_on_quality_option_selected):
		quality_option.item_selected.connect(_on_quality_option_selected)
	if not time_spin.value_changed.is_connected(_on_time_spin_changed):
		time_spin.value_changed.connect(_on_time_spin_changed)
	if not palette_option.item_selected.is_connected(_on_palette_option_selected):
		palette_option.item_selected.connect(_on_palette_option_selected)
	if not start_button.pressed.is_connected(_on_start_pressed):
		start_button.pressed.connect(_on_start_pressed)
	if not reset_button.pressed.is_connected(_on_reset_pressed):
		reset_button.pressed.connect(_on_reset_pressed)
	if not continue_button.pressed.is_connected(Callable(_owner, "_continue_saved_game")):
		continue_button.pressed.connect(Callable(_owner, "_continue_saved_game"))

	for i in range(5):
		var slot: int = i + 1
		var btn: Button = slot_grid.get_node_or_null("SlotButton_%d" % slot) as Button
		if btn != null:
			var callback := Callable(self, "_on_slot_pressed").bind(slot)
			if not btn.pressed.is_connected(callback):
				btn.pressed.connect(callback)


func _on_size_option_selected(index: int) -> void:
	_owner.selected_grid_size = size_option.get_item_id(index)
	_owner._save_menu_preferences()


func _on_mode_option_selected(index: int) -> void:
	_owner.selected_game_mode_name = mode_option.get_item_text(index)
	_update_mode_tip()
	_refresh_mode_tip()
	_owner._save_menu_preferences()


func _on_quality_option_selected(index: int) -> void:
	_owner.selected_quality_name = quality_option.get_item_text(index)
	_owner._save_menu_preferences()


func _on_time_spin_changed(value: float) -> void:
	_owner.selected_time_limit_minutes = clampi(int(round(value)), GameConfig.TIMED_MODE_MIN_MINUTES, GameConfig.TIMED_MODE_MAX_MINUTES)
	_update_mode_tip()
	_refresh_mode_tip()
	_owner._save_menu_preferences()


func _on_palette_option_selected(index: int) -> void:
	_owner.selected_palette_name = palette_option.get_item_text(index)
	_owner._save_menu_preferences()


func _on_start_pressed() -> void:
	_owner._save_menu_preferences()
	_owner._start_game(_owner.selected_grid_size)


func _on_reset_pressed() -> void:
	_owner.reset_menu_preferences()


func _on_slot_pressed(slot: int) -> void:
	_owner._select_save_slot(slot)
