extends SceneTree

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const ManifestScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeManifest.gd")
const ResolverScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeResolver.gd")
const DraftSystemScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeDraftSystem.gd")
const RunStateScript = preload("res://scripts/cardfront/run/CardfrontFactionRunState.gd")
const VolleyResolverScript = preload("res://scripts/cardfront/volley/CardfrontVolleyResolver.gd")
const ProjectileTypeScript = preload("res://scripts/cardfront/volley/CardfrontProjectileType.gd")
const FortifyLayerScript = preload("res://scripts/cardfront/fortify/FortifyLayer.gd")
const RuntimeScript = preload("res://scripts/cardfront/entities/CardfrontBattlefieldEntityLiveRuntime.gd")
const MapRegistryScript = preload("res://scripts/cardfront/maps/CardfrontMapRegistry.gd")


class MockDefenseSystem:
	extends Node
	var battlefield = null
	var fortify_layer = null
	func get_owner_cap(_owner_id: int) -> int:
		return 2
	func get_cell_defense(cell: Vector2i) -> int:
		return fortify_layer.get_fortify_stack(cell)


var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	await process_frame
	var fixture: Dictionary = _make_fixture()
	_test_entity_cards(fixture)
	_test_building_volley(fixture)
	_test_heavy_charge(fixture)
	_test_map_route_slots(fixture)
	_assert.report("[CardfrontEntityCardRuntimeTest]")
	TestFixtures.cleanup_node(fixture["battlefield"])
	quit(0 if _assert.failures.is_empty() else 1)


func _make_fixture() -> Dictionary:
	var battlefield = Battlefield.new()
	battlefield.configure(10)
	get_root().add_child(battlefield)
	var owners: Array = []
	for x in range(10):
		var column: Array = []
		for y in range(10):
			column.append(RulesScript.AI_FACTION if y < 5 else RulesScript.PLAYER_FACTION)
		owners.append(column)
	battlefield.replace_owners(owners, false)
	var fortify = FortifyLayerScript.new()
	fortify.configure(10)
	var defense = MockDefenseSystem.new()
	defense.battlefield = battlefield
	defense.fortify_layer = fortify
	get_root().add_child(defense)
	var runtime = RuntimeScript.new()
	battlefield.add_child(runtime)
	_assert.that(runtime.setup(battlefield), "entity cards: runtime setup")
	runtime.territory_defense_system = defense
	return {"battlefield": battlefield, "fortify": fortify, "runtime": runtime}


func _test_entity_cards(fixture: Dictionary) -> void:
	var runtime = fixture["runtime"]
	var resolver = ResolverScript.new()
	var state = RunStateScript.new()
	state.setup(RulesScript.PLAYER_FACTION)

	resolver.resolve(state, ManifestScript.UPGRADE_REPAIR_UNITS)
	var repair_results: Array = runtime.apply_pending_upgrade_actions(RulesScript.PLAYER_FACTION, state)
	_assert.eq(int((repair_results[0] as Dictionary).get("spawned", 0)), 2, "repair units: card summons two units")
	_assert.eq(state.owned_creature_count, 2, "repair units: run state receives live creature count")

	for expected_level in range(1, 4):
		resolver.resolve(state, ManifestScript.UPGRADE_FIRE_CONTROL_BEACON)
		runtime.apply_pending_upgrade_actions(RulesScript.PLAYER_FACTION, state)
		_assert.eq(state.get_tower_level(RuntimeScript.TOWER_FIRE_CONTROL_BEACON), expected_level, "fire-control beacon: repeated picks upgrade one tower")
	var beacon = runtime._find_owner_tower(RulesScript.PLAYER_FACTION, RuntimeScript.TOWER_FIRE_CONTROL_BEACON)
	_assert.eq(beacon.guidance_capacity, 10, "fire-control beacon: level three guides ten shots")
	for _round_index in range(3):
		runtime.advance_round()
	_assert.that(runtime._has_owner_creature_id(RulesScript.PLAYER_FACTION, RuntimeScript.CREATURE_SCOUT_UNIT), "fire-control beacon: level three maintains a scout")
	var creature_count_with_scout: int = runtime.registry.count_owner_entities(RulesScript.PLAYER_FACTION, "creature")
	for _round_index in range(2):
		runtime.advance_round()
	_assert.eq(runtime.registry.count_owner_entities(RulesScript.PLAYER_FACTION, "creature"), creature_count_with_scout, "fire-control beacon: scout respawn does not create duplicates")

	for expected_level in range(1, 4):
		resolver.resolve(state, ManifestScript.UPGRADE_INTERCEPTOR_TOWER)
		runtime.apply_pending_upgrade_actions(RulesScript.PLAYER_FACTION, state)
		_assert.eq(state.get_tower_level(RuntimeScript.TOWER_INTERCEPTOR), expected_level, "interceptor tower: repeated picks upgrade one tower")
	var interceptor = runtime._find_owner_tower(RulesScript.PLAYER_FACTION, RuntimeScript.TOWER_INTERCEPTOR)
	_assert.eq(interceptor.intercept_capacity, 3, "interceptor tower: level three intercepts three standard shots")
	_assert.eq(state.owned_defense_tower_count, 2, "tower cards: both route slots are occupied")


