extends Node2D

# Main orchestration boundary:
# Allowed here:
# - create runtime systems
# - connect signals
# - switch top-level game/menu/pause states
# - delegate to coordinators/controllers/views
# Do not add here:
# - concrete physics behavior
# - concrete draw behavior
# - deep save-field repair
# - specific event effect implementation

const VIEW_W: float = 1120.0
const VIEW_H: float = 720.0
const LEGACY_SAVE_PATH: String = "user://ballwar_save.json"
const LEGACY_SLOT_SAVE_PATH_TEMPLATE: String = "user://ballwar_save_slot_%d.json"
const SAVE_PATH_TEMPLATE: String = "user://ballwar_save_slot_%d.save"
const SAVE_SLOT_COUNT: int = 5
const MENU_PREF_PATH: String = "user://menu_preferences.json"
const GameRuntimeContextScript = preload("res://scripts/GameRuntimeContext.gd")
const StartMenuUi = preload("res://scripts/StartMenu.gd")
const CardfrontModeScript = preload("res://scripts/cardfront/CardfrontMode.gd")

var runtime = GameRuntimeContextScript.new()
var current_score_counts: Dictionary = {0: 0, 1: 0, 2: 0, 3: 0}
var is_mobile_layout: bool = false

var menu_layer
var game_layer
var selected_grid_size: int = 40
var selected_palette_name: String = "默认随机"
var selected_quality_name: String = GameConfig.QUALITY_MEDIUM
var selected_game_mode_name: String = GameConfig.GAME_MODE_BASIC
var selected_time_limit_minutes: int = GameConfig.DEFAULT_TIMED_MODE_MINUTES
var selected_save_slot: int = 1
var game_elapsed_time: float = 0.0
var is_game_over: bool = false

var menu_title_label
var menu_start_button
var menu_continue_button
var menu_save_slot_buttons: Dictionary = {}
var menu_status_label
var pending_menu_status_message: String = ""
var ui_time: float = 0.0
var chamber_scale: float = 1.0
var pending_restore_bullets: Array = []
var pending_restore_index: int = 0
var perf_debug_update_timer: float = 0.0
var hud_meta_update_timer: float = 0.0
const PERF_DEBUG_UPDATE_INTERVAL: float = 0.25
const HUD_META_UPDATE_INTERVAL: float = 0.25

func _runtime_grid_size() -> int:
	return int(runtime.current_config.get("grid_size", selected_grid_size))

func _hud_ref(key: String, default_value = null):
	return runtime.hud_ref(key, default_value)

func _set_hud_ref(key: String, value) -> void:
	runtime.set_hud_ref(key, value)

func _ui_runtime_ref(key: String, default_value = null):
	return runtime.ui_runtime_ref(key, default_value)

func _set_ui_runtime_ref(key: String, value) -> void:
	runtime.set_ui_runtime_ref(key, value)

func _build_runtime_layout(grid_size: int) -> Dictionary:
	var layout: Dictionary = LayoutProfiles.get_profile(grid_size).duplicate(true)
	layout.merge(LayoutCoordinator.calculate_layout(grid_size, Vector2(VIEW_W, VIEW_H), is_mobile_layout), true)
	return layout

func _sync_runtime_context(grid_size: int) -> void:
	runtime.set_layout(_build_runtime_layout(grid_size))
	runtime.set_config({
		"grid_size": grid_size,
		"palette_name": selected_palette_name,
		"quality_name": selected_quality_name,
		"game_mode_name": selected_game_mode_name,
		"time_limit_minutes": selected_time_limit_minutes,
		"save_slot": selected_save_slot,
	})

func _is_cardfront_mode() -> bool:
	return CardfrontModeScript.is_selected(selected_game_mode_name)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	randomize()
	is_mobile_layout = _detect_mobile_layout()
	_load_menu_preferences()
	_create_background()
	_create_start_menu()

