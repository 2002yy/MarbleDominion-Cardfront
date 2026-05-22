extends CanvasLayer
class_name CardfrontTopResourceBar

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const CardfrontUiAssetRegistryScript = preload("res://scripts/cardfront/ui/CardfrontUiAssetRegistry.gd")

var resource_states: Dictionary = {}
var economy_system = null
var last_energy: int = -1
var last_parts: int = -1
var _release_mode_override_for_test: int = -1

@onready var _energy_value: Label = $Margin/HBox/EnergyBox/Margin2/Inner/Value
@onready var _parts_value: Label = $Margin/HBox/PartsBox/Margin2/Inner/Value
@onready var _debug_hint: Label = $DebugHint
@onready var _energy_icon: TextureRect = $Margin/HBox/EnergyBox/Margin2/Inner/EnergyIcon
@onready var _parts_icon: TextureRect = $Margin/HBox/PartsBox/Margin2/Inner/PartsIcon
@onready var _energy_symbol: Label = $Margin/HBox/EnergyBox/Margin2/Inner/EnergySymbol
@onready var _parts_symbol: Label = $Margin/HBox/PartsBox/Margin2/Inner/PartsSymbol


func setup(new_economy_system, new_resource_states: Dictionary, mode_name: String) -> void:
	economy_system = new_economy_system
	resource_states = new_resource_states.duplicate(false)
	visible = CardfrontRulesScript.is_cardfront_mode(mode_name)
	_update_debug_hint(mode_name)
	if not visible:
		return
	_apply_art_assets()
	_connect_economy_signals()
	refresh(true)


func _connect_economy_signals() -> void:
	if economy_system == null:
		return
	var c := Callable(self, "_on_resources_changed")
	if economy_system.has_signal("resources_changed") and not economy_system.resources_changed.is_connected(c):
		economy_system.resources_changed.connect(c)


func _on_resources_changed(owner_id: int, _snapshot: Dictionary) -> void:
	if int(owner_id) != CardfrontRulesScript.PLAYER_FACTION:
		return
	refresh()


func refresh(force: bool = false) -> void:
	var state = resource_states.get(CardfrontRulesScript.PLAYER_FACTION, null)
	if state == null:
		return
	var e := int(state.energy)
	var p := int(state.parts)
	if force or e != last_energy:
		if _energy_value != null and is_instance_valid(_energy_value):
			_energy_value.text = str(e)
		last_energy = e
	if force or p != last_parts:
		if _parts_value != null and is_instance_valid(_parts_value):
			_parts_value.text = str(p)
		last_parts = p


func set_release_mode_override_for_test(is_release: bool) -> void:
	_release_mode_override_for_test = 1 if is_release else 0


func is_debug_hint_visible_for_test() -> bool:
	return _debug_hint != null and is_instance_valid(_debug_hint) and _debug_hint.visible


func get_debug_hint_text_for_test() -> String:
	if _debug_hint == null or not is_instance_valid(_debug_hint):
		return ""
	return _debug_hint.text


func _update_debug_hint(mode_name: String) -> void:
	if _debug_hint == null or not is_instance_valid(_debug_hint):
		return
	_debug_hint.visible = CardfrontRulesScript.is_cardfront_mode(mode_name) and not _is_release_build()


func _is_release_build() -> bool:
	if _release_mode_override_for_test >= 0:
		return _release_mode_override_for_test == 1
	return OS.has_feature("release")


func _apply_art_assets() -> void:
	var style_energy = CardfrontUiAssetRegistryScript.make_panel_style(
		"resource_panel_bg",
		Color(0.04, 0.07, 0.13, 0.95),
		Color(0.35, 0.72, 1.0, 0.35)
	)
	var style_parts = CardfrontUiAssetRegistryScript.make_panel_style(
		"resource_panel_bg",
		Color(0.04, 0.07, 0.13, 0.95),
		Color(1.0, 0.82, 0.36, 0.35)
	)
	var energy_box = get_node_or_null("Margin/HBox/EnergyBox")
	if energy_box is Panel:
		(energy_box as Panel).add_theme_stylebox_override("panel", style_energy)
	var parts_box = get_node_or_null("Margin/HBox/PartsBox")
	if parts_box is Panel:
		(parts_box as Panel).add_theme_stylebox_override("panel", style_parts)
	if CardfrontUiAssetRegistryScript.has_asset("resource_panel_bg"):
		for bg_path in ["Margin/HBox/EnergyBox/Bg", "Margin/HBox/PartsBox/Bg"]:
			var bg = get_node_or_null(bg_path)
			if bg is ColorRect:
				(bg as ColorRect).color = Color(0.04, 0.07, 0.13, 0.44)
	var font = CardfrontUiAssetRegistryScript.load_font()
	if font != null:
		for label_path in [
			"Margin/HBox/EnergyBox/Margin2/Inner/EnergySymbol",
			"Margin/HBox/EnergyBox/Margin2/Inner/Value",
			"Margin/HBox/PartsBox/Margin2/Inner/PartsSymbol",
			"Margin/HBox/PartsBox/Margin2/Inner/Value",
			"DebugHint",
		]:
			var label = get_node_or_null(label_path)
			if label is Label:
				(label as Label).add_theme_font_override("font", font)
	_apply_icon(_energy_icon, _energy_symbol, "icon_energy")
	_apply_icon(_parts_icon, _parts_symbol, "icon_parts")


func _apply_icon(tex_rect: TextureRect, symbol_label: Label, asset_id: String) -> void:
	if tex_rect == null or not is_instance_valid(tex_rect):
		return
	if symbol_label == null or not is_instance_valid(symbol_label):
		return
	var tex = CardfrontUiAssetRegistryScript.load_texture(asset_id)
	if tex != null:
		tex_rect.texture = tex
		tex_rect.visible = true
		symbol_label.visible = false
	else:
		tex_rect.visible = false
		symbol_label.visible = true
