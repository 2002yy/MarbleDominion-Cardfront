extends SceneTree

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const DeploymentQueryScript = preload("res://scripts/cardfront/deployment/DeploymentQuery.gd")
const DeploymentRulesScript = preload("res://scripts/cardfront/deployment/DeploymentRules.gd")
const DeploymentRuleTypeScript = preload("res://scripts/cardfront/deployment/DeploymentRuleType.gd")
const RegionMapScript = preload("res://scripts/cardfront/regions/RegionMap.gd")
const RegionTypeScript = preload("res://scripts/cardfront/regions/RegionType.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[DeploymentRulesTest] Starting Cardfront deployment rule tests")
	await process_frame

	_test_owned_cell()
	_test_owned_border()
	_test_region_control_thresholds()
	_test_invalid_inputs()
	_test_evaluate_is_read_only()
	await _flush()

	_assert.report("[DeploymentRulesTest]")
	if _assert.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _flush() -> void:
	await process_frame
	await process_frame


func _test_owned_cell() -> void:
	var fixture: Dictionary = _make_fixture()
	var bf: Battlefield = fixture.battlefield
	var owned_cell := Vector2i(5, 5)
	var neutral_cell := Vector2i(6, 5)
	var enemy_cell := Vector2i(7, 5)
	_set_owner(bf, owned_cell, CardfrontRulesScript.PLAYER_FACTION)
	_set_owner(bf, enemy_cell, CardfrontRulesScript.AI_FACTION)

	var owned_result = DeploymentRulesScript.evaluate(fixture.region_map, bf, _make_query(CardfrontRulesScript.PLAYER_FACTION, owned_cell, DeploymentRuleTypeScript.OWNED_CELL))
	var neutral_result = DeploymentRulesScript.evaluate(fixture.region_map, bf, _make_query(CardfrontRulesScript.PLAYER_FACTION, neutral_cell, DeploymentRuleTypeScript.OWNED_CELL))
	var enemy_result = DeploymentRulesScript.evaluate(fixture.region_map, bf, _make_query(CardfrontRulesScript.PLAYER_FACTION, enemy_cell, DeploymentRuleTypeScript.OWNED_CELL))

	_assert.that(owned_result.allowed, "owned cell: player-owned cell should be deployable")
	_assert.eq(owned_result.reason, DeploymentRulesScript.REASON_ALLOWED, "owned cell: allowed result should use allowed reason")
	_assert.that(not neutral_result.allowed, "owned cell: neutral cell should not be deployable")
	_assert.eq(neutral_result.reason, DeploymentRulesScript.REASON_NOT_OWNED_CELL, "owned cell: neutral cell should fail as not owned")
	_assert.that(not enemy_result.allowed, "owned cell: enemy cell should not be deployable")
	_assert.eq(enemy_result.reason, DeploymentRulesScript.REASON_NOT_OWNED_CELL, "owned cell: enemy cell should fail as not owned")
	_cleanup_fixture(fixture)


func _test_owned_border() -> void:
	var fixture: Dictionary = _make_fixture()
	var bf: Battlefield = fixture.battlefield
	var border_cell := Vector2i(20, 20)
	var internal_cell := Vector2i(10, 10)
	var neutral_cell := Vector2i(21, 20)
	var enemy_cell := Vector2i(22, 20)

	_set_owner(bf, border_cell, CardfrontRulesScript.PLAYER_FACTION)
	_set_owner(bf, enemy_cell, CardfrontRulesScript.AI_FACTION)
	_set_owned_block(bf, internal_cell, 1, CardfrontRulesScript.PLAYER_FACTION)

	var border_result = DeploymentRulesScript.evaluate(fixture.region_map, bf, _make_query(CardfrontRulesScript.PLAYER_FACTION, border_cell, DeploymentRuleTypeScript.OWNED_BORDER))
	var internal_result = DeploymentRulesScript.evaluate(fixture.region_map, bf, _make_query(CardfrontRulesScript.PLAYER_FACTION, internal_cell, DeploymentRuleTypeScript.OWNED_BORDER))
	var neutral_result = DeploymentRulesScript.evaluate(fixture.region_map, bf, _make_query(CardfrontRulesScript.PLAYER_FACTION, neutral_cell, DeploymentRuleTypeScript.OWNED_BORDER))
	var enemy_result = DeploymentRulesScript.evaluate(fixture.region_map, bf, _make_query(CardfrontRulesScript.PLAYER_FACTION, enemy_cell, DeploymentRuleTypeScript.OWNED_BORDER))

	_assert.that(border_result.allowed, "owned border: owned cell touching neutral area should be deployable")
	_assert.that(not internal_result.allowed, "owned border: fully surrounded owned cell should not be a border")
	_assert.eq(internal_result.reason, DeploymentRulesScript.REASON_NOT_OWNED_BORDER, "owned border: internal owned cell should fail as not border")
	_assert.that(not neutral_result.allowed, "owned border: neutral cell should not be deployable")
	_assert.eq(neutral_result.reason, DeploymentRulesScript.REASON_NOT_OWNED_CELL, "owned border: neutral cell should fail as not owned")
	_assert.that(not enemy_result.allowed, "owned border: enemy cell should not be deployable")
	_assert.eq(enemy_result.reason, DeploymentRulesScript.REASON_NOT_OWNED_CELL, "owned border: enemy cell should fail as not owned")
	_cleanup_fixture(fixture)