func _process(delta: float) -> void:
	ui_time += delta

	if GameStateCoordinator.should_process_restore_queue(get_tree(), is_game_over, pending_restore_bullets.size()):
		_process_pending_bullet_restore()

	if GameStateCoordinator.should_advance_gameplay(get_tree(), game_layer, is_game_over):
		game_elapsed_time += delta
		for chamber in runtime.chambers.values():
			if chamber != null and is_instance_valid(chamber):
				chamber.set_game_elapsed_time(game_elapsed_time)

	perf_debug_update_timer -= delta
	if perf_debug_update_timer <= 0.0:
		perf_debug_update_timer = PERF_DEBUG_UPDATE_INTERVAL
		var fps_label = _hud_ref("fps_label")
		if fps_label != null and is_instance_valid(fps_label):
			fps_label.text = RuntimeHudController.get_perf_debug_text(runtime.bullet_pool, runtime.battlefield, _runtime_grid_size(), runtime.turrets)

	hud_meta_update_timer -= delta
	if hud_meta_update_timer <= 0.0:
		hud_meta_update_timer = HUD_META_UPDATE_INTERVAL
		RuntimeHudController.update_meta(_hud_ref("timer_label"), _hud_ref("stage_label"), _hud_ref("leader_label"), current_score_counts, game_elapsed_time)
		_check_winner()

	UIAnimationController.animate_menu_and_title(
		ui_time,
		menu_title_label,
		menu_start_button,
		menu_continue_button,
		_hud_ref("game_title_label"),
		_hud_ref("winner_label")
	)
	UIAnimationController.animate_add_ball_buttons(
		get_tree().paused,
		_ui_runtime_ref("add_ball_buttons", {}),
		_ui_runtime_ref("add_ball_button_base_positions", {}),
		ui_time
	)

func _detect_mobile_layout() -> bool:
	if OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios"):
		return true
	if DisplayServer.get_name() == "headless" or GameConfig.is_test_mode():
		return false
	var screen_size: Vector2i = GameConfig.get_safe_screen_size()
	if screen_size.x <= 1400 or screen_size.y <= 900:
		return true
	return false

func _toggle_settings_panel() -> void:
	var settings_panel = _hud_ref("settings_panel")
	if settings_panel == null or not is_instance_valid(settings_panel):
		return
	if settings_panel.visible:
		if settings_panel.has_method("hide_panel"):
			settings_panel.hide_panel()
		else:
			settings_panel.visible = false
		return

	if settings_panel.has_method("show_content"):
		settings_panel.show_content(GameConfig.get_quality_name(), "手机横屏" if is_mobile_layout else "电脑")
	else:
		settings_panel.visible = true

func _create_background() -> void:
	var background = ColorRect.new()
	background.name = "MainBackground"
	background.color = Color(0.03, 0.07, 0.14)
	background.size = Vector2(VIEW_W, VIEW_H)
	add_child(background)
	background.z_index = -100

func _create_start_menu() -> void:
	if menu_layer != null:
		menu_layer.queue_free()

	var menu_nodes: Dictionary
	var menu_layout: Dictionary = _build_runtime_layout(LayoutProfiles.sanitize_grid_size(selected_grid_size))
	var scene_path: String = "res://scenes/ui/StartMenu.tscn"
	if ResourceLoader.exists(scene_path):
		var scene: PackedScene = load(scene_path)
		var instance: CanvasLayer = scene.instantiate()
		add_child(instance)
		instance.setup(self, Vector2(VIEW_W, VIEW_H), _get_save_slot_summaries(), menu_layout)
		menu_nodes = instance.get_parts()
		print("[StartMenu] Loaded scene StartMenu.tscn")
	else:
		menu_nodes = StartMenuView.create(self, Vector2(VIEW_W, VIEW_H), _get_save_slot_summaries(), menu_layout)
		print("[StartMenu] Scene load failed, fallback to legacy StartMenuView.gd")

	menu_layer = menu_nodes.get("menu_layer", null)
	menu_title_label = menu_nodes.get("menu_title_label", null)
	menu_start_button = menu_nodes.get("menu_start_button", null)
	menu_continue_button = menu_nodes.get("menu_continue_button", null)
	menu_save_slot_buttons = menu_nodes.get("menu_save_slot_buttons", {})
	menu_status_label = menu_nodes.get("menu_status_label", null)
	if pending_menu_status_message != "":
		_show_menu_status(pending_menu_status_message)
		pending_menu_status_message = ""

