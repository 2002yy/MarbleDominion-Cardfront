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
const GridExtentScript = preload("res://scripts/GridExtent.gd")
const StartMenuUi = preload("res://scripts/StartMenu.gd")
const CardfrontModeScript = preload("res://scripts/cardfront/CardfrontMode.gd")
const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const CardfrontRuntimeBuilderScript = preload("res://scripts/cardfront/runtime/CardfrontRuntimeBuilder.gd")
const CardfrontRuntimeSnapshotScript = preload("res://scripts/cardfront/save/CardfrontRuntimeSnapshot.gd")
const CardfrontMatchPhaseScript = preload("res://scripts/cardfront/run/CardfrontMatchPhase.gd")
const NetworkManagerScript = preload("res://scripts/cardfront/network/CardfrontNetworkManager.gd")
const PvpMatchScript = preload("res://scripts/cardfront/network/CardfrontPvpMatch.gd")
const NetworkProtocolScript = preload("res://scripts/cardfront/network/CardfrontNetworkProtocol.gd")
const CardfrontStatusFormatterScript = preload("res://scripts/cardfront/ui/CardfrontStatusFormatter.gd")
const CardfrontMatchFlowTextScript = preload("res://scripts/cardfront/ui/CardfrontMatchFlowText.gd")
const CardfrontHeroRegistryScript = preload("res://scripts/cardfront/heroes/CardfrontHeroRegistry.gd")
const CardfrontMapRegistryScript = preload("res://scripts/cardfront/maps/CardfrontMapRegistry.gd")
const CardfrontHUDScene = preload("res://scenes/ui/cardfront/CardfrontHUD.tscn")
const CardfrontPrematchScene = preload("res://scenes/ui/cardfront/CardfrontPrematchScreen.tscn")
const CardfrontBattleHeroHudScene = preload("res://scenes/ui/cardfront/CardfrontBattleHeroHud.tscn")
const GameHUDScene = preload("res://scenes/ui/GameHUD.tscn")

var runtime = GameRuntimeContextScript.new()
var cardfront_runtime_builder = null
var cardfront_legacy_compatibility_enabled: bool = false
var current_score_counts: Dictionary = {0: 0, 1: 0, 2: 0, 3: 0}
var is_mobile_layout: bool = false

var menu_layer
var game_layer
var selected_grid_size: int = 40
var selected_grid_extent: Vector2i = GridExtentScript.DEFAULT
var selected_palette_name: String = "默认随机"
var selected_quality_name: String = GameConfig.QUALITY_MEDIUM
var selected_game_mode_name: String = GameConfig.GAME_MODE_BASIC
var selected_cardfront_player_hero_id: String = CardfrontHeroRegistryScript.DEFAULT_PLAYER_HERO_ID
var selected_cardfront_ai_hero_id: String = CardfrontHeroRegistryScript.DEFAULT_AI_HERO_ID
var selected_cardfront_map_id: String = CardfrontMapRegistryScript.DEFAULT_DUEL_MAP_ID
var selected_time_limit_minutes: int = GameConfig.DEFAULT_TIMED_MODE_MINUTES
var selected_save_slot: int = 1
var game_elapsed_time: float = 0.0
var is_game_over: bool = false

var menu_title_label
var menu_start_button
var menu_continue_button
var menu_save_slot_buttons: Dictionary = {}
var menu_status_label
var cardfront_prematch_screen = null
var _command_point_label: Label = null
var _pvp_lobby_panel: Control = null
var _pvp_status_label: Label = null
var _pvp_ip_input: LineEdit = null
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

func _runtime_grid_extent() -> Vector2i:
	return GridExtentScript.from_config(runtime.current_config, selected_grid_extent)

func _runtime_cell_count() -> int:
	return GridExtentScript.cell_count(_runtime_grid_extent())

func _hud_ref(key: String, default_value = null):
	return runtime.hud_ref(key, default_value)

func _cardfront_status_label():
	# semantic alias: Cardfront uses event_label as status bar; BallWar keeps event log
	return _hud_ref("event_label")

func _set_hud_ref(key: String, value) -> void:
	runtime.set_hud_ref(key, value)

func _ui_runtime_ref(key: String, default_value = null):
	return runtime.ui_runtime_ref(key, default_value)

func _set_ui_runtime_ref(key: String, value) -> void:
	runtime.set_ui_runtime_ref(key, value)

func _build_runtime_layout(grid_extent_value) -> Dictionary:
	var extent := GridExtentScript.sanitize(grid_extent_value)
	var profile_size: int = maxi(extent.x, extent.y)
	var layout: Dictionary = LayoutProfiles.get_profile(profile_size).duplicate(true)
	layout.merge(LayoutCoordinator.calculate_layout(profile_size, Vector2(VIEW_W, VIEW_H), is_mobile_layout), true)
	if _is_cardfront_mode():
		layout = CardfrontModeScript.configure_runtime_layout(layout, extent, Vector2(VIEW_W, VIEW_H))
	return layout

func _sync_runtime_context(grid_extent_value) -> void:
	var extent := GridExtentScript.sanitize(grid_extent_value)
	runtime.set_layout(_build_runtime_layout(extent))
	runtime.set_config({
		"grid_size": extent.x,
		"grid_extent": GridExtentScript.to_array(extent),
		"palette_name": selected_palette_name,
		"quality_name": selected_quality_name,
		"game_mode_name": selected_game_mode_name,
		"player_hero_id": selected_cardfront_player_hero_id,
		"ai_hero_id": selected_cardfront_ai_hero_id,
		"map_id": selected_cardfront_map_id,
		"time_limit_minutes": selected_time_limit_minutes,
		"save_slot": selected_save_slot,
	})

func _is_cardfront_mode() -> bool:
	return CardfrontModeScript.is_selected(selected_game_mode_name)

