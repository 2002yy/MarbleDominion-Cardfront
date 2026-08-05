extends RefCounted
class_name CardfrontMatchPhaseController

signal phase_changed(previous_phase, next_phase)
signal draft_timeout_reached

const MatchPhaseScript = preload("res://scripts/cardfront/run/CardfrontMatchPhase.gd")

const DEFAULT_BATTLE_INTERVAL: float = 12.0
const DEFAULT_DRAFT_TIMEOUT: float = 8.0

var phase: String = MatchPhaseScript.BATTLE_COUNTDOWN
var battle_interval: float = DEFAULT_BATTLE_INTERVAL
var draft_timeout: float = DEFAULT_DRAFT_TIMEOUT
var time_remaining: float = DEFAULT_BATTLE_INTERVAL
var owner_ids: Array[int] = []
var selected_upgrade_ids: Dictionary = {}
var draft_timed_out: bool = false


func setup(new_owner_ids: Array, new_battle_interval: float = DEFAULT_BATTLE_INTERVAL, new_draft_timeout: float = DEFAULT_DRAFT_TIMEOUT) -> void:
	owner_ids.clear()
	for raw_owner_id in new_owner_ids:
		var owner_id: int = int(raw_owner_id)
		if not owner_ids.has(owner_id):
			owner_ids.append(owner_id)
	battle_interval = maxf(0.01, new_battle_interval)
	draft_timeout = maxf(0.01, new_draft_timeout)
	start_battle_cycle()


func start_battle_cycle() -> void:
	selected_upgrade_ids.clear()
	draft_timed_out = false
	time_remaining = battle_interval
	_set_phase(MatchPhaseScript.BATTLE_COUNTDOWN)


func tick(delta: float) -> String:
	var safe_delta: float = maxf(0.0, delta)
	if phase == MatchPhaseScript.BATTLE_COUNTDOWN:
		time_remaining = maxf(0.0, time_remaining - safe_delta)
		if time_remaining <= 0.0:
			begin_draft()
	elif phase == MatchPhaseScript.DRAFT_PAUSED:
		time_remaining = maxf(0.0, time_remaining - safe_delta)
		if time_remaining <= 0.0 and not draft_timed_out:
			draft_timed_out = true
			draft_timeout_reached.emit()
	return phase


func begin_draft() -> bool:
	if phase != MatchPhaseScript.BATTLE_COUNTDOWN:
		return false
	selected_upgrade_ids.clear()
	draft_timed_out = false
	time_remaining = draft_timeout
	_set_phase(MatchPhaseScript.DRAFT_PAUSED)
	return true


func select_upgrade(owner_id: int, upgrade_id: String) -> bool:
	if phase != MatchPhaseScript.DRAFT_PAUSED:
		return false
	if not owner_ids.has(int(owner_id)) or str(upgrade_id) == "":
		return false
	if selected_upgrade_ids.has(int(owner_id)):
		return false
	selected_upgrade_ids[int(owner_id)] = str(upgrade_id)
	return true


func get_selected_upgrade_id(owner_id: int) -> String:
	return str(selected_upgrade_ids.get(int(owner_id), ""))


func get_missing_owner_ids() -> Array[int]:
	var missing: Array[int] = []
	for owner_id in owner_ids:
		if not selected_upgrade_ids.has(int(owner_id)):
			missing.append(int(owner_id))
	return missing


func has_all_choices() -> bool:
	return not owner_ids.is_empty() and get_missing_owner_ids().is_empty()


func begin_resolve() -> bool:
	if phase != MatchPhaseScript.DRAFT_PAUSED or not has_all_choices():
		return false
	time_remaining = 0.0
	_set_phase(MatchPhaseScript.RESOLVE_CHOICES)
	return true


func begin_launch() -> bool:
	if phase != MatchPhaseScript.RESOLVE_CHOICES:
		return false
	_set_phase(MatchPhaseScript.LAUNCH_VOLLEY)
	return true


func complete_launch() -> bool:
	if phase != MatchPhaseScript.LAUNCH_VOLLEY:
		return false
	start_battle_cycle()
	return true


func snapshot() -> Dictionary:
	return {
		"phase": phase,
		"time_remaining": time_remaining,
		"battle_interval": battle_interval,
		"draft_timeout": draft_timeout,
		"owner_ids": owner_ids.duplicate(),
		"selected_upgrade_ids": selected_upgrade_ids.duplicate(),
		"draft_timed_out": draft_timed_out,
	}


func restore(data: Dictionary) -> void:
	phase = str(data.get("phase", MatchPhaseScript.BATTLE_COUNTDOWN))
	battle_interval = maxf(0.01, float(data.get("battle_interval", DEFAULT_BATTLE_INTERVAL)))
	draft_timeout = maxf(0.01, float(data.get("draft_timeout", DEFAULT_DRAFT_TIMEOUT)))
	time_remaining = maxf(0.0, float(data.get("time_remaining", battle_interval)))
	draft_timed_out = bool(data.get("draft_timed_out", false))
	owner_ids.clear()
	for raw_owner_id in data.get("owner_ids", []):
		var owner_id: int = int(raw_owner_id)
		if not owner_ids.has(owner_id):
			owner_ids.append(owner_id)
	selected_upgrade_ids.clear()
	var saved_selections: Dictionary = data.get("selected_upgrade_ids", {})
	for owner_id in saved_selections:
		selected_upgrade_ids[int(owner_id)] = str(saved_selections[owner_id])


func _set_phase(next_phase: String) -> void:
	if phase == next_phase:
		return
	var previous_phase: String = phase
	phase = next_phase
	phase_changed.emit(previous_phase, next_phase)
