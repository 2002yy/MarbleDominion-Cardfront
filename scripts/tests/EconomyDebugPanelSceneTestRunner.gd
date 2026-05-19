extends SceneTree

const CardfrontEconomyDebugPanelScript = preload("res://scripts/cardfront/economy/CardfrontEconomyDebugPanel.gd")
const CardfrontResourceStateScript = preload("res://scripts/cardfront/economy/CardfrontResourceState.gd")
const EconomyTickSystemScript = preload("res://scripts/cardfront/economy/EconomyTickSystem.gd")
const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const RegionMapScript = preload("res://scripts/cardfront/regions/RegionMap.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[EconomyDebugPanelSceneTest] Starting Cardfront economy debug panel scene tests")
	await process_frame

	_test_cardfront_panel_visible_and_compact()
	_test_non_cardfront_panel_hidden()
	await _flush()

	_assert.report("[EconomyDebugPanelSceneTest]")
	if _assert.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _flush() -> void:
	await process_frame
	await process_frame


func _test_cardfront_panel_visible_and_compact() -> void:
	var fixture: Dictionary = _make_fixture()
	var panel = CardfrontEconomyDebugPanelScript.new()
	get_root().add_child(panel)
	panel.setup(fixture.region_map, fixture.battlefield, fixture.economy_system, fixture.resource_states, GameConfig.GAME_MODE_CARDFRONT)

	var panel_box = panel.get_node_or_null("EconomyDebugPanel")
	_assert.that(panel.visible, "economy debug panel: Cardfront mode should be visible")
	_assert.that(panel_box != null, "economy debug panel: should create panel node")
	if panel_box != null:
		_assert.that(panel_box.size.x <= 280.0, "economy debug panel: width should stay compact")
		_assert.that(panel_box.size.y <= 170.0, "economy debug panel: height should stay compact")
	_assert.that(panel.get_debug_text().find("本tick") >= 0, "economy debug panel: compact text should include tick summary")
	_assert.that(_count_region_lines(panel.get_debug_text()) <= 3, "economy debug panel: compact text should show at most three region lines")

	TestFixtures.cleanup_node(panel)
	_cleanup_fixture(fixture)


func _test_non_cardfront_panel_hidden() -> void:
	var fixture: Dictionary = _make_fixture()
	var panel = CardfrontEconomyDebugPanelScript.new()
	get_root().add_child(panel)
	panel.setup(fixture.region_map, fixture.battlefield, fixture.economy_system, fixture.resource_states, GameConfig.GAME_MODE_BASIC)

	_assert.that(not panel.visible, "economy debug panel: old BallWar mode should be hidden")
	_assert.eq(panel.get_debug_text(), "", "economy debug panel: hidden panel should clear debug text")

	TestFixtures.cleanup_node(panel)
	_cleanup_fixture(fixture)


func _make_fixture() -> Dictionary:
	var region_map := RegionMapScript.new()
	region_map.configure(40)
	region_map.generate_default_layout()

	var battlefield := Battlefield.new()
	battlefield.configure(40)
	get_root().add_child(battlefield)

	var player_state = CardfrontResourceStateScript.new()
	player_state.add_energy(12)
	player_state.add_parts(4)
	var ai_state = CardfrontResourceStateScript.new()
	var resource_states: Dictionary = {
		CardfrontRulesScript.PLAYER_FACTION: player_state,
		CardfrontRulesScript.AI_FACTION: ai_state,
	}

	var economy_system = EconomyTickSystemScript.new()
	get_root().add_child(economy_system)
	economy_system.setup(region_map, battlefield, resource_states)

	return {
		"region_map": region_map,
		"battlefield": battlefield,
		"economy_system": economy_system,
		"resource_states": resource_states,
	}


func _cleanup_fixture(fixture: Dictionary) -> void:
	TestFixtures.cleanup_node(fixture.get("economy_system", null))
	TestFixtures.cleanup_node(fixture.get("battlefield", null))


func _count_region_lines(text: String) -> int:
	var total: int = 0
	for line in text.split("\n"):
		if String(line).find("#") >= 0:
			total += 1
	return total