func _ensure_cardfront_runtime_builder():
	if cardfront_runtime_builder == null:
		cardfront_runtime_builder = CardfrontRuntimeBuilderScript.new()
	return cardfront_runtime_builder

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
			if _is_cardfront_mode():
				fps_label.text = "FPS %d | %s" % [Engine.get_frames_per_second(), _build_cardfront_status_text()]
			else:
				fps_label.text = RuntimeHudController.get_perf_debug_text(runtime.bullet_pool, runtime.battlefield, _runtime_grid_size(), runtime.turrets)

	hud_meta_update_timer -= delta
	if hud_meta_update_timer <= 0.0:
		hud_meta_update_timer = HUD_META_UPDATE_INTERVAL
		RuntimeHudController.update_meta(_hud_ref("timer_label"), _hud_ref("stage_label"), _hud_ref("leader_label"), current_score_counts, game_elapsed_time)
		_update_cardfront_status_label()
		_check_winner()

	if runtime.region_info_panel != null and runtime.battlefield != null and is_instance_valid(runtime.battlefield) and runtime.battlefield.has_method("world_to_cell"):
		var mouse_cell: Vector2i = runtime.battlefield.world_to_cell(get_global_mouse_position())
		runtime.region_info_panel.update_for_cell(mouse_cell)

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
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	_add_pvp_menu_button()

func _start_game(grid_extent_value, suppress_banner: bool = false, clear_save: bool = true) -> void:
	var grid_extent := GridExtentScript.sanitize(grid_extent_value)
	if not _is_cardfront_mode() and not GridExtentScript.is_square(grid_extent):
		var legacy_side: int = LayoutProfiles.sanitize_grid_size(grid_extent.x)
		grid_extent = Vector2i(legacy_side, legacy_side)
	selected_grid_extent = grid_extent
	selected_grid_size = grid_extent.x
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
	_sync_runtime_context(grid_extent)

	game_layer = Node2D.new()
	game_layer.name = "GameLayer"
	# Main 是 ALWAYS 以便暂停菜单可点击，但游戏层必须显式设为 PAUSABLE。
	# 否则子节点继承 Main 的 ALWAYS，暂停后子弹/炮塔/控制仓仍会继续运行。
	game_layer.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(game_layer)

	_create_battlefield(grid_extent)
	_create_cardfront_runtime_core()
	_create_turrets()
	_create_cardfront_runtime_world_layers()
	_create_control_chambers()
	_create_ui()
	if not _is_cardfront_mode():
		_create_event_roulette_system()
	_create_control_buttons()
	if not suppress_banner:
		if _is_cardfront_mode():
			_show_center_banner("卡牌前线", CardfrontMatchFlowTextScript.opening_hint_text(), Color(0.62, 0.90, 1.0), true)
		else:
			_show_center_banner("领土战争", "开战！", Color(1.0, 0.94, 0.48), true)

func _create_battlefield(grid_extent_value) -> void:
	var scene_nodes: Dictionary = GameSceneBuilder.create_battlefield(self, game_layer, grid_extent_value, runtime.current_layout, Vector2(VIEW_W, VIEW_H))
	runtime.battlefield = scene_nodes.get("battlefield", null)
	runtime.bullet_pool = scene_nodes.get("bullet_container", null)
	chamber_scale = float(scene_nodes.get("chamber_scale", 0.80))
	if _is_cardfront_mode():
		CardfrontModeScript.configure_battlefield(runtime.battlefield)

func _create_cardfront_runtime_core() -> void:
	if not _is_cardfront_mode():
		return
	var builder = _ensure_cardfront_runtime_builder()
	var result: Dictionary
	if cardfront_legacy_compatibility_enabled:
		result = builder.build_core_systems(game_layer, runtime, Callable(self, "_on_cardfront_yield_tick"))
	else:
		result = builder.build_live_core_systems(game_layer, runtime)
	if not bool(result.get("configured", false)):
		push_warning("Cardfront runtime core setup failed: %s" % str(result.get("failures", [])))


func _on_cardfront_yield_tick(owner_id: int, yield_data: Dictionary) -> void:
	runtime.last_yield_snapshot[owner_id] = yield_data


func _create_turrets() -> void:
	var active_factions: Array = CardfrontModeScript.get_active_factions() if _is_cardfront_mode() else []
	runtime.turrets = GameSceneBuilder.create_turrets(self, game_layer, runtime.battlefield, runtime.bullet_pool, runtime.current_layout, active_factions)
	if runtime.bullet_pool != null and is_instance_valid(runtime.bullet_pool) and runtime.bullet_pool.has_method("set_tracked_turrets"):
		runtime.bullet_pool.set_tracked_turrets(runtime.turrets)

func _create_cardfront_runtime_world_layers() -> void:
	if not _is_cardfront_mode():
		return
	var builder = _ensure_cardfront_runtime_builder()
	var result: Dictionary
	if cardfront_legacy_compatibility_enabled:
		result = builder.build_world_layers(game_layer, runtime)
	else:
		result = builder.build_live_world_layers(game_layer, runtime)
	if not bool(result.get("configured", false)):
		push_warning("Cardfront runtime world-layer setup failed: %s" % str(result.get("failures", [])))


func _create_cardfront_feedback_bus() -> void:
	runtime.cardfront_feedback_bus = null
	if not _is_cardfront_mode():
		return
	var ui_canvas = _hud_ref("ui_canvas")
	if ui_canvas == null:
		return
	var bus_setup: Dictionary = CardfrontModeScript.create_feedback_bus(ui_canvas)
	if not bool(bus_setup.get("configured", false)):
		return
	runtime.cardfront_feedback_bus = bus_setup.get("feedback_bus", null)


