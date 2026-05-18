extends SceneTree

const CardfrontModeScript = preload("res://scripts/cardfront/CardfrontMode.gd")
const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const CardfrontEconomyDebugPanelScript = preload("res://scripts/cardfront/economy/CardfrontEconomyDebugPanel.gd")
const CardfrontResourceStateScript = preload("res://scripts/cardfront/economy/CardfrontResourceState.gd")
const EconomyTickSystemScript = preload("res://scripts/cardfront/economy/EconomyTickSystem.gd")
const RegionMapScript = preload("res://scripts/cardfront/regions/RegionMap.gd")
const RegionTypeScript = preload("res://scripts/cardfront/regions/RegionType.gd")
const RegionYieldCalculatorScript = preload("res://scripts/cardfront/economy/RegionYieldCalculator.gd")
const RegionYieldRulesScript = preload("res://scripts/cardfront/economy/RegionYieldRules.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[EconomyTickTest] Starting Cardfront economy tick tests")
	await process_frame

	_test_resource_state()
	_test_region_yield_rules()
	_test_region_yield_calculator()
	_test_economy_tick_interval()
	_test_tick_once_and_owner_grid_safety()
	await _test_main_economy_integration()
	await _flush()

	_assert.report("[EconomyTickTest]")
	if _assert.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _flush() -> void:
	await process_frame
	await process_frame


func _test_resource_state() -> void:
	var state = CardfrontResourceStateScript.new()
	_assert.eq(state.energy, 0, "resource state: energy should start at zero")
	_assert.eq(state.parts, 0, "resource state: parts should start at zero")
	state.add_energy(3)
	state.add_parts(2)
	_assert.eq(state.energy, 3, "resource state: add_energy should increase energy")
	_assert.eq(state.parts, 2, "resource state: add_parts should increase parts")
	_assert.that(state.can_pay(2, 1), "resource state: can_pay should pass when both resources are available")
	_assert.that(state.pay(2, 1), "resource state: pay should succeed when both resources are available")
	_assert.eq(state.energy, 1, "resource state: pay should deduct energy")
	_assert.eq(state.parts, 1, "resource state: pay should deduct parts")

	var before: Dictionary = state.snapshot()
	_assert.that(not state.pay(2, 0), "resource state: pay should fail when energy is short")
	_assert.eq(state.snapshot(), before, "resource state: failed pay should not deduct partial resources")

	state.restore({"energy": -5, "parts": -3})
	_assert.eq(state.energy, 0, "resource state: restore should clamp negative energy")
	_assert.eq(state.parts, 0, "resource state: restore should clamp negative parts")


func _test_region_yield_rules() -> void:
	_assert.eq(RegionYieldRulesScript.get_yield(RegionTypeScript.ENERGY, 0), {"energy": 0, "parts": 0}, "yield rules: ENERGY tier 0 should produce nothing")
	_assert.eq(RegionYieldRulesScript.get_yield(RegionTypeScript.ENERGY, 1), {"energy": 1, "parts": 0}, "yield rules: ENERGY tier 1 should produce energy 1")
	_assert.eq(RegionYieldRulesScript.get_yield(RegionTypeScript.ENERGY, 2), {"energy": 2, "parts": 0}, "yield rules: ENERGY tier 2 should produce energy 2")
	_assert.eq(RegionYieldRulesScript.get_yield(RegionTypeScript.FACTORY, 1), {"energy": 0, "parts": 1}, "yield rules: FACTORY tier 1 should produce parts 1")
	_assert.eq(RegionYieldRulesScript.get_yield(RegionTypeScript.FACTORY, 2), {"energy": 0, "parts": 2}, "yield rules: FACTORY tier 2 should produce parts 2")
	_assert.eq(RegionYieldRulesScript.get_yield(RegionTypeScript.LAB, 2), {"energy": 0, "parts": 0}, "yield rules: LAB should not produce regular resources yet")


