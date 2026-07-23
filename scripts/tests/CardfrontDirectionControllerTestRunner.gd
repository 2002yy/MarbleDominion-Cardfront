extends SceneTree

const CardfrontDirectionControllerScript = preload("res://scripts/cardfront/arena/CardfrontDirectionController.gd")
const CardfrontFireDirectorScript = preload("res://scripts/cardfront/fire/CardfrontFireDirector.gd")
const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontDirectionControllerTest] Starting direction controller tests")
	await process_frame

	await _test_angle_clamp_and_runtime_input()
	await _test_manual_angle_reaches_director()

	_assert.report("[CardfrontDirectionControllerTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_angle_clamp_and_runtime_input() -> void:
	var fixture: Dictionary = await _make_fixture()
	var controller = fixture.controller
	var turret = fixture.turret

	controller.set_offset_degrees(200.0)
	_assert.eq(controller.get_offset_degrees(), 60.0, "direction control: positive angle should clamp")
	controller.set_offset_degrees(-200.0)
	_assert.eq(controller.get_offset_degrees(), -60.0, "direction control: negative angle should clamp")
	_assert.that(bool(turret.manual_aim_enabled), "direction control: player turret should enter manual aim")
	_assert.that(
		absf(angle_difference(float(turret.manual_aim_angle), float(controller.get_current_angle()))) < 0.0001,
		"direction control: turret angle should match controller"
	)

	controller.set_offset_degrees(0.0)
	var event := InputEventKey.new()
	event.keycode = KEY_A
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	_assert.eq(controller.get_offset_degrees(), -4.0, "direction control: real A-key routing should nudge left")

	TestFixtures.cleanup_node(fixture.root)
	await process_frame


func _test_manual_angle_reaches_director() -> void:
	var fixture: Dictionary = await _make_fixture()
	var controller = fixture.controller
	var director = fixture.director

	controller.set_offset_degrees(27.0)
	_assert.that(
		director.has_owner_manual_angle(CardfrontRulesScript.PLAYER_FACTION),
		"direction control: FireDirector should register player manual angle"
	)
	_assert.that(
		absf(angle_difference(
			director.get_owner_manual_angle(CardfrontRulesScript.PLAYER_FACTION),
			controller.get_current_angle()
		)) < 0.0001,
		"direction control: FireDirector angle should match controller"
	)
	_assert.that(
		not director.has_owner_manual_angle(CardfrontRulesScript.AI_FACTION),
		"direction control: AI should retain automatic targeting"
	)

	TestFixtures.cleanup_node(fixture.root)
	await process_frame


func _make_fixture() -> Dictionary:
	var root := Node2D.new()
	get_root().add_child(root)
	var battlefield := Battlefield.new()
	battlefield.configure(20, 12)
	root.add_child(battlefield)
	var turret := Turret.new()
	turret.setup(CardfrontRulesScript.PLAYER_FACTION, Vector2(120.0, 220.0), battlefield, null)
	turret.set_aim_profile(-PI * 0.5, deg_to_rad(58.0))
	root.add_child(turret)
	var director = CardfrontFireDirectorScript.new()
	director.set_process(false)
	root.add_child(director)
	var controller = CardfrontDirectionControllerScript.new()
	root.add_child(controller)
	_assert.that(
		controller.setup(CardfrontRulesScript.PLAYER_FACTION, turret, director, -PI * 0.5),
		"direction control: fixture should configure"
	)
	await process_frame
	return {
		"root": root,
		"battlefield": battlefield,
		"turret": turret,
		"director": director,
		"controller": controller,
	}
