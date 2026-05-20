extends SceneTree

const ChamberBallPhysicsScript = preload("res://scripts/ChamberBallPhysics.gd")
const ChamberDrawModelScript = preload("res://scripts/ChamberDrawModel.gd")
const ChamberSaveAdapterScript = preload("res://scripts/ChamberSaveAdapter.gd")

var _failures: Array[String] = []
var _passes: int = 0

class DummyMain extends RefCounted:
	var current_score_counts: Dictionary = {}
	var game_elapsed_time: float = 0.0
	var selected_grid_size: int = 40
	var is_game_over: bool = false

	func _init() -> void:
		current_score_counts = {
			GameConfig.Faction.BLUE: 25,
			GameConfig.Faction.RED: 15,
			GameConfig.Faction.GREEN: 10,
			GameConfig.Faction.YELLOW: 50,
		}

	func _show_center_banner(_title: String, _body: String, _color: Color, _important: bool) -> void:
		pass

	func _refresh_add_ball_button(_faction_id: int) -> void:
		pass

class DummyCancelableTurret extends Node:
	var remaining: int = 0

	func cancel_burst() -> int:
		return remaining

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("[SmokeTest] Starting BallWar smoke tests")
	await process_frame

	_reset_and_assert_runtime_defaults("before save codec defaults")
	_test_save_game_codec_defaults()
	_reset_and_assert_runtime_defaults("after save codec defaults")

	_reset_and_assert_runtime_defaults("before event roulette intervals")
	_test_event_roulette_intervals_and_weights()
	_reset_and_assert_runtime_defaults("after event roulette intervals")

	_reset_and_assert_runtime_defaults("before event label format")
	_test_event_label_format()
	_reset_and_assert_runtime_defaults("after event label format")

	_reset_and_assert_runtime_defaults("before control chamber event rules")
	await _test_control_chamber_event_rules()
	_reset_and_assert_runtime_defaults("after control chamber event rules")

	_reset_and_assert_runtime_defaults("before event roulette signals")
	await _test_event_roulette_signal_bridge()
	_reset_and_assert_runtime_defaults("after event roulette signals")

	_reset_and_assert_runtime_defaults("before chamber ball physics helper")
	_test_chamber_ball_physics_helper()
	_reset_and_assert_runtime_defaults("after chamber ball physics helper")

	_reset_and_assert_runtime_defaults("before chamber draw model")
	_test_chamber_draw_model()
	_reset_and_assert_runtime_defaults("after chamber draw model")

	_reset_and_assert_runtime_defaults("before chamber save adapter")
	await _test_chamber_save_adapter()
	_reset_and_assert_runtime_defaults("after chamber save adapter")

	_reset_and_assert_runtime_defaults("before restore_from_state interfaces")
	await _test_restore_from_state_interfaces()
	_reset_and_assert_runtime_defaults("after restore_from_state interfaces")

	_reset_and_assert_runtime_defaults("before turret cancel burst")
	_test_turret_cancel_burst()
	_reset_and_assert_runtime_defaults("after turret cancel burst")

	_reset_and_assert_runtime_defaults("before bullet lifecycle")
	_test_bullet_lifecycle()
	_reset_and_assert_runtime_defaults("after bullet lifecycle")

	_reset_and_assert_runtime_defaults("before bullet restore")
	_test_bullet_restore_from_state()
	_reset_and_assert_runtime_defaults("after bullet restore")

	_reset_and_assert_runtime_defaults("before bullet pool incremental metrics")
	_test_bullet_pool_incremental_metrics()
	_reset_and_assert_runtime_defaults("after bullet pool incremental metrics")

	_reset_and_assert_runtime_defaults("before bullet pool active ordering")
	_test_bullet_pool_active_ordering()
	_reset_and_assert_runtime_defaults("after bullet pool active ordering")

	_reset_and_assert_runtime_defaults("before bullet trail dirty cache")
	_test_bullet_trail_dirty_cache()
	_reset_and_assert_runtime_defaults("after bullet trail dirty cache")

	_reset_and_assert_runtime_defaults("before player settings bool sanitization")
	_test_player_settings_bool_sanitization()
	_reset_and_assert_runtime_defaults("after player settings bool sanitization")
	await _flush_test_cleanup()

	if _failures.is_empty():
		print("[SmokeTest] PASS (%d checks)" % _passes)
		quit(0)
		return

	push_error("[SmokeTest] FAIL (%d failures)" % _failures.size())
	for failure in _failures:
		push_error(failure)
	quit(1)

func _cleanup_node(node: Node) -> void:
	if node == null:
		return
	if not is_instance_valid(node):
		return
	if node.get_parent() != null:
		node.queue_free()
	else:
		node.free()

func _cleanup_object(object) -> void:
	if object == null:
		return
	if not is_instance_valid(object):
		return
	if object is Node:
		_cleanup_node(object as Node)
		return
	if object.has_method("free"):
		object.free()

func _flush_test_cleanup() -> void:
	await process_frame
	await process_frame

func _assert_true(condition: bool, message: String) -> void:
	if condition:
		_passes += 1
		return
	_failures.append(message)

func _assert_eq(actual, expected, message: String) -> void:
	if actual == expected:
		_passes += 1
		return
	_failures.append("%s | expected=%s actual=%s" % [message, str(expected), str(actual)])


