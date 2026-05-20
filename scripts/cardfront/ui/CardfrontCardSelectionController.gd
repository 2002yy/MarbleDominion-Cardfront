extends RefCounted
class_name CardfrontCardSelectionController

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const CardPlayRequestScript = preload("res://scripts/cardfront/cards/CardPlayRequest.gd")

var card_system = null
var resource_states: Dictionary = {}
var hand_panel = null
var resource_bar = null
var target_preview = null
var selected_card_id: int = -1
var selected_card_data: Dictionary = {}


func setup(new_card_system, new_resource_states: Dictionary, new_hand_panel, new_resource_bar, new_target_preview = null) -> void:
	card_system = new_card_system
	resource_states = new_resource_states.duplicate(false)
	hand_panel = new_hand_panel
	resource_bar = new_resource_bar
	target_preview = new_target_preview


func on_card_clicked(card_id: int, card_data: Dictionary) -> void:
	if card_id == selected_card_id:
		clear_selection()
		return
	selected_card_id = card_id
	selected_card_data = card_data.duplicate(false)
	if hand_panel != null:
		hand_panel.set_card_selected(card_id)
	if target_preview != null:
		target_preview.show_for_card(card_id, card_data)


func on_battlefield_clicked(cell: Vector2i) -> Dictionary:
	if selected_card_id < 0:
		return {"success": false, "reason": "no_card_selected"}
	if target_preview != null and target_preview.is_valid_target(cell):
		var region_id: int = target_preview.get_target_region_id(cell)
		return on_target_selected(cell, region_id)
	return _invalid_target_feedback(cell)


func on_target_selected(target_cell: Vector2i, target_region_id: int) -> Dictionary:
	if selected_card_id < 0:
		return {"success": false, "reason": "no_card_selected"}
	if card_system == null:
		return {"success": false, "reason": "missing_card_system"}

	var req = CardPlayRequestScript.make(selected_card_id, CardfrontRulesScript.PLAYER_FACTION, target_cell, target_region_id)
	var result = card_system.play(req)
	if result == null:
		_clear_and_refresh()
		return {"success": false, "reason": "play_returned_null"}

	if result.success:
		_clear_and_refresh()
		return {"success": true, "card_name": result.card_name}
	else:
		_clear_and_refresh()
		return {"success": false, "reason": result.reason, "card_name": result.card_name}


func _invalid_target_feedback(cell: Vector2i) -> Dictionary:
	return {"success": false, "reason": "invalid_target", "cell": cell}


func clear_selection() -> void:
	selected_card_id = -1
	selected_card_data.clear()
	if hand_panel != null:
		hand_panel.clear_selection()
	if target_preview != null:
		target_preview.clear_preview()


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