func _create_cardfront_top_resource_bar() -> void:
	runtime.top_resource_bar = null
	if not _is_cardfront_mode():
		return
	var ui_canvas = _hud_ref("ui_canvas")
	if ui_canvas == null:
		return
	var bar_setup: Dictionary = CardfrontModeScript.create_top_resource_bar(ui_canvas, runtime.economy_system, runtime.resource_states)
	if not bool(bar_setup.get("configured", false)):
		return
	runtime.top_resource_bar = bar_setup.get("top_resource_bar", null)


func _create_cardfront_aim_control() -> void:
	runtime.aim_control = null
	if not _is_cardfront_mode():
		return
	var ui_canvas = _hud_ref("ui_canvas")
	if ui_canvas == null:
		return
	var control_setup: Dictionary = CardfrontModeScript.create_aim_control(ui_canvas, runtime.direction_controller, runtime.current_layout)
	if bool(control_setup.get("configured", false)):
		runtime.aim_control = control_setup.get("aim_control", null)


func _create_cardfront_three_choice_panel() -> void:
	runtime.three_choice_panel = null
	if not _is_cardfront_mode():
		return
	var ui_canvas = _hud_ref("ui_canvas")
	if ui_canvas == null:
		return
	var setup_result: Dictionary = CardfrontModeScript.create_three_choice_panel(
		ui_canvas,
		runtime.round_director,
		Vector2(VIEW_W, VIEW_H)
	)
	if bool(setup_result.get("configured", false)):
		runtime.three_choice_panel = setup_result.get("three_choice_panel", null)


func _create_cardfront_region_info_panel() -> void:
	runtime.region_info_panel = null
	if not _is_cardfront_mode():
		return
	var ui_canvas = _hud_ref("ui_canvas")
	if ui_canvas == null:
		return
	var panel_setup: Dictionary = CardfrontModeScript.create_region_info_panel(
		ui_canvas,
		runtime.region_map,
		runtime.battlefield,
		runtime.territory_defense_system,
		runtime.stronghold_system
	)
	if not bool(panel_setup.get("configured", false)):
		return
	runtime.region_info_panel = panel_setup.get("region_info_panel", null)


func _create_cardfront_tutorial_overlay() -> void:
	runtime.tutorial_overlay = null
	if not _is_cardfront_mode():
		return
	var ui_canvas = _hud_ref("ui_canvas")
	if ui_canvas == null:
		return
	var overlay_setup: Dictionary = CardfrontModeScript.create_tutorial_overlay(ui_canvas, Vector2(VIEW_W, VIEW_H))
	if bool(overlay_setup.get("configured", false)):
		runtime.tutorial_overlay = overlay_setup.get("tutorial_overlay", null)
		_wire_tutorial_settings_signals(overlay_setup.get("tutorial_overlay", null))


func _wire_tutorial_settings_signals(overlay) -> void:
	if overlay == null or not is_instance_valid(overlay):
		return
	var settings_panel = _hud_ref("settings_panel")
	if settings_panel == null or not is_instance_valid(settings_panel):
		return
	if not settings_panel.has_signal("settings_changed"):
		return
	var callable := Callable(overlay, "on_settings_changed")
	if not settings_panel.settings_changed.is_connected(callable):
		settings_panel.settings_changed.connect(callable)


func _create_cardfront_feedback_layers() -> void:
	runtime.card_detail_popup = null
	runtime.toast_layer = null
	runtime.card_audio_feedback = null
	if not _is_cardfront_mode():
		return
	var ui_canvas = _hud_ref("ui_canvas")
	if ui_canvas == null:
		return
	var feedback_setup: Dictionary = CardfrontModeScript.create_feedback_layers(ui_canvas, runtime.cardfront_feedback_bus, runtime.resource_states, Vector2(VIEW_W, VIEW_H))
	if not bool(feedback_setup.get("configured", false)):
		return
	runtime.card_detail_popup = feedback_setup.get("card_detail_popup", null)
	runtime.toast_layer = feedback_setup.get("toast_layer", null)
	runtime.card_audio_feedback = feedback_setup.get("card_audio_feedback", null)


func _create_cardfront_effect_visual_bridge() -> void:
	runtime.effect_visual_bridge = null
	if not _is_cardfront_mode():
		return
	var bridge_setup: Dictionary = CardfrontModeScript.create_effect_visual_bridge(game_layer, runtime.cardfront_feedback_bus, runtime.cardfront_vfx_layer)
	if not bool(bridge_setup.get("configured", false)):
		return
	runtime.effect_visual_bridge = bridge_setup.get("effect_visual_bridge", null)


func _create_cardfront_hand_panel() -> void:
	runtime.hand_panel = null
	runtime.selection_controller = null
	if not _is_cardfront_mode():
		return
	var ui_canvas = _hud_ref("ui_canvas")
	if ui_canvas == null:
		return
	var hand_setup: Dictionary = CardfrontModeScript.create_hand_panel(ui_canvas, runtime.card_system, runtime.resource_states, runtime.economy_system, Vector2(VIEW_W, VIEW_H), runtime.cardfront_feedback_bus)
	if not bool(hand_setup.get("configured", false)):
		return
	runtime.hand_panel = hand_setup.get("hand_panel", null)
	var ctrl_setup: Dictionary = CardfrontModeScript.create_card_selection_controller(runtime.card_system, runtime.resource_states, runtime.hand_panel, runtime.top_resource_bar, runtime.target_preview_layer, runtime.cardfront_feedback_bus)
	if bool(ctrl_setup.get("configured", false)):
		runtime.selection_controller = ctrl_setup.get("selection_controller", null)


func _create_control_chambers() -> void:
	runtime.chambers = {}
	if _is_cardfront_mode() and not CardfrontModeScript.uses_control_chambers():
		return
	var active_factions: Array = CardfrontModeScript.get_active_factions() if _is_cardfront_mode() else []
	runtime.chambers = GameSceneBuilder.create_control_chambers(self, game_layer, runtime.battlefield, runtime.turrets, runtime.current_layout, chamber_scale, Vector2(VIEW_W, VIEW_H), active_factions)
	_sync_chamber_game_elapsed_time()