func _reset_and_assert_runtime_defaults(context: String) -> void:
	GameConfig.reset_runtime_defaults()
	_assert_eq(GameConfig.get_game_mode_name(), GameConfig.GAME_MODE_BASIC, "%s mode reset" % context)
	_assert_eq(GameConfig.get_quality_name(), GameConfig.QUALITY_MEDIUM, "%s quality reset" % context)
	_assert_eq(GameConfig.get_palette_name(), "经典", "%s palette reset" % context)

func _test_save_game_codec_defaults() -> void:
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_BASIC)
	var raw: Dictionary = {
		"save_version": "1.9.35",
		"grid_size": 40,
		"quality_name": "bad_quality",
		"game_mode_name": "bad_mode",
		"time_limit_minutes": 999,
		"bullets": "bad_bullets",
		"event_state": {
			"next_event_time_left": -5.0,
			"reroll_count": 99,
		},
		"factions": [
			{
				"faction_id": 9,
				"chamber_pending_count": 99999,
				"queued_round_modifiers": "bad_modifiers",
			}
		],
	}
	var clean: Dictionary = SaveGameCodec.validate_save_data(raw)

	_assert_eq(clean.get("game_mode_name", ""), GameConfig.GAME_MODE_BASIC, "save codec should normalize invalid game mode")
	_assert_true(str(clean.get("quality_name", "")) in GameConfig.get_quality_names(), "save codec should normalize invalid quality name")
	_assert_eq(int(clean.get("time_limit_minutes", 0)), GameConfig.TIMED_MODE_MAX_MINUTES, "save codec should clamp timed mode minutes")
	_assert_true(clean.get("bullets", []) is Array, "save codec should normalize bullet list")
	_assert_true(clean.get("event_state", {}) is Dictionary, "save codec should preserve event_state dictionary")
	_assert_eq(float(clean["event_state"].get("next_event_time_left", 999.0)), 0.0, "save codec should clamp negative event countdown")
	_assert_eq(int(clean["event_state"].get("reroll_count", -1)), 2, "save codec should clamp reroll count")
	_assert_eq(int(clean["factions"][0].get("faction_id", -1)), 3, "save codec should clamp faction id")
	_assert_true(clean["factions"][0].get("queued_round_modifiers", null) is Array, "save codec should normalize queued_round_modifiers")
	_assert_eq(float(clean["factions"][0].get("chamber_jammed_time_left", -1.0)), 0.0, "save codec should default chamber jammed time")

func _test_event_roulette_intervals_and_weights() -> void:
	var controller: EventRouletteController = EventRouletteController.new()
	var dummy_main: DummyMain = DummyMain.new()
	var dummy_battlefield: Node = Node.new()
	controller.main_ref = dummy_main
	controller.battlefield = dummy_battlefield

	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_BASIC)
	_assert_eq(controller._compute_initial_delay(), 60.0, "basic mode initial delay should be 60s")
	_assert_eq(controller._compute_current_interval(), 60.0, "basic mode interval should be 60s")

	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_OCCUPATION)
	dummy_main.current_score_counts = {
		GameConfig.Faction.BLUE: 26,
		GameConfig.Faction.RED: 24,
		GameConfig.Faction.GREEN: 25,
		GameConfig.Faction.YELLOW: 25,
	}
	_assert_eq(controller._compute_current_interval(), 40.0, "occupation mode default interval should be 40s")
	dummy_main.current_score_counts = {
		GameConfig.Faction.BLUE: 70,
		GameConfig.Faction.RED: 10,
		GameConfig.Faction.GREEN: 10,
		GameConfig.Faction.YELLOW: 10,
	}
	_assert_eq(controller._compute_current_interval(), 30.0, "occupation mode should speed up near 65 percent lead")

	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_TIMED)
	GameConfig.set_time_limit_minutes(5)
	dummy_main.game_elapsed_time = 100.0
	_assert_eq(controller._compute_current_interval(), 45.0, "timed mode early interval should be 45s")
	dummy_main.game_elapsed_time = 190.0
	_assert_eq(controller._compute_current_interval(), 30.0, "timed mode mid interval should be 30s")
	dummy_main.game_elapsed_time = 250.0
	_assert_eq(controller._compute_current_interval(), 20.0, "timed mode late interval should be 20s")

	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_WILD)
	var wild_interval: float = controller._compute_current_interval()
	_assert_true(wild_interval >= 20.0 and wild_interval <= 30.0, "wild mode interval should stay in 20-30s range")

	_assert_true(
		controller._weight_for_effect_rank(EventRouletteController.EFFECT_BONUS_10, 4) > controller._weight_for_effect_rank(EventRouletteController.EFFECT_BONUS_10, 1),
		"positive events should favor trailing factions"
	)
	_assert_true(
		controller._weight_for_effect_rank(EventRouletteController.EFFECT_JAM, 1) > controller._weight_for_effect_rank(EventRouletteController.EFFECT_JAM, 4),
		"jam should favor leading factions"
	)

	var save_state: Dictionary = {
		"event_roulette_enabled": true,
		"next_event_time_left": 12.5,
		"current_event_interval": 45.0,
		"last_event_faction": 2,
		"last_event_effect": EventRouletteController.EFFECT_X3,
		"reroll_count": 1,
	}
	controller.import_save_state(save_state)
	var exported: Dictionary = controller.export_save_state()
	_assert_eq(float(exported.get("next_event_time_left", 0.0)), 12.5, "event controller should preserve imported countdown")
	_assert_eq(str(exported.get("last_event_effect", "")), EventRouletteController.EFFECT_X3, "event controller should preserve imported effect")
	controller.battlefield = null
	controller.main_ref = null
	_cleanup_node(dummy_battlefield)
	_cleanup_node(controller)


