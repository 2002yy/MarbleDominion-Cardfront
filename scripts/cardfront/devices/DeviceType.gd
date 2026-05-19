extends RefCounted

const ABSORBER_CORE: String = "absorber_core"
const ENGINEER_BOT: String = "engineer_bot"
const PIONEER_BEACON: String = "pioneer_beacon"

static func is_valid(device_type: String) -> bool:
	return device_type in [ABSORBER_CORE, ENGINEER_BOT, PIONEER_BEACON]
