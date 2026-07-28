extends SceneTree

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const ProjectileTypeScript = preload("res://scripts/cardfront/volley/CardfrontProjectileType.gd")
const FortifyLayerScript = preload("res://scripts/cardfront/fortify/FortifyLayer.gd")
const RuntimeScript = preload("res://scripts/cardfront/entities/CardfrontBattlefieldEntityLiveRuntime.gd")
const CreatureStateScript = preload("res://scripts/cardfront/entities/CardfrontCreatureState.gd")

const WATCHDOG_SECONDS: float = 12.0

class MockDefenseSystem:
	extends Node
	var battlefield = null
	var fortify_layer = null
	var caps: Dictionary = {}
	func get_owner_cap(owner_id: int) -> int:
		return int(caps.get(owner_id, 1))
	func get_cell_defense(cell: Vector2i) -> int:
		return fortify_layer.get_fortify_stack(cell)

class MockBullet:
	extends Node2D
	var faction_id: int = RulesScript.PLAYER_FACTION
	var projectile_type: String = ProjectileTypeScript.STANDARD
	var direction: Vector2 = Vector2(0.2, -1.0).normalized()
	var capture_context: Dictionary = {}
	var is_active: bool = true

var _assert: TestAssert
var _finished: bool = false
var _watchdog_timer: Timer


func _initialize() -> void:
	call_deferred("_run")
	_watchdog_timer = Timer.new()
	_watchdog_timer.one_shot = true
	_watchdog_timer.wait_time = WATCHDOG_SECONDS
	_watchdog_timer.autostart = true
	_watchdog_timer.timeout.connect(_on_watchdog_timeout)
	get_root().add_child(_watchdog_timer)


func _on_watchdog_timeout() -> void:
	if _finished:
		return
	push_error("[CardfrontBattlefieldEntityRuntimeTest] WATCHDOG: test did not finish")
	quit(2)


func _run() -> void:
	_assert = TestAssert.new()
	await process_frame
	print("[CardfrontBattlefieldEntityRuntimeTest] fixture")
	var fixture: Dictionary = _make_fixture()
	print("[CardfrontBattlefieldEntityRuntimeTest] prototypes")
	_test_debug_prototypes(fixture)
	print("[CardfrontBattlefieldEntityRuntimeTest] contacts")
	_test_projectile_contacts(fixture)
	print("[CardfrontBattlefieldEntityRuntimeTest] repair")
	_test_repair_action(fixture)
	print("[CardfrontBattlefieldEntityRuntimeTest] expiry")
	_test_expiry_signal(fixture)
	print("[CardfrontBattlefieldEntityRuntimeTest] tower")
	_test_tower_power_and_guidance(fixture)
	print("[CardfrontBattlefieldEntityRuntimeTest] report")
	_assert.report("[CardfrontBattlefieldEntityRuntimeTest]")
	_finished = true
	var battlefield = fixture["battlefield"]
	TestFixtures.cleanup_node(battlefield)
	TestFixtures.cleanup_node(fixture["defense"])
	_watchdog_timer.stop()
	TestFixtures.cleanup_node(_watchdog_timer)
	quit(0 if _assert.failures.is_empty() else 1)


func _make_fixture() -> Dictionary:
	var battlefield = Battlefield.new()
	battlefield.configure(8)
	get_root().add_child(battlefield)
	var owners: Array = []
	for x in range(8):
		var col: Array = []
		for y in range(8):
			var owner: int = RulesScript.NEUTRAL_OWNER
			if y <= 2:
				owner = RulesScript.AI_FACTION
			elif y >= 4:
				owner = RulesScript.PLAYER_FACTION
			col.append(owner)
		owners.append(col)
	battlefield.replace_owners(owners, false)

	var fortify = FortifyLayerScript.new()
	fortify.configure(8)
	var defense = MockDefenseSystem.new()
	defense.battlefield = battlefield
	defense.fortify_layer = fortify
	defense.caps = {
		RulesScript.PLAYER_FACTION: 2,
		RulesScript.AI_FACTION: 1,
	}
	get_root().add_child(defense)

	var runtime = RuntimeScript.new()
	battlefield.add_child(runtime)
	_assert.that(runtime.setup(battlefield), "runtime setup")
	runtime.territory_defense_system = defense
	return {
		"battlefield": battlefield,
		"fortify": fortify,
		"defense": defense,
		"runtime": runtime,
	}


func _test_debug_prototypes(fixture: Dictionary) -> void:
	var runtime = fixture["runtime"]
	var repair_units: Array = runtime.debug_spawn_repair_units(RulesScript.PLAYER_FACTION, 2)
	_assert.eq(repair_units.size(), 2, "debug repair prototype spawns two units")
	_assert.eq(runtime.registry.count_owner_entities(RulesScript.PLAYER_FACTION, "creature"), 2, "repair units enter registry")
	var beacon = runtime.debug_spawn_fire_control_beacon(RulesScript.PLAYER_FACTION, 0)
	_assert.that(beacon != null, "debug fire-control beacon spawns")
	_assert.eq(beacon.hp, 5, "fire-control beacon starts at five structure")
	_assert.eq(beacon.guidance_capacity, 6, "level-one beacon guides six standard shots")
	_assert.eq(runtime.registry.count_owner_entities(RulesScript.PLAYER_FACTION, "defense_tower"), 1, "beacon occupies tower slot")