func _test_event_label_format() -> void:
	var controller: EventRouletteController = EventRouletteController.new()

	controller.is_presenting_event = false
	controller.last_event_faction = -1
	controller.last_event_effect = ""
	controller.next_event_time_left = 25.0
	_assert_eq(controller._build_event_status_text(), "事件：待命｜下次事件 00:25", "event label idle format")

	GameConfig.set_palette_by_name("薄荷")
	controller.last_event_faction = GameConfig.Faction.BLUE
	controller.last_event_effect = EventRouletteController.EFFECT_X2
	controller.next_event_time_left = 20.0
	_assert_eq(controller._build_event_status_text(), "事件：海方获得 x2｜下次事件 00:20", "event label resolved format")

	controller.is_presenting_event = true
	_assert_eq(controller._build_event_status_text(), "事件：转盘中｜下次事件 --:--", "event label presenting format")

	_cleanup_node(controller)

func _test_control_chamber_event_rules() -> void:
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_BASIC)

	var chamber: ControlChamber = ControlChamber.new()
	var init_signal_state: Dictionary = {"count": 0}
	chamber.ball_count_changed.connect(func(_faction_id: int, _count: int) -> void:
		init_signal_state["count"] = int(init_signal_state.get("count", 0)) + 1
	)
	get_root().add_child(chamber)
	await process_frame

	_assert_eq(chamber.balls.size(), 1, "control chamber should create exactly one silent initial ball")
	_assert_eq(int(init_signal_state.get("count", 0)), 0, "control chamber initial ready path should not emit ball_count_changed")

	chamber.add_control_ball()
	_assert_eq(int(init_signal_state.get("count", 0)), 1, "public add_control_ball should still emit ball_count_changed")

	chamber.pending_count = 10
	chamber.apply_pending_bonus(10)
	_assert_eq(chamber.pending_count, 20, "pending bonus should apply immediately when chamber is not locked")
	chamber.apply_pending_multiplier(3)
	_assert_eq(chamber.pending_count, 60, "pending multiplier should apply immediately when chamber is not locked")

	while chamber.balls.size() < GameConfig.MAX_CONTROL_BALLS_PER_CHAMBER:
		chamber.add_control_ball()
	var before_full_bonus: int = chamber.pending_count
	chamber.add_control_ball_from_event()
	_assert_eq(chamber.pending_count, before_full_bonus + 10, "full chamber should convert add-ball event into +10 pending")

	chamber.set_damaged()
	chamber.apply_jammed(5.0)
	_assert_eq(chamber.get_jammed_time_left(), 0.0, "jam should not reactivate a damaged chamber")

	var burst_chamber: ControlChamber = ControlChamber.new()
	get_root().add_child(burst_chamber)
	await process_frame

	var dummy_turret: DummyCancelableTurret = DummyCancelableTurret.new()
	dummy_turret.remaining = 40
	get_root().add_child(dummy_turret)
	burst_chamber.set_linked_turret(dummy_turret)
	burst_chamber.is_locked = true
	burst_chamber.pending_count = 99
	burst_chamber.cancel_current_burst_with_refund(0.25)
	_assert_true(not burst_chamber.is_locked, "jam refund path should unlock the chamber")
	_assert_eq(burst_chamber.pending_count, 10, "jam refund should preserve 25 percent of remaining burst")

	burst_chamber.queue_next_round_modifier({"type": "bonus_10", "amount": 10})
	_assert_eq(burst_chamber.get_queued_round_modifiers().size(), 1, "queued modifiers should be stored while chamber is locked")

	burst_chamber.set_linked_turret(null)
	_cleanup_node(chamber)
	_cleanup_node(burst_chamber)
	_cleanup_node(dummy_turret)
	await _flush_test_cleanup()

