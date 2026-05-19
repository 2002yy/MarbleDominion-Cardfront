extends CanvasLayer
class_name CardfrontEconomyDebugPanel

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const RegionControlCalculatorScript = preload("res://scripts/cardfront/regions/RegionControlCalculator.gd")
const RegionTypeScript = preload("res://scripts/cardfront/regions/RegionType.gd")
const RegionYieldCalculatorScript = preload("res://scripts/cardfront/economy/RegionYieldCalculator.gd")

const MAX_REGION_LINES: int = 3

var region_map = null
var battlefield = null
var economy_system = null
var resource_states: Dictionary = {}
var refresh_interval: float = 0.25
var _refresh_elapsed: float = 0.0
var _panel: Panel = null
var _label: Label = null


func _init() -> void:
	name = "CardfrontEconomyDebugPanel"
	layer = 18


func setup(new_region_map, new_battlefield, new_economy_system, new_resource_states: Dictionary, mode_name: String) -> void:
	region_map = new_region_map
	battlefield = new_battlefield
	economy_system = new_economy_system
	resource_states = new_resource_states.duplicate(false)
	visible = CardfrontRulesScript.is_cardfront_mode(mode_name)
	_ensure_ui()
	_connect_economy_signals()
	_refresh_text()
	set_process(visible)


func _process(delta: float) -> void:
	if not visible:
		return
	_refresh_elapsed += maxf(0.0, delta)
	if _refresh_elapsed >= refresh_interval:
		_refresh_elapsed = 0.0
		_refresh_text()


func mark_dirty() -> void:
	_refresh_elapsed = refresh_interval
	_refresh_text()


func get_debug_text() -> String:
	return _label.text if _label != null else ""


func _ensure_ui() -> void:
	if _panel != null:
		return
	_panel = Panel.new()
	_panel.name = "EconomyDebugPanel"
	_panel.position = Vector2(8.0, 118.0)
	_panel.size = Vector2(260.0, 150.0)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.z_index = 100
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.06, 0.09, 0.58)
	style.border_color = Color(0.42, 0.80, 1.0, 0.60)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	_label = Label.new()
	_label.name = "EconomyDebugLabel"
	_label.position = Vector2(8.0, 6.0)
	_label.size = Vector2(244.0, 138.0)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_size_override("font_size", 12)
	_label.add_theme_color_override("font_color", Color(0.88, 0.95, 1.0, 0.96))
	_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.55))
	_label.add_theme_constant_override("outline_size", 2)
	_panel.add_child(_label)


func _connect_economy_signals() -> void:
	if economy_system == null or not is_instance_valid(economy_system):
		return
	var resource_callable := Callable(self, "_on_resources_changed")
	if not economy_system.resources_changed.is_connected(resource_callable):
		economy_system.resources_changed.connect(resource_callable)
	var yield_callable := Callable(self, "_on_yield_tick")
	if not economy_system.yield_tick.is_connected(yield_callable):
		economy_system.yield_tick.connect(yield_callable)


func _on_resources_changed(_owner_id: int, _snapshot: Dictionary) -> void:
	mark_dirty()


func _on_yield_tick(_owner_id: int, _yield_data: Dictionary) -> void:
	mark_dirty()


func _refresh_text() -> void:
	_ensure_ui()
	if _label == null:
		return
	if not visible:
		_label.text = ""
		return

	var player_state = resource_states.get(CardfrontRulesScript.PLAYER_FACTION, null)
	var energy: int = int(player_state.energy) if player_state != null else 0
	var parts: int = int(player_state.parts) if player_state != null else 0
	var lines: Array[String] = [
		"能量：%d" % energy,
		"零件：%d" % parts,
		_format_tick_summary(),
	]

	for region_id in _get_key_region_ids():
		lines.append(_format_region_line(int(region_id)))
	_label.text = "\n".join(lines)


func _format_tick_summary() -> String:
	if region_map == null or battlefield == null:
		return "本tick：无产出"
	var player_yield: Dictionary = RegionYieldCalculatorScript.calculate_for_owner(region_map, battlefield, CardfrontRulesScript.PLAYER_FACTION).get("total_yield", {})
	var ai_yield: Dictionary = RegionYieldCalculatorScript.calculate_for_owner(region_map, battlefield, CardfrontRulesScript.AI_FACTION).get("total_yield", {})
	return "本tick：玩家 %s｜AI %s" % [_yield_summary(player_yield), _yield_summary(ai_yield)]


func _yield_summary(yield_data: Dictionary) -> String:
	var parts: Array[String] = []
	var energy: int = int(yield_data.get("energy", 0))
	var part_count: int = int(yield_data.get("parts", 0))
	if energy > 0:
		parts.append("+%d能量" % energy)
	if part_count > 0:
		parts.append("+%d零件" % part_count)
	if parts.is_empty():
		return "无产出"
	return " ".join(parts)


