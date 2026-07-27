extends SceneTree
const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const HeroRegistryScript = preload("res://scripts/cardfront/heroes/CardfrontHeroRegistry.gd")
const RunStateScript = preload("res://scripts/cardfront/run/CardfrontFactionRunState.gd")
const VolleyResolverScript = preload("res://scripts/cardfront/volley/CardfrontVolleyResolver.gd")
const ProjectileTypeScript = preload("res://scripts/cardfront/volley/CardfrontProjectileType.gd")
const FortifyLayerScript = preload("res://scripts/cardfront/fortify/FortifyLayer.gd")
const CaptureInterceptorScript = preload("res://scripts/cardfront/fortify/CardfrontCaptureInterceptor.gd")
class MockRoundDirector:
	extends RefCounted
	var states: Dictionary = {}
	func get_run_state(owner_id: int): return states.get(owner_id, null)
class MockDefenseSystem:
	extends RefCounted
	var battlefield = null
var _assert: TestAssert
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	_assert = TestAssert.new()
	await process_frame
	_test_mixes()
	_test_cards()
	_test_chamber_and_visuals()
	_test_defense()
	_test_engineer_passives()
	_assert.report("[CardfrontProjectileTypeCombatTest]")
	quit(0 if _assert.failures.is_empty() else 1)
func _test_mixes() -> void:
	var resolver = VolleyResolverScript.new()
	var ep = resolver.build_and_consume(_state(HeroRegistryScript.HERO_FORTIFICATION_ENGINEER))
	var bp = resolver.build_and_consume(_state(HeroRegistryScript.HERO_BALANCED_COMMANDER))
	var gp = resolver.build_and_consume(_state(HeroRegistryScript.HERO_RAPID_GUNNER))
	_assert.eq(ep.projectile_counts[ProjectileTypeScript.STANDARD], 4, "Engineer standard")
	_assert.eq(ep.projectile_counts[ProjectileTypeScript.SIEGE], 1, "Engineer siege")
	_assert.eq(bp.projectile_counts[ProjectileTypeScript.STANDARD], 6, "Balanced standard")
	_assert.eq(gp.projectile_counts[ProjectileTypeScript.SUPPRESSION], 1, "Gunner suppression")
	_assert.eq(ProjectileTypeScript.direct_damage_units_for_sequence(ep.projectile_sequence), 6.0, "Engineer direct budget")
	_assert.eq(ProjectileTypeScript.direct_damage_units_for_sequence(gp.projectile_sequence), 6.0, "Gunner direct budget")
	_assert.eq(ProjectileTypeScript.territory_pressure_units(ProjectileTypeScript.SUPPRESSION), 1.0, "suppression uses one visible territory contact")
	_assert.eq(ProjectileTypeScript.territory_pressure_units(ProjectileTypeScript.SIEGE), 1.0, "siege uses one visible territory contact")
func _test_cards() -> void:
	var resolver = VolleyResolverScript.new()
	var engineer = _state(HeroRegistryScript.HERO_FORTIFICATION_ENGINEER)
	engineer.add_next_volley_bonus(5)
	var plus = resolver.build_and_consume(engineer)
	_assert.eq(plus.projectile_counts[ProjectileTypeScript.STANDARD], 9, "+5 all standard")
	_assert.eq(plus.projectile_counts[ProjectileTypeScript.SIEGE], 1, "+5 no siege")
	var gunner = _state(HeroRegistryScript.HERO_RAPID_GUNNER)
	gunner.multiply_next_volley(2)
	var doubled = resolver.build_and_consume(gunner)
	_assert.eq(doubled.projectile_counts[ProjectileTypeScript.SUPPRESSION], 2, "x2 duplicates group")
