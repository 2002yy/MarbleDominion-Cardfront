extends RefCounted
class_name CardfrontRuntimeSnapshot

var resource_states: Dictionary = {}
var used_card_ids: Array = []
var fortify_stacks: Array = []
var morale_effects: Array = []
var target_bias_state: Dictionary = {}
var devices: Array = []


func to_dict() -> Dictionary:
	return {
		"resource_states": resource_states,
		"used_card_ids": used_card_ids,
		"fortify_stacks": fortify_stacks,
		"morale_effects": morale_effects,
		"target_bias_state": target_bias_state,
		"devices": devices,
	}


static func from_dict(data: Dictionary):
	var snap = load("res://scripts/cardfront/save/CardfrontRuntimeSnapshot.gd").new()
	snap.resource_states = data.get("resource_states", {})
	snap.used_card_ids = data.get("used_card_ids", [])
	snap.fortify_stacks = data.get("fortify_stacks", [])
	snap.morale_effects = data.get("morale_effects", [])
	snap.target_bias_state = data.get("target_bias_state", {})
	snap.devices = data.get("devices", [])
	return snap