func _test_projectile_contacts(fixture: Dictionary) -> void:
	var runtime = fixture["runtime"]
	var cell := Vector2i(5, 4)
	var normal = runtime.registry.spawn_creature(
		"contact_normal",
		"fixture_normal",
		RulesScript.AI_FACTION,
		cell,
		3,
		CreatureStateScript.ARMOR_NORMAL
	)
	var standard_context: Dictionary = {
		"projectile_type": ProjectileTypeScript.STANDARD,
		"projectile_direction": Vector2.RIGHT,
	}
	var standard: Dictionary = runtime.resolve_capture_contact(cell, RulesScript.PLAYER_FACTION, standard_context)
	_assert.eq(standard.get("damage_applied", 0), 1, "standard damages normal creature")
	_assert.that(bool(standard.get("bounce_projectile", false)), "standard bounces from creature")
	_assert.that(not bool(standard.get("consume_projectile", true)), "standard remains after bounce")

	var armored = runtime.registry.spawn_creature(
		"contact_armored",
		"fixture_armored",
		RulesScript.AI_FACTION,
		Vector2i(6, 4),
		4,
		CreatureStateScript.ARMOR_ARMORED
	)
	var siege: Dictionary = runtime.resolve_capture_contact(Vector2i(6, 4), RulesScript.PLAYER_FACTION, {
		"projectile_type": ProjectileTypeScript.SIEGE,
		"projectile_direction": Vector2.RIGHT,
	})
	_assert.eq(siege.get("damage_applied", 0), 2, "siege deals two to armored creature")
	_assert.that(bool(siege.get("consume_projectile", false)), "siege is consumed by entity")

	var before_cell: Vector2i = armored.cell
	var suppression: Dictionary = runtime.resolve_capture_contact(Vector2i(6, 4), RulesScript.PLAYER_FACTION, {
		"projectile_type": ProjectileTypeScript.SUPPRESSION,
		"projectile_direction": Vector2.LEFT,
	})
	_assert.eq(suppression.get("damage_applied", 0), 0, "suppression deals no creature damage")
	_assert.eq(armored.get_status_rounds("stunned"), 1, "suppression stuns for one round")
	_assert.that(armored.cell != before_cell or not bool(suppression.get("pushed", false)), "suppression push result is consistent")
	_assert.that(normal != null, "normal contact fixture remains valid")


func _test_repair_action(fixture: Dictionary) -> void:
	var runtime = fixture["runtime"]
	var fortify = fixture["fortify"]
	var target := Vector2i(2, 4)
	fortify.set_fortify_stack(target, 0)
	var before: int = fortify.get_fortify_stack(target)
	runtime.advance_round()
	var after: int = fortify.get_fortify_stack(target)
	_assert.that(after >= before, "repair unit never reduces defense")
	_assert.gte(after, 1, "repair unit restores a nearby frontline layer")


func _test_expiry_signal(fixture: Dictionary) -> void:
	var runtime = fixture["runtime"]
	var expiring = runtime.registry.spawn_creature(
		"expiring_unit",
		"repair_unit",
		RulesScript.PLAYER_FACTION,
		Vector2i(1, 5),
		1,
		CreatureStateScript.ARMOR_NORMAL,
		1,
		"repair",
		1
	)
	var removed_ids: Array = []
	runtime.entity_removed.connect(
		func(entity_id, _kind, _owner_id, _cell): removed_ids.append(str(entity_id))
	)
	runtime.advance_round()
	_assert.that(
		removed_ids.has(expiring.entity_id),
		"expired creature emits entity_removed for death presentation"
	)


func _test_tower_power_and_guidance(fixture: Dictionary) -> void:
	var battlefield = fixture["battlefield"]
	var runtime = fixture["runtime"]
	var beacon = null
	for entity in runtime.registry.entities_by_id.values():
		if str(entity.get("tower_id")) == RuntimeScript.TOWER_FIRE_CONTROL_BEACON:
			beacon = entity
			break
	_assert.that(beacon != null, "guidance beacon fixture exists")
	if beacon == null:
		return

	var bullet = MockBullet.new()
	battlefield.add_child(bullet)
	var guidance_cell := Vector2i(mini(7, beacon.cell.x + 2), beacon.cell.y)
	bullet.global_position = battlefield.to_global((Vector2(guidance_cell) + Vector2(0.5, 0.5)) * float(battlefield.cell_size))
	var before_direction: Vector2 = bullet.direction
	var before_guidance: int = beacon.guidance_remaining
	runtime._apply_fire_control_guidance(bullet)
	_assert.eq(beacon.guidance_remaining, before_guidance - 1, "beacon consumes one guidance charge")
	_assert.neq(bullet.direction, before_direction, "beacon visibly adjusts standard trajectory")

	battlefield.owners[beacon.cell.x][beacon.cell.y] = RulesScript.NEUTRAL_OWNER
	runtime.advance_round()
	_assert.that(not beacon.powered, "tower loses power on neutral ground")
	var hp_before_enemy_hold: int = beacon.hp
	battlefield.owners[beacon.cell.x][beacon.cell.y] = RulesScript.AI_FACTION
	runtime.advance_round()
	_assert.eq(beacon.hp, hp_before_enemy_hold - 1, "enemy-held tower cell deals one structure damage per round")
	TestFixtures.cleanup_node(bullet)
