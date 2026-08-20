extends CanvasLayer
class_name CardfrontRegionInfoPanel

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const RegionControlCalculatorScript = preload("res://scripts/cardfront/regions/RegionControlCalculator.gd")
const RegionTypeScript = preload("res://scripts/cardfront/regions/RegionType.gd")
const CardfrontUiAssetRegistryScript = preload("res://scripts/cardfront/ui/CardfrontUiAssetRegistry.gd")
const StrongholdRulesScript = preload("res://scripts/cardfront/strongholds/CardfrontStrongholdRules.gd")

var region_map = null
var battlefield = null
var territory_defense_system = null
var stronghold_system = null
var layout: Dictionary = {}
var arena_view = null

var _panel: Panel
var _title_label: Label
var _control_labels: Dictionary = {}
var _threshold_50: Label
var _threshold_80: Label
var _stronghold_label: Label
var _yield_label: Label
var _status_label: Label
var _no_region_label: Label
var _pinned_region_id: int = -1

const PANEL_W: float = 184.0
const PANEL_H: float = 190.0
const RIGHT_TOOL_RAIL_W: float = 86.0
const MARGIN_RIGHT: float = 8.0
const MARGIN_TOP: float = 104.0
const CONTENT_X: float = 11.0
const CONTENT_W: float = PANEL_W - CONTENT_X * 2.0


func _init() -> void:
	name = "CardfrontRegionInfoPanel"
	layer = 17


func setup(new_region_map, new_battlefield, mode_name: String, new_territory_defense_system = null, new_stronghold_system = null, new_layout: Dictionary = {}, new_arena_view = null) -> void:
	region_map = new_region_map
	battlefield = new_battlefield
	territory_defense_system = new_territory_defense_system
	stronghold_system = new_stronghold_system
	layout = new_layout.duplicate(true)
	arena_view = new_arena_view
	visible = CardfrontRulesScript.is_cardfront_mode(mode_name)
	if visible:
		_ensure_ui()
		_show_empty()
		_no_region_label.text = "鼠标移至区域上方"


func _ensure_ui() -> void:
	_panel = Panel.new()
	_panel.name = "RegionPanel"
	_panel.self_modulate = Color(0.13, 0.22, 0.34, 0.98)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_theme_stylebox_override("panel", CardfrontUiAssetRegistryScript.make_panel_style(
		"region_info_panel",
		Color(0.06, 0.11, 0.19, 0.98),
		Color(0.66, 0.92, 1.0, 0.82)
	))
	add_child(_panel)

	var bg := ColorRect.new()
	bg.name = "Bg"
	bg.color = Color(0.05, 0.10, 0.18, 0.86 if CardfrontUiAssetRegistryScript.has_asset("region_info_panel") else 0.98)
	_panel.add_child(bg)

	_title_label = _make_label(_panel, Vector2(CONTENT_X, 7), Vector2(CONTENT_W, 23), "", 16, Color(1.0, 0.97, 0.76))

	var y: float = 34.0
	for owner_id in [CardfrontRulesScript.PLAYER_FACTION, CardfrontRulesScript.AI_FACTION, CardfrontRulesScript.NEUTRAL_OWNER]:
		var c := CardfrontRulesScript.owner_color(owner_id)
		if owner_id == CardfrontRulesScript.NEUTRAL_OWNER:
			c = Color(0.78, 0.84, 0.92)
		var label := _make_label(_panel, Vector2(CONTENT_X, y), Vector2(CONTENT_W, 18), "", 13, c)
		_control_labels[owner_id] = label
		y += 19.0

	y += 2.0
	_threshold_50 = _make_label(_panel, Vector2(CONTENT_X, y), Vector2(CONTENT_W, 17), "", 12, Color(0.78, 0.86, 0.96))
	y += 18.0
	_threshold_80 = _make_label(_panel, Vector2(CONTENT_X, y), Vector2(CONTENT_W, 17), "", 12, Color(0.78, 0.86, 0.96))
	y += 18.0
	_stronghold_label = _make_label(_panel, Vector2(CONTENT_X, y), Vector2(CONTENT_W, 17), "", 12, Color(1.0, 0.82, 0.32))
	y += 18.0
	_yield_label = _make_label(_panel, Vector2(CONTENT_X, y), Vector2(CONTENT_W, 17), "", 12, Color(0.72, 0.94, 1.0))
	y += 18.0
	_status_label = _make_label(_panel, Vector2(CONTENT_X, y), Vector2(CONTENT_W, 17), "", 12, Color(0.94, 0.97, 1.0))

	_no_region_label = _make_label(_panel, Vector2(CONTENT_X, 55), Vector2(CONTENT_W, 28), "", 11, Color(0.74, 0.82, 0.92))