func _test_event_roulette_signal_bridge() -> void:
	var controller: EventRouletteController = EventRouletteController.new()
	var chamber: ControlChamber = ControlChamber.new()
	var banner_state: Dictionary = {"count": 0}
	var refresh_state: Dictionary = {"count": 0, "last_faction_id": -1}
	get_root().add_child(chamber)
	await process_frame

	controller.banner_requested.connect(func(title_text: String, sub_text: String, accent: Color, auto_hide: bool) -> void:
		banner_state["count"] = int(banner_state.get("count", 0)) + 1
		banner_state["title_text"] = title_text
		banner_state["sub_text"] = sub_text
		banner_state["accent"] = accent
		banner_state["auto_hide"] = auto_hide
	)
	controller.chamber_ui_refresh_requested.connect(func(faction_id: int) -> void:
		refresh_state["count"] = int(refresh_state.get("count", 0)) + 1
		refresh_state["last_faction_id"] = faction_id
	)
	controller.chambers = {GameConfig.Faction.BLUE: chamber}
	controller.main_ref = Node.new()

	controller._apply_resolved_event({
		"faction_id": GameConfig.Faction.BLUE,
		"final_effect": EventRouletteController.EFFECT_BONUS_10,
	})

	_assert_eq(chamber.pending_count, 11, "event roulette should still apply event effects through chamber state")
	_assert_eq(int(banner_state.get("count", 0)), 1, "event roulette should request one banner via signal")
	_assert_true(banner_state.get("accent", null) is Color, "event roulette banner signal should carry a color payload")
	_assert_true(bool(banner_state.get("auto_hide", false)), "event roulette banner signal should preserve auto-hide flag")
	_assert_eq(int(refresh_state.get("count", 0)), 1, "event roulette should request chamber ui refresh via signal")
	_assert_eq(int(refresh_state.get("last_faction_id", -1)), GameConfig.Faction.BLUE, "event roulette refresh signal should target the affected chamber id")

	_cleanup_node(chamber)
	_cleanup_node(controller.main_ref)
	_cleanup_node(controller)
	await _flush_test_cleanup()

func _test_chamber_ball_physics_helper() -> void:
	var chamber_size: Vector2 = Vector2(120.0, 286.0)
	var ball: ControlBall = ControlBall.new()
	ball.radius = ControlChamber.CONTROL_BALL_RADIUS
	ball.position = Vector2(24.0, chamber_size.y - ball.radius + 0.5)
	ball.velocity = Vector2.ZERO

	var left_gate_result: Dictionary = ChamberBallPhysicsScript.step_ball(
		ball,
		0.016,
		{
			"gravity": 420.0,
			"pegs": [],
			"peg_collision_radii": [],
			"chamber_size": chamber_size,
			"gate_x": chamber_size.x * 0.5,
			"gate_divider_width": ControlChamber.GATE_DIVIDER_WIDTH,
			"gate_height": ControlChamber.GATE_HEIGHT,
			"gate_divider_rise": ControlChamber.GATE_DIVIDER_RISE,
			"jammed": false,
			"stuck_move_eps": ControlChamber.STUCK_MOVE_EPS,
			"stuck_speed_eps": ControlChamber.STUCK_SPEED_EPS,
			"stuck_time_limit": ControlChamber.STUCK_TIME_LIMIT,
			"wall_stuck_margin": ControlChamber.WALL_STUCK_MARGIN,
			"wall_stuck_y_eps": ControlChamber.WALL_STUCK_Y_EPS,
			"control_ball_max_stay_time": ControlChamber.CONTROL_BALL_MAX_STAY_TIME,
		},
		{},
		0.0
	)
	_assert_eq(str(left_gate_result.get("gate_result", "")), ChamberBallPhysicsScript.GATE_RESULT_LEFT, "chamber physics helper should detect left gate landing")

	ball.position = Vector2(96.0, chamber_size.y - ball.radius + 0.5)
	var right_gate_result: Dictionary = ChamberBallPhysicsScript.step_ball(
		ball,
		0.016,
		{
			"gravity": 420.0,
			"pegs": [],
			"peg_collision_radii": [],
			"chamber_size": chamber_size,
			"gate_x": chamber_size.x * 0.5,
			"gate_divider_width": ControlChamber.GATE_DIVIDER_WIDTH,
			"gate_height": ControlChamber.GATE_HEIGHT,
			"gate_divider_rise": ControlChamber.GATE_DIVIDER_RISE,
			"jammed": false,
			"stuck_move_eps": ControlChamber.STUCK_MOVE_EPS,
			"stuck_speed_eps": ControlChamber.STUCK_SPEED_EPS,
			"stuck_time_limit": ControlChamber.STUCK_TIME_LIMIT,
			"wall_stuck_margin": ControlChamber.WALL_STUCK_MARGIN,
			"wall_stuck_y_eps": ControlChamber.WALL_STUCK_Y_EPS,
			"control_ball_max_stay_time": ControlChamber.CONTROL_BALL_MAX_STAY_TIME,
		},
		{},
		0.0
	)
	_assert_eq(str(right_gate_result.get("gate_result", "")), ChamberBallPhysicsScript.GATE_RESULT_RIGHT, "chamber physics helper should detect right gate landing")

	var relaunch_result: Dictionary = ChamberBallPhysicsScript.step_ball(
		ball,
		0.016,
		{
			"gravity": 420.0,
			"pegs": [],
			"peg_collision_radii": [],
			"chamber_size": chamber_size,
			"gate_x": chamber_size.x * 0.5,
			"gate_divider_width": ControlChamber.GATE_DIVIDER_WIDTH,
			"gate_height": ControlChamber.GATE_HEIGHT,
			"gate_divider_rise": ControlChamber.GATE_DIVIDER_RISE,
			"jammed": false,
			"stuck_move_eps": ControlChamber.STUCK_MOVE_EPS,
			"stuck_speed_eps": ControlChamber.STUCK_SPEED_EPS,
			"stuck_time_limit": ControlChamber.STUCK_TIME_LIMIT,
			"wall_stuck_margin": ControlChamber.WALL_STUCK_MARGIN,
			"wall_stuck_y_eps": ControlChamber.WALL_STUCK_Y_EPS,
			"control_ball_max_stay_time": ControlChamber.CONTROL_BALL_MAX_STAY_TIME,
		},
		{},
		ControlChamber.CONTROL_BALL_MAX_STAY_TIME
	)
	_assert_true(bool(relaunch_result.get("relaunch_request", false)), "chamber physics helper should request relaunch after max stay time")

	_cleanup_node(ball)

