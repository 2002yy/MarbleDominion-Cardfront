extends CanvasLayer
class_name GameHUD

@onready var top_panel: Panel = get_node("TopPanel")
@onready var top_panel_bg: ColorRect = get_node("TopPanel/Bg")
@onready var top_panel_accent: ColorRect = get_node("TopPanel/AccentLine")
@onready var top_panel_header: ColorRect = get_node("TopPanel/HeaderStrip")
@onready var leader_label: Label = get_node("TopPanel/LeaderLabel")
@onready var timer_label: Label = get_node("TopPanel/TimerLabel")
@onready var stage_label: Label = get_node("TopPanel/StageLabel")
@onready var top_bar_shell: Panel = get_node("TopPanel/BarBG")
@onready var top_bar_inner: ColorRect = get_node("TopPanel/BarBG/BarInner")
@onready var badge: Control = get_node("TopPanel/Badge")
@onready var game_title_label: Label = get_node("TopPanel/GameTitleLabel")
@onready var palette_label: Label = get_node("TopPanel/PaletteLabel")

@onready var fps_bg: ColorRect = get_node("FPSBg")
@onready var fps_label: Label = get_node("FPSLabel")
@onready var event_label: Label = get_node("EventLabel")
@onready var settings_button: Button = get_node("SettingsButton")
@onready var pause_button: Button = get_node("PauseButton")
@onready var exit_button: Button = get_node("ExitButton")
@onready var pause_overlay: Control = get_node("PauseOverlay")
@onready var pause_panel: Panel = get_node("PauseOverlay/PausePanel")
@onready var resume_button: Button = get_node("PauseOverlay/PausePanel/ResumeButton")
@onready var save_exit_button: Button = get_node("PauseOverlay/PausePanel/SaveExitButton")
@onready var winner_label: Label = get_node("WinnerLabel")

var settings_panel: Control
var top_bar_segments: Dictionary = {}
var top_bar_labels: Dictionary = {}
var top_bar_name_labels: Dictionary = {}
var top_bar_total_width: float = 0.0
var event_log_label: RichTextLabel
var event_log_toggle_btn: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_collect_top_bar_nodes()
	_load_settings_panel()