func _start_game(grid_size: int, suppress_banner: bool = false, clear_save: bool = true) -> void:
	grid_size = LayoutProfiles.sanitize_grid_size(grid_size)
	selected_grid_size = grid_size
	game_elapsed_time = 0.0
	is_game_over = false

	if clear_save and _has_save_file(selected_save_slot):
		var save_path: String = _get_save_path(selected_save_slot)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveFlowController.get_backup_path(save_path)))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveFlowController.get_temp_path(save_path)))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(LEGACY_SLOT_SAVE_PATH_TEMPLATE % selected_save_slot))
		if selected_save_slot == 1 and FileAccess.file_exists(LEGACY_SAVE_PATH):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(LEGACY_SAVE_PATH))

	GameConfig.set_quality_by_name(selected_quality_name)
	GameConfig.set_game_mode_by_name(selected_game_mode_name)
	GameConfig.set_time_limit_minutes(selected_time_limit_minutes)

	if selected_palette_name == "默认随机":
		GameConfig.set_random_palette()
	else:
		GameConfig.set_palette_by_name(selected_palette_name)

	_cleanup_menu()
	_cleanup_game_layer()
	get_tree().paused = false
	_sync_runtime_context(grid_size)

	game_layer = Node2D.new()
	game_layer.name = "GameLayer"
	# Main 是 ALWAYS 以便暂停菜单可点击，但游戏层必须显式设为 PAUSABLE。
	# 否则子节点继承 Main 的 ALWAYS，暂停后子弹/炮塔/控制仓仍会继续运行。
	game_layer.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(game_layer)

	_create_battlefield(grid_size)
	_create_cardfront_regions()
	_create_turrets()
	_create_control_chambers()
	_create_ui()
	if not _is_cardfront_mode():
		_create_event_roulette_system()
	_create_control_buttons()
	if not suppress_banner:
		if _is_cardfront_mode():
			_show_center_banner("卡牌前线", "玩家 vs AI 基线", Color(0.62, 0.90, 1.0), true)
		else:
			_show_center_banner("领土战争", "开战！", Color(1.0, 0.94, 0.48), true)

func _create_battlefield(grid_size: int) -> void:
	var scene_nodes: Dictionary = GameSceneBuilder.create_battlefield(self, game_layer, grid_size, runtime.current_layout, Vector2(VIEW_W, VIEW_H))
	runtime.battlefield = scene_nodes.get("battlefield", null)
	runtime.bullet_pool = scene_nodes.get("bullet_container", null)
	chamber_scale = float(scene_nodes.get("chamber_scale", 0.80))
	if _is_cardfront_mode():
		CardfrontModeScript.configure_battlefield(runtime.battlefield)

func _create_cardfront_regions() -> void:
	runtime.region_map = null
	runtime.region_overlay = null
	if not _is_cardfront_mode():
		return
	var region_setup: Dictionary = CardfrontModeScript.create_regions(game_layer, runtime.battlefield)
	if not bool(region_setup.get("configured", false)):
		push_warning("Cardfront region setup failed: %s" % str(region_setup.get("reason", "unknown")))
		return
	runtime.region_map = region_setup.get("region_map", null)
	runtime.region_overlay = region_setup.get("region_overlay", null)

func _create_turrets() -> void:
	var active_factions: Array = CardfrontModeScript.get_active_factions() if _is_cardfront_mode() else []
	runtime.turrets = GameSceneBuilder.create_turrets(self, game_layer, runtime.battlefield, runtime.bullet_pool, runtime.current_layout, active_factions)
	if runtime.bullet_pool != null and is_instance_valid(runtime.bullet_pool) and runtime.bullet_pool.has_method("set_tracked_turrets"):
		runtime.bullet_pool.set_tracked_turrets(runtime.turrets)

func _create_control_chambers() -> void:
	var active_factions: Array = CardfrontModeScript.get_active_factions() if _is_cardfront_mode() else []
	runtime.chambers = GameSceneBuilder.create_control_chambers(self, game_layer, runtime.battlefield, runtime.turrets, runtime.current_layout, chamber_scale, Vector2(VIEW_W, VIEW_H), active_factions)
	_sync_chamber_game_elapsed_time()

func _create_ui() -> void:
	var hud_nodes: Dictionary
	var scene_path: String = "res://scenes/ui/GameHUD.tscn"
	if ResourceLoader.exists(scene_path):
		var scene: PackedScene = load(scene_path)
		var game_hud: CanvasLayer = scene.instantiate()
		game_hud.name = "UICanvas"
		game_layer.add_child(game_hud)
		game_hud.setup_static(self, Vector2(VIEW_W, VIEW_H), runtime.current_layout, is_mobile_layout)
		hud_nodes = game_hud.get_static_parts()
		print("[GameHUD] Loaded scene GameHUD.tscn")
	else:
		hud_nodes = GameHudView.create_runtime_ui(self, game_layer, runtime.battlefield, runtime.current_layout, Vector2(VIEW_W, VIEW_H), is_mobile_layout)
		print("[GameHUD] Scene load failed, fallback to legacy GameHudView.gd")

	runtime.set_hud_parts(hud_nodes)
	runtime.set_ui_runtime_parts({
		"top_bar_segments": hud_nodes.get("top_bar_segments", {}),
		"top_bar_labels": hud_nodes.get("top_bar_labels", {}),
		"top_bar_name_labels": hud_nodes.get("top_bar_name_labels", {}),
		"top_bar_total_width": hud_nodes.get("top_bar_total_width", 0.0),
	})
	runtime.set_hud_ref("opening_banner", null)

	_on_scores_changed(runtime.battlefield.count_cells_by_team())