func _test_chamber_draw_model() -> void:
	var chamber_size: Vector2 = Vector2(120.0, 286.0)
	var neutral_snapshot: Dictionary = ChamberDrawModelScript.build_snapshot({
		"faction_color": GameConfig.faction_color(GameConfig.Faction.BLUE),
		"chamber_size": chamber_size,
		"gate_height": ControlChamber.GATE_HEIGHT,
		"peg_radius": ControlChamber.PEG_RADIUS,
		"pegs": [],
		"is_damaged": false,
		"is_locked": false,
		"jammed_time_left": 0.0,
		"status_anim_t": 1.0,
		"game_elapsed_time": ControlChamber.GATE_RAMP_SECONDS,
		"gate_multiplier": 3,
		"scale_x": 1.0,
		"gate_ramp_seconds": ControlChamber.GATE_RAMP_SECONDS,
		"gate_start_release_ratio": ControlChamber.GATE_START_RELEASE_RATIO,
		"gate_end_release_ratio": ControlChamber.GATE_END_RELEASE_RATIO,
		"gate_min_ratio": ControlChamber.GATE_MIN_RATIO,
	})
	_assert_eq(str(neutral_snapshot.get("left_gate_text", "")), "x3", "chamber draw model should expose x3 label when multiplier is 3")
	_assert_eq(str(neutral_snapshot.get("right_gate_text", "")), "发射", "chamber draw model should expose launch label when healthy")
	_assert_eq(snappedf(float(neutral_snapshot.get("x2_width", 0.0)), 0.01), 84.0, "chamber draw model should widen x2 gate as the match progresses")

	var jammed_snapshot: Dictionary = ChamberDrawModelScript.build_snapshot({
		"faction_color": GameConfig.faction_color(GameConfig.Faction.RED),
		"chamber_size": chamber_size,
		"gate_height": ControlChamber.GATE_HEIGHT,
		"peg_radius": ControlChamber.PEG_RADIUS,
		"pegs": [],
		"is_damaged": false,
		"is_locked": false,
		"jammed_time_left": 3.0,
		"status_anim_t": 1.0,
		"game_elapsed_time": 0.0,
		"gate_multiplier": 2,
		"scale_x": 1.0,
		"gate_ramp_seconds": ControlChamber.GATE_RAMP_SECONDS,
		"gate_start_release_ratio": ControlChamber.GATE_START_RELEASE_RATIO,
		"gate_end_release_ratio": ControlChamber.GATE_END_RELEASE_RATIO,
		"gate_min_ratio": ControlChamber.GATE_MIN_RATIO,
	})
	_assert_true(bool(jammed_snapshot.get("jammed", false)), "chamber draw model should mark jammed snapshots")
	_assert_eq(str(jammed_snapshot.get("left_gate_text", "")), "短路", "chamber draw model should expose jammed left label")
	_assert_eq(snappedf(float(jammed_snapshot.get("x2_width", 0.0)), 0.01), 60.0, "jammed chamber should collapse to equal-width gates")

	var damaged_snapshot: Dictionary = ChamberDrawModelScript.build_snapshot({
		"faction_color": GameConfig.faction_color(GameConfig.Faction.GREEN),
		"chamber_size": chamber_size,
		"gate_height": ControlChamber.GATE_HEIGHT,
		"peg_radius": ControlChamber.PEG_RADIUS,
		"pegs": [],
		"is_damaged": true,
		"is_locked": false,
		"jammed_time_left": 0.0,
		"status_anim_t": 1.0,
		"game_elapsed_time": 0.0,
		"gate_multiplier": 2,
		"scale_x": 1.0,
		"gate_ramp_seconds": ControlChamber.GATE_RAMP_SECONDS,
		"gate_start_release_ratio": ControlChamber.GATE_START_RELEASE_RATIO,
		"gate_end_release_ratio": ControlChamber.GATE_END_RELEASE_RATIO,
		"gate_min_ratio": ControlChamber.GATE_MIN_RATIO,
	})
	_assert_eq(str(damaged_snapshot.get("left_gate_text", "")), "X", "chamber draw model should expose damage label on the left gate")
	_assert_eq(str(damaged_snapshot.get("right_gate_text", "")), "X", "chamber draw model should expose damage label on the right gate")

