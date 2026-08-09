extends RefCounted
class_name SupportCaptureStateMachine

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const TuningScript = preload("res://scripts/cardfront/support/capture/SupportCaptureTuning.gd")


static func step(
	current_state: Dictionary,
	player_capture_power: float,
	ai_capture_power: float,
	delta_seconds: float,
	tuning: Dictionary = {}
) -> Dictionary:
	var next: Dictionary = _normalized_state(current_state)
	next["claim_changed"] = false
	next["capture_completed"] = false
	next["previous_claim_owner"] = int(next.claim_owner)

	var player_power: float = maxf(0.0, player_capture_power)
	var ai_power: float = maxf(0.0, ai_capture_power)
	var delta: float = maxf(0.0, delta_seconds)
	var has_player: bool = player_power > 0.0
	var has_ai: bool = ai_power > 0.0

	if has_player and has_ai:
		next["contested"] = true
		next["capture_idle_seconds"] = 0.0
		return next

	next["contested"] = false
	if not has_player and not has_ai:
		_apply_idle_policy(next, delta, tuning)
		return next

	next["capture_idle_seconds"] = 0.0
	var active_side: int = RulesScript.PLAYER_FACTION if has_player else RulesScript.AI_FACTION
	var active_power: float = player_power if has_player else ai_power

	# A working enemy support must first be suppressed by the separate territory
	# evidence pipeline. This pure capture transition never performs suppression.
	if int(next.claim_owner) != RulesScript.NEUTRAL_OWNER \
	and int(next.claim_owner) != active_side \
	and bool(next.operational):
		return next

	# Contributors already owning the support do not create takeover progress.
	if int(next.claim_owner) == active_side:
		return next

	if int(next.capture_side) != active_side:
		next["capture_side"] = active_side
		next["capture_progress"] = 0.0

	var rate: float = maxf(0.0, float(_tuning_value(tuning, "base_capture_rate_per_second")))
	next["capture_progress"] = clampf(float(next.capture_progress) + active_power * rate * delta, 0.0, 1.0)
	if float(next.capture_progress) < 1.0:
		return next

	next["claim_owner"] = active_side
	next["capture_side"] = RulesScript.NEUTRAL_OWNER
	next["capture_progress"] = 0.0
	next["capture_idle_seconds"] = 0.0
	next["claim_changed"] = true
	next["capture_completed"] = true
	# Claim completion does not grant operational recovery or graph connectivity.
	next["operational"] = false
	next["network_connected"] = false
	return next


static func _apply_idle_policy(next: Dictionary, delta: float, tuning: Dictionary) -> void:
	var previous_idle: float = maxf(0.0, float(next.capture_idle_seconds))
	var current_idle: float = previous_idle + delta
	next["capture_idle_seconds"] = current_idle
	var grace: float = maxf(0.0, float(_tuning_value(tuning, "capture_idle_grace_seconds")))
	var decay_seconds: float = maxf(0.0, current_idle - maxf(previous_idle, grace))
	if decay_seconds <= 0.0 or float(next.capture_progress) <= 0.0:
		return
	var base_rate: float = maxf(0.0, float(_tuning_value(tuning, "base_capture_rate_per_second")))
	var decay_multiplier: float = maxf(0.0, float(_tuning_value(tuning, "capture_idle_decay_multiplier")))
	next["capture_progress"] = maxf(0.0, float(next.capture_progress) - base_rate * decay_multiplier * decay_seconds)
	if float(next.capture_progress) <= 0.0:
		next["capture_side"] = RulesScript.NEUTRAL_OWNER


static func _tuning_value(tuning: Dictionary, key: String) -> Variant:
	return tuning.get(key, TuningScript.state_machine_defaults()[key])


static func _normalized_state(current_state: Dictionary) -> Dictionary:
	return {
		"support_id": str(current_state.get("support_id", "")),
		"claim_owner": int(current_state.get("claim_owner", RulesScript.NEUTRAL_OWNER)),
		"operational": bool(current_state.get("operational", false)),
		"capture_side": int(current_state.get("capture_side", RulesScript.NEUTRAL_OWNER)),
		"capture_progress": clampf(float(current_state.get("capture_progress", 0.0)), 0.0, 1.0),
		"capture_idle_seconds": maxf(0.0, float(current_state.get("capture_idle_seconds", 0.0))),
		"network_connected": bool(current_state.get("network_connected", false)),
		"contested": bool(current_state.get("contested", false)),
	}