func update_for_cell(cell: Vector2i) -> void:
	if not visible or region_map == null:
		return
	if _pinned_region_id >= 0:
		_update_panel(_pinned_region_id)
		return
	var region_id: int = _region_id_for_cell(cell)
	if region_id < 0:
		_show_empty()
		return
	_update_panel(region_id)


func toggle_pinned_cell(cell: Vector2i) -> bool:
	var region_id: int = _region_id_for_cell(cell)
	if region_id < 0:
		clear_pinned_region()
		return false
	if _pinned_region_id == region_id:
		clear_pinned_region()
		return false
	_pinned_region_id = region_id
	_update_panel(region_id)
	return true


func clear_pinned_region() -> void:
	_pinned_region_id = -1


func is_region_pinned_for_test() -> bool:
	return _pinned_region_id >= 0


func get_pinned_region_id_for_test() -> int:
	return _pinned_region_id


func _region_id_for_cell(cell: Vector2i) -> int:
	if not region_map.has_method("is_inside") or not region_map.is_inside(cell):
		return -1
	var region_id: int = int(region_map.get_region_id(cell))
	if region_id < 0:
		return -1
	if region_map.has_method("get_controllable_region_ids"):
		var controllable_ids: Array = region_map.get_controllable_region_ids()
		if not controllable_ids.has(region_id):
			return -1
	return region_id


func _update_panel(region_id: int) -> void:
	_panel.visible = true
	var region_type: String = region_map.get_region_type_by_id(region_id)
	var control: Dictionary = RegionControlCalculatorScript.calculate(region_map, battlefield, region_id)
	var player_pct: int = RegionControlCalculatorScript.get_owner_percent(control, CardfrontRulesScript.PLAYER_FACTION)
	var ai_pct: int = RegionControlCalculatorScript.get_owner_percent(control, CardfrontRulesScript.AI_FACTION)
	var neutral_pct: int = RegionControlCalculatorScript.get_owner_percent(control, CardfrontRulesScript.NEUTRAL_OWNER)
	var status: String = RegionControlCalculatorScript.get_region_status(control)
	var leader_owner: int = _leading_owner(player_pct, ai_pct, neutral_pct)

	var type_name: String = _region_type_name(region_type)
	_title_label.text = "◆ %s%s" % [type_name, " · 固定" if _pinned_region_id == region_id else ""]
	_title_label.add_theme_color_override("font_color", _region_type_color(region_type))

	_control_labels[CardfrontRulesScript.PLAYER_FACTION].text = "玩家　%d%%" % player_pct
	_control_labels[CardfrontRulesScript.AI_FACTION].text = "AI　%d%%" % ai_pct
	_control_labels[CardfrontRulesScript.NEUTRAL_OWNER].text = "中立　%d%%" % neutral_pct

	_threshold_50.text = "过半控制：%s" % ("已达成" if player_pct >= 50 else "还差%d%%" % (50 - player_pct))
	_threshold_50.add_theme_color_override("font_color", Color(0.45, 0.80, 0.50) if player_pct >= 50 else Color(0.80, 0.72, 0.58))
	# P0-05B3: 80% remains a real control/status threshold, but it no longer
	# promises a Factory/Energy/Lab numeric ability.
	_threshold_80.text = "据点控制：%s" % ("已达成" if player_pct >= StrongholdRulesScript.ACTIVATION_PERCENT else "还差%d%%" % (StrongholdRulesScript.ACTIVATION_PERCENT - player_pct))
	_threshold_80.add_theme_color_override("font_color", Color(0.90, 0.80, 0.34) if player_pct >= StrongholdRulesScript.ACTIVATION_PERCENT else Color(0.80, 0.72, 0.58))
	var active_owner: int = leader_owner if maxi(player_pct, ai_pct) >= StrongholdRulesScript.ACTIVATION_PERCENT else CardfrontRulesScript.NEUTRAL_OWNER
	var sampled: Dictionary = {}
	if stronghold_system != null and is_instance_valid(stronghold_system):
		sampled = stronghold_system.get_region_activation(region_id)
	if bool(sampled.get("active", false)):
		var sampled_owner: int = int(sampled.get("owner_id", CardfrontRulesScript.NEUTRAL_OWNER))
		_stronghold_label.text = "据点状态：有效控制 · %s" % CardfrontRulesScript.owner_display_name(sampled_owner)
		_stronghold_label.add_theme_color_override("font_color", CardfrontRulesScript.owner_color(sampled_owner).lightened(0.30))
	elif active_owner == CardfrontRulesScript.NEUTRAL_OWNER:
		_stronghold_label.text = "据点状态：未达阈值"
		_stronghold_label.add_theme_color_override("font_color", Color(0.74, 0.78, 0.86))
	else:
		_stronghold_label.text = "据点状态：待本轮刷新 · %s" % CardfrontRulesScript.owner_display_name(active_owner)
		_stronghold_label.add_theme_color_override("font_color", CardfrontRulesScript.owner_color(active_owner).lightened(0.30))

	if leader_owner == CardfrontRulesScript.NEUTRAL_OWNER:
		_yield_label.text = "阵地防守：中立无护盾"
		_yield_label.add_theme_color_override("font_color", Color(0.62, 0.68, 0.76))
	elif territory_defense_system != null and is_instance_valid(territory_defense_system):
		var defense: Dictionary = territory_defense_system.get_region_defense_summary(region_id, leader_owner)
		_yield_label.text = "阵地防守：%.1f / 上限 %d" % [
			float(defense.get("average", 0.0)),
			int(defense.get("cap", 0)),
		]
		_yield_label.add_theme_color_override("font_color", CardfrontRulesScript.owner_color(leader_owner).lightened(0.25))
	else:
		_yield_label.text = "阵地防守：等待下一轮补充"
		_yield_label.add_theme_color_override("font_color", Color(0.50, 0.50, 0.55))

	_status_label.text = "状态：%s" % _status_text(status)
	_status_label.add_theme_color_override("font_color", _status_color(status))

	_no_region_label.text = ""
	_panel.position = Vector2(_panel_x(), MARGIN_TOP)
	_panel.size = Vector2(PANEL_W, PANEL_H)
	var bg: ColorRect = _panel.get_node("Bg") as ColorRect
	bg.size = _panel.size