func _create_ui() -> void:
	var hud_nodes: Dictionary
	if _is_cardfront_mode():
		var cf_hud: CanvasLayer = CardfrontHUDScene.instantiate()
		cf_hud.name = "UICanvas"
		game_layer.add_child(cf_hud)
		cf_hud.setup_static(self, Vector2(VIEW_W, VIEW_H), runtime.current_layout, is_mobile_layout)
		hud_nodes = cf_hud.get_static_parts()
		print("[CardfrontHUD] Loaded CardfrontHUD.tscn")
	elif ResourceLoader.exists("res://scenes/ui/GameHUD.tscn"):
		var game_hud: CanvasLayer = GameHUDScene.instantiate()
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

	if _is_cardfront_mode():
		CardfrontModeScript.configure_runtime_hud(runtime.hud)
		_create_cardfront_aim_control()
		_create_cardfront_battlefield_scale_control()
		_create_cardfront_region_info_panel()
		if cardfront_legacy_compatibility_enabled:
			_create_cardfront_feedback_bus()
			_create_cardfront_top_resource_bar()
			_create_cardfront_hand_panel()
			_create_cardfront_feedback_layers()
			_create_cardfront_effect_visual_bridge()
			_create_cardfront_tutorial_overlay()
		_create_cardfront_three_choice_panel()
		_configure_cardfront_three_choice_ui()
		_create_cardfront_battle_hero_hud()
	_connect_stronghold_label_signals()
	_setup_command_point_indicator()

	_on_scores_changed(runtime.battlefield.count_cells_by_team())


func _connect_stronghold_label_signals() -> void:
	if runtime.round_director == null or not is_instance_valid(runtime.round_director):
		return
	if runtime.orthographic_arena_view == null or not is_instance_valid(runtime.orthographic_arena_view):
		return
	var rd = runtime.round_director
	if rd.has_signal("draft_opened"):
		var draft_cb := Callable(self, "_on_draft_opened_show_labels")
		if not rd.draft_opened.is_connected(draft_cb):
			rd.draft_opened.connect(draft_cb)
	if rd.has_signal("volley_launched"):
		var volley_cb := Callable(self, "_on_volley_launched_hide_labels")
		if not rd.volley_launched.is_connected(volley_cb):
			rd.volley_launched.connect(volley_cb)
	if rd.has_signal("director_stopped"):
		var stop_cb := Callable(self, "_on_director_stopped_hide_labels")
		if not rd.director_stopped.is_connected(stop_cb):
			rd.director_stopped.connect(stop_cb)


func _on_draft_opened_show_labels(_a, _b, _c, _d) -> void:
	if runtime.orthographic_arena_view != null and is_instance_valid(runtime.orthographic_arena_view):
		runtime.orthographic_arena_view.set_stronghold_labels_visible(true)

func _on_volley_launched_hide_labels(_a, _b) -> void:
	if runtime.orthographic_arena_view != null and is_instance_valid(runtime.orthographic_arena_view):
		runtime.orthographic_arena_view.set_stronghold_labels_visible(false)

func _on_director_stopped_hide_labels() -> void:
	if runtime.orthographic_arena_view != null and is_instance_valid(runtime.orthographic_arena_view):
		runtime.orthographic_arena_view.set_stronghold_labels_visible(false)


func _setup_command_point_indicator() -> void:
	if not _is_cardfront_mode():
		return
	if runtime.round_director == null or not is_instance_valid(runtime.round_director):
		return
	_command_point_label = Label.new()
	_command_point_label.name = "CommandPointIndicator"
	_command_point_label.text = ""
	_command_point_label.visible = false
	_command_point_label.add_theme_font_size_override("font_size", 18)
	_command_point_label.add_theme_color_override("font_color", Color(0.95, 0.84, 0.30))
	_command_point_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	_command_point_label.add_theme_constant_override("shadow_offset_x", 1)
	_command_point_label.add_theme_constant_override("shadow_offset_y", 1)
	_command_point_label.add_theme_constant_override("shadow_outline_size", 2)
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	_command_point_label.position = Vector2(viewport_size.x - 180.0, 78.0)
	_command_point_label.size = Vector2(170.0, 28.0)
	_command_point_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if game_layer != null and is_instance_valid(game_layer):
		game_layer.add_child(_command_point_label)
	var cp = runtime.round_director.command_points
	if cp != null and cp.has_signal("points_changed"):
		var cb := Callable(self, "_on_command_points_changed")
		if not cp.points_changed.is_connected(cb):
			cp.points_changed.connect(cb)
	if runtime.round_director.has_signal("volley_launched"):
		var volley_cb := Callable(self, "_on_volley_show_cp")
		if not runtime.round_director.volley_launched.is_connected(volley_cb):
			runtime.round_director.volley_launched.connect(volley_cb)
	if runtime.round_director.has_signal("draft_opened"):
		var draft_cb := Callable(self, "_on_draft_hide_cp")
		if not runtime.round_director.draft_opened.is_connected(draft_cb):
			runtime.round_director.draft_opened.connect(draft_cb)
	if runtime.round_director.has_signal("director_stopped"):
		var stop_cb := Callable(self, "_on_director_hide_cp")
		if not runtime.round_director.director_stopped.is_connected(stop_cb):
			runtime.round_director.director_stopped.connect(stop_cb)


func _update_command_point_display() -> void:
	if _command_point_label == null or not is_instance_valid(_command_point_label):
		return
	if runtime.round_director == null or not is_instance_valid(runtime.round_director):
		return
	var points: int = runtime.round_director.command_points.get_points(CardfrontRulesScript.PLAYER_FACTION)
	var diamonds: String = ""
	for i in range(3):
		diamonds += "◆" if i < points else "◇"
	_command_point_label.text = "指挥点  %s" % diamonds