func _create_event_roulette_system() -> void:
	var ui_canvas = _hud_ref("ui_canvas")
	if game_layer == null or ui_canvas == null:
		return

	var scene_path: String = "res://scenes/ui/EventRouletteView.tscn"
	if ResourceLoader.exists(scene_path):
		var scene: PackedScene = load(scene_path)
		runtime.event_view = scene.instantiate()
		runtime.event_view.setup(Vector2(VIEW_W, VIEW_H), runtime.current_layout, is_mobile_layout)
		print("[EventRoulette] Loaded scene EventRouletteView.tscn")
	else:
		var event_view_script = load("res://scripts/EventRouletteView.gd")
		runtime.event_view = event_view_script.new()
		runtime.event_view.name = "EventRouletteView"
		runtime.event_view.setup(Vector2(VIEW_W, VIEW_H), runtime.current_layout, is_mobile_layout)
		print("[EventRoulette] Scene load failed, fallback to legacy EventRouletteView.gd")
	ui_canvas.add_child(runtime.event_view)

	var event_controller_script = load("res://scripts/EventRouletteController.gd")
	runtime.event_controller = event_controller_script.new()
	runtime.event_controller.name = "EventRouletteController"
	game_layer.add_child(runtime.event_controller)
	runtime.event_controller.setup(self, runtime.battlefield, runtime.chambers, runtime.turrets, _hud_ref("event_label"), runtime.event_view)

	var finished_callable: Callable = Callable(self, "_on_event_round_finished")
	if not runtime.event_controller.event_round_finished.is_connected(finished_callable):
		runtime.event_controller.event_round_finished.connect(finished_callable)
	var banner_callable: Callable = Callable(self, "_on_event_banner_requested")
	if not runtime.event_controller.banner_requested.is_connected(banner_callable):
		runtime.event_controller.banner_requested.connect(banner_callable)
	var chamber_refresh_callable: Callable = Callable(self, "_on_event_chamber_ui_refresh_requested")
	if not runtime.event_controller.chamber_ui_refresh_requested.is_connected(chamber_refresh_callable):
		runtime.event_controller.chamber_ui_refresh_requested.connect(chamber_refresh_callable)

	_refresh_event_log()

func _create_control_buttons() -> void:
	var button_nodes: Dictionary = GameHudView.create_control_buttons(self, game_layer, runtime.chambers, runtime.current_layout, Vector2(VIEW_W, VIEW_H), is_mobile_layout)
	_set_ui_runtime_ref("add_ball_buttons", button_nodes.get("add_ball_buttons", {}))
	_set_ui_runtime_ref("add_ball_button_base_positions", button_nodes.get("add_ball_button_base_positions", {}))
	for faction_id in _ui_runtime_ref("add_ball_buttons", {}).keys():
		_refresh_add_ball_button(faction_id)

func _add_ball_to_chamber(faction_id: int) -> void:
	if not runtime.chambers.has(faction_id):
		return
	runtime.chambers[faction_id].add_control_ball()
	_refresh_add_ball_button(faction_id)

func _on_ball_count_changed(faction_id: int, _count: int) -> void:
	_refresh_add_ball_button(faction_id)

func _refresh_add_ball_button(faction_id: int) -> void:
	GameHudView.refresh_add_ball_button(faction_id, _ui_runtime_ref("add_ball_buttons", {}), runtime.chambers)

func _on_chamber_release_requested(faction_id, bullet_count, chamber) -> void:
	if is_game_over:
		chamber.set_locked(false)
		_refresh_add_ball_button(faction_id)
		return

	if runtime.turrets.has(faction_id):
		chamber.start_locked(bullet_count)
		_refresh_add_ball_button(faction_id)
		runtime.turrets[faction_id].fire_burst(bullet_count)

func _on_turret_burst_progress(faction_id, remaining) -> void:
	if runtime.chambers.has(faction_id):
		runtime.chambers[faction_id].update_locked_remaining(remaining)
	_refresh_add_ball_button(faction_id)

