extends RefCounted

var device_type: String = ""
var max_per_owner: int = 3
var default_lifetime: float = 30.0
var display_name: String = ""

func snapshot() -> Dictionary:
	return {
		"device_type": device_type,
		"max_per_owner": max_per_owner,
		"default_lifetime": default_lifetime,
		"display_name": display_name,
	}