func _get_key_region_ids() -> Array[int]:
	var selected: Array[int] = []
	if region_map == null or battlefield == null:
		return selected
	var scored: Array[Dictionary] = []
	for raw_region_id in region_map.get_controllable_region_ids():
		var region_id: int = int(raw_region_id)
		scored.append({
			"region_id": region_id,
			"score": _score_region(region_id),
		})
	scored.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.get("score", 0)) == int(b.get("score", 0)):
			return int(a.get("region_id", 0)) < int(b.get("region_id", 0))
		return int(a.get("score", 0)) > int(b.get("score", 0))
	)
	for item in scored:
		if selected.size() >= MAX_REGION_LINES:
			break
		selected.append(int(item.get("region_id", -1)))
	return selected


func _score_region(region_id: int) -> int:
	var control: Dictionary = RegionControlCalculatorScript.calculate(region_map, battlefield, region_id)
	var player_percent: int = RegionControlCalculatorScript.get_owner_percent(control, CardfrontRulesScript.PLAYER_FACTION)
	var ai_percent: int = RegionControlCalculatorScript.get_owner_percent(control, CardfrontRulesScript.AI_FACTION)
	var player_detail: Dictionary = RegionYieldCalculatorScript.calculate_region_yield(region_map, battlefield, region_id, CardfrontRulesScript.PLAYER_FACTION)
	var ai_detail: Dictionary = RegionYieldCalculatorScript.calculate_region_yield(region_map, battlefield, region_id, CardfrontRulesScript.AI_FACTION)
	var best_tier: int = maxi(int(player_detail.get("yield_tier", 0)), int(ai_detail.get("yield_tier", 0)))
	return best_tier * 100 + maxi(player_percent, ai_percent) + _type_priority(region_map.get_region_type_by_id(region_id))


func _type_priority(region_type: String) -> int:
	match region_type:
		RegionTypeScript.LAB:
			return 18
		RegionTypeScript.ENERGY, RegionTypeScript.FACTORY:
			return 10
		_:
			return 0


func _format_region_line(region_id: int) -> String:
	var region_type: String = region_map.get_region_type_by_id(region_id)
	var control: Dictionary = RegionControlCalculatorScript.calculate(region_map, battlefield, region_id)
	var player_percent: int = RegionControlCalculatorScript.get_owner_percent(control, CardfrontRulesScript.PLAYER_FACTION)
	var ai_percent: int = RegionControlCalculatorScript.get_owner_percent(control, CardfrontRulesScript.AI_FACTION)
	var label: String = _region_display_name(region_type, region_id)
	var owner_text: String = _owner_control_text(player_percent, ai_percent)
	var yield_text: String = _region_yield_text(region_id, player_percent, ai_percent)
	return "%s：%s｜%s" % [label, owner_text, yield_text]


func _owner_control_text(player_percent: int, ai_percent: int) -> String:
	if player_percent > ai_percent and player_percent > 0:
		return "玩家 %d%%" % player_percent
	if ai_percent > player_percent and ai_percent > 0:
		return "AI %d%%" % ai_percent
	return "中立争夺"


func _region_yield_text(region_id: int, player_percent: int, ai_percent: int) -> String:
	if region_map.get_region_type_by_id(region_id) == RegionTypeScript.LAB:
		return "暂不产出"
	var player_detail: Dictionary = RegionYieldCalculatorScript.calculate_region_yield(region_map, battlefield, region_id, CardfrontRulesScript.PLAYER_FACTION)
	var ai_detail: Dictionary = RegionYieldCalculatorScript.calculate_region_yield(region_map, battlefield, region_id, CardfrontRulesScript.AI_FACTION)
	var player_yield: Dictionary = player_detail.get("yield", {})
	var ai_yield: Dictionary = ai_detail.get("yield", {})
	if player_percent > ai_percent:
		return _yield_text_for_owner(player_yield, "")
	if ai_percent > player_percent:
		return _yield_text_for_owner(ai_yield, "AI ")
	return "无产出"


func _yield_text_for_owner(yield_data: Dictionary, prefix: String) -> String:
	var energy: int = int(yield_data.get("energy", 0))
	var parts: int = int(yield_data.get("parts", 0))
	if energy <= 0 and parts <= 0:
		return "无产出"
	if energy > 0:
		return "%s+%d 能量/s" % [prefix, energy]
	return "%s+%d 零件/s" % [prefix, parts]


func _region_display_name(region_type: String, region_id: int) -> String:
	match region_type:
		RegionTypeScript.ENERGY:
			return "能源区#%d" % region_id
		RegionTypeScript.FACTORY:
			return "工厂区#%d" % region_id
		RegionTypeScript.LAB:
			return "实验室#%d" % region_id
		_:
			return "区域#%d" % region_id
