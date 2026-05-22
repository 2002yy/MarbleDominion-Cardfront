extends CanvasLayer
class_name CardfrontRegionInfoPanel

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const RegionControlCalculatorScript = preload("res://scripts/cardfront/regions/RegionControlCalculator.gd")
const RegionYieldCalculatorScript = preload("res://scripts/cardfront/economy/RegionYieldCalculator.gd")
const RegionTypeScript = preload("res://scripts/cardfront/regions/RegionType.gd")
const CardfrontUiAssetRegistryScript = preload("res://scripts/cardfront/ui/CardfrontUiAssetRegistry.gd")

var region_map = null
var battlefield = null

var _panel: Panel
var _title_label: Label
var _control_labels: Dictionary = {}
var _threshold_50: Label
var _threshold_80: Label
var _yield_label: Label
var _status_label: Label
var _no_region_label: Label

const PANEL_W: float = 220.0
const PANEL_H: float = 168.0
const MARGIN_RIGHT: float = 16.0
const MARGIN_TOP: float = 110.0


func _init() -> void:
	name = "CardfrontRegionInfoPanel"
	layer = 17


func setup(new_region_map, new_battlefield, mode_name: String) -> void:
	region_map = new_region_map
	battlefield = new_battlefield
	visible = CardfrontRulesScript.is_cardfront_mode(mode_name)
	if visible:
		_ensure_ui()
		_no_region_label.text = "鼠标移至区域上方"


func _ensure_ui() -> void:
	_panel = Panel.new()
	_panel.name = "RegionPanel"
	_panel.self_modulate = Color(0.06, 0.10, 0.18, 0.92)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_theme_stylebox_override("panel", CardfrontUiAssetRegistryScript.make_panel_style(
		"region_info_panel",
		Color(0.04, 0.07, 0.13, 0.95),
		Color(0.45, 0.78, 1.0, 0.45)
	))
	add_child(_panel)

	var bg := ColorRect.new()
	bg.name = "Bg"
	bg.color = Color(0.04, 0.07, 0.13, 0.62 if CardfrontUiAssetRegistryScript.has_asset("region_info_panel") else 0.95)
	_panel.add_child(bg)

	_title_label = _make_label(_panel, Vector2(12, 8), Vector2(196, 22), "", 14, Color(1.0, 0.95, 0.72))

	var y: float = 36.0
	for owner_id in [CardfrontRulesScript.PLAYER_FACTION, CardfrontRulesScript.AI_FACTION, CardfrontRulesScript.NEUTRAL_OWNER]:
		var owner_name := CardfrontRulesScript.owner_display_name(owner_id)
		var c := CardfrontRulesScript.owner_color(owner_id)
		var label := _make_label(_panel, Vector2(12, y), Vector2(196, 16), "", 11, c)
		_control_labels[owner_id] = label
		y += 17.0

	y += 4.0
	_threshold_50 = _make_label(_panel, Vector2(12, y), Vector2(196, 14), "", 10, Color(0.55, 0.65, 0.78))
	y += 15.0
	_threshold_80 = _make_label(_panel, Vector2(12, y), Vector2(196, 14), "", 10, Color(0.55, 0.65, 0.78))
	y += 15.0
	_yield_label = _make_label(_panel, Vector2(12, y), Vector2(196, 14), "", 10, Color(0.62, 0.90, 1.0))
	y += 15.0
	_status_label = _make_label(_panel, Vector2(12, y), Vector2(196, 14), "", 10, Color(0.88, 0.92, 1.0))

	_no_region_label = _make_label(_panel, Vector2(12, 60), Vector2(196, 30), "", 11, Color(0.45, 0.50, 0.60))


func update_for_cell(cell: Vector2i) -> void:
	if not visible or region_map == null:
		return
	if not region_map.has_method("is_inside") or not region_map.is_inside(cell):
		_show_empty()
		return
	var region_id: int = int(region_map.get_region_id(cell))
	if region_id < 0:
		_show_empty()
		return
	_update_panel(region_id)