func _on_turret_burst_lock_changed(faction_id, locked) -> void:
	if runtime.chambers.has(faction_id):
		runtime.chambers[faction_id].set_locked(locked)
	_refresh_add_ball_button(faction_id)

func _on_turret_destroyed(faction_id: int) -> void:
	if runtime.chambers.has(faction_id):
		runtime.chambers[faction_id].set_damaged()
	_refresh_add_ball_button(faction_id)
	_check_winner()

func _check_winner() -> void:
	if is_game_over:
		return
	if game_layer == null or runtime.battlefield == null or runtime.turrets.is_empty():
		return

	var mode_name: String = GameConfig.get_game_mode_name()
	var counts: Dictionary = current_score_counts
	if counts.is_empty() and runtime.battlefield != null and is_instance_valid(runtime.battlefield):
		counts = runtime.battlefield.count_cells_by_team()

	var time_expired: bool = (mode_name == GameConfig.GAME_MODE_TIMED and game_elapsed_time >= GameConfig.get_time_limit_seconds()) \
		or (mode_name == GameConfig.GAME_MODE_CARDFRONT and game_elapsed_time >= CardfrontModeScript.get_match_duration_seconds())
	var total_cells: int = _runtime_grid_size() * _runtime_grid_size()

	var result: Dictionary = WinConditionEvaluator.evaluate(mode_name, runtime.turrets, counts, total_cells, time_expired)

	if not result.ended:
		return
	if result.draw:
		_finish_as_draw(result.sub_text)
	else:
		_finish_with_winner(result.winner, result.sub_text)

func _finish_with_winner(faction_id: int, sub_text: String) -> void:
	GameStateCoordinator.finish_with_winner(self, _hud_ref("winner_label"), faction_id, sub_text)

func _finish_as_draw(sub_text: String) -> void:
	GameStateCoordinator.finish_as_draw(self, _hud_ref("winner_label"), sub_text)

func _stop_all_actions_for_game_over() -> void:
	GameStateCoordinator.stop_actions_for_game_over(
		runtime.turrets,
		runtime.chambers,
		Callable(self, "_refresh_add_ball_button"),
		Callable(self, "_clear_bullets"),
		runtime.event_controller,
		runtime.event_view
	)

func _on_scores_changed(counts: Dictionary) -> void:
	current_score_counts = counts.duplicate()
	RuntimeHudController.update_top_bar(
		counts,
		_ui_runtime_ref("top_bar_segments", {}),
		_ui_runtime_ref("top_bar_labels", {}),
		_ui_runtime_ref("top_bar_name_labels", {}),
		float(_ui_runtime_ref("top_bar_total_width", 0.0)),
		is_mobile_layout
	)
	RuntimeHudController.update_meta(_hud_ref("timer_label"), _hud_ref("stage_label"), _hud_ref("leader_label"), current_score_counts, game_elapsed_time)

func _show_center_banner(title_text: String, sub_text: String, accent: Color, auto_hide: bool) -> void:
	_set_hud_ref(
		"opening_banner",
		BannerController.show(
			self,
			_hud_ref("ui_canvas"),
			_hud_ref("opening_banner"),
			Vector2(VIEW_W, VIEW_H),
			runtime.current_layout,
			title_text,
			sub_text,
			accent,
			auto_hide
		)
	)

func _sync_chamber_game_elapsed_time() -> void:
	for chamber in runtime.chambers.values():
		if chamber != null and is_instance_valid(chamber):
			chamber.set_game_elapsed_time(game_elapsed_time)
			chamber.queue_redraw()

func _toggle_pause() -> void:
	if GameStateCoordinator.should_ignore_pause(is_game_over, game_layer):
		return
	GameStateCoordinator.apply_pause_toggle(
		get_tree(),
		_hud_ref("pause_overlay"),
		_hud_ref("pause_button"),
		Callable(self, "_save_game_progress")
	)

func _refresh_event_log() -> void:
	var event_log_label = _hud_ref("event_log_label")
	if event_log_label == null or not is_instance_valid(event_log_label):
		return
	if runtime.event_controller == null or not is_instance_valid(runtime.event_controller):
		return
	if not runtime.event_controller.has_method("get_event_log_text"):
		return
	var log_text: String = runtime.event_controller.get_event_log_text(8)
	if log_text.is_empty():
		return
	if event_log_label.has_method("update_event_log"):
		event_log_label.update_event_log(log_text)
	else:
		event_log_label.text = log_text

