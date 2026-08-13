extends SceneTree

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const SupportIdsScript = preload("res://scripts/cardfront/support/CardfrontSupportIds.gd")
const CardTargetTypeScript = preload("res://scripts/cardfront/cards/CardTargetType.gd")
const TargetPreviewScript = preload("res://scripts/cardfront/ui/CardfrontTargetPreviewLayer.gd")
const DeploymentGeometryScript = preload("res://scripts/cardfront/deployment/DeploymentGeometry.gd")

const DESKTOP := Vector2i(1120, 720)
const NARROW := Vector2i(760, 540)

var _main
var _capture_runtime
var _authority
var _annotation: Label
var _output_dir: String
var _sha: String
var _baseline_owners: Array


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("P0 visual evidence requires a rendering display")
		quit(1)
		return
	_output_dir = OS.get_environment("CARDFRONT_P0_VISUAL_OUTPUT").strip_edges().replace("\\", "/")
	if _output_dir == "":
		_output_dir = ProjectSettings.globalize_path("res://artifacts/p0-11L")
	_sha = OS.get_environment("CARDFRONT_P0_COMMIT").strip_edges()
	DirAccess.make_dir_recursive_absolute(_output_dir)
	root.size = DESKTOP
	GameConfig.reset_runtime_defaults()
	paused = false
	_main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(_main)
	await process_frame
	_main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	_main.selected_grid_size = 40
	_main._start_game(40, true, false)
	await _frames(5)
	_capture_runtime = _main.runtime.support_capture_runtime
	_authority = _main.runtime.battlefield.get_meta("cardfront_support_deployment_authority", null)
	if _capture_runtime == null or _authority == null:
		push_error("P0 Support runtime/authority missing")
		quit(2)
		return
	_capture_runtime.set_process(false)
	_baseline_owners = _main.runtime.battlefield.owners.duplicate(true)
	_build_annotation()

	await _save("01-default-battle.png", "default battle / neutral Supports / no persistent network lines")
	_set_support_states({
		SupportIdsScript.SUPPORT_LEFT_SOUTH: _record(RulesScript.PLAYER_FACTION, true),
		SupportIdsScript.SUPPORT_LEFT_NORTH: _record(RulesScript.PLAYER_FACTION, true),
	})
	await _save("02-active-support.png", "Active Support connected to Player Core")
	_set_support_states({})
	await _save("03-neutral-offline-support.png", "Neutral / disabled Support")
	_set_support_states({SupportIdsScript.SUPPORT_LEFT_NORTH: _record(RulesScript.NEUTRAL_OWNER, false, RulesScript.PLAYER_FACTION, 0.46)})
	await _save("04-capturing-support.png", "Capturing Support at 46 percent")
	_set_support_states({SupportIdsScript.SUPPORT_CENTER: _record(RulesScript.NEUTRAL_OWNER, false, RulesScript.PLAYER_FACTION, 0.52)})
	_capture_runtime.states_by_support_id[SupportIdsScript.SUPPORT_CENTER].set_contested(true)
	_authority.notify_presentation_state_changed()
	await _save("05-contested-support.png", "Contested Support / progress frozen")
	_set_support_states({SupportIdsScript.SUPPORT_LEFT_NORTH: _record(RulesScript.PLAYER_FACTION, true)})
	await _save("06-captured-offline.png", "CapturedOffline / owned but no Core path")
	_set_support_states({
		SupportIdsScript.SUPPORT_LEFT_SOUTH: _record(RulesScript.PLAYER_FACTION, true),
		SupportIdsScript.SUPPORT_LEFT_NORTH: _record(RulesScript.PLAYER_FACTION, true),
	})
	_own_support_footprint(SupportIdsScript.SUPPORT_LEFT_NORTH)
	var active_zone_count: int = await _capture_deployment_zone("07-active-support-zone.png", "Active Support legal targeting projection")
	_main.runtime.battlefield.replace_owners(_baseline_owners.duplicate(true), false)
	_set_support_states({})
	var core_zone_count: int = await _capture_deployment_zone("08-core-fallback-zone.png", "Core fallback legal targeting projection")
	if active_zone_count <= core_zone_count:
		push_error("Active Support evidence must expand beyond Core fallback (%d <= %d)" % [active_zone_count, core_zone_count])
		quit(3)
		return
	_set_support_states({
		SupportIdsScript.SUPPORT_LEFT_SOUTH: _record(RulesScript.PLAYER_FACTION, false),
		SupportIdsScript.SUPPORT_LEFT_NORTH: _record(RulesScript.PLAYER_FACTION, true),
		SupportIdsScript.SUPPORT_RIGHT_SOUTH: _record(RulesScript.PLAYER_FACTION, true),
		SupportIdsScript.SUPPORT_RIGHT_NORTH: _record(RulesScript.PLAYER_FACTION, true),
	})
	await _save("09-route-severed-branch-survives.png", "left route severed / right branch survives")
	_main.runtime.round_director.set_seed_for_tests(1107)
	_main.runtime.round_director.force_open_draft_for_test()
	await _frames(3)
	await _save("10-draft-three-choice.png", "formal Draft / exactly three choices")
	_main.runtime.three_choice_panel._toggle_peek()
	await _frames(2)
	await _save("11-battlefield-preview.png", "Battlefield Preview / Draft hidden / battle paused")
	_main.runtime.three_choice_panel._toggle_peek()
	await _frames(2)
	await _save("12-preview-return.png", "Preview return / same Offer geometry")
	root.size = NARROW
	_main.runtime.three_choice_panel.setup(_main.runtime.round_director, Vector2(NARROW))
	await _frames(3)
	await _save("13-narrow-draft.png", "narrow 760x540 Draft / all three choices visible")

	_main._cleanup_game_layer()
	TestFixtures.cleanup_node(_main)
	print("[CardfrontP0VisualEvidence] saved to %s" % _output_dir)
	quit(0)


