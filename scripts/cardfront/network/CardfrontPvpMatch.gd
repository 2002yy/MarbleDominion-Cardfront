extends Node
class_name CardfrontPvpMatch

signal opponent_input_received(phase: String, round_number: int, data: Dictionary)
signal opponent_ready(phase: String, round_number: int)
signal opponent_command_point(action: String, cell: Vector2i, round_number: int)
signal opponent_disconnected()
signal handshake_received(hero_id: String, map_id: String)
signal match_config_received(config: Dictionary)

const Protocol = preload("res://scripts/cardfront/network/CardfrontNetworkProtocol.gd")
const NetworkManagerScript = preload("res://scripts/cardfront/network/CardfrontNetworkManager.gd")

var _network = null
var _local_input_submitted: bool = false
var _opponent_input: Dictionary = {}
var _local_ready: bool = false
var _opponent_ready: bool = false


func setup(network) -> void:
	_network = network
	if _network == null:
		return
	if not _network.message_received.is_connected(_on_message_received):
		_network.message_received.connect(_on_message_received)
	if not _network.peer_disconnected.is_connected(_on_opponent_disconnected):
		_network.peer_disconnected.connect(_on_opponent_disconnected)


func send_handshake(hero_id: String, map_id: String) -> void:
	if _network == null or not _network.is_connected_to_peer():
		return
	_network.send({"type": Protocol.MSG_HANDSHAKE, "hero_id": hero_id, "map_id": map_id})


func send_match_config(map_id: String, player_hero: String, ai_hero: String, grid_extent: Vector2i) -> void:
	if _network == null or not _network.is_connected_to_peer():
		return
	_network.send({
		"type": Protocol.MSG_MATCH_CONFIG,
		"map_id": map_id,
		"player_hero": player_hero,
		"ai_hero": ai_hero,
		"grid_extent": [grid_extent.x, grid_extent.y],
	})


func submit_phase_input(
	phase: String,
	round_number: int,
	angle: float,
	lane_split: float,
	priority_target: Vector2i,
	draft_choice: String,
	command_point_actions: Array
) -> void:
	if _network == null or not _network.is_connected_to_peer():
		return
	_network.send({
		"type": Protocol.MSG_PHASE_INPUT,
		"phase": phase,
		"round_number": round_number,
		"angle": angle,
		"lane_split": lane_split,
		"priority_target": [priority_target.x, priority_target.y],
		"draft_choice": draft_choice,
		"command_point_actions": command_point_actions,
	})
	_local_input_submitted = true


func signal_phase_ready(phase: String, round_number: int) -> void:
	if _network == null or not _network.is_connected_to_peer():
		return
	_network.send({
		"type": Protocol.MSG_PHASE_READY,
		"phase": phase,
		"round_number": round_number,
	})
	_local_ready = true


func send_command_point_action(action: String, cell: Vector2i, round_number: int) -> void:
	if _network == null or not _network.is_connected_to_peer():
		return
	_network.send({
		"type": Protocol.MSG_COMMAND_POINT,
		"action": action,
		"cell": [cell.x, cell.y],
		"round_number": round_number,
	})


func send_disconnect(reason: String = "") -> void:
	if _network == null or not _network.is_connected_to_peer():
		return
	_network.send({"type": Protocol.MSG_DISCONNECT, "reason": reason})


func has_opponent_input() -> bool:
	return not _opponent_input.is_empty()


func get_opponent_input() -> Dictionary:
	return _opponent_input.duplicate(true)


func has_opponent_ready() -> bool:
	return _opponent_ready


func reset_phase_state() -> void:
	_local_input_submitted = false
	_opponent_input.clear()
	_local_ready = false
	_opponent_ready = false


func is_local_input_submitted() -> bool:
	return _local_input_submitted


func _on_message_received(data: Dictionary) -> void:
	if data.is_empty():
		return
	var msg_type: int = int(data.get("type", 0))
	match msg_type:
		Protocol.MSG_HANDSHAKE:
			handshake_received.emit(str(data.get("hero_id", "")), str(data.get("map_id", "")))
		Protocol.MSG_MATCH_CONFIG:
			match_config_received.emit(data)
		Protocol.MSG_PHASE_INPUT:
			_opponent_input = data.duplicate(true)
			opponent_input_received.emit(
				str(data.get("phase", "")),
				int(data.get("round_number", 0)),
				data
			)
		Protocol.MSG_PHASE_READY:
			_opponent_ready = true
			opponent_ready.emit(str(data.get("phase", "")), int(data.get("round_number", 0)))
		Protocol.MSG_COMMAND_POINT:
			var cell_arr: Array = data.get("cell", [0, 0])
			opponent_command_point.emit(
				str(data.get("action", "")),
				Vector2i(int(cell_arr[0]), int(cell_arr[1])),
				int(data.get("round_number", 0))
			)
		Protocol.MSG_DISCONNECT:
			_on_opponent_disconnected(0)


func _on_opponent_disconnected(_peer_id: int) -> void:
	opponent_disconnected.emit()