func _test_building_volley(fixture: Dictionary) -> void:
	var runtime = fixture["runtime"]
	var resolver = ResolverScript.new()
	var state = RunStateScript.new()
	state.setup(RulesScript.PLAYER_FACTION)
	runtime.sync_run_state_entity_summary(state)
	var definition: Dictionary = ManifestScript.get_definition(ManifestScript.UPGRADE_BUILDING_VOLLEY)
	_assert.that(DraftSystemScript.new().is_upgrade_eligible(definition, state), "building volley: requires at least one live tower")
	resolver.resolve(state, ManifestScript.UPGRADE_BUILDING_VOLLEY)
	var plan = VolleyResolverScript.new().build_and_consume(state)
	runtime.decorate_volley_plan(RulesScript.PLAYER_FACTION, plan)
	_assert.eq(plan.building_sources.size(), 2, "building volley: both powered towers become independent sources")
	_assert.eq(plan.building_shot_count, 8, "building volley: level one adds four shots per powered tower")
	_assert.eq(plan.shot_count, state.base_volley_count, "building volley: command chamber volley is not multiplied")

	var first_tower = runtime._owner_towers(RulesScript.PLAYER_FACTION)[0]
	first_tower.powered = false
	runtime.decorate_volley_plan(RulesScript.PLAYER_FACTION, plan)
	_assert.eq(plan.building_shot_count, 4, "building volley: unpowered towers do not fire")


func _test_heavy_charge(fixture: Dictionary) -> void:
	var runtime = fixture["runtime"]
	var fortify = fixture["fortify"]
	var resolver = ResolverScript.new()
	var state = RunStateScript.new()
	state.setup(RulesScript.PLAYER_FACTION)
	var enemy_tower_result: Dictionary = runtime.build_or_upgrade_tower(
		RulesScript.AI_FACTION,
		RuntimeScript.TOWER_FIRE_CONTROL_BEACON
	)
	_assert.that(bool(enemy_tower_result.get("success", false)), "heavy charge: enemy tower fixture builds")
	var enemy_tower = runtime._find_owner_tower(RulesScript.AI_FACTION, RuntimeScript.TOWER_FIRE_CONTROL_BEACON)
	var adjacent_cell: Vector2i = enemy_tower.cell + Vector2i.RIGHT
	var splash_target = runtime.registry.spawn_creature(
		"heavy_splash_target",
		"fixture",
		RulesScript.AI_FACTION,
		adjacent_cell,
		2
	)
	fortify.set_fortify_stack(enemy_tower.cell, 2)
	fortify.set_fortify_stack(adjacent_cell, 1)
	resolver.resolve(state, ManifestScript.UPGRADE_HEAVY_CHARGE)
	var plan = VolleyResolverScript.new().build_and_consume(state)
	var pool: Dictionary = {"remaining": 1, "spec": plan.heavy_charge_spec}
	var result: Dictionary = runtime.resolve_capture_contact(
		enemy_tower.cell,
		RulesScript.PLAYER_FACTION,
		{
			"projectile_type": ProjectileTypeScript.STANDARD,
			"projectile_direction": Vector2.UP,
			"heavy_charge_pool": pool,
		}
	)
	_assert.eq(enemy_tower.hp, enemy_tower.max_hp - 3, "heavy charge: normal hit plus two center damage")
	_assert.eq(splash_target.hp, 0, "heavy charge: nearby enemy entity takes two splash damage")
	_assert.eq(fortify.get_fortify_stack(adjacent_cell), 0, "heavy charge: nearby enemy defense loses one layer")
	_assert.eq(int(pool.get("remaining", -1)), 0, "heavy charge: first enemy tower contact consumes the shared charge")
	_assert.that(result.has("heavy_charge"), "heavy charge: contact result reports explosion details")
	runtime.resolve_capture_contact(
		enemy_tower.cell,
		RulesScript.PLAYER_FACTION,
		{
			"projectile_type": ProjectileTypeScript.STANDARD,
			"projectile_direction": Vector2.UP,
			"heavy_charge_pool": pool,
		}
	)
	_assert.eq(enemy_tower.hp, enemy_tower.max_hp - 4, "heavy charge: later contacts deal only normal projectile damage")


func _test_map_route_slots(fixture: Dictionary) -> void:
	var runtime = fixture["runtime"]
	var battlefield = fixture["battlefield"]
	var definition: Dictionary = MapRegistryScript.get_map_definition(
		MapRegistryScript.CROSS_RESOURCE_MAP_ID,
		int(battlefield.grid_size)
	)
	runtime.configure_map_definition(definition)
	var lanes: Array = (definition.get("route_layout", {}) as Dictionary).get("lanes", []) as Array
	var expected_x: int = roundi(
		float(int(battlefield.grid_size) - 1)
		* float((lanes[0] as Dictionary).get("center_ratio", 0.5))
	)
	var slot: Dictionary = runtime.registry.building_slots.get(
		runtime._route_slot_id(RulesScript.PLAYER_FACTION, 0),
		{}
	) as Dictionary
	_assert.eq((slot.get("cell", Vector2i.ZERO) as Vector2i).x, expected_x, "entity cards: tower slots follow the selected map route definition")
