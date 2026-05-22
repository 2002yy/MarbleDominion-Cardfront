extends RefCounted
class_name CardfrontCardSelectionController

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const CardPlayRequestScript = preload("res://scripts/cardfront/cards/CardPlayRequest.gd")

var card_system = null
var resource_states: Dictionary = {}
var hand_panel = null
var resource_bar = null
var target_preview = null
var feedback_bus = null
var selected_card_id: int = -1
var selected_card_data: Dictionary = {}


func setup(new_card_system, new_resource_states: Dictionary, new_hand_panel, new_resource_bar, new_target_preview = null, new_feedback_bus = null) -> void:
	card_system = new_card_system
	resource_states = new_resource_states.duplicate(false)
	hand_panel = new_hand_panel
	resource_bar = new_resource_bar
	target_preview = new_target_preview
	feedback_bus = new_feedback_bus


func on_card_clicked(card_id: int, card_data: Dictionary) -> void:
	if card_id == selected_card_id:
		clear_selection()
		return
	if selected_card_id >= 0 and feedback_bus != null and feedback_bus.has_method("emit_card_deselected"):
		feedback_bus.emit_card_deselected(selected_card_id, selected_card_data)
	selected_card_id = card_id
	selected_card_data = card_data.duplicate(false)
	if hand_panel != null:
		hand_panel.set_card_selected(card_id)
	if target_preview != null:
		target_preview.show_for_card(card_id, card_data)
	if feedback_bus != null and feedback_bus.has_method("emit_card_selected"):
		feedback_bus.emit_card_selected(selected_card_id, selected_card_data)


func on_battlefield_clicked(cell: Vector2i) -> Dictionary:
	if selected_card_id < 0:
		return {"success": false, "reason": "no_card_selected"}
	if target_preview != null and target_preview.is_valid_target(cell):
		var region_id: int = target_preview.get_target_region_id(cell)
		return on_target_selected(cell, region_id)
	return _invalid_target_feedback(cell)


func on_target_selected(target_cell: Vector2i, target_region_id: int) -> Dictionary:
	if selected_card_id < 0:
		var no_card_result := {"success": false, "reason": "no_card_selected", "target_cell": target_cell, "target_region_id": target_region_id}
		_emit_play_failed(-1, {}, no_card_result)
		return no_card_result
	if card_system == null:
		var missing_result := _make_play_payload(false, "missing_card_system", "", target_cell, target_region_id)
		_emit_play_failed(selected_card_id, selected_card_data, missing_result)
		return missing_result

	var play_card_id: int = selected_card_id
	var play_card_data: Dictionary = selected_card_data.duplicate(false)
	var req = CardPlayRequestScript.make(selected_card_id, CardfrontRulesScript.PLAYER_FACTION, target_cell, target_region_id)
	var result = card_system.play(req)
	if result == null:
		var null_result := _make_play_payload(false, "play_returned_null", str(play_card_data.get("card_name", "")), target_cell, target_region_id)
		_emit_play_failed(play_card_id, play_card_data, null_result)
		_clear_and_refresh()
		return null_result

	if result.success:
		var success_result := _make_play_payload(true, str(result.reason), str(result.card_name), target_cell, target_region_id)
		success_result["consumed_energy"] = int(result.consumed_energy)
		success_result["consumed_parts"] = int(result.consumed_parts)
		_emit_play_succeeded(play_card_id, play_card_data, success_result)
		_clear_and_refresh()
		return success_result
	else:
		var fail_result := _make_play_payload(false, str(result.reason), str(result.card_name), target_cell, target_region_id)
		_emit_play_failed(play_card_id, play_card_data, fail_result)
		_clear_and_refresh()
		return fail_result


func _invalid_target_feedback(cell: Vector2i) -> Dictionary:
	if feedback_bus != null and feedback_bus.has_method("emit_target_invalid"):
		feedback_bus.emit_target_invalid(selected_card_id, selected_card_data, cell, "invalid_target")
	return {"success": false, "reason": "invalid_target", "cell": cell, "card_id": selected_card_id, "card_name": selected_card_data.get("card_name", "")}


func clear_selection() -> void:
	var old_card_id: int = selected_card_id
	var old_card_data: Dictionary = selected_card_data.duplicate(false)
	selected_card_id = -1
	selected_card_data.clear()
	if hand_panel != null:
		hand_panel.clear_selection()
	if target_preview != null:
		target_preview.clear_preview()
	if old_card_id >= 0 and feedback_bus != null and feedback_bus.has_method("emit_card_deselected"):
		feedback_bus.emit_card_deselected(old_card_id, old_card_data)


func _clear_and_refresh() -> void:
	clear_selection()
	if hand_panel != null:
		hand_panel.refresh()
	if resource_bar != null:
		resource_bar.refresh(true)


func get_selected_card_id() -> int:
	return selected_card_id


func get_selected_card_data() -> Dictionary:
	return selected_card_data.duplicate(false)


func _make_play_payload(success: bool, reason: String, card_name: String, target_cell: Vector2i, target_region_id: int) -> Dictionary:
	return {
		"success": success,
		"reason": str(reason),
		"card_id": selected_card_id,
		"card_name": str(card_name),
		"target_cell": target_cell,
		"target_region_id": int(target_region_id),
		"effect_id": str(selected_card_data.get("effect_id", "")),
	}


func _emit_play_succeeded(card_id: int, card_data: Dictionary, result: Dictionary) -> void:
	if feedback_bus != null and feedback_bus.has_method("emit_card_play_succeeded"):
		feedback_bus.emit_card_play_succeeded(card_id, card_data, result)


func _emit_play_failed(card_id: int, card_data: Dictionary, result: Dictionary) -> void:
	if feedback_bus != null and feedback_bus.has_method("emit_card_play_failed"):
		feedback_bus.emit_card_play_failed(card_id, card_data, result)
