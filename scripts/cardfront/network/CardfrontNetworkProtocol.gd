extends RefCounted
class_name CardfrontNetworkProtocol

const MSG_HANDSHAKE: int = 1
const MSG_PHASE_INPUT: int = 2
const MSG_PHASE_READY: int = 3
const MSG_COMMAND_POINT: int = 4
const MSG_MATCH_CONFIG: int = 5
const MSG_RESYNC_REQUEST: int = 6
const MSG_RESYNC_RESPONSE: int = 7
const MSG_DISCONNECT: int = 8

const PHASE_AIM: String = "aim"
const PHASE_DRAFT: String = "draft"
const PHASE_VOLLEY: String = "volley"

const ROLE_HOST: int = 1
const ROLE_GUEST: int = 2


static func pack_handshake(hero_id: String, map_id: String) -> PackedByteArray:
	var data: Dictionary = {
		"type": MSG_HANDSHAKE,
		"hero_id": hero_id,
		"map_id": map_id,
	}
	return _to_bytes(data)


static func pack_match_config(map_id: String, player_hero: String, ai_hero: String, grid_extent: Array) -> PackedByteArray:
	var data: Dictionary = {
		"type": MSG_MATCH_CONFIG,
		"map_id": map_id,
		"player_hero": player_hero,
		"ai_hero": ai_hero,
		"grid_extent": grid_extent,
	}
	return _to_bytes(data)


static func pack_phase_input(
	phase: String,
	round_number: int,
	angle: float,
	lane_split: float,
	priority_target: Array,
	draft_choice: String,
	command_point_actions: Array
) -> PackedByteArray:
	var data: Dictionary = {
		"type": MSG_PHASE_INPUT,
		"phase": phase,
		"round_number": round_number,
		"angle": angle,
		"lane_split": lane_split,
		"priority_target": priority_target,
		"draft_choice": draft_choice,
		"command_point_actions": command_point_actions,
	}
	return _to_bytes(data)


static func pack_phase_ready(phase: String, round_number: int) -> PackedByteArray:
	var data: Dictionary = {
		"type": MSG_PHASE_READY,
		"phase": phase,
		"round_number": round_number,
	}
	return _to_bytes(data)


static func pack_command_point(action: String, cell: Array, round_number: int) -> PackedByteArray:
	var data: Dictionary = {
		"type": MSG_COMMAND_POINT,
		"action": action,
		"cell": cell,
		"round_number": round_number,
	}
	return _to_bytes(data)


static func pack_disconnect(reason: String = "") -> PackedByteArray:
	return _to_bytes({"type": MSG_DISCONNECT, "reason": reason})


static func unpack(bytes: PackedByteArray) -> Dictionary:
	if bytes.is_empty():
		return {}
	var json = JSON.new()
	if json.parse(bytes.get_string_from_utf8()) != OK:
		return {}
	var data = json.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	return data


static func _to_bytes(data: Dictionary) -> PackedByteArray:
	return JSON.stringify(data).to_utf8_buffer()