func _test_chamber_save_adapter() -> void:
	var chamber: ControlChamber = ControlChamber.new()
	chamber.setup(GameConfig.Faction.GREEN, Vector2(48.0, 64.0))
	get_root().add_child(chamber)
	await process_frame

	chamber.pending_count = 9
	chamber.locked_remaining = 4
	chamber.is_locked = true
	chamber.set_jammed_time_left(2.25)
	chamber.set_queued_round_modifiers([{"type": "bonus_10", "amount": 10}])
	chamber.release_ball = chamber.balls[0]

	var collected: Dictionary = chamber.collect_state()
	_assert_eq(int(collected.get("chamber_pending_count", 0)), 9, "chamber save adapter should collect pending count")
	_assert_eq(int(collected.get("chamber_locked_remaining", 0)), 4, "chamber save adapter should collect locked remaining")
	_assert_true(bool(collected.get("chamber_is_locked", false)), "chamber save adapter should collect lock flag")
	_assert_eq(int(collected.get("chamber_release_ball_index", -1)), 0, "chamber save adapter should collect release ball index")
	_assert_eq(collected.get("queued_round_modifiers", []).size(), 1, "chamber save adapter should collect queued modifiers")
	_assert_eq(collected.get("control_balls", []).size(), 1, "chamber save adapter should collect control ball states")

	var restored: Dictionary = ChamberSaveAdapterScript.restore_state({
		"chamber_pending_count": 7,
		"chamber_locked_remaining": 3,
		"chamber_is_locked": true,
		"chamber_is_damaged": false,
		"chamber_ball_count": 99,
		"chamber_release_ball_index": 8,
		"chamber_jammed_time_left": 1.5,
		"queued_round_modifiers": [{"type": "x2", "multiplier": 2}, "bad"],
		"control_balls": [
			{
				"radius": 99.0,
				"position": [-20.0, 999.0],
				"velocity": [9999.0, 9999.0],
				"stay_time": 999.0,
			}
		]
	}, {
		"chamber_size": chamber.chamber_size,
		"default_ball_radius": ControlChamber.CONTROL_BALL_RADIUS,
		"max_restore_control_balls": ControlChamber.MAX_RESTORE_CONTROL_BALLS,
		"max_control_balls": GameConfig.MAX_CONTROL_BALLS_PER_CHAMBER,
		"max_pending_count": GameConfig.get_max_pending_count(),
	})
	_assert_eq(restored.get("queued_round_modifiers", []).size(), 1, "chamber save adapter should drop invalid queued modifiers")
	_assert_eq(restored.get("control_balls", []).size(), 1, "chamber save adapter should keep sanitized control balls")
	_assert_eq(int(restored.get("chamber_release_ball_index", -2)), -1, "chamber save adapter should clear invalid release index")
	var restored_ball: Dictionary = restored.get("control_balls", [])[0]
	_assert_eq(snappedf(float(restored_ball.get("radius", 0.0)), 0.01), 12.0, "chamber save adapter should clamp restored radius")
	_assert_eq(snappedf((restored_ball.get("position", Vector2.ZERO) as Vector2).x, 0.01), 12.0, "chamber save adapter should clamp restored ball x")
	_assert_eq(snappedf((restored_ball.get("position", Vector2.ZERO) as Vector2).y, 0.01), chamber.chamber_size.y - 12.0, "chamber save adapter should clamp restored ball y")
	_assert_eq(snappedf(float(restored_ball.get("stay_time", 0.0)), 0.01), ControlChamber.CONTROL_BALL_MAX_STAY_TIME, "chamber save adapter should clamp restored stay time")
	_assert_true((restored_ball.get("velocity", Vector2.ZERO) as Vector2).length() <= 520.01, "chamber save adapter should clamp restored velocity")

	_cleanup_node(chamber)
	await _flush_test_cleanup()

func _test_restore_from_state_interfaces() -> void:
	var chamber: ControlChamber = ControlChamber.new()
	chamber.setup(GameConfig.Faction.GREEN, Vector2(48.0, 64.0))
	get_root().add_child(chamber)
	await process_frame

	chamber.restore_from_state({
		"chamber_pending_count": 7,
		"chamber_locked_remaining": 5,
		"chamber_jammed_time_left": 2.5,
		"chamber_is_locked": true,
		"chamber_release_ball_index": 1,
		"queued_round_modifiers": [{"type": "bonus_10", "amount": 10}],
		"control_balls": [
			{
				"position": [20.0, 30.0],
				"velocity": [12.0, -24.0],
				"stay_time": 0.5,
			},
			{
				"position": [40.0, 56.0],
				"velocity": [-18.0, 8.0],
				"stay_time": 1.25,
			}
		]
	})
	_assert_eq(chamber.pending_count, 7, "restore_from_state should restore chamber pending count")
	_assert_eq(chamber.locked_remaining, 5, "restore_from_state should restore chamber locked remaining")
	_assert_true(chamber.is_locked, "restore_from_state should restore chamber locked flag")
	_assert_eq(chamber.balls.size(), 2, "restore_from_state should rebuild chamber control balls")
	_assert_true(chamber.release_ball == chamber.balls[1], "restore_from_state should restore chamber release ball")
	_assert_eq(chamber.get_queued_round_modifiers().size(), 1, "restore_from_state should restore queued chamber modifiers")
	_assert_eq(snappedf(chamber.get_jammed_time_left(), 0.01), 2.5, "restore_from_state should restore chamber jam timer")

	var turret: Turret = Turret.new()
	turret.restore_from_state({
		"turret_health": 17,
		"turret_burst_remaining": 12,
		"turret_burst_total": 16,
		"turret_burst_index": 4,
		"turret_burst_timer": 0.3,
		"turret_burst_locked": true,
	})
	_assert_eq(turret.health, 17, "restore_from_state should restore turret health")
	_assert_eq(turret.burst_remaining, 12, "restore_from_state should restore turret burst remaining")
	_assert_eq(turret.burst_total, 16, "restore_from_state should restore turret burst total")
	_assert_true(turret.burst_locked, "restore_from_state should restore turret burst lock")

	_cleanup_node(chamber)
	_cleanup_node(turret)
	await _flush_test_cleanup()