func _test_chamber_and_visuals() -> void:
	var target = Turret.new()
	target.faction_id = RulesScript.AI_FACTION
	target.configure_health_pool(20, true)
	target.global_position = Vector2.ZERO
	get_root().add_child(target)
	var standard = _bullet(ProjectileTypeScript.STANDARD, target)
	var siege = _bullet(ProjectileTypeScript.SIEGE, target)
	var suppression = _bullet(ProjectileTypeScript.SUPPRESSION, target)
	standard._try_hit_enemy_turret(); _assert.eq(target.health, 19, "standard damage")
	siege._try_hit_enemy_turret(); _assert.eq(target.health, 17, "siege double damage")
	suppression._try_hit_enemy_turret(); _assert.eq(target.health, 17, "suppression zero damage")
	_assert.neq(standard.get_projectile_visual_signature()["fill"], siege.get_projectile_visual_signature()["fill"], "siege visible")
	_assert.neq(standard.get_projectile_visual_signature()["fill"], suppression.get_projectile_visual_signature()["fill"], "suppression visible")
	for node in [standard, siege, suppression, target]: TestFixtures.cleanup_node(node)
func _test_defense() -> void:
	var layer = FortifyLayerScript.new(); layer.configure(4)
	var interceptor = CaptureInterceptorScript.new(); interceptor.setup(layer)
	var cell := Vector2i(1, 1)
	layer.set_fortify_stack(cell, 1)
	_assert.that(not interceptor.should_block_capture(cell, 1, 2, {"projectile_defense_pierce_remaining": 1}), "siege through one")
	layer.set_fortify_stack(cell, 2)
	_assert.that(interceptor.should_block_capture(cell, 1, 2, {"projectile_defense_pierce_remaining": 1}), "siege blocked by two")
	_assert.eq(layer.get_fortify_stack(cell), 0, "siege consumes two")
	layer.set_fortify_stack(cell, 1)
	_assert.that(interceptor.should_block_capture(cell, 1, 2, {}), "suppression normal defense")
func _test_engineer_passives() -> void:
	var battlefield = Battlefield.new(); battlefield.configure(4); get_root().add_child(battlefield)
	var owners: Array = []
	for x in range(4):
		var col: Array = []
		for y in range(4): col.append(RulesScript.NEUTRAL_OWNER)
		owners.append(col)
	owners[1][1] = RulesScript.AI_FACTION; owners[1][2] = RulesScript.PLAYER_FACTION
	battlefield.replace_owners(owners, false)
	var layer = FortifyLayerScript.new(); layer.configure(4)
	var interceptor = CaptureInterceptorScript.new(); interceptor.setup(layer)
	var director = MockRoundDirector.new(); director.states[RulesScript.PLAYER_FACTION] = _state(HeroRegistryScript.HERO_FORTIFICATION_ENGINEER); director.states[RulesScript.AI_FACTION] = _state(HeroRegistryScript.HERO_BALANCED_COMMANDER)
	var defense = MockDefenseSystem.new(); defense.battlefield = battlefield
	interceptor.configure_runtime(director, defense); battlefield.capture_interceptor = interceptor
	_assert.eq(battlefield.apply_bullet(Vector2i(1, 1), RulesScript.PLAYER_FACTION, {}), "HIT_ENEMY_CELL", "capture")
	_assert.eq(layer.get_fortify_stack(Vector2i(1, 1)), 1, "captured front defense")
	var engineer = director.states[RulesScript.PLAYER_FACTION]; engineer.request_territory_repair(6, "frontline")
	_assert.eq(engineer.consume_pending_repair()["points"], 8, "Engineer repair +2")
	TestFixtures.cleanup_node(battlefield)
func _state(hero_id: String):
	var state = RunStateScript.new(); state.setup_from_hero(RulesScript.PLAYER_FACTION, hero_id); return state
func _bullet(projectile_type: String, target):
	var bullet = Bullet.new(); bullet.setup(RulesScript.PLAYER_FACTION, Vector2.ZERO, Vector2.RIGHT, null, {RulesScript.AI_FACTION: target}, 1, 4, {"projectile_type": projectile_type}); get_root().add_child(bullet); return bullet
