extends CanvasLayer
class_name CardfrontTutorialOverlay

const PlayerSettingsStoreClass = preload("res://scripts/PlayerSettingsStore.gd")

const VIEW_W: float = 1120.0
const VIEW_H: float = 720.0

const DIM_COLOR := Color(0.03, 0.06, 0.15, 0.75)
const FOCUS_BORDER_COLOR := Color(1.0, 1.0, 1.0, 0.60)
const FOCUS_BORDER_WIDTH: float = 2.0

const TOOLTIP_SIZE := Vector2(360.0, 160.0)
const TOOLTIP_GAP: float = 20.0

const PULSE_SPEED: float = 2.0
const PULSE_ALPHA_MIN: float = 0.30
const PULSE_ALPHA_MAX: float = 0.80

const STEP_DATA: Array[Dictionary] = [
	{
		"title": "① 资源栏",
		"text": "屏幕顶部显示的能量（⚡）和零件（⚙）是您的资源。\n能量和零件会随时间自动增长，用于打出各种卡牌。",
		"focus_rect": Rect2(440, 82, 240, 48),
	},
	{
		"title": "② 手牌栏",
		"text": "屏幕底部是您的手牌。点击一张卡牌将其选中，\n然后点击战场上的高亮区域来释放卡牌效果。",
		"focus_rect": Rect2(276, 562, 568, 158),
	},
	{
		"title": "③ 战场区域",
		"text": "选中卡牌后，战场上会高亮显示可以释放的区域。\n点击高亮格子即可释放效果，影响战局走向。",
		"focus_rect": Rect2(100, 150, 600, 400),
	},
]

var _current_step: int = 0
var _total_steps: int = STEP_DATA.size()
var _ui_time: float = 0.0
var _is_tutorial_active: bool = false

var _dim_top: ColorRect
var _dim_bottom: ColorRect
var _dim_left: ColorRect
var _dim_right: ColorRect
var _focus_highlight: ColorRect
var _tooltip_panel: Panel
var _tooltip_bg: ColorRect
var _accent_line: ColorRect
var _title_label: Label
var _text_label: Label
var _step_label: Label
var _next_button: Button
var _skip_button: Button


func _init() -> void:
	name = "CardfrontTutorialOverlay"
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS


func setup() -> void:
	_build_nodes()
	var settings := PlayerSettingsStoreClass.load_settings()
	var show_hint: bool = bool(settings.get("show_newbie_hint", true))
	var tutorial_done: bool = bool(settings.get("tutorial_completed", false))
	if show_hint and not tutorial_done:
		start_tutorial()
	else:
		queue_free()


func _build_nodes() -> void:
	for name_str in ["DimTop", "DimBottom", "DimLeft", "DimRight"]:
		var rect := ColorRect.new()
		rect.name = name_str
		rect.color = DIM_COLOR
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(rect)
	_dim_top = $DimTop
	_dim_bottom = $DimBottom
	_dim_left = $DimLeft
	_dim_right = $DimRight

	_focus_highlight = ColorRect.new()
	_focus_highlight.name = "FocusHighlight"
	_focus_highlight.color = FOCUS_BORDER_COLOR
	_focus_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_focus_highlight)

	_tooltip_panel = Panel.new()
	_tooltip_panel.name = "TooltipPanel"
	_tooltip_panel.size = TOOLTIP_SIZE
	_tooltip_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_tooltip_panel)

	_tooltip_bg = ColorRect.new()
	_tooltip_bg.name = "PanelBg"
	_tooltip_bg.color = Color(0.06, 0.09, 0.15, 0.96)
	_tooltip_bg.size = TOOLTIP_SIZE
	_tooltip_panel.add_child(_tooltip_bg)

	_accent_line = ColorRect.new()
	_accent_line.name = "AccentLine"
	_accent_line.color = Color(0.98, 0.76, 0.18, 0.55)
	_accent_line.position = Vector2(12.0, 4.0)
	_accent_line.size = Vector2(TOOLTIP_SIZE.x - 24.0, 2.0)
	_tooltip_panel.add_child(_accent_line)

	_title_label = Label.new()
	_title_label.name = "TitleLabel"
	_title_label.position = Vector2(16.0, 12.0)
	_title_label.size = Vector2(TOOLTIP_SIZE.x - 32.0, 24.0)
	_title_label.add_theme_font_size_override("font_size", 18)
	_title_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.72, 1.0))
	_tooltip_panel.add_child(_title_label)

	_text_label = Label.new()
	_text_label.name = "TextLabel"
	_text_label.position = Vector2(16.0, 40.0)
	_text_label.size = Vector2(TOOLTIP_SIZE.x - 32.0, 74.0)
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.add_theme_font_size_override("font_size", 13)
	_text_label.add_theme_color_override("font_color", Color(0.82, 0.90, 1.0, 1.0))
	_tooltip_panel.add_child(_text_label)

	_step_label = Label.new()
	_step_label.name = "StepLabel"
	_step_label.position = Vector2(16.0, TOOLTIP_SIZE.y - 38.0)
	_step_label.size = Vector2(80.0, 22.0)
	_step_label.add_theme_font_size_override("font_size", 12)
	_step_label.add_theme_color_override("font_color", Color(0.62, 0.68, 0.82, 1.0))
	_tooltip_panel.add_child(_step_label)

	_next_button = Button.new()
	_next_button.name = "NextButton"
	_next_button.position = Vector2(TOOLTIP_SIZE.x - 110.0, TOOLTIP_SIZE.y - 40.0)
	_next_button.size = Vector2(94.0, 28.0)
	_next_button.text = "下一步"
	_next_button.add_theme_font_size_override("font_size", 14)
	_next_button.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	_next_button.self_modulate = Color(0.24, 0.52, 0.92, 1.0)
	_next_button.pressed.connect(_on_next_pressed)
	_tooltip_panel.add_child(_next_button)

	_skip_button = Button.new()
	_skip_button.name = "SkipButton"
	_skip_button.position = Vector2(VIEW_W - 140.0, 16.0)
	_skip_button.size = Vector2(124.0, 28.0)
	_skip_button.text = "跳过 / 不再提示"
	_skip_button.add_theme_font_size_override("font_size", 12)
	_skip_button.add_theme_color_override("font_color", Color(0.62, 0.68, 0.82, 1.0))
	_skip_button.self_modulate = Color(0.34, 0.34, 0.54, 0.85)
	_skip_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_skip_button.pressed.connect(_on_skip_pressed)
	add_child(_skip_button)