func _test_region_yield_calculator() -> void:
	var region_map = _make_region_map(40)
	var bf := _make_battlefield(40)
	var energy_id: int = int(region_map.get_region_ids_by_type(RegionTypeScript.ENERGY)[0])
	var factory_id: int = int(region_map.get_region_ids_by_type(RegionTypeScript.FACTORY)[0])
	var lab_id: int = int(region_map.get_region_ids_by_type(RegionTypeScript.LAB)[0])

	_set_region_owner_percent(bf, region_map, energy_id, CardfrontRulesScript.PLAYER_FACTION, 0.0)
	var energy_tier_0: Dictionary = RegionYieldCalculatorScript.calculate_region_yield(region_map, bf, energy_id, CardfrontRulesScript.PLAYER_FACTION)
	_assert.eq(energy_tier_0.get("yield", {}), {"energy": 0, "parts": 0}, "yield calculator: ENERGY tier 0 should produce nothing")

	_set_region_owner_percent(bf, region_map, energy_id, CardfrontRulesScript.PLAYER_FACTION, 0.50)
	var energy_tier_1: Dictionary = RegionYieldCalculatorScript.calculate_region_yield(region_map, bf, energy_id, CardfrontRulesScript.PLAYER_FACTION)
	_assert.eq(energy_tier_1.get("yield_tier", -1), 1, "yield calculator: ENERGY 50 percent should be tier 1")
	_assert.eq(energy_tier_1.get("yield", {}), {"energy": 1, "parts": 0}, "yield calculator: ENERGY tier 1 should produce energy 1")

	_set_region_owner_percent(bf, region_map, energy_id, CardfrontRulesScript.PLAYER_FACTION, 0.80)
	var energy_tier_2: Dictionary = RegionYieldCalculatorScript.calculate_region_yield(region_map, bf, energy_id, CardfrontRulesScript.PLAYER_FACTION)
	_assert.eq(energy_tier_2.get("yield_tier", -1), 2, "yield calculator: ENERGY 80 percent should be tier 2")
	_assert.eq(energy_tier_2.get("yield", {}), {"energy": 2, "parts": 0}, "yield calculator: ENERGY tier 2 should produce energy 2")

	_set_region_owner_percent(bf, region_map, factory_id, CardfrontRulesScript.PLAYER_FACTION, 0.50)
	var factory_tier_1: Dictionary = RegionYieldCalculatorScript.calculate_region_yield(region_map, bf, factory_id, CardfrontRulesScript.PLAYER_FACTION)
	_assert.eq(factory_tier_1.get("yield", {}), {"energy": 0, "parts": 1}, "yield calculator: FACTORY tier 1 should produce parts 1")

	_set_region_owner_percent(bf, region_map, factory_id, CardfrontRulesScript.PLAYER_FACTION, 0.80)
	var factory_tier_2: Dictionary = RegionYieldCalculatorScript.calculate_region_yield(region_map, bf, factory_id, CardfrontRulesScript.PLAYER_FACTION)
	_assert.eq(factory_tier_2.get("yield", {}), {"energy": 0, "parts": 2}, "yield calculator: FACTORY tier 2 should produce parts 2")

	_set_region_owner_percent(bf, region_map, lab_id, CardfrontRulesScript.PLAYER_FACTION, 0.80)
	var lab_yield: Dictionary = RegionYieldCalculatorScript.calculate_region_yield(region_map, bf, lab_id, CardfrontRulesScript.PLAYER_FACTION)
	_assert.eq(lab_yield.get("yield", {}), {"energy": 0, "parts": 0}, "yield calculator: LAB should not produce regular resources")

	_set_region_owner_percent(bf, region_map, energy_id, CardfrontRulesScript.AI_FACTION, 0.80)
	var player_yield_from_ai_area: Dictionary = RegionYieldCalculatorScript.calculate_region_yield(region_map, bf, energy_id, CardfrontRulesScript.PLAYER_FACTION)
	var ai_yield_from_ai_area: Dictionary = RegionYieldCalculatorScript.calculate_region_yield(region_map, bf, energy_id, CardfrontRulesScript.AI_FACTION)
	_assert.eq(player_yield_from_ai_area.get("yield", {}), {"energy": 0, "parts": 0}, "yield calculator: AI-controlled ENERGY should not produce for player")
	_assert.eq(ai_yield_from_ai_area.get("yield", {}), {"energy": 2, "parts": 0}, "yield calculator: AI-controlled ENERGY should produce for AI")

	_set_all_neutral(bf, 40)
	var owners: Array = bf.owners.duplicate(true)
	_assign_region_owner_percent(owners, region_map.get_region_cells(energy_id), CardfrontRulesScript.PLAYER_FACTION, 0.80)
	_assign_region_owner_percent(owners, region_map.get_region_cells(factory_id), CardfrontRulesScript.PLAYER_FACTION, 0.50)
	bf.replace_owners(owners, false)
	var total_yield: Dictionary = RegionYieldCalculatorScript.calculate_for_owner(region_map, bf, CardfrontRulesScript.PLAYER_FACTION)
	_assert.eq(total_yield.get("total_yield", {}), {"energy": 2, "parts": 1}, "yield calculator: total tick yield should sum controllable regions")

	TestFixtures.cleanup_node(bf)


