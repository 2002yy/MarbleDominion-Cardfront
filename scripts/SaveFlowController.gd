extends RefCounted
class_name SaveFlowController

const StartMenuUi = preload("res://scripts/StartMenu.gd")

const SAVE_INTEGRITY_STATUS_MESSAGE: String = "\u68c0\u6d4b\u5230\u5b58\u6863\u5b8c\u6574\u6027\u4e0d\u4e00\u81f4\uff0c\u5df2\u6309\u4fee\u590d\u6a21\u5f0f\u8bfb\u53d6"
const SAVE_INTEGRITY_WARNING_MESSAGE: String = "\u5b58\u6863\u53ef\u80fd\u88ab\u4fee\u6539\u6216\u5df2\u635f\u574f\uff0c\u5f53\u524d\u4ee5\u5bb9\u9519\u6a21\u5f0f\u7ee7\u7eed"
const MISSING_SAVE_ERROR_MESSAGE: String = "\u5b58\u6863\u8bfb\u53d6\u5931\u8d25\u6216\u5b58\u6863\u5df2\u635f\u574f"
const BACKUP_RECOVERED_STATUS_MESSAGE: String = "\u4e3b\u5b58\u6863\u5df2\u635f\u574f\uff0c\u5df2\u4ece\u5907\u4efd\u6062\u590d"
const BACKUP_ONLY_RECOVERED_STATUS_MESSAGE: String = "\u4e3b\u5b58\u6863\u7f3a\u5931\uff0c\u5df2\u4ece\u5907\u4efd\u6062\u590d"
const DEFAULT_PALETTE_NAME: String = "\u7ecf\u5178"
const SLOT_EMPTY_TITLE: String = "\u7a7a\u5b58\u6863"
const SLOT_INCOMPATIBLE_TITLE: String = "\u7248\u672c\u4e0d\u517c\u5bb9"
const SLOT_DAMAGED_TITLE: String = "\u5b58\u6863\u635f\u574f"

static func normalize_slot(slot_index: int, selected_save_slot: int, save_slot_count: int) -> int:
	return selected_save_slot if slot_index < 1 else clampi(slot_index, 1, save_slot_count)


static func get_save_path(slot_index: int, save_path_template: String, save_slot_count: int) -> String:
	return save_path_template % clampi(slot_index, 1, save_slot_count)


static func get_backup_path(save_path: String) -> String:
	return "%s.bak" % save_path


static func get_temp_path(save_path: String) -> String:
	return "%s.tmp" % save_path


static func has_save_file(
	slot_index: int,
	selected_save_slot: int,
	save_slot_count: int,
	save_path_template: String,
	legacy_save_path: String,
	legacy_slot_path_template: String = ""
) -> bool:
	var slot: int = normalize_slot(slot_index, selected_save_slot, save_slot_count)
	var path: String = get_save_path(slot, save_path_template, save_slot_count)
	if FileAccess.file_exists(path) or FileAccess.file_exists(get_backup_path(path)):
		return true
	if legacy_slot_path_template != "":
		var legacy_slot_path: String = get_save_path(slot, legacy_slot_path_template, save_slot_count)
		if FileAccess.file_exists(legacy_slot_path):
			return true
	return slot == 1 and FileAccess.file_exists(legacy_save_path)


static func load_saved_data(
	slot_index: int,
	selected_save_slot: int,
	save_slot_count: int,
	save_path_template: String,
	legacy_save_path: String,
	allow_legacy: bool = true,
	legacy_slot_path_template: String = ""
) -> Dictionary:
	return load_saved_data_result(
		slot_index,
		selected_save_slot,
		save_slot_count,
		save_path_template,
		legacy_save_path,
		allow_legacy,
		legacy_slot_path_template
	).get("data", {})