func _test_turret_cancel_burst() -> void:
	var turret: Turret = Turret.new()
	turret.burst_remaining = 32
	turret.burst_total = 32
	turret.burst_index = 6
	turret.burst_timer = 0.5
	turret.burst_progress_emit_timer = 0.2
	turret.burst_locked = true

	var remaining: int = turret.cancel_burst()
	_assert_eq(remaining, 32, "cancel_burst should return the remaining shot count")
	_assert_eq(turret.burst_remaining, 0, "cancel_burst should clear remaining shots")
	_assert_eq(turret.burst_total, 0, "cancel_burst should clear total shots")
	_assert_true(not turret.burst_locked, "cancel_burst should unlock the turret")
	_cleanup_node(turret)


func _test_bullet_lifecycle() -> void:
	var pool: BulletPool = BulletPool.new()
	var fresh_bullet: Bullet = Bullet.new()
	_assert_true(not fresh_bullet.is_active, "new bullet should start inactive")

	var spawned: Bullet = pool.spawn_bullet(GameConfig.Faction.BLUE, Vector2(8.0, 12.0), Vector2.RIGHT, null, {})
	_assert_true(spawned.is_active, "spawned bullet should be active")
	_assert_eq(pool.active_bullets.size(), 1, "spawn should register active bullet")
	_assert_eq(pool.inactive_bullets.size(), 0, "spawn should not increase inactive bullet list yet")

	pool.recycle_bullet(spawned)
	_assert_true(not spawned.is_active, "recycled bullet should become inactive")
	_assert_eq(pool.active_bullets.size(), 0, "recycle should remove active bullet")
	_assert_eq(pool.inactive_bullets.size(), 1, "recycle should return bullet to inactive pool")

	_cleanup_node(fresh_bullet)
	_cleanup_node(pool)

func _test_bullet_restore_from_state() -> void:
	var bullet: Bullet = Bullet.new()
	bullet.simple_draw = false
	bullet.trail_max_points = 8
	bullet.restore_from_state({
		"faction_id": GameConfig.Faction.YELLOW,
		"position": [60.0, 80.0],
		"direction": [0.0, 1.0],
		"age": 1.75,
		"last_cell": [3, 4],
		"trail_points": [
			[60.0, 80.0],
			[60.0, 72.0],
			[60.0, 64.0],
			[60.0, 56.0],
		],
	}, null, {})
	_assert_eq(bullet.faction_id, GameConfig.Faction.YELLOW, "bullet restore should restore faction")
	_assert_eq(snappedf(bullet.global_position.x, 0.01), 60.0, "bullet restore should restore position x")
	_assert_eq(snappedf(bullet.global_position.y, 0.01), 80.0, "bullet restore should restore position y")
	_assert_eq(snappedf(bullet.direction.x, 0.01), 0.0, "bullet restore should restore direction x")
	_assert_eq(snappedf(bullet.direction.y, 0.01), 1.0, "bullet restore should restore direction y")
	_assert_eq(snappedf(bullet.age, 0.01), 1.75, "bullet restore should restore age")
	_assert_eq(bullet.last_cell, Vector2i(3, 4), "bullet restore should restore last touched cell")
	_assert_eq(bullet.trail_points.size(), 3, "bullet restore should clamp trail restore length")
	_assert_eq(bullet.trail_points[0], Vector2(60.0, 80.0), "bullet restore should preserve leading trail point")
	_cleanup_node(bullet)

func _test_bullet_pool_incremental_metrics() -> void:
	var turret: Turret = Turret.new()
	var pool: BulletPool = BulletPool.new()
	pool.set_tracked_turrets({GameConfig.Faction.BLUE: turret})
	_assert_eq(pool.get_tracked_queue_total(), 0, "tracked queue total should start from current turret state")

	turret.restore_from_state({
		"turret_burst_remaining": 18,
		"turret_burst_total": 18,
		"turret_burst_locked": true,
	})
	_assert_eq(pool.get_tracked_queue_total(), 18, "tracked queue total should update from turret burst progress")

	turret.cancel_burst()
	_assert_eq(pool.get_tracked_queue_total(), 0, "tracked queue total should shrink when burst is cancelled")

	var bullet: Bullet = Bullet.new()
	bullet.pool = pool
	bullet.global_position = Vector2(32.0, 48.0)
	bullet.replace_trail_points([Vector2(32.0, 48.0), Vector2(40.0, 48.0), Vector2(48.0, 48.0)])
	_assert_eq(pool.estimate_trail_segments(), 2, "trail segment estimate should track bullet trail changes incrementally")
	bullet.replace_trail_points([Vector2(48.0, 48.0)])
	_assert_eq(pool.estimate_trail_segments(), 0, "trail segment estimate should drop when bullet trail collapses")

	var restored = pool.spawn_bullet_from_state({
		"faction_id": GameConfig.Faction.BLUE,
		"position": [20.0, 24.0],
		"direction": [1.0, 0.0],
		"trail_points": [
			[20.0, 24.0],
			[14.0, 24.0],
			[8.0, 24.0],
		],
	}, null, {})
	_assert_eq(restored.faction_id, GameConfig.Faction.BLUE, "spawn_bullet_from_state should restore faction through pool")
	_assert_eq(pool.estimate_trail_segments(), 2, "spawn_bullet_from_state should register restored trail segments")

	_cleanup_node(turret)
	_cleanup_node(bullet)
	_cleanup_node(pool)

