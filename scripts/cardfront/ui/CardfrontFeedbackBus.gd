extends Node
class_name CardfrontFeedbackBus

signal card_hovered(card_id: int, card_data: Dictionary, card_view: Control)
signal card_unhovered(card_id: int, card_data: Dictionary, card_view: Control)
signal card_clicked(card_id: int, card_data: Dictionary, card_view: Control)
signal card_selected(card_id: int, card_data: Dictionary)
signal card_deselected(card_id: int, card_data: Dictionary)
signal target_invalid(card_id: int, card_data: Dictionary, cell: Vector2i, reason: String)
signal card_play_succeeded(card_id: int, card_data: Dictionary, result: Dictionary)
signal card_play_failed(card_id: int, card_data: Dictionary, result: Dictionary)


func _init() -> void:
	name = "CardfrontFeedbackBus"


func emit_card_hovered(card_id: int, card_data: Dictionary, card_view: Control) -> void:
	card_hovered.emit(int(card_id), card_data.duplicate(false), card_view)


func emit_card_unhovered(card_id: int, card_data: Dictionary, card_view: Control) -> void:
	card_unhovered.emit(int(card_id), card_data.duplicate(false), card_view)


func emit_card_clicked(card_id: int, card_data: Dictionary, card_view: Control) -> void:
	card_clicked.emit(int(card_id), card_data.duplicate(false), card_view)


func emit_card_selected(card_id: int, card_data: Dictionary) -> void:
	card_selected.emit(int(card_id), card_data.duplicate(false))


func emit_card_deselected(card_id: int, card_data: Dictionary) -> void:
	card_deselected.emit(int(card_id), card_data.duplicate(false))


func emit_target_invalid(card_id: int, card_data: Dictionary, cell: Vector2i, reason: String = "invalid_target") -> void:
	target_invalid.emit(int(card_id), card_data.duplicate(false), cell, str(reason))


func emit_card_play_succeeded(card_id: int, card_data: Dictionary, result: Dictionary) -> void:
	card_play_succeeded.emit(int(card_id), card_data.duplicate(false), result.duplicate(false))


func emit_card_play_failed(card_id: int, card_data: Dictionary, result: Dictionary) -> void:
	card_play_failed.emit(int(card_id), card_data.duplicate(false), result.duplicate(false))