func start_tutorial() -> void:
	_current_step = 0
	visible = true
	_is_tutorial_active = true
	_apply_step(_current_step)
	set_process(true)


func _apply_step(step_index: int) -> void:
	if step_index < 0 or step_index >= _total_steps:
		return
	var step: Dictionary = STEP_DATA[step_index]
	var focus: Rect2 = step["focus_rect"]

	_dim_top.position = Vector2(0.0, 0.0)
	_dim_top.size = Vector2(VIEW_W, focus.position.y)

	_dim_bottom.position = Vector2(0.0, focus.position.y + focus.size.y)
	_dim_bottom.size = Vector2(VIEW_W, VIEW_H - focus.position.y - focus.size.y)

	_dim_left.position = Vector2(0.0, focus.position.y)
	_dim_left.size = Vector2(focus.position.x, focus.size.y)

	_dim_right.position = Vector2(focus.position.x + focus.size.x, focus.position.y)
	_dim_right.size = Vector2(VIEW_W - focus.position.x - focus.size.x, focus.size.y)

	_focus_highlight.position = focus.position - Vector2(FOCUS_BORDER_WIDTH, FOCUS_BORDER_WIDTH)
	_focus_highlight.size = focus.size + Vector2(FOCUS_BORDER_WIDTH * 2.0, FOCUS_BORDER_WIDTH * 2.0)

	_position_tooltip(focus)

	_title_label.text = step["title"]
	_text_label.text = step["text"]
	_step_label.text = "%d / %d" % [step_index + 1, _total_steps]
	_next_button.text = "完成！" if step_index >= _total_steps - 1 else "下一步"


func _position_tooltip(focus: Rect2) -> void:
	var tooltip_x: float = (VIEW_W - TOOLTIP_SIZE.x) * 0.5
	var tooltip_y: float
	match _current_step:
		0:
			tooltip_y = focus.position.y + focus.size.y + TOOLTIP_GAP
		1:
			tooltip_y = focus.position.y - TOOLTIP_GAP - TOOLTIP_SIZE.y
		_:
			tooltip_y = VIEW_H - TOOLTIP_SIZE.y - 240.0
	_tooltip_panel.position = Vector2(tooltip_x, tooltip_y)


func _on_next_pressed() -> void:
	_current_step += 1
	if _current_step >= _total_steps:
		_complete_tutorial()
	else:
		_apply_step(_current_step)


func _on_skip_pressed() -> void:
	_complete_tutorial()


func _complete_tutorial() -> void:
	var settings := PlayerSettingsStoreClass.load_settings()
	settings["tutorial_completed"] = true
	PlayerSettingsStoreClass.save_settings(settings)
	_is_tutorial_active = false
	visible = false
	set_process(false)


func on_settings_changed(settings: Dictionary) -> void:
	var show_hint: bool = bool(settings.get("show_newbie_hint", true))
	if _is_tutorial_active and not show_hint:
		_is_tutorial_active = false
		visible = false
		set_process(false)
		var saved := PlayerSettingsStoreClass.load_settings()
		saved["tutorial_completed"] = true
		PlayerSettingsStoreClass.save_settings(saved)


func _process(delta: float) -> void:
	_ui_time += delta
	var pulse := PULSE_ALPHA_MIN + (PULSE_ALPHA_MAX - PULSE_ALPHA_MIN) * (0.5 + 0.5 * sin(_ui_time * PULSE_SPEED))
	_focus_highlight.modulate = Color(FOCUS_BORDER_COLOR.r, FOCUS_BORDER_COLOR.g, FOCUS_BORDER_COLOR.b, pulse)