static func load_saved_data_result(
	slot_index: int,
	selected_save_slot: int,
	save_slot_count: int,
	save_path_template: String,
	legacy_save_path: String,
	allow_legacy: bool = true,
	legacy_slot_path_template: String = ""
) -> Dictionary:
	var slot: int = normalize_slot(slot_index, selected_save_slot, save_slot_count)
	var path: String = get_save_path(slot, save_path_template, save_slot_count)
	var backup_path: String = get_backup_path(path)

	if FileAccess.file_exists(path):
		var primary_result: Dictionary = _read_save_dictionary(path)
		if bool(primary_result.get("ok", false)):
			return _build_load_success_result(primary_result, path, "primary")

		if FileAccess.file_exists(backup_path):
			var backup_result: Dictionary = _read_save_dictionary(backup_path)
			if bool(backup_result.get("ok", false)):
				var restore_ok: bool = _copy_file(backup_path, path)
				return {
					"ok": true,
					"data": backup_result.get("data", {}),
					"source_path": backup_path,
					"source_kind": "backup",
					"recovered_from_backup": true,
					"restore_succeeded": restore_ok,
					"status_message": _merge_message(BACKUP_RECOVERED_STATUS_MESSAGE, str(backup_result.get("status_message", ""))),
					"warning_message": str(backup_result.get("warning_message", "")),
				}

		return {
			"ok": false,
			"error_message": MISSING_SAVE_ERROR_MESSAGE,
			"warning_message": str(primary_result.get("warning_message", "")),
		}

	if FileAccess.file_exists(backup_path):
		var backup_only_result: Dictionary = _read_save_dictionary(backup_path)
		if bool(backup_only_result.get("ok", false)):
			var restore_from_backup_ok: bool = _copy_file(backup_path, path)
			return {
				"ok": true,
				"data": backup_only_result.get("data", {}),
				"source_path": backup_path,
				"source_kind": "backup_only",
				"recovered_from_backup": true,
				"restore_succeeded": restore_from_backup_ok,
				"status_message": _merge_message(BACKUP_ONLY_RECOVERED_STATUS_MESSAGE, str(backup_only_result.get("status_message", ""))),
				"warning_message": str(backup_only_result.get("warning_message", "")),
			}

	if allow_legacy and legacy_slot_path_template != "":
		var legacy_slot_path: String = get_save_path(slot, legacy_slot_path_template, save_slot_count)
		if FileAccess.file_exists(legacy_slot_path):
			var legacy_slot_result: Dictionary = _read_save_dictionary(legacy_slot_path)
			if bool(legacy_slot_result.get("ok", false)):
				return {
					"ok": true,
					"data": legacy_slot_result.get("data", {}),
					"source_path": legacy_slot_path,
					"source_kind": "legacy_slot",
				}

	if allow_legacy and slot == 1 and FileAccess.file_exists(legacy_save_path):
		var legacy_result: Dictionary = _read_save_dictionary(legacy_save_path)
		if bool(legacy_result.get("ok", false)):
			return {
				"ok": true,
				"data": legacy_result.get("data", {}),
				"source_path": legacy_save_path,
				"source_kind": "legacy_single",
			}

	return {
		"ok": false,
		"error_message": MISSING_SAVE_ERROR_MESSAGE,
	}


static func prepare_continue_payload(
	slot_index: int,
	selected_save_slot: int,
	save_slot_count: int,
	save_path_template: String,
	legacy_save_path: String,
	allow_legacy: bool = true,
	legacy_slot_path_template: String = ""
) -> Dictionary:
	var load_result: Dictionary = load_saved_data_result(
		slot_index,
		selected_save_slot,
		save_slot_count,
		save_path_template,
		legacy_save_path,
		allow_legacy,
		legacy_slot_path_template
	)
	var raw_data: Dictionary = load_result.get("data", {})
	var status_message: String = str(load_result.get("status_message", ""))
	var warning_message: String = str(load_result.get("warning_message", ""))
	if not bool(load_result.get("ok", false)) or raw_data.is_empty():
		return {
			"ok": false,
			"error_message": str(load_result.get("error_message", MISSING_SAVE_ERROR_MESSAGE)),
			"warning_message": warning_message,
		}

	var source_path: String = str(load_result.get("source_path", ""))
	if source_path != "":
		var source_read_result: Dictionary = _read_save_dictionary(source_path)
		status_message = _merge_message(status_message, str(source_read_result.get("status_message", "")))
		warning_message = _merge_message(warning_message, str(source_read_result.get("warning_message", "")))

	var save_version: String = str(raw_data.get("save_version", ""))
	if not SaveGameCodec.is_supported_save_version(save_version):
		return {
			"ok": false,
			"error_message": "\u5f53\u524d\u7248\u672c\u4e0d\u652f\u6301\u8be5\u5b58\u6863\u7248\u672c %s" % save_version,
			"warning_message": "\u5b58\u6863\u7248\u672c %s \u4e0e\u5f53\u524d\u7248\u672c\u4e0d\u517c\u5bb9" % save_version,
			"save_version": save_version,
		}

	var clean_data: Dictionary = SaveGameCodec.validate_save_data(raw_data)
	if clean_data.has("_invalid_reason"):
		return {
			"ok": false,
			"error_message": str(clean_data["_invalid_reason"]),
			"save_version": save_version,
			"warning_message": warning_message,
		}

	if not clean_data.has("grid_size"):
		return {
			"ok": false,
			"error_message": "\u5b58\u6863\u7f3a\u5c11\u5fc5\u8981\u7684\u5730\u56fe\u5c3a\u5bf8\u4fe1\u606f",
			"save_version": save_version,
			"warning_message": warning_message,
		}

	return {
		"ok": true,
		"data": clean_data,
		"save_version": save_version,
		"status_message": status_message,
		"warning_message": warning_message,
		"source_kind": str(load_result.get("source_kind", "primary")),
	}