func _test_region_control_thresholds() -> void:
	var fixture: Dictionary = _make_fixture()
	var region_id: int = int(fixture.region_map.get_region_ids_by_type(RegionTypeScript.ENERGY)[0])

	_set_region_owner_percent(fixture.battlefield, fixture.region_map, region_id, CardfrontRulesScript.PLAYER_FACTION, 49)
	var below_result = DeploymentRulesScript.evaluate(fixture.region_map, fixture.battlefield, _make_region_query(CardfrontRulesScript.PLAYER_FACTION, region_id, 50))
	_assert.that(not below_result.allowed, "region controlled: 49 percent should not satisfy 50 percent rule")
	_assert.eq(below_result.reason, DeploymentRulesScript.REASON_REGION_CONTROL_TOO_LOW, "region controlled: below threshold should explain low control")
	_assert.eq(below_result.owner_percent, 49, "region controlled: below threshold should report owner percent")

	_set_region_owner_percent(fixture.battlefield, fixture.region_map, region_id, CardfrontRulesScript.PLAYER_FACTION, 50)
	var equal_result = DeploymentRulesScript.evaluate(fixture.region_map, fixture.battlefield, _make_region_query(CardfrontRulesScript.PLAYER_FACTION, region_id, 50))
	_assert.that(equal_result.allowed, "region controlled: 50 percent should satisfy 50 percent rule")
	_assert.eq(equal_result.owner_percent, 50, "region controlled: equal threshold should report owner percent")

	_set_region_owner_percent(fixture.battlefield, fixture.region_map, region_id, CardfrontRulesScript.PLAYER_FACTION, 80)
	var high_result = DeploymentRulesScript.evaluate(fixture.region_map, fixture.battlefield, _make_region_query(CardfrontRulesScript.PLAYER_FACTION, region_id, 50))
	_assert.that(high_result.allowed, "region controlled: 80 percent should satisfy 50 percent rule")
	_assert.eq(high_result.owner_percent, 80, "region controlled: high control should report owner percent")
	_cleanup_fixture(fixture)


func _test_invalid_inputs() -> void:
	var fixture: Dictionary = _make_fixture()
	var outside_result = DeploymentRulesScript.evaluate(fixture.region_map, fixture.battlefield, _make_query(CardfrontRulesScript.PLAYER_FACTION, Vector2i(-1, 0), DeploymentRuleTypeScript.OWNED_CELL))
	var invalid_region_result = DeploymentRulesScript.evaluate(fixture.region_map, fixture.battlefield, _make_region_query(CardfrontRulesScript.PLAYER_FACTION, 999999, 50))

	_assert.that(not outside_result.allowed, "invalid input: outside cell should not be allowed")
	_assert.eq(outside_result.reason, DeploymentRulesScript.REASON_OUTSIDE_MAP, "invalid input: outside cell should return outside_map")
	_assert.that(not invalid_region_result.allowed, "invalid input: unknown region should not be allowed")
	_assert.eq(invalid_region_result.reason, DeploymentRulesScript.REASON_INVALID_REGION, "invalid input: unknown region should return invalid_region")
	_cleanup_fixture(fixture)


