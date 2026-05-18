extends SceneTree

const CardfrontModeScript = preload("res://scripts/cardfront/CardfrontMode.gd")
const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[NeutralOwnerCompatibilityTest] Starting neutral owner compatibility tests")
	await process_frame

	_test_quadrant_reset_has_no_neutral_cells()
	_test_battlefield_replace_owners_accepts_generic_owner_ids()
	_test_cardfront_reset_uses_neutral_cells()
	_test_save_validation_preserves_neutral_owner()
	_test_save_restore_preserves_neutral_owner()
	_test_hud_accepts_neutral_owner()
	_test_neutral_draw_color_and_decor()
	await _flush()

	_assert.report("[NeutralOwnerCompatibilityTest]")
	if _assert.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _flush() -> void:
	await process_frame
	await process_frame


func _test_quadrant_reset_has_no_neutral_cells() -> void:
	var bf := Battlefield.new()
	bf.configure(40)
	get_root().add_child(bf)
	bf.reset_quadrants()

	var counts: Dictionary = bf.count_cells_by_team()
	var total: int = 0
	for faction_id in [GameConfig.Faction.BLUE, GameConfig.Faction.RED, GameConfig.Faction.GREEN, GameConfig.Faction.YELLOW]:
		total += int(counts.get(faction_id, 0))

	_assert.eq(total, 1600, "quadrants: four faction counts should cover the full grid")
	_assert.eq(int(counts.get(CardfrontRulesScript.NEUTRAL_OWNER, 0)), 0, "quadrants: neutral owner count should stay zero")
	_assert.eq(_count_owner_cells(bf, CardfrontRulesScript.NEUTRAL_OWNER), 0, "quadrants: no cell should be neutral")
	TestFixtures.cleanup_node(bf)


func _test_battlefield_replace_owners_accepts_generic_owner_ids() -> void:
	var bf := Battlefield.new()
	bf.configure(10)
	get_root().add_child(bf)
	var owner_grid: Array = []
	for x in range(10):
		var col: Array = []
		for y in range(10):
			col.append(42)
		owner_grid.append(col)
	owner_grid[0][0] = CardfrontRulesScript.NEUTRAL_OWNER

	_assert.that(bf.replace_owners(owner_grid, false), "replace owners: generic owner grid should be accepted")
	var counts: Dictionary = bf.count_cells_by_team()
	_assert.eq(int(counts.get(42, 0)), 99, "replace owners: arbitrary int owner should be counted")
	_assert.eq(int(counts.get(CardfrontRulesScript.NEUTRAL_OWNER, 0)), 1, "replace owners: neutral int owner should be counted")
	TestFixtures.cleanup_node(bf)


func _test_cardfront_reset_uses_neutral_cells() -> void:
	var bf := Battlefield.new()
	bf.configure(40)
	get_root().add_child(bf)
	var setup: Dictionary = CardfrontModeScript.configure_battlefield(bf)

	_assert.that(bool(setup.get("configured", false)), "cardfront reset: mode initializer should configure battlefield")
	var counts: Dictionary = bf.count_cells_by_team()
	_assert.gt(int(counts.get(CardfrontRulesScript.NEUTRAL_OWNER, 0)), 0, "cardfront reset: neutral owner count should exist")
	_assert.eq(int(bf.owners[20][20]), CardfrontRulesScript.NEUTRAL_OWNER, "cardfront reset: center cell should be neutral")
	_assert.eq(_sum_counts(counts), 1600, "cardfront reset: owner counts should include neutral cells")
	TestFixtures.cleanup_node(bf)


func _test_save_validation_preserves_neutral_owner() -> void:
	var payload: Dictionary = _build_neutral_owner_save_payload()
	var clean: Dictionary = SaveGameCodec.validate_save_data(payload)
	var owners: Array = clean.get("owners", [])

	_assert.that(clean.has("owners"), "save validate: valid owners array should be preserved")
	_assert.eq(int(owners[20][20]), CardfrontRulesScript.NEUTRAL_OWNER, "save validate: neutral owner should not be clamped to BLUE")
	_assert.eq(str(clean.get("game_mode_name", "")), GameConfig.GAME_MODE_CARDFRONT, "save validate: Cardfront mode name should be preserved")


func _test_save_restore_preserves_neutral_owner() -> void:
	var bf := Battlefield.new()
	bf.configure(40)
	get_root().add_child(bf)
	var clean: Dictionary = SaveGameCodec.validate_save_data(_build_neutral_owner_save_payload())
	SaveStateApplier.apply_owners(bf, clean)

	var counts: Dictionary = bf.count_cells_by_team()
	_assert.eq(int(bf.owners[20][20]), CardfrontRulesScript.NEUTRAL_OWNER, "save restore: neutral owner should survive owner application")
	_assert.gt(int(counts.get(CardfrontRulesScript.NEUTRAL_OWNER, 0)), 0, "save restore: neutral count should survive owner rebuild")
	_assert.eq(_sum_counts(counts), 1600, "save restore: rebuilt owner counts should cover all cells")
	TestFixtures.cleanup_node(bf)