static func build_continue_runtime_state(data: Dictionary, fallback_time_limit_minutes: int) -> Dictionary:
	var normalized: Dictionary = data.duplicate(true)
	normalized["palette_name"] = str(normalized.get("palette_name", DEFAULT_PALETTE_NAME))
	normalized["quality_name"] = str(normalized.get("quality_name", GameConfig.QUALITY_MEDIUM))
	normalized["game_mode_name"] = str(normalized.get("game_mode_name", GameConfig.GAME_MODE_BASIC))
	normalized["time_limit_minutes"] = clampi(
		int(normalized.get("time_limit_minutes", fallback_time_limit_minutes)),
		GameConfig.TIMED_MODE_MIN_MINUTES,
		GameConfig.TIMED_MODE_MAX_MINUTES
	)
	normalized["grid_size"] = LayoutProfiles.sanitize_grid_size(normalized.get("grid_size", 40))
	normalized["game_elapsed_time"] = maxf(0.0, float(normalized.get("game_elapsed_time", 0.0)))
	return normalized


static func build_continue_game_config_state(data: Dictionary) -> Dictionary:
	return {
		"palette_name": str(data.get("palette_name", DEFAULT_PALETTE_NAME)),
		"quality_name": str(data.get("quality_name", GameConfig.QUALITY_MEDIUM)),
		"game_mode_name": str(data.get("game_mode_name", GameConfig.GAME_MODE_BASIC)),
		"time_limit_minutes": int(data.get("time_limit_minutes", GameConfig.DEFAULT_TIMED_MODE_MINUTES)),
	}


static func apply_continue_game_config(config_state: Dictionary) -> Dictionary:
	var palette_name: String = str(config_state.get("palette_name", DEFAULT_PALETTE_NAME))
	var quality_name: String = str(config_state.get("quality_name", GameConfig.QUALITY_MEDIUM))
	var game_mode_name: String = str(config_state.get("game_mode_name", GameConfig.GAME_MODE_BASIC))
	var time_limit_minutes: int = int(config_state.get("time_limit_minutes", GameConfig.DEFAULT_TIMED_MODE_MINUTES))
	GameConfig.set_palette_by_name(palette_name)
	GameConfig.set_quality_by_name(quality_name)
	GameConfig.set_game_mode_by_name(game_mode_name)
	GameConfig.set_time_limit_minutes(time_limit_minutes)
	return {
		"palette_name": palette_name,
		"quality_name": quality_name,
		"game_mode_name": game_mode_name,
		"time_limit_minutes": time_limit_minutes,
	}


static func build_continue_start_values(data: Dictionary) -> Dictionary:
	return {
		"grid_size": int(data.get("grid_size", 40)),
		"game_elapsed_time": float(data.get("game_elapsed_time", 0.0)),
	}


static func build_continue_selection_state(data: Dictionary, fallback_time_limit_minutes: int) -> Dictionary:
	return {
		"selected_palette_name": str(data.get("palette_name", DEFAULT_PALETTE_NAME)),
		"selected_quality_name": str(data.get("quality_name", GameConfig.QUALITY_MEDIUM)),
		"selected_game_mode_name": str(data.get("game_mode_name", GameConfig.GAME_MODE_BASIC)),
		"selected_time_limit_minutes": int(data.get("time_limit_minutes", fallback_time_limit_minutes)),
	}