func _test_economy_tick_interval() -> void:
	var region_map = _make_region_map(40)
	var bf := _make_battlefield(40)
	var energy_id: int = int(region_map.get_region_ids_by_type(RegionTypeScript.ENERGY)[0])
	_set_region_owner_percent(bf, region_map, energy_id, CardfrontRulesScript.PLAYER_FACTION, 0.80)

	var state = CardfrontResourceStateScript.new()
	var system = EconomyTickSystemScript.new()
	get_root().add_child(system)
	system.setup(region_map, bf, {CardfrontRulesScript.PLAYER_FACTION: state})
	system._process(0.99)
	_assert.eq(state.energy, 0, "economy tick: interval below one second should not settle")
	system._process(0.01)
	_assert.eq(state.energy, 2, "economy tick: interval reaching one second should settle once")

	TestFixtures.cleanup_node(system)
	TestFixtures.cleanup_node(bf)


func _test_tick_once_and_owner_grid_safety() -> void:
	var region_map = _make_region_map(40)
	var bf := _make_battlefield(40)
	var energy_id: int = int(region_map.get_region_ids_by_type(RegionTypeScript.ENERGY)[0])
	var factory_id: int = int(region_map.get_region_ids_by_type(RegionTypeScript.FACTORY)[0])
	_set_all_neutral(bf, 40)
	var owners: Array = bf.owners.duplicate(true)
	_assign_region_owner_percent(owners, region_map.get_region_cells(energy_id), CardfrontRulesScript.PLAYER_FACTION, 0.80)
	_assign_region_owner_percent(owners, region_map.get_region_cells(factory_id), CardfrontRulesScript.PLAYER_FACTION, 0.50)
	bf.replace_owners(owners, false)

	var before_owners: String = JSON.stringify(bf.owners)
	var state = CardfrontResourceStateScript.new()
	var system = EconomyTickSystemScript.new()
	get_root().add_child(system)
	system.setup(region_map, bf, {CardfrontRulesScript.PLAYER_FACTION: state})
	system.tick_once()
	_assert.eq(state.snapshot(), {"energy": 2, "parts": 1}, "economy tick: tick_once should settle current yield")
	system.tick_once()
	_assert.eq(state.snapshot(), {"energy": 4, "parts": 2}, "economy tick: repeated tick_once should settle stable yield again")
	_assert.eq(JSON.stringify(bf.owners), before_owners, "economy tick: tick system should not change battlefield owners")

	var panel = CardfrontEconomyDebugPanelScript.new()
	get_root().add_child(panel)
	panel.setup(region_map, bf, system, {CardfrontRulesScript.PLAYER_FACTION: state}, GameConfig.GAME_MODE_CARDFRONT)
	var debug_text: String = panel.get_debug_text()
	_assert.that(debug_text.find("能量：4") >= 0, "economy debug panel: should show current player energy")
	_assert.that(debug_text.find("零件：2") >= 0, "economy debug panel: should show current player parts")
	_assert.that(debug_text.find("+2 能量/s") >= 0, "economy debug panel: should show ENERGY tier 2 output")
	_assert.that(debug_text.find("+1 零件/s") >= 0, "economy debug panel: should show FACTORY tier 1 output")
	_assert.that(debug_text.find("暂不产出") >= 0, "economy debug panel: LAB should be marked as not producing yet")

	TestFixtures.cleanup_node(panel)
	TestFixtures.cleanup_node(system)
	TestFixtures.cleanup_node(bf)