func _test_hud_accepts_neutral_owner() -> void:
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_CARDFRONT)
	var counts := {
		CardfrontRulesScript.PLAYER_FACTION: 320,
		CardfrontRulesScript.AI_FACTION: 320,
		CardfrontRulesScript.NEUTRAL_OWNER: 960,
	}
	var timer_label := Label.new()
	var stage_label := Label.new()
	var leader_label := Label.new()
	get_root().add_child(timer_label)
	get_root().add_child(stage_label)
	get_root().add_child(leader_label)

	RuntimeHudController.update_meta(timer_label, stage_label, leader_label, counts, 12.0)
	_assert.that(stage_label.text.begins_with("卡牌前线"), "hud meta: Cardfront stage text should render")
	_assert.that(leader_label.text.length() > 0, "hud meta: leader label should render with neutral present")

	var top_bar_segments: Dictionary = {}
	var top_bar_labels: Dictionary = {}
	var top_bar_name_labels: Dictionary = {}
	for faction_id in [GameConfig.Faction.BLUE, GameConfig.Faction.RED, GameConfig.Faction.GREEN, GameConfig.Faction.YELLOW]:
		top_bar_segments[faction_id] = _make_top_bar_segment()
		top_bar_labels[faction_id] = Label.new()
		top_bar_name_labels[faction_id] = Label.new()

	RuntimeHudController.update_top_bar(counts, top_bar_segments, top_bar_labels, top_bar_name_labels, 420.0, false)
	_assert.that((top_bar_segments[GameConfig.Faction.GREEN] as Panel).visible, "hud top bar: neutral segment should be visible in Cardfront mode")
	_assert.eq((top_bar_name_labels[GameConfig.Faction.GREEN] as Label).text, CardfrontRulesScript.owner_display_name(CardfrontRulesScript.NEUTRAL_OWNER), "hud top bar: neutral segment should use neutral display name")
	_assert.that(not (top_bar_segments[GameConfig.Faction.YELLOW] as Panel).visible, "hud top bar: unused fourth segment should be hidden in Cardfront mode")

	TestFixtures.cleanup_node(timer_label)
	TestFixtures.cleanup_node(stage_label)
	TestFixtures.cleanup_node(leader_label)
	for node in top_bar_segments.values():
		TestFixtures.cleanup_node(node)
	for node in top_bar_labels.values():
		TestFixtures.cleanup_node(node)
	for node in top_bar_name_labels.values():
		TestFixtures.cleanup_node(node)
	GameConfig.reset_runtime_defaults()


func _test_neutral_draw_color_and_decor() -> void:
	var bf := Battlefield.new()
	bf.configure(40)
	get_root().add_child(bf)
	CardfrontModeScript.configure_battlefield(bf)

	var neutral_pixel: Color = bf.cell_image.get_pixel(20, 20)
	_assert.that(_color_close(neutral_pixel, CardfrontRulesScript.NEUTRAL_COLOR, 0.01), "draw color: neutral cell should use neutral color")
	_assert.that(bf.decor_layer != null and is_instance_valid(bf.decor_layer), "decor: BattlefieldDecorLayer should exist with neutral owners")
	bf.apply_quality_style()
	bf.mark_decor_dirty()
	_assert.that(is_instance_valid(bf.decor_layer), "decor: visual setting refresh should tolerate neutral owners")
	TestFixtures.cleanup_node(bf)


func _build_neutral_owner_save_payload() -> Dictionary:
	var owners: Array = []
	for x in range(40):
		var col: Array = []
		for y in range(40):
			col.append(CardfrontRulesScript.NEUTRAL_OWNER)
		owners.append(col)
	for x in range(8):
		for y in range(40):
			owners[x][y] = CardfrontRulesScript.PLAYER_FACTION
			owners[39 - x][y] = CardfrontRulesScript.AI_FACTION

	return {
		"save_version": SaveGameCodec.SAVE_SCHEMA_VERSION,
		"grid_size": 40,
		"quality_name": GameConfig.QUALITY_MEDIUM,
		"game_mode_name": GameConfig.GAME_MODE_CARDFRONT,
		"time_limit_minutes": 5,
		"owners": owners,
		"factions": [],
	}


func _make_top_bar_segment() -> Panel:
	var panel := Panel.new()
	panel.size = Vector2(120, 32)

	var fill := ColorRect.new()
	fill.name = "Fill"
	panel.add_child(fill)

	var gloss := ColorRect.new()
	gloss.name = "Gloss"
	panel.add_child(gloss)

	var bottom_shadow := ColorRect.new()
	bottom_shadow.name = "BottomShadow"
	panel.add_child(bottom_shadow)

	var separator := ColorRect.new()
	separator.name = "Separator"
	panel.add_child(separator)

	return panel


func _count_owner_cells(battlefield, owner_id: int) -> int:
	var total: int = 0
	for x in range(battlefield.grid_size):
		for y in range(battlefield.grid_size):
			if int(battlefield.owners[x][y]) == owner_id:
				total += 1
	return total


func _sum_counts(counts: Dictionary) -> int:
	var total: int = 0
	for value in counts.values():
		total += int(value)
	return total


func _color_close(actual: Color, expected: Color, tolerance: float) -> bool:
	return absf(actual.r - expected.r) <= tolerance \
		and absf(actual.g - expected.g) <= tolerance \
		and absf(actual.b - expected.b) <= tolerance \
		and absf(actual.a - expected.a) <= tolerance