func _on_command_points_changed(_owner_id: int, _remaining: int) -> void:
	_update_command_point_display()


func _on_volley_show_cp(_a, _b) -> void:
	if _command_point_label != null and is_instance_valid(_command_point_label):
		_command_point_label.visible = true
	_update_command_point_display()


func _on_draft_hide_cp(_a, _b, _c, _d) -> void:
	if _command_point_label != null and is_instance_valid(_command_point_label):
		_command_point_label.visible = false


func _on_director_hide_cp() -> void:
	if _command_point_label != null and is_instance_valid(_command_point_label):
		_command_point_label.visible = false


func _add_pvp_menu_button() -> void:
	if menu_layer == null or not is_instance_valid(menu_layer):
		return
	var existing = menu_layer.get_node_or_null("PvpMenuButton")
	if existing != null:
		return
	var btn := Button.new()
	btn.name = "PvpMenuButton"
	btn.text = "联机对战"
	btn.position = Vector2(VIEW_W * 0.5 - 80, VIEW_H - 130)
	btn.size = Vector2(160, 38)
	btn.add_theme_font_size_override("font_size", 16)
	btn.pressed.connect(_open_pvp_lobby)
	menu_layer.add_child(btn)


func _open_pvp_lobby() -> void:

	if _pvp_lobby_panel != null and is_instance_valid(_pvp_lobby_panel):
		_pvp_lobby_panel.visible = true
		return
	var panel := Control.new()
	panel.name = "PvpLobby"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.03, 0.05, 0.94)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_child(bg)
	var vbox := VBoxContainer.new()
	vbox.position = Vector2(360, 220)
	vbox.size = Vector2(400, 280)
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "联机对战"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	_pvp_status_label = Label.new()
	_pvp_status_label.text = "选择创建房间或加入房间"
	_pvp_status_label.add_theme_font_size_override("font_size", 16)
	_pvp_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_pvp_status_label)

	var host_btn := Button.new()
	host_btn.text = "创建房间"
	host_btn.custom_minimum_size = Vector2(400, 44)
	host_btn.pressed.connect(_on_pvp_host)
	vbox.add_child(host_btn)

	var ip_row := HBoxContainer.new()
	ip_row.add_theme_constant_override("separation", 8)
	var ip_label := Label.new()
	ip_label.text = "IP:"
	ip_label.add_theme_font_size_override("font_size", 16)
	ip_row.add_child(ip_label)
	_pvp_ip_input = LineEdit.new()
	_pvp_ip_input.text = "127.0.0.1"
	_pvp_ip_input.custom_minimum_size = Vector2(240, 36)
	_pvp_ip_input.placeholder_text = "对方 IP 地址"
	ip_row.add_child(_pvp_ip_input)
	vbox.add_child(ip_row)

	var join_btn := Button.new()
	join_btn.text = "加入房间"
	join_btn.custom_minimum_size = Vector2(400, 44)
	join_btn.pressed.connect(_on_pvp_join)
	vbox.add_child(join_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "取消"
	cancel_btn.custom_minimum_size = Vector2(400, 36)
	cancel_btn.pressed.connect(func(): panel.visible = false)
	vbox.add_child(cancel_btn)

	menu_layer.add_child(panel)
	_pvp_lobby_panel = panel


func _on_pvp_host() -> void:
	if runtime.network_manager == null:
		runtime.network_manager = NetworkManagerScript.new()
		menu_layer.add_child(runtime.network_manager)
	if runtime.network_manager.host_game():
		_pvp_status_label.text = "等待对手加入... 端口 %d" % NetworkManagerScript.DEFAULT_PORT
		if not runtime.network_manager.peer_connected.is_connected(_on_pvp_peer_connected):
			runtime.network_manager.peer_connected.connect(_on_pvp_peer_connected)
		if not runtime.network_manager.connection_failed.is_connected(_on_pvp_connection_failed):
			runtime.network_manager.connection_failed.connect(_on_pvp_connection_failed)
	else:
		_pvp_status_label.text = "创建房间失败"


func _on_pvp_join() -> void:
	if runtime.network_manager == null:
		runtime.network_manager = NetworkManagerScript.new()
		menu_layer.add_child(runtime.network_manager)
	var ip: String = "127.0.0.1"
	if _pvp_ip_input != null and is_instance_valid(_pvp_ip_input):
		ip = str(_pvp_ip_input.text).strip_edges()
		if ip.is_empty():
			ip = "127.0.0.1"
	if runtime.network_manager.join_game(ip):
		_pvp_status_label.text = "正在连接 %s ..." % ip
		if not runtime.network_manager.join_succeeded.is_connected(_on_pvp_join_succeeded):
			runtime.network_manager.join_succeeded.connect(_on_pvp_join_succeeded)
		if not runtime.network_manager.connection_failed.is_connected(_on_pvp_connection_failed):
			runtime.network_manager.connection_failed.connect(_on_pvp_connection_failed)
	else:
		_pvp_status_label.text = "连接失败"


func _on_pvp_peer_connected(_peer_id: int) -> void:
	_pvp_status_label.text = "对手已连接！"
	runtime.pvp_enabled = true
	if _pvp_lobby_panel != null and is_instance_valid(_pvp_lobby_panel):
		_pvp_lobby_panel.visible = false
	selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	_open_cardfront_prematch()


func _on_pvp_join_succeeded() -> void:
	_pvp_status_label.text = "连接成功！"
	runtime.pvp_enabled = true
	if _pvp_lobby_panel != null and is_instance_valid(_pvp_lobby_panel):
		_pvp_lobby_panel.visible = false
	selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	_open_cardfront_prematch()


func _on_pvp_connection_failed(reason: String) -> void:
	_pvp_status_label.text = "连接失败: %s" % str(reason)


func _request_start_from_menu() -> void:
	_save_menu_preferences()
	if _is_cardfront_mode():
		_open_cardfront_prematch()
	else:
		_start_game(selected_grid_size)


func _open_cardfront_prematch() -> void:
	if cardfront_prematch_screen != null and is_instance_valid(cardfront_prematch_screen):
		return
	cardfront_prematch_screen = CardfrontPrematchScene.instantiate()
	add_child(cardfront_prematch_screen)
	cardfront_prematch_screen.setup(selected_cardfront_map_id, selected_cardfront_player_hero_id)
	cardfront_prematch_screen.battle_confirmed.connect(_on_cardfront_prematch_confirmed)
	cardfront_prematch_screen.cancelled.connect(_on_cardfront_prematch_cancelled)
	if menu_layer != null and is_instance_valid(menu_layer):
		menu_layer.visible = false


func _on_cardfront_prematch_confirmed(map_id: String, player_hero_id: String, ai_hero_id: String) -> void:
	selected_cardfront_map_id = map_id
	selected_cardfront_player_hero_id = player_hero_id
	selected_cardfront_ai_hero_id = ai_hero_id
	_save_menu_preferences()
	_close_cardfront_prematch()
	_start_game(selected_grid_extent)


func _on_cardfront_prematch_cancelled() -> void:
	_close_cardfront_prematch()
	if menu_layer != null and is_instance_valid(menu_layer):
		menu_layer.visible = true


func _close_cardfront_prematch() -> void:
	if cardfront_prematch_screen != null and is_instance_valid(cardfront_prematch_screen):
		cardfront_prematch_screen.queue_free()
	cardfront_prematch_screen = null


func _create_cardfront_battle_hero_hud() -> void:
	var ui_canvas = _hud_ref("ui_canvas")
	if ui_canvas == null:
		return
	var hero_hud = CardfrontBattleHeroHudScene.instantiate()
	ui_canvas.add_child(hero_hud)
	hero_hud.configure(runtime.hero_assignments, runtime.turrets)
	runtime.battle_hero_hud = hero_hud


func _create_cardfront_battlefield_scale_control() -> void:
	# The 120% framing is the player-facing composition. Keep scale selection as
	# an arena API for QA, but do not spend battle-space on a permanent debug widget.
	runtime.battlefield_scale_control = null


func _configure_cardfront_three_choice_ui() -> void:
	if runtime.three_choice_panel == null:
		return
	if runtime.hand_panel != null and is_instance_valid(runtime.hand_panel):
		if runtime.selection_controller != null and runtime.selection_controller.has_method("clear_selection"):
			runtime.selection_controller.clear_selection()
		runtime.hand_panel.visible = false
	if runtime.top_resource_bar != null and is_instance_valid(runtime.top_resource_bar):
		runtime.top_resource_bar.visible = false
	var event_label = _hud_ref("event_label")
	if event_label != null and is_instance_valid(event_label):
		event_label.visible = false

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

func _create_control_buttons() -> void:
	_set_ui_runtime_ref("add_ball_buttons", {})
	_set_ui_runtime_ref("add_ball_button_base_positions", {})
	if _is_cardfront_mode() and not CardfrontModeScript.uses_control_chambers():
		return
	var button_nodes: Dictionary = GameHudView.create_control_buttons(self, game_layer, runtime.chambers, runtime.current_layout, Vector2(VIEW_W, VIEW_H), is_mobile_layout)
	_set_ui_runtime_ref("add_ball_buttons", button_nodes.get("add_ball_buttons", {}))
	_set_ui_runtime_ref("add_ball_button_base_positions", button_nodes.get("add_ball_button_base_positions", {}))
	for faction_id in _ui_runtime_ref("add_ball_buttons", {}).keys():
		_refresh_add_ball_button(faction_id)

func _add_ball_to_chamber(faction_id: int) -> void:
	if _is_cardfront_mode() and not CardfrontModeScript.uses_control_chambers():
		return
	if not runtime.chambers.has(faction_id):
		return
	runtime.chambers[faction_id].add_control_ball()
	_refresh_add_ball_button(faction_id)

func _on_ball_count_changed(faction_id: int, _count: int) -> void:
	_refresh_add_ball_button(faction_id)

func _refresh_add_ball_button(faction_id: int) -> void:
	GameHudView.refresh_add_ball_button(faction_id, _ui_runtime_ref("add_ball_buttons", {}), runtime.chambers)

func _on_chamber_release_requested(faction_id, bullet_count, chamber) -> void:
	if _is_cardfront_mode() and not CardfrontModeScript.uses_control_chambers():
		if chamber != null and is_instance_valid(chamber):
			chamber.set_locked(false)
		return
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

func _update_cardfront_status_label() -> void:
	var event_label = _hud_ref("event_label")
	if event_label != null and is_instance_valid(event_label) and _is_cardfront_mode():
		event_label.text = CardfrontStatusFormatterScript.build_status_text(runtime)


func _build_cardfront_status_text() -> String:
	return CardfrontStatusFormatterScript.build_status_text(runtime)


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
	var total_cells: int = _runtime_cell_count()
	var stronghold_snapshot: Dictionary = {}
	if mode_name == GameConfig.GAME_MODE_CARDFRONT and time_expired:
		counts = runtime.battlefield.count_cells_by_team()
		current_score_counts = counts.duplicate()
		if runtime.stronghold_system != null and is_instance_valid(runtime.stronghold_system):
			stronghold_snapshot = runtime.stronghold_system.sample_bonuses()

	var result: Dictionary = WinConditionEvaluator.evaluate(
		mode_name,
		runtime.turrets,
		counts,
		total_cells,
		time_expired,
		stronghold_snapshot
	)

	if not result.ended:
		return
	if result.draw:
		_finish_as_draw(result.sub_text, result)
	else:
		_finish_with_winner(result.winner, result.sub_text, result)

func _finish_with_winner(faction_id: int, sub_text: String, result: Dictionary = {}) -> void:
	GameStateCoordinator.finish_with_winner(self, _hud_ref("winner_label"), faction_id, sub_text)
	if _is_cardfront_mode():
		_show_cardfront_match_result(faction_id, false, result)

func _finish_as_draw(sub_text: String, result: Dictionary = {}) -> void:
	GameStateCoordinator.finish_as_draw(self, _hud_ref("winner_label"), sub_text)
	if _is_cardfront_mode():
		_show_cardfront_match_result(-1, true, result)


func _show_cardfront_match_result(winner_id: int, is_draw: bool, result: Dictionary = {}) -> void:
	var result_panel = _hud_ref("match_result_panel")
	if result_panel == null or not is_instance_valid(result_panel) or not result_panel.has_method("show_result"):
		return
	var time_expired: bool = game_elapsed_time >= CardfrontModeScript.get_match_duration_seconds()
	var title_text: String = "\u5e73\u5c40" if is_draw else "%s\u80dc\u5229\uff01" % CardfrontRulesScript.owner_display_name(winner_id)
	var accent: Color = Color(0.92, 0.94, 1.0) if is_draw else CardfrontRulesScript.owner_color(winner_id)
	result_panel.show_result(
		title_text,
		str(result.get("sub_text", CardfrontMatchFlowTextScript.result_reason(time_expired))),
		current_score_counts,
		_runtime_cell_count(),
		accent,
		result.get("score_breakdown", {}) as Dictionary
	)


func _restart_current_cardfront_match() -> void:
	if not _is_cardfront_mode():
		return
	_start_game(selected_grid_extent, false, true)


func _exit_cardfront_result_to_menu() -> void:
	if not _is_cardfront_mode():
		return
	get_tree().paused = false
	_cleanup_game_layer()
	_create_start_menu()

func _stop_all_actions_for_game_over() -> void:
	if runtime.round_director != null and is_instance_valid(runtime.round_director):
		runtime.round_director.stop()
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
	if _is_cardfront_mode() and runtime.round_director != null and is_instance_valid(runtime.round_director):
		if runtime.round_director.is_draft_active():
			return
	GameStateCoordinator.apply_pause_toggle(
		get_tree(),
		_hud_ref("pause_overlay"),
		_hud_ref("pause_button"),
		Callable(self, "_save_game_progress")
	)

func _on_event_round_finished(_payload: Dictionary) -> void:
	pass

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
	selected_grid_extent = GridExtentScript.sanitize(data.get("grid_extent", selected_grid_size))
	selected_palette_name = _sanitize_pref_palette(str(data.get("palette_name", "默认随机")))
	selected_quality_name = _sanitize_pref_quality(str(data.get("quality_name", GameConfig.QUALITY_MEDIUM)))
	selected_game_mode_name = _sanitize_pref_mode(str(data.get("game_mode_name", GameConfig.GAME_MODE_BASIC)))
	selected_cardfront_map_id = str(data.get("cardfront_map_id", CardfrontMapRegistryScript.DEFAULT_DUEL_MAP_ID))
	if not CardfrontMapRegistryScript.get_registered_map_ids().has(selected_cardfront_map_id):
		selected_cardfront_map_id = CardfrontMapRegistryScript.DEFAULT_DUEL_MAP_ID
	selected_cardfront_player_hero_id = CardfrontHeroRegistryScript.sanitize_hero_id(
		str(data.get("cardfront_player_hero_id", CardfrontHeroRegistryScript.DEFAULT_PLAYER_HERO_ID))
	)
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
		"grid_extent": GridExtentScript.to_array(selected_grid_extent),
		"palette_name": selected_palette_name,
		"quality_name": selected_quality_name,
		"game_mode_name": selected_game_mode_name,
		"cardfront_map_id": selected_cardfront_map_id,
		"cardfront_player_hero_id": selected_cardfront_player_hero_id,
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
	selected_grid_extent = GridExtentScript.DEFAULT
	selected_palette_name = "默认随机"
	selected_quality_name = GameConfig.QUALITY_MEDIUM
	selected_game_mode_name = GameConfig.GAME_MODE_BASIC
	selected_cardfront_map_id = CardfrontMapRegistryScript.DEFAULT_DUEL_MAP_ID
	selected_cardfront_player_hero_id = CardfrontHeroRegistryScript.DEFAULT_PLAYER_HERO_ID
	selected_cardfront_ai_hero_id = CardfrontHeroRegistryScript.DEFAULT_AI_HERO_ID
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
	_close_cardfront_prematch()
	if menu_layer != null:
		menu_layer.queue_free()
		menu_layer = null
	menu_title_label = null
	menu_start_button = null
	menu_continue_button = null
	menu_save_slot_buttons.clear()
	menu_status_label = null

func _unhandled_input(event: InputEvent) -> void:
	if not _is_cardfront_mode():
		return
	if game_layer == null or is_game_over or get_tree().paused:
		return
	if runtime.selection_controller == null:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if runtime.selection_controller.get_selected_card_id() >= 0:
			_cancel_cardfront_selection()
			get_viewport().set_input_as_handled()
			return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if runtime.selection_controller.get_selected_card_id() >= 0:
			_cancel_cardfront_selection()
			get_viewport().set_input_as_handled()
			return
	if event is InputEventMouseMotion:
		_update_cardfront_hover_hint()
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if runtime.selection_controller.get_selected_card_id() < 0:
		if not _handle_priority_target_click(event):
			_handle_fortify_click(event)
		return
	if runtime.battlefield == null or not is_instance_valid(runtime.battlefield):
		return
	if not runtime.battlefield.has_method("world_to_cell"):
		return

	var canvas_transform: Transform2D = get_viewport().get_canvas_transform()
	var world_position: Vector2 = canvas_transform.affine_inverse() * event.position
	var cell: Vector2i = runtime.battlefield.world_to_cell(world_position)
	if not runtime.battlefield.is_inside(cell):
		return

	runtime.selection_controller.on_battlefield_clicked(cell)
	get_viewport().set_input_as_handled()


func _handle_priority_target_click(event: InputEvent) -> bool:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return false
	if runtime.direction_controller == null or not is_instance_valid(runtime.direction_controller):
		return false
	if runtime.round_director == null or not is_instance_valid(runtime.round_director):
		return false
	if not runtime.round_director.active:
		return false
	if runtime.round_director.phase_controller.phase != CardfrontMatchPhaseScript.BATTLE_COUNTDOWN:
		return false
	if runtime.battlefield == null or not is_instance_valid(runtime.battlefield):
		return false
	if not runtime.battlefield.has_method("world_to_cell"):
		return false
	var canvas_transform: Transform2D = get_viewport().get_canvas_transform()
	var world_position: Vector2 = canvas_transform.affine_inverse() * event.position
	var cell: Vector2i = runtime.battlefield.world_to_cell(world_position)
	if not runtime.battlefield.is_inside(cell):
		return false
	var owner_id: int = int(runtime.battlefield.get_cell_owner(cell))
	if owner_id == CardfrontRulesScript.AI_FACTION or owner_id == CardfrontRulesScript.NEUTRAL_OWNER:
		runtime.direction_controller.set_priority_target(cell)
		get_viewport().set_input_as_handled()
		return true
	elif runtime.direction_controller.has_priority_target():
		runtime.direction_controller.clear_priority_target()
		get_viewport().set_input_as_handled()
		return true
	return false


func _handle_fortify_click(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if runtime.round_director == null or not is_instance_valid(runtime.round_director):
		return
	if runtime.round_director.phase_controller.phase != CardfrontMatchPhaseScript.LAUNCH_VOLLEY:
		return
	if not runtime.round_director.command_points.has_points(CardfrontRulesScript.PLAYER_FACTION):
		return
	if runtime.battlefield == null or not is_instance_valid(runtime.battlefield):
		return
	if runtime.fortify_layer == null or not is_instance_valid(runtime.fortify_layer):
		return
	if not runtime.battlefield.has_method("world_to_cell"):
		return
	var canvas_transform: Transform2D = get_viewport().get_canvas_transform()
	var world_position: Vector2 = canvas_transform.affine_inverse() * event.position
	var cell: Vector2i = runtime.battlefield.world_to_cell(world_position)
	if not runtime.battlefield.is_inside(cell):
		return
	var owner_id: int = int(runtime.battlefield.get_cell_owner(cell))
	if owner_id != CardfrontRulesScript.PLAYER_FACTION:
		return
	if runtime.round_director.command_points.spend_point(CardfrontRulesScript.PLAYER_FACTION):
		runtime.fortify_layer.add_fortify_stack(cell, 1)
		get_viewport().set_input_as_handled()


func _cancel_cardfront_selection() -> void:
	if runtime.selection_controller != null and runtime.selection_controller.get_selected_card_id() >= 0:
		runtime.selection_controller.clear_selection()


func _update_cardfront_hover_hint() -> void:
	if not _is_cardfront_mode():
		return
	if runtime.selection_controller == null:
		return
	if runtime.selection_controller.get_selected_card_id() < 0:
		return
	if runtime.battlefield == null or not is_instance_valid(runtime.battlefield):
		return
	if not runtime.battlefield.has_method("world_to_cell"):
		return
	var cell: Vector2i = runtime.battlefield.world_to_cell(get_global_mouse_position())
	if not runtime.battlefield.is_inside(cell):
		runtime.selection_controller.restore_action_hint()
		return
	runtime.selection_controller.update_hover_target_hint(cell)


func _cleanup_game_layer() -> void:
	GameStateCoordinator.reset_pause_and_winner_state(_hud_ref("pause_overlay"), _hud_ref("pause_button"), _hud_ref("winner_label"))
	if game_layer != null:
		game_layer.queue_free()
		game_layer = null
	runtime.reset()
	cardfront_runtime_builder = null
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
	var cardfront_data: Dictionary = {}
	if selected_game_mode_name == GameConfig.GAME_MODE_CARDFRONT and runtime != null:
		var snapshot = CardfrontRuntimeSnapshotScript.capture(runtime)
		if snapshot != null:
			cardfront_data = snapshot.to_dict()
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
		_hud_ref("winner_label"),
		cardfront_data
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
	var cardfront_snapshot_data: Dictionary = prepared.get("data", {}).get("cardfront_snapshot", {})
	_apply_continue_start_plan(execution_plan, restore_plan, cardfront_snapshot_data)

func _apply_continue_start_plan(execution_plan: Dictionary, restore_plan: RestorePlan, cardfront_snapshot_data: Dictionary = {}) -> void:
	var execution_start_values: Dictionary = execution_plan.get("start_values", {})
	var execution_banner: Dictionary = execution_plan.get("banner", {})
	SaveFlowController.apply_continue_start_plan(execution_plan, self)
	_start_game(execution_start_values.get("grid_extent", execution_start_values.get("grid_size", 40)), true, false)
	game_elapsed_time = float(execution_start_values.get("game_elapsed_time", 0.0))
	_sync_chamber_game_elapsed_time()
	_apply_saved_state(restore_plan)
	if not cardfront_snapshot_data.is_empty() and selected_game_mode_name == GameConfig.GAME_MODE_CARDFRONT:
		CardfrontRuntimeSnapshotScript.apply_to_runtime(runtime, cardfront_snapshot_data)
	_show_center_banner(
		str(execution_banner.get("title", "领土战争")),
		str(execution_banner.get("subtitle", "继续作战")),
		execution_banner.get("accent", Color(0.84, 0.96, 1.0)),
		bool(execution_banner.get("auto_hide", true))
	)
