extends SceneTree

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const FortifyLayerScript = preload("res://scripts/cardfront/fortify/FortifyLayer.gd")
const CaptureInterceptorScript = preload("res://scripts/cardfront/fortify/CardfrontCaptureInterceptor.gd")
const TerritoryDefenseSystemScript = preload("res://scripts/cardfront/defense/CardfrontTerritoryDefenseSystem.gd")
const RunStateScript = preload("res://scripts/cardfront/run/CardfrontFactionRunState.gd")
const UpgradeManifestScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeManifest.gd")
const UpgradeResolverScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeResolver.gd")
const VolleyResolverScript = preload("res://scripts/cardfront/volley/CardfrontVolleyResolver.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontCardPoolRebalanceTest] Starting v0.3.2b card-pool tests")
	await process_frame

	await _test_frontline_repair_uses_six_different_cells()
	await _test_frontline_repair_does_not_revisit_short_frontline()
	_test_armor_pierce_budget_is_shared_and_limited()
	_test_upgrade_wires_repair_and_pierce_into_state()
	_test_attack_levels_are_capped_and_fractional()

	_assert.report("[CardfrontCardPoolRebalanceTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_frontline_repair_uses_six_different_cells() -> void:
	var battlefield := Battlefield.new()
	battlefield.configure(8, 16)
	get_root().add_child(battlefield)
	await process_frame
	var owners: Array = battlefield.owners.duplicate(true)
	for x in range(8):
		for y in range(8):
			owners[x][y] = RulesScript.NEUTRAL_OWNER
	var frontline_cells: Array[Vector2i] = []
	for x in range(7):
		var cell := Vector2i(x, 3)
		frontline_cells.append(cell)
		owners[cell.x][cell.y] = RulesScript.PLAYER_FACTION
	battlefield.replace_owners(owners, false)

	var fortify = FortifyLayerScript.new()
	fortify.configure(8)
	var system = TerritoryDefenseSystemScript.new()
	system.battlefield = battlefield
	system.fortify_layer = fortify
	system.owner_caps = {RulesScript.PLAYER_FACTION: 2}
	var restored: int = system.repair_owner(RulesScript.PLAYER_FACTION, 6, "frontline")
	var total_defense: int = 0
	var repaired_cells: int = 0
	for cell in frontline_cells:
		var defense: int = fortify.get_fortify_stack(cell)
		total_defense += defense
		if defense > 0:
			repaired_cells += 1
		_assert.that(defense <= 1, "repair: one card must add at most one layer to each cell")

	_assert.eq(restored, 6, "repair: six available points should restore six different cells")
	_assert.eq(total_defense, 6, "repair: total restored defense should equal the six-point budget")
	_assert.eq(repaired_cells, 6, "repair: exactly six different frontline cells should be selected")
	_assert.eq(fortify.get_fortify_stack(Vector2i(7, 7)), 0, "repair: neutral map cells must not be repaired")
	system.free()
	TestFixtures.cleanup_node(battlefield)
	await process_frame
	await process_frame


func _test_frontline_repair_does_not_revisit_short_frontline() -> void:
	var battlefield := Battlefield.new()
	battlefield.configure(5, 16)
	get_root().add_child(battlefield)
	await process_frame
	var owners: Array = battlefield.owners.duplicate(true)
	for x in range(5):
		for y in range(5):
			owners[x][y] = RulesScript.NEUTRAL_OWNER
	var frontline_cells: Array[Vector2i] = [Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2)]
	for cell in frontline_cells:
		owners[cell.x][cell.y] = RulesScript.PLAYER_FACTION
	battlefield.replace_owners(owners, false)

	var fortify = FortifyLayerScript.new()
	fortify.configure(5)
	var system = TerritoryDefenseSystemScript.new()
	system.battlefield = battlefield
	system.fortify_layer = fortify
	system.owner_caps = {RulesScript.PLAYER_FACTION: 2}
	var restored: int = system.repair_owner(RulesScript.PLAYER_FACTION, 6, "frontline")

	_assert.eq(restored, 3, "repair: a six-point card should restore only three points when only three cells are eligible")
	for cell in frontline_cells:
		_assert.eq(fortify.get_fortify_stack(cell), 1, "repair: the card must not revisit a cell during the same resolution")
	system.free()
	TestFixtures.cleanup_node(battlefield)
	await process_frame
	await process_frame


func _test_armor_pierce_budget_is_shared_and_limited() -> void:
	var fortify = FortifyLayerScript.new()
	fortify.configure(8)
	var interceptor = CaptureInterceptorScript.new()
	interceptor.setup(fortify)
	var context: Dictionary = {"armor_pierce_contacts_remaining": 6}
	for index in range(6):
		var cell := Vector2i(index, 0)
		fortify.set_fortify_stack(cell, 1)
		_assert.that(
			not interceptor.should_block_capture(cell, RulesScript.PLAYER_FACTION, RulesScript.AI_FACTION, context),
			"pierce: each of the first six contacts should bypass one defense layer"
		)
	var seventh := Vector2i(6, 0)
	fortify.set_fortify_stack(seventh, 1)
	_assert.that(
		interceptor.should_block_capture(seventh, RulesScript.PLAYER_FACTION, RulesScript.AI_FACTION, context),
		"pierce: the seventh defended contact should block normally"
	)
	_assert.eq(int(context.armor_pierce_contacts_remaining), 0, "pierce: shared volley budget should be exhausted after six contacts")


func _test_upgrade_wires_repair_and_pierce_into_state() -> void:
	var state = RunStateScript.new()
	state.setup(RulesScript.PLAYER_FACTION)
	var resolver = UpgradeResolverScript.new()
	resolver.resolve(state, UpgradeManifestScript.UPGRADE_FRONTLINE_REPAIR)
	resolver.resolve(state, UpgradeManifestScript.UPGRADE_ARMOR_PIERCING)
	var plan = VolleyResolverScript.new().build_and_consume(state)
	var repair_request: Dictionary = state.consume_pending_repair()

	_assert.eq(int(repair_request.points), 6, "content: repair card should request six finite points")
	_assert.eq(str(repair_request.zone), "frontline", "content: first-generation repair should target the frontline")
	_assert.eq(plan.armor_pierce_contacts, 6, "content: armor-piercing card should arm six contacts")
	_assert.eq(VolleyResolverScript.new().build_and_consume(state).armor_pierce_contacts, 0, "content: armor piercing should last one volley")


func _test_attack_levels_are_capped_and_fractional() -> void:
	var state = RunStateScript.new()
	state.setup(RulesScript.PLAYER_FACTION)
	for _index in range(6):
		state.increase_attack_level(1)
	var plan = VolleyResolverScript.new().build_and_consume(state)
	var turret := Turret.new()
	turret.health = 20
	turret.max_health = 20
	for _index in range(4):
		turret.take_damage_quarters(plan.chamber_damage_quarters)

	_assert.eq(state.attack_level, RunStateScript.MAX_ATTACK_LEVEL, "attack: permanent level should cap at three")
	_assert.eq(plan.chamber_damage_quarters, 7, "attack: level three should deal 175 percent damage")
	_assert.eq(turret.health, 13, "attack: four level-three hits should deal seven chamber health")
	turret.free()