func _test_bullet_pool_active_ordering() -> void:
	var pool: BulletPool = BulletPool.new()
	var bullet_a: Bullet = Bullet.new()
	var bullet_b: Bullet = Bullet.new()
	var bullet_c: Bullet = Bullet.new()
	bullet_a.activate()
	bullet_b.activate()
	bullet_c.activate()
	pool._finalize_spawned_bullet(bullet_a)
	pool._finalize_spawned_bullet(bullet_b)
	pool._finalize_spawned_bullet(bullet_c)

	pool.recycle_bullet(bullet_b)
	_assert_eq(pool.active_bullets.size(), 2, "recycle should swap-pop active bullets without losing count")
	_assert_true(not pool.active_bullet_indices.has(bullet_b.get_instance_id()), "recycle should clear swapped bullet index entry")
	_assert_eq(int(pool.active_bullet_indices.get(bullet_a.get_instance_id(), -1)), 0, "oldest bullet should keep a valid active index after middle removal")

	var oldest = pool._get_oldest_active_bullet()
	_assert_true(oldest == bullet_a, "oldest active bullet lookup should ignore swapped ordering")

	_cleanup_node(bullet_a)
	_cleanup_node(bullet_b)
	_cleanup_node(bullet_c)
	_cleanup_node(pool)

func _test_bullet_trail_dirty_cache() -> void:
	var pool: BulletPool = BulletPool.new()
	var trail_layer: BulletTrailLayer = BulletTrailLayer.new()
	pool.set_trail_layer(trail_layer)

	var bullet: Bullet = Bullet.new()
	bullet.pool = pool
	bullet.set_trail_layer(trail_layer)
	bullet.activate()
	bullet.global_position = Vector2(32.0, 48.0)
	bullet.replace_trail_points([Vector2(32.0, 48.0), Vector2(40.0, 48.0), Vector2(48.0, 48.0)])
	trail_layer._flush_dirty_trail_bullets()
	_assert_eq(int(trail_layer.get_debug_metrics().get("drawable_trail_bullets", 0)), 1, "dirty trail cache should register bullets with drawable trails")

	bullet.configure_visuals(true, true, 0)
	trail_layer._flush_dirty_trail_bullets()
	_assert_eq(int(trail_layer.get_debug_metrics().get("drawable_trail_bullets", -1)), 0, "dirty trail cache should evict bullets when trail drawing is disabled")

	_cleanup_node(bullet)
	_cleanup_node(trail_layer)
	_cleanup_node(pool)

func _test_player_settings_bool_sanitization() -> void:
	var settings_path: String = PlayerSettingsStore.SETTINGS_PATH
	var settings_abs: String = ProjectSettings.globalize_path(settings_path)
	if FileAccess.file_exists(settings_path):
		DirAccess.remove_absolute(settings_abs)

	var raw_file := FileAccess.open(settings_path, FileAccess.WRITE)
	_assert_true(raw_file != null, "player settings test should create settings file")
	if raw_file != null:
		raw_file.store_string("{\"show_performance_info\":\"abc\",\"low_effect_mode\":\"true\"}")
		raw_file.close()

	var loaded: Dictionary = PlayerSettingsStore.load_settings()
	_assert_eq(typeof(loaded.get("show_performance_info", null)), TYPE_BOOL, "player settings should normalize show_performance_info to bool")
	_assert_eq(typeof(loaded.get("low_effect_mode", null)), TYPE_BOOL, "player settings should normalize low_effect_mode to bool")
	_assert_eq(bool(loaded.get("show_performance_info", not OS.is_debug_build())), OS.is_debug_build(), "player settings should fall back to default for invalid bool strings")
	_assert_true(bool(loaded.get("low_effect_mode", false)), "player settings should parse truthy strings")

	PlayerSettingsStore.save_settings({
		"show_performance_info": "off",
		"low_effect_mode": 1,
	})
	var saved_file := FileAccess.open(settings_path, FileAccess.READ)
	_assert_true(saved_file != null, "player settings save should write normalized file")
	if saved_file != null:
		var parsed = JSON.parse_string(saved_file.get_as_text())
		saved_file.close()
		_assert_true(parsed is Dictionary, "player settings save should persist dictionary json")
		if parsed is Dictionary:
			_assert_eq(typeof(parsed.get("show_performance_info", null)), TYPE_BOOL, "saved player settings should keep bool type for performance flag")
			_assert_eq(typeof(parsed.get("low_effect_mode", null)), TYPE_BOOL, "saved player settings should keep bool type for low effect mode")

	if FileAccess.file_exists(settings_path):
		DirAccess.remove_absolute(settings_abs)