func _test_evaluate_is_read_only() -> void:
	var fixture: Dictionary = _make_fixture()
	var region_id: int = int(fixture.region_map.get_region_ids_by_type(RegionTypeScript.FACTORY)[0])
	_set_region_owner_percent(fixture.battlefield, fixture.region_map, region_id, CardfrontRulesScript.PLAYER_FACTION, 50)
	var owners_before: String = JSON.stringify(fixture.battlefield.owners)
	var region_snapshot_before: String = JSON.stringify(fixture.region_map.snapshot(), "", true, true)

	DeploymentRulesScript.evaluate(fixture.region_map, fixture.battlefield, _make_region_query(CardfrontRulesScript.PLAYER_FACTION, region_id, 50))
	DeploymentRulesScript.evaluate(fixture.region_map, fixture.battlefield, _make_query(CardfrontRulesScript.PLAYER_FACTION, fixture.region_map.get_region_cells(region_id)[0], DeploymentRuleTypeScript.OWNED_BORDER))

	_assert.eq(JSON.stringify(fixture.battlefield.owners), owners_before, "read only: evaluate should not change battlefield owners")
	_assert.eq(JSON.stringify(fixture.region_map.snapshot(), "", true, true), region_snapshot_before, "read only: evaluate should not change RegionMap snapshot")
	_cleanup_fixture(fixture)


func _make_fixture() -> Dictionary:
	var region_map := RegionMapScript.new()
	region_map.configure(40)
	region_map.generate_default_layout()
	var battlefield := Battlefield.new()
	battlefield.configure(40)
	get_root().add_child(battlefield)
	battlefield.replace_owners(_make_owner_grid(40, CardfrontRulesScript.NEUTRAL_OWNER), false)
	return {
		"region_map": region_map,
		"battlefield": battlefield,
	}


func _make_query(owner_id: int, cell: Vector2i, rule_type: String):
	var query = DeploymentQueryScript.new()
	query.owner_id = owner_id
	query.cell = cell
	query.rule_type = rule_type
	return query


func _make_region_query(owner_id: int, region_id: int, min_percent: int):
	var query = DeploymentQueryScript.new()
	query.owner_id = owner_id
	query.region_id = region_id
	query.rule_type = DeploymentRuleTypeScript.OWNED_REGION_CONTROLLED
	query.min_region_control_percent = min_percent
	return query


func _make_owner_grid(grid_size: int, owner_id: int) -> Array:
	var owners: Array = []
	for x in range(grid_size):
		var col: Array = []
		for y in range(grid_size):
			col.append(owner_id)
		owners.append(col)
	return owners


func _set_owner(battlefield: Battlefield, cell: Vector2i, owner_id: int) -> void:
	var owners: Array = battlefield.owners.duplicate(true)
	owners[cell.x][cell.y] = owner_id
	battlefield.replace_owners(owners, false)


func _set_owned_block(battlefield: Battlefield, center: Vector2i, radius: int, owner_id: int) -> void:
	var owners: Array = battlefield.owners.duplicate(true)
	for x in range(center.x - radius, center.x + radius + 1):
		for y in range(center.y - radius, center.y + radius + 1):
			owners[x][y] = owner_id
	battlefield.replace_owners(owners, false)


func _set_region_owner_percent(battlefield: Battlefield, region_map, region_id: int, owner_id: int, percent: int) -> void:
	battlefield.replace_owners(_make_owner_grid(int(region_map.grid_size), CardfrontRulesScript.NEUTRAL_OWNER), false)
	var owners: Array = battlefield.owners.duplicate(true)
	var cells: Array = region_map.get_region_cells(region_id)
	var owner_count: int = int(ceil(float(cells.size()) * clampf(float(percent) / 100.0, 0.0, 1.0)))
	while owner_count > 0 and int(floor(float(owner_count) * 100.0 / float(cells.size()))) > percent:
		owner_count -= 1
	for index in range(cells.size()):
		var cell: Vector2i = cells[index]
		if index < owner_count:
			owners[cell.x][cell.y] = owner_id
	battlefield.replace_owners(owners, false)


func _cleanup_fixture(fixture: Dictionary) -> void:
	TestFixtures.cleanup_node(fixture.get("battlefield", null))