func _on_event_round_finished(_payload: Dictionary) -> void:
	_refresh_event_log()

func _on_event_banner_requested(title_text: String, sub_text: String, accent: Color, auto_hide: bool) -> void:
	_show_center_banner(title_text, sub_text, accent, auto_hide)

func _on_event_chamber_ui_refresh_requested(faction_id: int) -> void:
	_refresh_add_ball_button(faction_id)

func _load_menu_preferences() -> void:
	if not FileAccess.file_exists(MENU_PREF_PATH):
		return
	var file: FileAccess = FileAccess.open(MENU_PREF_PATH, FileAccess.READ)
	if file == null:
		return
	var raw_text: String = file.get_as_text()
	file.close()
	if raw_text.is_empty():
		return
	var test_json = JSON.new()
	if test_json.parse(raw_text) != OK:
		return
	var data = test_json.get_data()
	if not (data is Dictionary):
		return
	selected_grid_size = LayoutProfiles.sanitize_grid_size(int(data.get("grid_size", 40)))
	selected_palette_name = _sanitize_pref_palette(str(data.get("palette_name", "默认随机")))
	selected_quality_name = _sanitize_pref_quality(str(data.get("quality_name", GameConfig.QUALITY_MEDIUM)))
	selected_game_mode_name = _sanitize_pref_mode(str(data.get("game_mode_name", GameConfig.GAME_MODE_BASIC)))
	selected_time_limit_minutes = clampi(int(data.get("time_limit_minutes", GameConfig.DEFAULT_TIMED_MODE_MINUTES)), GameConfig.TIMED_MODE_MIN_MINUTES, GameConfig.TIMED_MODE_MAX_MINUTES)
	selected_save_slot = clampi(int(data.get("save_slot", 1)), 1, SAVE_SLOT_COUNT)

func _sanitize_pref_palette(value: String) -> String:
	if value == "默认随机":
		return value
	for pn in GameConfig.get_palette_names():
		if pn == value:
			return value
	return "默认随机"

func _sanitize_pref_quality(value: String) -> String:
	for qn in GameConfig.get_quality_names():
		if qn == value:
			return value
	return GameConfig.QUALITY_MEDIUM

func _sanitize_pref_mode(value: String) -> String:
	for mn in GameConfig.get_game_mode_names():
		if mn == value:
			return value
	return GameConfig.GAME_MODE_BASIC