func _update_panel(region_id: int) -> void:
	var region_type: String = region_map.get_region_type_by_id(region_id)
	var control: Dictionary = RegionControlCalculatorScript.calculate(region_map, battlefield, region_id)
	var player_pct: int = RegionControlCalculatorScript.get_owner_percent(control, CardfrontRulesScript.PLAYER_FACTION)
	var ai_pct: int = RegionControlCalculatorScript.get_owner_percent(control, CardfrontRulesScript.AI_FACTION)
	var neutral_pct: int = RegionControlCalculatorScript.get_owner_percent(control, CardfrontRulesScript.NEUTRAL_OWNER)
	var status: String = RegionControlCalculatorScript.get_region_status(control)
	var tier: int = RegionControlCalculatorScript.get_yield_tier(control, CardfrontRulesScript.PLAYER_FACTION)
	var yield_data: Dictionary = RegionYieldCalculatorScript.calculate_region_yield(region_map, battlefield, region_id, CardfrontRulesScript.PLAYER_FACTION)
	var yld: Dictionary = yield_data.get("yield", {})

	var type_name: String = _region_type_name(region_type)
	_title_label.text = "◆ %s" % type_name
	_title_label.add_theme_color_override("font_color", _region_type_color(region_type))

	_control_labels[CardfrontRulesScript.PLAYER_FACTION].text = "玩家 %d%%%s" % [player_pct, _bar(player_pct)]
	_control_labels[CardfrontRulesScript.AI_FACTION].text = "AI %d%%%s" % [ai_pct, _bar(ai_pct)]
	_control_labels[CardfrontRulesScript.NEUTRAL_OWNER].text = "中立 %d%%%s" % [neutral_pct, _bar(neutral_pct)]

	_threshold_50.text = "50%% %s" % ("✓ 已达成" if player_pct >= 50 else "✗ %d%%" % (50 - player_pct))
	_threshold_50.add_theme_color_override("font_color", Color(0.45, 0.80, 0.50) if player_pct >= 50 else Color(0.55, 0.50, 0.45))
	_threshold_80.text = "80%% %s" % ("✓ 已达成" if player_pct >= 80 else "✗ %d%%" % (80 - player_pct))
	_threshold_80.add_theme_color_override("font_color", Color(0.80, 0.72, 0.30) if player_pct >= 80 else Color(0.55, 0.50, 0.45))

	if int(yld.get("energy", 0)) > 0:
		_yield_label.text = "[T%d] 产出：+%d 能量/s" % [tier, int(yld.energy)]
		_yield_label.add_theme_color_override("font_color", Color(0.62, 0.90, 1.0))
	elif int(yld.get("parts", 0)) > 0:
		_yield_label.text = "[T%d] 产出：+%d 零件/s" % [tier, int(yld.parts)]
		_yield_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.36))
	else:
		_yield_label.text = "产出：无（实验室）"
		_yield_label.add_theme_color_override("font_color", Color(0.50, 0.50, 0.55))

	_status_label.text = "状态：%s" % _status_text(status)
	_status_label.add_theme_color_override("font_color", _status_color(status))

	_no_region_label.text = ""
	_panel.position = Vector2(_view_width() - PANEL_W - MARGIN_RIGHT, MARGIN_TOP)
	_panel.size = Vector2(PANEL_W, PANEL_H)
	var bg: ColorRect = _panel.get_node("Bg") as ColorRect
	bg.size = _panel.size


func _show_empty() -> void:
	_title_label.text = ""
	for label in _control_labels.values():
		label.text = ""
	_threshold_50.text = ""
	_threshold_80.text = ""
	_yield_label.text = ""
	_status_label.text = ""
	_no_region_label.text = "鼠标移至区域上方"
	_panel.position = Vector2(_view_width() - PANEL_W - MARGIN_RIGHT, MARGIN_TOP)
	_panel.size = Vector2(PANEL_W, PANEL_H)
	var bg: ColorRect = _panel.get_node("Bg") as ColorRect
	bg.size = _panel.size


func _make_label(parent: Node, pos: Vector2, sz: Vector2, text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = pos
	label.size = sz
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	var font = CardfrontUiAssetRegistryScript.load_font()
	if font != null:
		label.add_theme_font_override("font", font)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.4))
	label.add_theme_constant_override("outline_size", 1)
	parent.add_child(label)
	return label


func _bar(pct: int) -> String:
	var filled: int = clampi(floori(float(pct) / 5.0), 0, 20)
	var bar_str := ""
	for _i in range(filled):
		bar_str += "█"
	for _i in range(20 - filled):
		bar_str += "░"
	return " %s" % bar_str


func _region_type_name(rt: String) -> String:
	match rt:
		RegionTypeScript.ENERGY: return "能源区"
		RegionTypeScript.FACTORY: return "工厂区"
		RegionTypeScript.LAB: return "实验室"
		_: return "未知区域"


func _region_type_color(rt: String) -> Color:
	match rt:
		RegionTypeScript.ENERGY: return Color(0.35, 0.82, 1.0)
		RegionTypeScript.FACTORY: return Color(1.0, 0.64, 0.22)
		RegionTypeScript.LAB: return Color(0.72, 0.45, 1.0)
		_: return Color(0.60, 0.60, 0.65)


func _status_text(s: String) -> String:
	match s:
		RegionControlCalculatorScript.STATUS_CONTROLLED: return "稳定控制"
		RegionControlCalculatorScript.STATUS_INFLUENCED: return "优势控制"
		RegionControlCalculatorScript.STATUS_CONTESTED: return "争夺中"
		RegionControlCalculatorScript.STATUS_EMPTY: return "空置"
		_: return s


func _status_color(s: String) -> Color:
	match s:
		RegionControlCalculatorScript.STATUS_CONTROLLED: return Color(0.45, 0.85, 0.50)
		RegionControlCalculatorScript.STATUS_INFLUENCED: return Color(0.62, 0.90, 1.0)
		RegionControlCalculatorScript.STATUS_CONTESTED: return Color(1.0, 0.75, 0.34)
		RegionControlCalculatorScript.STATUS_EMPTY: return Color(0.50, 0.50, 0.55)
		_: return Color(0.80, 0.80, 0.80)


func _view_width() -> float:
	var vp = get_viewport()
	if vp != null:
		return vp.get_visible_rect().size.x
	return 1120.0