func setup_static(controller_ref, view_size: Vector2, current_layout: Dictionary = {}, mobile_mode: bool = false) -> void:
	var layout: Dictionary = current_layout if not current_layout.is_empty() else LayoutProfiles.get_profile(40)
	var hud_positions: Dictionary = layout.get("hud_positions", {})
	_collect_top_bar_nodes()

	var top_panel_rect: Rect2 = hud_positions.get(
		"top_panel_rect",
		Rect2(Vector2((view_size.x - 710.0) * 0.5, 8.0), Vector2(710.0, 98.0 if mobile_mode else 90.0))
	)
	top_panel.position = top_panel_rect.position
	top_panel.size = top_panel_rect.size
	top_panel_bg.position = Vector2(4.0, 4.0)
	top_panel_bg.size = top_panel.size - Vector2(8.0, 8.0)
	top_panel_accent.position = Vector2(12.0, 4.0)
	top_panel_accent.size = Vector2(top_panel.size.x - 24.0, 2.0)
	top_panel_header.position = Vector2(10.0, 6.0)
	top_panel_header.size = Vector2(top_panel.size.x - 20.0, 22.0)

	var leader_label_rect: Rect2 = hud_positions.get("leader_label_rect", Rect2(top_panel.position + Vector2(16.0, 4.0), Vector2(176.0, 24.0)))
	leader_label.position = leader_label_rect.position - top_panel.position
	leader_label.size = leader_label_rect.size

	var timer_label_rect: Rect2 = hud_positions.get("timer_label_rect", Rect2(top_panel.position + Vector2((top_panel.size.x - 110.0) * 0.5, 1.0), Vector2(110.0, 26.0)))
	timer_label.position = timer_label_rect.position - top_panel.position
	timer_label.size = timer_label_rect.size

	var stage_label_rect: Rect2 = hud_positions.get("stage_label_rect", Rect2(top_panel.position + Vector2(top_panel.size.x - 182.0, 4.0), Vector2(168.0, 24.0)))
	stage_label.position = stage_label_rect.position - top_panel.position
	stage_label.size = stage_label_rect.size

	var bar_bg_rect: Rect2 = hud_positions.get(
		"bar_bg_rect",
		Rect2(top_panel.position + Vector2(18.0, 31.0), Vector2(top_panel.size.x - 36.0, float(layout.get("bar_h", 36.0))))
	)
	top_bar_shell.position = bar_bg_rect.position - top_panel.position
	top_bar_shell.size = bar_bg_rect.size

	var bar_inner_rect: Rect2 = hud_positions.get(
		"bar_inner_rect",
		Rect2(bar_bg_rect.position + Vector2(3.0, 3.0), bar_bg_rect.size - Vector2(6.0, 6.0))
	)
	top_bar_inner.position = bar_inner_rect.position - bar_bg_rect.position
	top_bar_inner.size = bar_inner_rect.size
	top_bar_total_width = top_bar_inner.size.x
	_layout_top_bar_segments()

	var badge_rect: Rect2 = hud_positions.get("badge_rect", Rect2(top_panel.position + Vector2(top_panel.size.x * 0.5 - 118.0, 60.0), Vector2(28.0, 28.0)))
	badge.position = badge_rect.position - top_panel.position
	badge.size = badge_rect.size

	var title_rect: Rect2 = hud_positions.get("title_rect", Rect2(top_panel.position + Vector2(0.0, top_panel.size.y - 26.0), Vector2(top_panel.size.x, 28.0)))
	game_title_label.position = title_rect.position - top_panel.position
	game_title_label.size = title_rect.size
	game_title_label.add_theme_font_size_override("font_size", 24 if mobile_mode else int(layout.get("title_font", 31)))

	if mobile_mode:
		palette_label.visible = false
	else:
		palette_label.visible = true
		var palette_rect: Rect2 = hud_positions.get("palette_rect", Rect2(top_panel.position + Vector2(top_panel.size.x - 166.0, 66.0), Vector2(152.0, 22.0)))
		palette_label.position = palette_rect.position - top_panel.position
		palette_label.size = palette_rect.size
		palette_label.text = "配色：%s" % GameConfig.get_palette_name()
		palette_label.add_theme_font_size_override("font_size", int(layout.get("palette_font", 16)))

	_layout_side_buttons(view_size, mobile_mode, layout)
	_layout_bottom_hud(view_size, mobile_mode, layout)
	_try_attach_event_log(layout, view_size, mobile_mode)
	_layout_pause_overlay(view_size)

	var winner_label_rect: Rect2 = hud_positions.get("winner_label_rect", Rect2(Vector2(0.0, float(layout.get("winner_y", 666.0))), Vector2(view_size.x, 34.0)))
	winner_label.position = winner_label_rect.position
	winner_label.size = winner_label_rect.size

	_refresh_settings_panel_content(mobile_mode)
	_connect_if_available(settings_button, controller_ref, "_toggle_settings_panel")
	_connect_if_available(pause_button, controller_ref, "_toggle_pause")
	_connect_if_available(exit_button, controller_ref, "_save_and_exit_to_menu")
	_connect_if_available(resume_button, controller_ref, "_toggle_pause")
	_connect_if_available(save_exit_button, controller_ref, "_save_and_exit_to_menu")

func get_static_parts() -> Dictionary:
	return {
		"ui_canvas": self,
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
		"event_log_label": event_log_label,
		"event_log_toggle": event_log_toggle_btn,
	}

func setup_side_buttons(controller_ref) -> void:
	_connect_if_available(settings_button, controller_ref, "_toggle_settings_panel")
	_connect_if_available(pause_button, controller_ref, "_toggle_pause")
	_connect_if_available(exit_button, controller_ref, "_save_and_exit_to_menu")