func _save_menu_preferences() -> void:
	var data: Dictionary = {
		"grid_size": selected_grid_size,
		"palette_name": selected_palette_name,
		"quality_name": selected_quality_name,
		"game_mode_name": selected_game_mode_name,
		"time_limit_minutes": selected_time_limit_minutes,
		"save_slot": selected_save_slot,
	}
	var file: FileAccess = FileAccess.open(MENU_PREF_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("[Main] cannot write menu preferences")
		return
	file.store_string(JSON.stringify(data, "\t", false, true))
	file.close()

func reset_menu_preferences() -> void:
	selected_grid_size = 40
	selected_palette_name = "默认随机"
	selected_quality_name = GameConfig.QUALITY_MEDIUM
	selected_game_mode_name = GameConfig.GAME_MODE_BASIC
	selected_time_limit_minutes = GameConfig.DEFAULT_TIMED_MODE_MINUTES
	_save_menu_preferences()
	_create_start_menu()

func _save_and_exit_to_menu() -> void:
	if runtime.battlefield != null:
		_save_game_progress()
	get_tree().paused = false
	_cleanup_game_layer()
	_create_start_menu()

func _cleanup_menu() -> void:
	if menu_layer != null:
		menu_layer.queue_free()
		menu_layer = null
	menu_title_label = null
	menu_start_button = null
	menu_continue_button = null
	menu_save_slot_buttons.clear()
	menu_status_label = null

func _cleanup_game_layer() -> void:
	GameStateCoordinator.reset_pause_and_winner_state(_hud_ref("pause_overlay"), _hud_ref("pause_button"), _hud_ref("winner_label"))
	if game_layer != null:
		game_layer.queue_free()
		game_layer = null
	runtime.reset()
	pending_restore_bullets.clear()
	pending_restore_index = 0

func _get_save_path(slot_index: int) -> String:
	return SaveFlowController.get_save_path(slot_index, SAVE_PATH_TEMPLATE, SAVE_SLOT_COUNT)

func _has_save_file(slot_index: int = -1) -> bool:
	return SaveFlowController.has_save_file(
		slot_index,
		selected_save_slot,
		SAVE_SLOT_COUNT,
		SAVE_PATH_TEMPLATE,
		LEGACY_SAVE_PATH,
		LEGACY_SLOT_SAVE_PATH_TEMPLATE
	)

func _get_save_slot_summaries() -> Array:
	return SaveFlowController.build_save_slot_summaries(
		SAVE_SLOT_COUNT,
		Callable(self, "_load_saved_data")
	)

func _clear_bullets() -> void:
	if runtime.bullet_pool == null:
		return
	if runtime.bullet_pool.has_method("clear_active"):
		runtime.bullet_pool.clear_active()
	else:
		for node in runtime.bullet_pool.get_children():
			node.queue_free()

func _restore_bullet_states(states) -> void:
	if runtime.bullet_pool == null or runtime.battlefield == null:
		return

	_clear_bullets()
	pending_restore_bullets.clear()
	pending_restore_index = 0

	if not (states is Array):
		return

	var restore_count: int = mini(states.size(), GameConfig.get_restore_bullet_limit())
	for i in range(restore_count):
		if states[i] is Dictionary:
			pending_restore_bullets.append(states[i])

func _process_pending_bullet_restore() -> void:
	if runtime.bullet_pool == null or runtime.battlefield == null:
		pending_restore_bullets.clear()
		pending_restore_index = 0
		return

	var end_index: int = mini(pending_restore_index + GameConfig.get_restore_per_frame(), pending_restore_bullets.size())
	for i in range(pending_restore_index, end_index):
		var state = pending_restore_bullets[i]
		if not (state is Dictionary):
			continue

		var bullet
		if runtime.bullet_pool.has_method("spawn_bullet_from_state"):
			bullet = runtime.bullet_pool.spawn_bullet_from_state(state, runtime.battlefield, runtime.turrets)
		else:
			bullet = Bullet.new()
			bullet.restore_from_state(state, runtime.battlefield, runtime.turrets)
			bullet.activate()
			runtime.bullet_pool.add_child(bullet)

	pending_restore_index = end_index
	if pending_restore_index >= pending_restore_bullets.size():
		pending_restore_bullets.clear()
		pending_restore_index = 0


func _save_game_progress() -> Dictionary:
	var result: Dictionary = SaveFlowController.write_game_progress_result(
		selected_save_slot,
		SAVE_PATH_TEMPLATE,
		SAVE_SLOT_COUNT,
		runtime.chambers,
		runtime.turrets,
		runtime.battlefield,
		runtime.bullet_pool,
		runtime.event_controller,
		game_elapsed_time,
		is_game_over,
		_hud_ref("winner_label")
	)
	if not bool(result.get("ok", false)):
		pending_menu_status_message = str(result.get("error_message", "保存失败"))
		push_warning(pending_menu_status_message)
		if _hud_ref("ui_canvas") != null:
			_show_center_banner("保存失败", pending_menu_status_message, Color(1.0, 0.50, 0.36), true)
	return result

func _load_saved_data(slot_index: int = -1, allow_legacy: bool = true) -> Dictionary:
	return SaveFlowController.load_saved_data(
		slot_index,
		selected_save_slot,
		SAVE_SLOT_COUNT,
		SAVE_PATH_TEMPLATE,
		LEGACY_SAVE_PATH,
		allow_legacy,
		LEGACY_SLOT_SAVE_PATH_TEMPLATE
	)

func _select_save_slot(slot_index: int) -> void:
	selected_save_slot = SaveFlowController.normalize_slot(slot_index, selected_save_slot, SAVE_SLOT_COUNT)
	_save_menu_preferences()
	_show_menu_status(SaveFlowController.build_slot_selection_status_message(selected_save_slot, _has_save_file(selected_save_slot)))
	_refresh_menu_save_slots()

func _refresh_menu_save_slots() -> void:
	var summaries: Array = _get_save_slot_summaries()
	if menu_layer != null and is_instance_valid(menu_layer) and menu_layer.has_method("refresh_slots"):
		menu_layer.refresh_slots(summaries)
		return
	if menu_layer != null and is_instance_valid(menu_layer) and menu_layer.has_method("refresh_save_slots"):
		menu_layer.refresh_save_slots(summaries)
		return
	_refresh_menu_slot_buttons_fallback(summaries)

func _refresh_menu_slot_buttons_fallback(summaries: Array) -> void:
	for summary in summaries:
		if not (summary is Dictionary):
			continue
		var slot: int = int(summary.get("slot", 1))
		if not menu_save_slot_buttons.has(slot):
			continue
		var button: Button = menu_save_slot_buttons[slot] as Button
		if button == null or not is_instance_valid(button):
			continue
		button.text = StartMenuUi.build_slot_label(slot, summary, selected_save_slot)
		button.tooltip_text = str(summary.get("detail", "点击选择此槽"))
		button.self_modulate = Color(0.28, 0.54, 0.88) if slot == selected_save_slot else Color(0.16, 0.22, 0.32)

	var has_selected_save: bool = _has_save_file(selected_save_slot)
	if menu_continue_button != null and is_instance_valid(menu_continue_button):
		menu_continue_button.disabled = not has_selected_save
		menu_continue_button.text = StartMenuUi.build_continue_button_text(selected_save_slot)
	if menu_start_button != null and is_instance_valid(menu_start_button):
		menu_start_button.text = StartMenuUi.build_start_button_label(selected_save_slot, has_selected_save)

func _show_menu_status(message: String) -> void:
	if menu_status_label != null and is_instance_valid(menu_status_label):
		menu_status_label.text = message
	else:
		push_warning(message)

func _continue_saved_game() -> void:
	var prepared: Dictionary = SaveFlowController.prepare_continue_payload(
		-1,
		selected_save_slot,
		SAVE_SLOT_COUNT,
		SAVE_PATH_TEMPLATE,
		LEGACY_SAVE_PATH,
		true,
		LEGACY_SLOT_SAVE_PATH_TEMPLATE
	)
	if not bool(prepared.get("ok", false)):
		_show_menu_status(str(prepared.get("error_message", "存档读取失败或存档已损坏")))
		var warning_message: String = str(prepared.get("warning_message", ""))
		if warning_message != "":
			push_warning(warning_message)
		return

	_continue_from_prepared_payload(prepared)

func _apply_saved_state(restore_input) -> void:
	if runtime.battlefield == null:
		return

	var restore_plan: RestorePlan = restore_input if restore_input is RestorePlan else RestorePlan.build_from_clean_data(restore_input if restore_input is Dictionary else {})
	var restore_data: Dictionary = restore_plan.to_restore_dictionary()

	SaveStateApplier.apply_owners(runtime.battlefield, restore_data, Callable(self, "_on_scores_changed"))
	SaveStateApplier.apply_factions(
		runtime.chambers,
		runtime.turrets,
		restore_plan.faction_states,
		func(chamber): chamber.set_locked(false),
		Callable(self, "_refresh_add_ball_button")
	)

	SaveStateApplier.apply_event_state(runtime.event_controller, {"event_state": restore_plan.event_state})

	_refresh_event_log()

	_restore_bullet_states(restore_plan.bullet_states)

	is_game_over = SaveStateApplier.apply_game_over_state(restore_plan.game_over_state, _hud_ref("winner_label"))
	if is_game_over:
		_stop_all_actions_for_game_over()

func _continue_from_prepared_payload(prepared: Dictionary) -> void:
	var execution_plan: Dictionary = SaveFlowController.prepare_continue_start_plan(prepared.get("data", {}), selected_time_limit_minutes)
	var status_message: String = str(prepared.get("status_message", ""))
	if status_message != "":
		var banner: Dictionary = execution_plan.get("banner", {}).duplicate(true)
		banner["subtitle"] = "%s\n%s" % [str(banner.get("subtitle", "继续作战")), status_message]
		execution_plan["banner"] = banner
	var execution_data: Dictionary = execution_plan.get("data", {})
	var restore_plan: RestorePlan = RestorePlan.build_from_clean_data(execution_data)
	_apply_continue_start_plan(execution_plan, restore_plan)

func _apply_continue_start_plan(execution_plan: Dictionary, restore_plan: RestorePlan) -> void:
	var execution_start_values: Dictionary = execution_plan.get("start_values", {})
	var execution_banner: Dictionary = execution_plan.get("banner", {})
	SaveFlowController.apply_continue_start_plan(execution_plan, self)
	_start_game(int(execution_start_values.get("grid_size", 40)), true, false)
	game_elapsed_time = float(execution_start_values.get("game_elapsed_time", 0.0))
	_sync_chamber_game_elapsed_time()
	_apply_saved_state(restore_plan)
	_show_center_banner(
		str(execution_banner.get("title", "领土战争")),
		str(execution_banner.get("subtitle", "继续作战")),
		execution_banner.get("accent", Color(0.84, 0.96, 1.0)),
		bool(execution_banner.get("auto_hide", true))
	)