static func apply_continue_selection_state(selection_state: Dictionary, controller_ref) -> Dictionary:
	if controller_ref == null:
		return selection_state

	controller_ref.selected_palette_name = str(selection_state.get("selected_palette_name", controller_ref.selected_palette_name))
	controller_ref.selected_quality_name = str(selection_state.get("selected_quality_name", controller_ref.selected_quality_name))
	controller_ref.selected_game_mode_name = str(selection_state.get("selected_game_mode_name", controller_ref.selected_game_mode_name))
	controller_ref.selected_time_limit_minutes = int(selection_state.get("selected_time_limit_minutes", controller_ref.selected_time_limit_minutes))
	return selection_state


static func build_continue_banner_config() -> Dictionary:
	return {
		"title": "\u9886\u571f\u6218\u4e89",
		"subtitle": "\u7ee7\u7eed\u4f5c\u6218",
		"accent": Color(0.84, 0.96, 1.0),
		"auto_hide": true,
	}


static func prepare_continue_start_plan(data: Dictionary, fallback_time_limit_minutes: int) -> Dictionary:
	var normalized: Dictionary = build_continue_runtime_state(data, fallback_time_limit_minutes)
	return {
		"data": normalized,
		"game_config": build_continue_game_config_state(normalized),
		"start_values": build_continue_start_values(normalized),
		"selection_state": build_continue_selection_state(normalized, fallback_time_limit_minutes),
		"banner": build_continue_banner_config(),
	}


static func apply_continue_start_plan(plan: Dictionary, controller_ref = null) -> Dictionary:
	var selection_state: Dictionary = plan.get("selection_state", {})
	var game_config_state: Dictionary = plan.get("game_config", {})
	return {
		"selection_state": apply_continue_selection_state(selection_state, controller_ref),
		"game_config": apply_continue_game_config(game_config_state),
	}


static func build_save_slot_summaries(save_slot_count: int, loader: Callable) -> Array:
	var result: Array = []
	for slot in range(1, save_slot_count + 1):
		var data: Dictionary = {}
		if loader.is_valid():
			data = loader.call(slot, true)

		var state: String = "empty"
		var title: String = SLOT_EMPTY_TITLE
		var detail: String = "\u70b9\u51fb\u9009\u62e9\u6b64\u69fd"

		if not data.is_empty():
			var version: String = str(data.get("save_version", ""))
			var clean: Dictionary = SaveGameCodec.validate_save_data(data)
			if not SaveGameCodec.is_supported_save_version(version):
				state = "incompatible"
				title = SLOT_INCOMPATIBLE_TITLE
				detail = "\u5b58\u6863\u7248\u672c %s \u4e0e\u5f53\u524d\u7248\u672c\u4e0d\u517c\u5bb9" % version
			elif clean.has("_invalid_reason") or not clean.has("grid_size"):
				state = "damaged"
				title = SLOT_DAMAGED_TITLE
				detail = str(clean.get("_invalid_reason", "\u5b58\u6863\u7f3a\u5c11\u5fc5\u8981\u6570\u636e"))
			else:
				state = "valid"
				var grid_size: int = LayoutProfiles.sanitize_grid_size(clean.get("grid_size", 40))
				var mode_name: String = str(clean.get("game_mode_name", GameConfig.GAME_MODE_BASIC))
				var quality_name: String = str(clean.get("quality_name", GameConfig.QUALITY_MEDIUM))
				var elapsed: float = maxf(0.0, float(clean.get("game_elapsed_time", 0.0)))
				var ver_display: String = version if version != "" else "?"
				title = "%s\uFF5C%d\u00D7%d\uFF5C%s" % [mode_name, grid_size, grid_size, quality_name]
				detail = "\u8fdb\u5ea6 %s\uFF5C\u7248\u672c %s" % [RuntimeHudController.format_time_text(elapsed), ver_display]

		result.append({
			"slot": slot,
			"state": state,
			"has_data": state != "empty",
			"is_playable": state == "valid",
			"title": title,
			"detail": detail,
		})
	return result