func _collect_top_bar_nodes() -> void:
	top_bar_segments = {
		GameConfig.Faction.BLUE: get_node("TopPanel/BarBG/BarInner/BlueSegment"),
		GameConfig.Faction.RED: get_node("TopPanel/BarBG/BarInner/RedSegment"),
		GameConfig.Faction.GREEN: get_node("TopPanel/BarBG/BarInner/GreenSegment"),
		GameConfig.Faction.YELLOW: get_node("TopPanel/BarBG/BarInner/YellowSegment"),
	}
	top_bar_labels = {
		GameConfig.Faction.BLUE: get_node("TopPanel/BarBG/BarInner/BlueSegment/ValueLabel"),
		GameConfig.Faction.RED: get_node("TopPanel/BarBG/BarInner/RedSegment/ValueLabel"),
		GameConfig.Faction.GREEN: get_node("TopPanel/BarBG/BarInner/GreenSegment/ValueLabel"),
		GameConfig.Faction.YELLOW: get_node("TopPanel/BarBG/BarInner/YellowSegment/ValueLabel"),
	}
	top_bar_name_labels = {
		GameConfig.Faction.BLUE: get_node("TopPanel/BarBG/BarInner/BlueSegment/NameLabel"),
		GameConfig.Faction.RED: get_node("TopPanel/BarBG/BarInner/RedSegment/NameLabel"),
		GameConfig.Faction.GREEN: get_node("TopPanel/BarBG/BarInner/GreenSegment/NameLabel"),
		GameConfig.Faction.YELLOW: get_node("TopPanel/BarBG/BarInner/YellowSegment/NameLabel"),
	}

func _layout_top_bar_segments() -> void:
	var x_offset: float = 3.0
	var segment_height: float = top_bar_inner.size.y
	var segment_width: float = top_bar_total_width * 0.25
	for faction_id in [GameConfig.Faction.BLUE, GameConfig.Faction.RED, GameConfig.Faction.GREEN, GameConfig.Faction.YELLOW]:
		var segment: Panel = top_bar_segments.get(faction_id, null)
		if segment == null:
			continue
		segment.position = Vector2(x_offset, 3.0)
		segment.size = Vector2(segment_width, segment_height)

		var fill: ColorRect = segment.get_node("Fill") as ColorRect
		fill.position = Vector2(2.0, 2.0)
		fill.size = Vector2(segment.size.x - 4.0, segment.size.y - 4.0)
		fill.color = GameConfig.faction_color(faction_id)

		var gloss: ColorRect = segment.get_node("Gloss") as ColorRect
		gloss.position = Vector2(2.0, 2.0)
		gloss.size = Vector2(segment.size.x - 4.0, maxf(5.0, (segment.size.y - 4.0) * 0.42))

		var bottom_shadow: ColorRect = segment.get_node("BottomShadow") as ColorRect
		bottom_shadow.position = Vector2(2.0, maxf(4.0, segment.size.y - 8.0))
		bottom_shadow.size = Vector2(segment.size.x - 4.0, 4.0)

		var name_label: Label = top_bar_name_labels.get(faction_id, null)
		name_label.position = Vector2(6.0, 2.0)
		name_label.size = Vector2(74.0, 14.0)
		name_label.text = GameConfig.faction_name(faction_id)
		name_label.add_theme_color_override("font_color", GameConfig.faction_color(faction_id).lightened(0.56))

		var value_label: Label = top_bar_labels.get(faction_id, null)
		value_label.position = Vector2(0.0, -1.0)
		value_label.size = segment.size

		if segment.has_node("Separator"):
			var separator: ColorRect = segment.get_node("Separator") as ColorRect
			separator.position = Vector2(segment.size.x - 2.0, 0.0)
			separator.size = Vector2(2.0, segment.size.y)

		x_offset += segment.size.x

