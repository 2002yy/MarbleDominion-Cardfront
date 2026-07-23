extends RefCounted
class_name CardfrontMatchPhase

const BATTLE_COUNTDOWN: String = "battle_countdown"
const DRAFT_PAUSED: String = "draft_paused"
const RESOLVE_CHOICES: String = "resolve_choices"
const LAUNCH_VOLLEY: String = "launch_volley"

const ALL: Array[String] = [
	BATTLE_COUNTDOWN,
	DRAFT_PAUSED,
	RESOLVE_CHOICES,
	LAUNCH_VOLLEY,
]


static func is_valid(value: String) -> bool:
	return str(value) in ALL