static func write_game_progress(
	selected_save_slot: int,
	save_path_template: String,
	save_slot_count: int,
	chambers: Dictionary,
	turrets: Dictionary,
	battlefield,
	bullet_container,
	event_roulette_controller,
	game_elapsed_time: float,
	is_game_over: bool,
	winner_label
) -> bool:
	return bool(write_game_progress_result(
		selected_save_slot,
		save_path_template,
		save_slot_count,
		chambers,
		turrets,
		battlefield,
		bullet_container,
		event_roulette_controller,
		game_elapsed_time,
		is_game_over,
		winner_label
	).get("ok", false))


static func write_game_progress_result(
	selected_save_slot: int,
	save_path_template: String,
	save_slot_count: int,
	chambers: Dictionary,
	turrets: Dictionary,
	battlefield,
	bullet_container,
	event_roulette_controller,
	game_elapsed_time: float,
	is_game_over: bool,
	winner_label
) -> Dictionary:
	if battlefield == null:
		return {
			"ok": false,
			"error_message": "\u7f3a\u5c11\u6218\u573a\u5b9e\u4f8b\uff0c\u65e0\u6cd5\u4fdd\u5b58\u6e38\u620f\u8fdb\u5ea6",
		}

	var save_path: String = get_save_path(selected_save_slot, save_path_template, save_slot_count)
	var data: Dictionary = SaveStateBuilder.build_save_payload(
		chambers,
		turrets,
		battlefield,
		bullet_container,
		event_roulette_controller,
		game_elapsed_time,
		is_game_over,
		selected_save_slot,
		winner_label
	)
	return _write_json_atomically(save_path, data)


static func build_slot_selection_status(selected_save_slot: int, has_save_data: bool) -> String:
	return build_slot_selection_status_message(selected_save_slot, has_save_data)


static func build_slot_selection_status_message(selected_save_slot: int, has_save_data: bool) -> String:
	if has_save_data:
		return "\u5df2\u9009\u62e9\u5b58\u6863\u69fd %d\uff0c\u65b0\u6e38\u620f\u4f1a\u8986\u76d6\u8fd9\u91cc\u7684\u5b58\u6863" % selected_save_slot
	return "\u5df2\u9009\u62e9\u7a7a\u5b58\u6863\u69fd %d\uff0c\u65b0\u6e38\u620f\u4f1a\u4fdd\u5b58\u5728\u8fd9\u91cc" % selected_save_slot


static func refresh_menu_slot_ui(menu_save_slot_buttons: Dictionary, selected_save_slot: int, summaries: Array, menu_continue_button, has_selected_save: bool) -> void:
	if menu_save_slot_buttons.is_empty():
		return

	for summary in summaries:
		if not (summary is Dictionary):
			continue
		var slot: int = int(summary.get("slot", 1))
		if not menu_save_slot_buttons.has(slot):
			continue
		var button: Button = menu_save_slot_buttons[slot] as Button
		button.text = StartMenuUi.build_slot_label(slot, summary, selected_save_slot)
		button.self_modulate = Color(0.28, 0.54, 0.88) if slot == selected_save_slot else Color(0.16, 0.22, 0.32)

	if menu_continue_button != null and is_instance_valid(menu_continue_button):
		menu_continue_button.disabled = not has_selected_save
		menu_continue_button.text = StartMenuUi.build_continue_button_text(selected_save_slot)