func _layout_side_buttons(view_size: Vector2, mobile_mode: bool, current_layout: Dictionary = {}) -> void:
	var side_button_size: Vector2 = current_layout.get("side_button_size", Vector2(114.0, 46.0) if mobile_mode else Vector2(96.0, 42.0))
	var side_button_positions: Dictionary = current_layout.get("side_button_positions", {})

	_apply_button_layout(settings_button, side_button_positions.get("settings", Vector2(view_size.x - side_button_size.x - 18.0, 84.0)), side_button_size)
	_apply_button_layout(pause_button, side_button_positions.get("pause", Vector2(settings_button.position.x, settings_button.position.y + side_button_size.y + 8.0)), side_button_size)
	_apply_button_layout(exit_button, side_button_positions.get("exit", Vector2(settings_button.position.x, pause_button.position.y + side_button_size.y + 8.0)), side_button_size)

	if settings_panel != null and is_instance_valid(settings_panel):
		var hud_positions: Dictionary = current_layout.get("hud_positions", {})
		var default_rect := Rect2(settings_button.position, Vector2(278.0, 92.0) if mobile_mode else Vector2(286.0, 96.0))
		var settings_panel_rect: Rect2 = hud_positions.get("settings_panel_rect", default_rect)
		settings_panel.position = settings_panel_rect.position
		settings_panel.size = settings_panel_rect.size

func _layout_bottom_hud(view_size: Vector2, mobile_mode: bool, current_layout: Dictionary = {}) -> void:
	var hud_positions: Dictionary = current_layout.get("hud_positions", {})
	var fps_bg_rect: Rect2 = hud_positions.get("fps_bg_rect", Rect2(Vector2(396.0, 652.0), Vector2(714.0, 30.0)))
	fps_bg.position = fps_bg_rect.position
	fps_bg.size = fps_bg_rect.size
	fps_bg.visible = not mobile_mode

	var fps_label_rect: Rect2 = hud_positions.get("fps_label_rect", Rect2(Vector2(402.0, 649.0), Vector2(702.0, 24.0)))
	fps_label.position = fps_label_rect.position
	fps_label.size = fps_label_rect.size
	fps_label.visible = not mobile_mode

	var default_event_rect := Rect2(
		Vector2(view_size.x - 272.0, view_size.y - 84.0),
		Vector2(260.0, 22.0) if mobile_mode else Vector2(332.0, 24.0)
	)
	var event_label_rect: Rect2 = hud_positions.get("event_label_rect", default_event_rect)
	event_label.position = event_label_rect.position
	event_label.size = event_label_rect.size

func _layout_pause_overlay(view_size: Vector2) -> void:
	pause_overlay.position = Vector2.ZERO
	pause_overlay.size = view_size
	var dimmer: ColorRect = pause_overlay.get_node("Dimmer") as ColorRect
	dimmer.size = view_size
	pause_panel.position = Vector2((view_size.x - pause_panel.size.x) * 0.5, (view_size.y - pause_panel.size.y) * 0.5)

func _apply_button_layout(button: Button, position_value: Vector2, size_value: Vector2) -> void:
	button.position = position_value
	button.size = size_value

