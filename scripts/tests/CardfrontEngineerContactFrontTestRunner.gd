extends SceneTree

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const BattlefieldInitializerScript = preload("res://scripts/cardfront/CardfrontBattlefieldInitializer.gd")
const HeroRegistryScript = preload("res://scripts/cardfront/heroes/CardfrontHeroRegistry.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontEngineerContactFrontTest] Starting engineer opening fortification tests")
	await process_frame

	var main = await _start_main()
	_test_initial_contact_front(main)
	_test_consumption_recapture_repair_and_no_dynamic_refill(main)
	_test_visual_distinction(main)

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)
	await _flush()
	GameConfig.reset_runtime_defaults()
	paused = false

	_assert.report("[CardfrontEngineerContactFrontTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_initial_contact_front(main) -> void:
	var battlefield = main.runtime.battlefield
	var defense = main.runtime.territory_defense_system
	var grid_size: int = int(battlefield.grid_size)
	var spawn_rows: int = BattlefieldInitializerScript.get_spawn_rows(grid_size)
	var player_front_y: int = grid_size - spawn_rows
	var ai_front_y: int = spawn_rows - 1
	var player_front: Array = defense.get_starting_contact_front_cells(RulesScript.PLAYER_FACTION)
	var ai_front: Array = defense.get_starting_contact_front_cells(RulesScript.AI_FACTION)

	_assert.eq(player_front.size(), grid_size, "engineer front: full player contact row should be identified once")
	_assert.eq(ai_front.size(), grid_size, "engineer front: full AI contact row should be identified once")
	for raw_cell in player_front:
		var cell: Vector2i = raw_cell
		_assert.eq(cell.y, player_front_y, "engineer front: player contact cells should face the neutral center")
		_assert.eq(defense.get_cell_defense(cell), 2, "engineer front: every initial player contact cell should begin at two of two")
	for raw_cell in ai_front:
		var cell: Vector2i = raw_cell
		_assert.eq(cell.y, ai_front_y, "engineer front: AI contact cells should face the neutral center")
		_assert.eq(defense.get_cell_defense(cell), 1, "engineer front: non-engineer contact cells should remain one of one")

	var player_interior := Vector2i(0, player_front_y + 1)
	_assert.eq(int(battlefield.owners[player_interior.x][player_interior.y]), RulesScript.PLAYER_FACTION, "engineer front: selected interior cell should remain owned")
	_assert.that(not player_front.has(player_interior), "engineer front: interior territory must not be classified as contact front")
	_assert.eq(defense.get_cell_defense(player_interior), 1, "engineer front: ordinary initial territory should remain one of two")


func _test_consumption_recapture_repair_and_no_dynamic_refill(main) -> void:
	var battlefield = main.runtime.battlefield
	var defense = main.runtime.territory_defense_system
	var initial_front_snapshot: Array = defense.get_starting_contact_front_cells(RulesScript.PLAYER_FACTION)
	var contact_cell: Vector2i = initial_front_snapshot[0] if not initial_front_snapshot.is_empty() else Vector2i(-1, -1)
	var interior_cell := contact_cell + Vector2i.DOWN

	_assert.that(contact_cell.x >= 0, "engineer lifecycle: a contact-front cell should exist")
	_assert.eq(defense.get_cell_defense(contact_cell), 2, "engineer lifecycle: selected contact cell should begin at two")
	_assert.eq(
		battlefield.apply_bullet(contact_cell, RulesScript.AI_FACTION),
		"BLOCKED_BY_FORTIFY",
		"engineer lifecycle: first hostile hit should consume one opening fortification"
	)
	_assert.eq(defense.get_cell_defense(contact_cell), 1, "engineer lifecycle: first hostile hit should leave one layer")
	_assert.eq(
		battlefield.apply_bullet(contact_cell, RulesScript.AI_FACTION),
		"BLOCKED_BY_FORTIFY",
		"engineer lifecycle: second hostile hit should consume the final layer"
	)
	_assert.eq(defense.get_cell_defense(contact_cell), 0, "engineer lifecycle: second hostile hit should leave zero defense")
	_assert.eq(int(battlefield.owners[contact_cell.x][contact_cell.y]), RulesScript.PLAYER_FACTION, "engineer lifecycle: owner should remain until a later hit captures")
	_assert.eq(defense.get_cell_defense(interior_cell), 1, "engineer lifecycle: newly exposed interior cell must not auto-promote to two")

	defense.initialize_starting_defense()
	_assert.eq(defense.get_cell_defense(contact_cell), 0, "engineer lifecycle: initialization is one-shot and must not refill a depleted front")
	_assert.eq(defense.get_cell_defense(interior_cell), 1, "engineer lifecycle: one-shot initialization must not build a new inner front")
	_assert.eq(defense.get_starting_contact_front_cells(RulesScript.PLAYER_FACTION), initial_front_snapshot, "engineer lifecycle: initial contact-front snapshot must remain locked")

	_assert.eq(
		battlefield.apply_bullet(contact_cell, RulesScript.AI_FACTION),
		"HIT_ENEMY_CELL",
		"engineer lifecycle: third hostile hit should capture after both layers are gone"
	)
	_assert.eq(int(battlefield.owners[contact_cell.x][contact_cell.y]), RulesScript.AI_FACTION, "engineer lifecycle: enemy should own the captured cell")
	_assert.eq(defense.get_cell_defense(contact_cell), 0, "engineer lifecycle: newly captured territory should begin at zero")

	_assert.eq(
		battlefield.apply_bullet(contact_cell, RulesScript.PLAYER_FACTION),
		"HIT_ENEMY_CELL",
		"engineer lifecycle: engineer should be able to recapture the depleted cell"
	)
	_assert.eq(int(battlefield.owners[contact_cell.x][contact_cell.y]), RulesScript.PLAYER_FACTION, "engineer lifecycle: recaptured cell should return to the engineer")
	_assert.eq(defense.get_cell_defense(contact_cell), 0, "engineer lifecycle: recaptured territory must still begin at zero")

	_assert.eq(defense.repair_owner(RulesScript.PLAYER_FACTION, 1, "frontline"), 1, "engineer lifecycle: frontline repair should restore one distinct cell")
	_assert.eq(defense.get_cell_defense(contact_cell), 1, "engineer lifecycle: repair should restore only one layer, not recreate the opening two-layer bonus")
	defense.refresh_territory_defense()
	_assert.eq(defense.get_cell_defense(contact_cell), 1, "engineer lifecycle: cap synchronization must not refill repaired territory")


func _test_visual_distinction(main) -> void:
	var defense = main.runtime.territory_defense_system
	var overlay = main.runtime.fortify_overlay
	var front_cells: Array = defense.get_starting_contact_front_cells(RulesScript.PLAYER_FACTION)
	var fortified_cell: Vector2i = front_cells[1] if front_cells.size() > 1 else Vector2i(-1, -1)
	var ordinary_cell := fortified_cell + Vector2i.DOWN

	_assert.eq(defense.get_cell_defense(fortified_cell), 2, "engineer visual: untouched contact cell should retain two layers")
	_assert.eq(defense.get_cell_defense(ordinary_cell), 1, "engineer visual: adjacent interior cell should retain one layer")
	overlay._build_texture()
	var texture = overlay._sprite.texture
	_assert.that(texture != null, "engineer visual: fortification overlay should build a cached texture")
	if texture == null:
		return
	var image: Image = texture.get_image()
	var front_alpha: float = _cell_alpha_sum(image, fortified_cell, int(overlay.cell_size))
	var ordinary_alpha: float = _cell_alpha_sum(image, ordinary_cell, int(overlay.cell_size))
	_assert.gt(front_alpha, ordinary_alpha, "engineer visual: two-layer contact front should render more strongly than one-layer interior")


func _cell_alpha_sum(image: Image, cell: Vector2i, cell_size: int) -> float:
	var total: float = 0.0
	var origin := Vector2i(cell.x * cell_size, cell.y * cell_size)
	for local_x in range(cell_size):
		for local_y in range(cell_size):
			total += image.get_pixel(origin.x + local_x, origin.y + local_y).a
	return total


func _start_main():
	GameConfig.reset_runtime_defaults()
	paused = false
	var scene: PackedScene = load("res://scenes/Main.tscn")
	var main = scene.instantiate()
	get_root().add_child(main)
	await process_frame
	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_size = 20
	main.selected_cardfront_player_hero_id = HeroRegistryScript.HERO_FORTIFICATION_ENGINEER
	main.selected_cardfront_ai_hero_id = HeroRegistryScript.HERO_RAPID_GUNNER
	main._start_game(20, true, false)
	await _flush()
	return main


func _flush() -> void:
	await process_frame
	await process_frame
