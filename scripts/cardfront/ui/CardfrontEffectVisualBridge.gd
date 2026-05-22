extends Node
class_name CardfrontEffectVisualBridge

var feedback_bus = null
var vfx_layer = null


func _init() -> void:
	name = "CardfrontEffectVisualBridge"


func setup(new_feedback_bus, new_vfx_layer) -> void:
	feedback_bus = new_feedback_bus
	vfx_layer = new_vfx_layer
	if feedback_bus == null:
		return
	var c := Callable(self, "_on_card_play_succeeded")
	if feedback_bus.has_signal("card_play_succeeded") and not feedback_bus.card_play_succeeded.is_connected(c):
		feedback_bus.card_play_succeeded.connect(c)


func _on_card_play_succeeded(_card_id: int, card_data: Dictionary, result: Dictionary) -> void:
	if vfx_layer == null or not is_instance_valid(vfx_layer):
		return
	var effect_id: String = str(card_data.get("effect_id", result.get("effect_id", "")))
	var target_cell: Vector2i = result.get("target_cell", Vector2i.ZERO)
	var target_region_id: int = int(result.get("target_region_id", -1))
	match effect_id:
		"fortify_border":
			_play_if_available("play_shield_pulse", [target_cell])
		"calibrated_shot", "morale_fluctuation":
			if target_region_id < 0:
				target_region_id = _region_id_for_cell(target_cell)
			_play_if_available("play_region_pulse", [target_region_id])
		"pioneer_beacon_lite":
			_play_if_available("play_energy_ripple", [target_cell])


func _play_if_available(method_name: String, args: Array) -> void:
	if vfx_layer == null or not is_instance_valid(vfx_layer):
		return
	if not vfx_layer.has_method(method_name):
		return
	vfx_layer.callv(method_name, args)


func _region_id_for_cell(cell: Vector2i) -> int:
	if vfx_layer == null or not is_instance_valid(vfx_layer):
		return -1
	var rm = vfx_layer.get("region_map")
	if rm == null or not rm.has_method("get_region_id"):
		return -1
	if rm.has_method("is_inside") and not rm.is_inside(cell):
		return -1
	return int(rm.get_region_id(cell))
