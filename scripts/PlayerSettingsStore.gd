extends RefCounted
class_name PlayerSettingsStore

const SETTINGS_PATH := "user://player_settings.json"

static func default_settings() -> Dictionary:
	return {
		"show_performance_info": OS.is_debug_build(),
		"low_effect_mode": false,
		"show_newbie_hint": true,
		"tutorial_completed": false,
	}

static func load_settings() -> Dictionary:
	var defaults := default_settings()
	if not FileAccess.file_exists(SETTINGS_PATH):
		return defaults
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return defaults
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not (parsed is Dictionary):
		return defaults
	return sanitize_settings(parsed)

static func save_settings(settings: Dictionary) -> void:
	var clean := sanitize_settings(settings)
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(clean, "\t"))
	file.close()

static func sanitize_settings(settings: Dictionary) -> Dictionary:
	var defaults := default_settings()
	return {
		"show_performance_info": _coerce_bool(settings.get("show_performance_info", defaults["show_performance_info"]), bool(defaults["show_performance_info"])),
		"low_effect_mode": _coerce_bool(settings.get("low_effect_mode", defaults["low_effect_mode"]), bool(defaults["low_effect_mode"])),
		"show_newbie_hint": _coerce_bool(settings.get("show_newbie_hint", defaults["show_newbie_hint"]), bool(defaults["show_newbie_hint"])),
		"tutorial_completed": _coerce_bool(settings.get("tutorial_completed", defaults["tutorial_completed"]), bool(defaults["tutorial_completed"])),
	}

static func _coerce_bool(value, default_value: bool) -> bool:
	if value is bool:
		return value
	if value is int or value is float:
		return value != 0
	if value is String:
		var normalized: String = value.strip_edges().to_lower()
		match normalized:
			"1", "true", "yes", "on":
				return true
			"0", "false", "no", "off", "":
				return false
			_:
				return default_value
	return default_value