func _test_main_economy_integration() -> void:
	GameConfig.reset_runtime_defaults()
	var scene: PackedScene = load("res://scenes/Main.tscn")
	var main = scene.instantiate()
	get_root().add_child(main)
	await process_frame

	main.selected_game_mode_name = GameConfig.GAME_MODE_BASIC
	main.selected_grid_size = 40
	main._start_game(40, true, false)
	await process_frame
	_assert.eq(main.runtime.economy_system, null, "main integration: old BallWar mode should not create economy_system")
	_assert.eq(main.runtime.economy_debug_panel, null, "main integration: old BallWar mode should not create economy debug panel")
	_assert.that(main.runtime.resource_states.is_empty(), "main integration: old BallWar mode should not create resource states")

	main._cleanup_game_layer()
	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_size = 40
	main._start_game(40, true, false)
	await process_frame
	_assert.that(main.runtime.economy_system != null and is_instance_valid(main.runtime.economy_system), "main integration: Cardfront should create economy_system")
	_assert.that(main.runtime.economy_debug_panel != null and is_instance_valid(main.runtime.economy_debug_panel), "main integration: Cardfront should create economy debug panel")
	_assert.that(main.runtime.economy_debug_panel.visible, "main integration: Cardfront economy debug panel should be visible")
	_assert.that(main.runtime.resource_states.has(CardfrontRulesScript.PLAYER_FACTION), "main integration: Cardfront should create player resource state")
	_assert.that(main.runtime.resource_states.has(CardfrontRulesScript.AI_FACTION), "main integration: Cardfront should create AI resource state")
	_assert.that(main.runtime.economy_debug_panel.get_debug_text().find("能量：0") >= 0, "main integration: economy debug panel should show player energy")
	_assert.that(main.runtime.economy_debug_panel.get_debug_text().find("能源区#") >= 0, "main integration: economy debug panel should list ENERGY regions")

	TestFixtures.cleanup_node(main)
	await _flush()
	GameConfig.reset_runtime_defaults()


func _make_region_map(grid_size: int):
	var region_map := RegionMapScript.new()
	region_map.configure(grid_size)
	region_map.generate_default_layout()
	return region_map


func _make_battlefield(grid_size: int) -> Battlefield:
	var bf := Battlefield.new()
	bf.configure(grid_size)
	get_root().add_child(bf)
	_set_all_neutral(bf, grid_size)
	return bf


func _set_all_neutral(bf: Battlefield, grid_size: int) -> void:
	var owners: Array = []
	for x in range(grid_size):
		var col: Array = []
		for y in range(grid_size):
			col.append(CardfrontRulesScript.NEUTRAL_OWNER)
		owners.append(col)
	bf.replace_owners(owners, false)


func _set_region_owner_percent(bf: Battlefield, region_map, region_id: int, owner_id: int, percent: float) -> void:
	_set_all_neutral(bf, int(region_map.grid_size))
	var owners: Array = bf.owners.duplicate(true)
	_assign_region_owner_percent(owners, region_map.get_region_cells(region_id), owner_id, percent)
	bf.replace_owners(owners, false)


func _assign_region_owner_percent(owners: Array, cells: Array, owner_id: int, percent: float) -> void:
	var owner_count: int = int(ceil(float(cells.size()) * clampf(percent, 0.0, 1.0)))
	for index in range(cells.size()):
		var cell: Vector2i = cells[index]
		if index < owner_count:
			owners[cell.x][cell.y] = owner_id