func _show_empty() -> void:
	if _panel != null:
		_panel.visible = false
	_title_label.text = ""
	for label in _control_labels.values():
		label.text = ""
	_threshold_50.text = ""
	_threshold_80.text = ""
	_stronghold_label.text = ""
	_yield_label.text = ""
	_status_label.text = ""
	_no_region_label.text = "鼠标移至区域上方"
	_panel.position = Vector2(_panel_x(), MARGIN_TOP)
	_panel.size = Vector2(PANEL_W, PANEL_H)
	var bg: ColorRect = _panel.get_node("Bg") as ColorRect
	bg.size = _panel.size


func _panel_x() -> float:
	if arena_view != null and is_instance_valid(arena_view) and arena_view.has_method("get_playable_screen_rect_for_ui"):
		var playable_rect: Rect2 = arena_view.get_playable_screen_rect_for_ui()
		if playable_rect.size.x > 0.0:
			return minf(playable_rect.end.x + 10.0, _view_width() - PANEL_W - MARGIN_RIGHT)
	var battlefield_rect: Rect2 = layout.get("battlefield_rect", Rect2())
	if battlefield_rect.size.x > 0.0:
		return minf(battlefield_rect.end.x + 10.0, _view_width() - PANEL_W - MARGIN_RIGHT)
	if battlefield != null and is_instance_valid(battlefield):
		var battlefield_right: float = battlefield.global_position.x + battlefield.get_pixel_extent().x
		return minf(battlefield_right + 10.0, _view_width() - PANEL_W - MARGIN_RIGHT)
	return _view_width() - PANEL_W - RIGHT_TOOL_RAIL_W - MARGIN_RIGHT


func _make_label(parent: Node, pos: Vector2, sz: Vector2, text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = pos
	label.size = sz
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	CardfrontUiAssetRegistryScript.apply_body_font(label)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.68))
	label.add_theme_constant_override("outline_size", 2)
	parent.add_child(label)
	return label


func _region_type_name(rt: String) -> String:
	match rt:
		RegionTypeScript.ENERGY: return StrongholdRulesScript.display_name(rt)
		RegionTypeScript.FACTORY: return StrongholdRulesScript.display_name(rt)
		RegionTypeScript.LAB: return StrongholdRulesScript.display_name(rt)
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


func _leading_owner(player_pct: int, ai_pct: int, neutral_pct: int) -> int:
	if player_pct >= ai_pct and player_pct >= neutral_pct:
		return CardfrontRulesScript.PLAYER_FACTION
	if ai_pct >= player_pct and ai_pct >= neutral_pct:
		return CardfrontRulesScript.AI_FACTION
	return CardfrontRulesScript.NEUTRAL_OWNER


func _view_width() -> float:
	var vp = get_viewport()
	if vp != null:
		return vp.get_visible_rect().size.x
	return 1120.0