func _try_attach_event_log(layout: Dictionary, view_size: Vector2, mobile_mode: bool) -> void:
	if has_node("EventLogLabel"):
		event_log_label = get_node("EventLogLabel") as RichTextLabel
		if is_instance_valid(event_log_label):
			return

	event_log_label = RichTextLabel.new()
	event_log_label.name = "EventLogLabel"
	event_log_label.process_mode = Node.PROCESS_MODE_ALWAYS
	event_log_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	event_log_label.scroll_active = false
	event_log_label.selection_enabled = false
	event_log_label.bbcode_enabled = true
	event_log_label.fit_content = true

	var hud_positions: Dictionary = layout.get("hud_positions", {})
	var event_log_rect: Rect2 = hud_positions.get("event_log_rect", Rect2(Vector2(view_size.x - 290.0 - 10.0, 106.0), Vector2(290.0, 230.0)))
	event_log_label.position = event_log_rect.position
	event_log_label.size = event_log_rect.size
	event_log_label.add_theme_font_size_override("normal_font_size", 11 if mobile_mode else 13)
	event_log_label.add_theme_color_override("default_color", Color(0.88, 0.92, 1.0, 0.94))
	event_log_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.5))
	event_log_label.add_theme_constant_override("shadow_offset_x", 1)
	event_log_label.add_theme_constant_override("shadow_offset_y", 1)
	event_log_label.add_theme_constant_override("shadow_size", 1)
	add_child(event_log_label)

	var btn_size: float = 18.0 if mobile_mode else 20.0
	event_log_toggle_btn = Button.new()
	event_log_toggle_btn.name = "EventLogToggle"
	event_log_toggle_btn.text = "◀"
	event_log_toggle_btn.position = Vector2(event_log_rect.position.x - btn_size - 2.0, event_log_rect.position.y + 4.0)
	event_log_toggle_btn.size = Vector2(btn_size, btn_size)
	event_log_toggle_btn.add_theme_font_size_override("font_size", 10 if mobile_mode else 12)
	event_log_toggle_btn.add_theme_color_override("font_color", Color(0.72, 0.82, 1.0))
	event_log_toggle_btn.add_theme_color_override("font_hover_color", Color.WHITE)
	event_log_toggle_btn.self_modulate = Color(0.06, 0.10, 0.18, 0.70)
	event_log_toggle_btn.tooltip_text = "显示/隐藏事件日志"
	event_log_toggle_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	event_log_toggle_btn.pressed.connect(_toggle_event_log)
	add_child(event_log_toggle_btn)

func _toggle_event_log() -> void:
	if event_log_label == null or not is_instance_valid(event_log_label):
		return
	var visible_now: bool = event_log_label.visible
	event_log_label.visible = not visible_now
	if event_log_toggle_btn != null and is_instance_valid(event_log_toggle_btn):
		event_log_toggle_btn.text = "▶" if event_log_label.visible else "◀"

func update_event_log(log_text: String) -> void:
	if event_log_label == null or not is_instance_valid(event_log_label):
		return
	event_log_label.text = log_text

func _load_settings_panel() -> void:
	var sp_path: String = "res://scenes/ui/SettingsPanel.tscn"
	if ResourceLoader.exists(sp_path):
		settings_panel = load(sp_path).instantiate()
		settings_panel.name = "SettingsPanel"
		add_child(settings_panel)
		print("[GameHUD] Loaded SettingsPanel.tscn")
	else:
		settings_panel = Panel.new()
		settings_panel.name = "SettingsPanel"
		settings_panel.visible = false
		settings_panel.process_mode = Node.PROCESS_MODE_ALWAYS
		settings_panel.self_modulate = Color(0.94, 0.97, 1.0, 0.96)
		settings_panel.size = Vector2(286.0, 96.0)
		add_child(settings_panel)
		print("[GameHUD] SettingsPanel.tscn not found, fallback to code-generated")

func _refresh_settings_panel_content(mobile_mode: bool) -> void:
	if settings_panel == null or not is_instance_valid(settings_panel):
		return

	var layout_name: String = "mobile_landscape" if mobile_mode else "desktop"
	if settings_panel.has_method("show_content"):
		settings_panel.show_content(GameConfig.get_quality_name(), layout_name)
		if settings_panel.has_method("hide_panel"):
			settings_panel.hide_panel()
		else:
			settings_panel.visible = false
		return

	if settings_panel.has_node("ContentLabel"):
		var content_label: Label = settings_panel.get_node("ContentLabel") as Label
		content_label.text = "Quality: %s\nLayout: %s\nNote: mobile uses larger action buttons, desktop keeps more HUD info." % [GameConfig.get_quality_name(), layout_name]
		settings_panel.visible = false

func _connect_if_available(button: Button, controller_ref, method_name: String) -> void:
	if button == null or controller_ref == null or not controller_ref.has_method(method_name):
		return
	var target := Callable(controller_ref, method_name)
	if not button.pressed.is_connected(target):
		button.pressed.connect(target)