func _capture_deployment_zone(file_name: String, scenario: String) -> int:
	var preview = TargetPreviewScript.new()
	root.add_child(preview)
	preview.setup(_main.runtime.battlefield, _main.runtime.region_map, GameConfig.GAME_MODE_CARDFRONT)
	preview.configure_deployment_authority(Callable(_authority, "deployment_context"), Callable(_authority, "deployment_revision"))
	_main.runtime.orthographic_arena_view.set_deployment_zone_source(preview)
	preview.show_for_card(99011, {"target_type": CardTargetTypeScript.FRONTLINE_DEPLOYMENT, "params": {}})
	await _frames(3)
	var visible_count: int = _main.runtime.orthographic_arena_view.get_deployment_zone_cell_count_for_test()
	await _save(file_name, "%s / %d allowed cells" % [scenario, visible_count])
	_main.runtime.orthographic_arena_view.set_deployment_zone_source(null)
	preview.queue_free()
	return visible_count


func _own_support_footprint(support_id: String) -> void:
	var context: Dictionary = _authority.deployment_context(RulesScript.PLAYER_FACTION)
	var owners: Array = _baseline_owners.duplicate(true)
	var extent: Vector2i = _main.runtime.battlefield.grid_extent
	for raw_source in context.get("support_sources", []) as Array:
		var source: Dictionary = raw_source as Dictionary
		if str(source.get("support_id", "")) != support_id:
			continue
		for x in range(extent.x):
			for y in range(extent.y):
				var cell := Vector2i(x, y)
				if DeploymentGeometryScript.classify(
					str(source.get("profile_id", "")),
					source.get("anchor_cell", Vector2i.ZERO) as Vector2i,
					source.get("forward", Vector2i.ZERO) as Vector2i,
					cell,
					extent
				) == DeploymentGeometryScript.CLASS_INSIDE:
					owners[x][y] = RulesScript.PLAYER_FACTION
		break
	_main.runtime.battlefield.replace_owners(owners, false)


func _set_support_states(overrides: Dictionary) -> void:
	var data: Dictionary = {}
	for support_id in _capture_runtime.states_by_support_id.keys():
		var record: Dictionary = (overrides.get(str(support_id), _default_record(str(support_id))) as Dictionary).duplicate(true)
		record["support_id"] = str(support_id)
		data[support_id] = record
	_capture_runtime.restore_states(data)


func _default_record(support_id: String) -> Dictionary:
	if support_id == SupportIdsScript.CORE_PLAYER:
		return _record(RulesScript.PLAYER_FACTION, true)
	if support_id == SupportIdsScript.CORE_AI:
		return _record(RulesScript.AI_FACTION, true)
	return _record(RulesScript.NEUTRAL_OWNER, false)


func _record(claim_owner: int, operational: bool, capture_side: int = -1, progress: float = 0.0) -> Dictionary:
	return {
		"support_id": "",
		"claim_owner": claim_owner,
		"operational": operational,
		"capture_side": capture_side,
		"capture_progress": progress,
	}


func _build_annotation() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 100
	root.add_child(canvas)
	_annotation = Label.new()
	_annotation.position = Vector2(8, 8)
	_annotation.add_theme_font_size_override("font_size", 15)
	_annotation.add_theme_color_override("font_color", Color.WHITE)
	_annotation.add_theme_color_override("font_outline_color", Color.BLACK)
	_annotation.add_theme_constant_override("outline_size", 5)
	canvas.add_child(_annotation)


func _save(file_name: String, scenario: String) -> void:
	_annotation.text = "commit %s | viewport %dx%d | %s" % [_sha, root.size.x, root.size.y, scenario]
	await _frames(3)
	var image := root.get_texture().get_image()
	var error: int = image.save_png(_output_dir.path_join(file_name))
	if error != OK:
		push_error("Cannot save %s (%d)" % [file_name, error])


func _frames(count: int) -> void:
	for _frame in count:
		await process_frame