static func _read_save_dictionary(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {
			"ok": false,
			"error_message": "\u65e0\u6cd5\u6253\u5f00\u5b58\u6863\uff1a%s" % path,
		}

	var json := JSON.new()
	var parse_result: Error = json.parse(file.get_as_text())
	if parse_result == OK and json.data is Dictionary:
		var integrity_result: Dictionary = SaveGameCodec.inspect_payload_integrity(json.data)
		var integrity_status: String = str(integrity_result.get("integrity_status", SaveGameCodec.INTEGRITY_STATUS_MISSING))
		return {
			"ok": true,
			"data": integrity_result.get("data", {}),
			"integrity_status": integrity_status,
			"integrity_ok": bool(integrity_result.get("integrity_ok", true)),
			"expected_hash": int(integrity_result.get("expected_hash", 0)),
			"stored_hash": integrity_result.get("stored_hash", null),
			"status_message": SAVE_INTEGRITY_STATUS_MESSAGE if integrity_status == SaveGameCodec.INTEGRITY_STATUS_MISMATCH else "",
			"warning_message": SAVE_INTEGRITY_WARNING_MESSAGE if integrity_status == SaveGameCodec.INTEGRITY_STATUS_MISMATCH else "",
		}
	return {
		"ok": false,
		"error_message": "\u5b58\u6863 JSON \u89e3\u6790\u5931\u8d25\uff1a%s" % path,
	}


static func _build_load_success_result(read_result: Dictionary, source_path: String, source_kind: String) -> Dictionary:
	return {
		"ok": true,
		"data": read_result.get("data", {}),
		"source_path": source_path,
		"source_kind": source_kind,
		"integrity_status": str(read_result.get("integrity_status", SaveGameCodec.INTEGRITY_STATUS_MISSING)),
		"integrity_ok": bool(read_result.get("integrity_ok", true)),
		"expected_hash": int(read_result.get("expected_hash", 0)),
		"stored_hash": read_result.get("stored_hash", null),
		"status_message": str(read_result.get("status_message", "")),
		"warning_message": str(read_result.get("warning_message", "")),
	}


static func _merge_message(base_message: String, extra_message: String) -> String:
	if base_message == "":
		return extra_message
	if extra_message == "":
		return base_message
	if base_message == extra_message:
		return base_message
	return "%s | %s" % [base_message, extra_message]


static func _write_json_atomically(save_path: String, data: Dictionary) -> Dictionary:
	var temp_path: String = get_temp_path(save_path)
	var backup_path: String = get_backup_path(save_path)
	var json_text: String = JSON.stringify(data)
	var had_existing: bool = FileAccess.file_exists(save_path)

	_remove_if_exists(temp_path)

	if not _write_text_file(temp_path, json_text):
		return {
			"ok": false,
			"error_message": "\u65e0\u6cd5\u5199\u5165\u4e34\u65f6\u5b58\u6863\u6587\u4ef6",
			"temp_path": temp_path,
		}

	var verify_result: Dictionary = _read_save_dictionary(temp_path)
	if not bool(verify_result.get("ok", false)):
		_remove_if_exists(temp_path)
		return {
			"ok": false,
			"error_message": "\u4e34\u65f6\u5b58\u6863\u9a8c\u8bc1\u5931\u8d25",
			"temp_path": temp_path,
		}

	if had_existing and not _copy_file(save_path, backup_path):
		_remove_if_exists(temp_path)
		return {
			"ok": false,
			"error_message": "\u65e0\u6cd5\u521b\u5efa\u5b58\u6863\u5907\u4efd",
			"save_path": save_path,
			"backup_path": backup_path,
		}

	if had_existing and not _remove_if_exists(save_path):
		_remove_if_exists(temp_path)
		return {
			"ok": false,
			"error_message": "\u65e0\u6cd5\u79fb\u9664\u65e7\u5b58\u6863",
			"save_path": save_path,
		}

	if not _rename_file(temp_path, save_path):
		if had_existing and FileAccess.file_exists(backup_path):
			_copy_file(backup_path, save_path)
		_remove_if_exists(temp_path)
		return {
			"ok": false,
			"error_message": "\u65e0\u6cd5\u63d0\u4ea4\u65b0\u5b58\u6863\u6587\u4ef6",
			"save_path": save_path,
			"backup_path": backup_path,
		}

	return {
		"ok": true,
		"save_path": save_path,
		"backup_path": backup_path,
		"temp_path": temp_path,
		"had_existing_save": had_existing,
	}


static func _write_text_file(path: String, text: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text)
	file.flush()
	return file.get_error() == OK


static func _copy_file(source_path: String, target_path: String) -> bool:
	if not FileAccess.file_exists(source_path):
		return false
	_remove_if_exists(target_path)
	return DirAccess.copy_absolute(ProjectSettings.globalize_path(source_path), ProjectSettings.globalize_path(target_path)) == OK


static func _rename_file(source_path: String, target_path: String) -> bool:
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(source_path), ProjectSettings.globalize_path(target_path)) == OK


static func _remove_if_exists(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return true
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK
