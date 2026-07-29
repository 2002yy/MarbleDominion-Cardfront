extends SceneTree

const CardfrontArenaLayoutScript = preload("res://scripts/cardfront/arena/CardfrontArenaLayout.gd")
const CardfrontBattlefieldInitializerScript = preload("res://scripts/cardfront/CardfrontBattlefieldInitializer.gd")
const CardfrontMapRegistryScript = preload("res://scripts/cardfront/maps/CardfrontMapRegistry.gd")
const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontArenaLayoutTest] Starting arena layout tests")
	await process_frame

	_test_desktop_layout(40)
	_test_desktop_layout(60)
	_test_top_bottom_spawn_contract()
	_test_default_map_declares_vertical_spawns()

	_assert.report("[CardfrontArenaLayoutTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_desktop_layout(grid_size: int) -> void:
	var viewport_size := Vector2(1120.0, 720.0)
	var base: Dictionary = LayoutCoordinator.calculate_layout(grid_size, viewport_size, false)
	var layout: Dictionary = CardfrontArenaLayoutScript.apply_to(base, grid_size, viewport_size)
	var battlefield_rect: Rect2 = layout.get("battlefield_rect", Rect2())
	var arena_view_rect: Rect2 = layout.get("arena_view_rect", Rect2())
	var player_pos: Vector2 = layout.get("turret_positions", {}).get(CardfrontRulesScript.PLAYER_FACTION, Vector2.ZERO)
	var ai_pos: Vector2 = layout.get("turret_positions", {}).get(CardfrontRulesScript.AI_FACTION, Vector2.ZERO)
	var aim_rect: Rect2 = layout.get("aim_control_rect", Rect2())

	_assert.that(CardfrontArenaLayoutScript.is_arena_layout(layout), "arena layout: Cardfront marker should be enabled")
	_assert.eq(str(layout.get("arena_composition", "")), "open_dual_bridge", "arena layout: composition should declare the open dual-bridge direction")
	_assert.eq(float(layout.get("arena_vertical_scale", 0.0)), 1.0, "arena layout: rectangular composition must not add a second vertical stretch")
	_assert.gte(int(layout.get("battlefield_cell_size", 0)), 8, "arena layout: logical cell size should stay readable")
	_assert.gte(battlefield_rect.position.x, 0.0, "arena layout: battlefield should stay inside left edge")
	_assert.gte(battlefield_rect.position.y, 72.0, "arena layout: battlefield should leave room for the slim top HUD")
	_assert.that(battlefield_rect.end.x <= viewport_size.x, "arena layout: battlefield should stay inside right edge")
	_assert.that(battlefield_rect.end.y <= viewport_size.y - 64.0, "arena layout: logical battlefield should leave a compact bottom UI margin")
	_assert.gte(arena_view_rect.size.x / viewport_size.x, 0.95, "arena layout: 3D arena should span almost the full viewport width")
	_assert.gte(arena_view_rect.size.y / viewport_size.y, 0.84, "arena layout: slim HUD should give the 3D arena more vertical breathing room")
	_assert.that(arena_view_rect.encloses(battlefield_rect), "arena layout: expanded presentation should enclose the logical battlefield")
	_assert.that(ai_pos.y < battlefield_rect.position.y, "arena layout: AI turret should sit outside the top battlefield edge")
	_assert.that(player_pos.y > battlefield_rect.end.y, "arena layout: player turret should sit outside the bottom battlefield edge")
	_assert.that(bool(layout.get("turrets_outside_battlefield", false)), "arena layout: outside turret placement should be explicit")
	_assert.that(is_equal_approx(ai_pos.x, player_pos.x), "arena layout: duel turrets should share the center lane")
	_assert.that(aim_rect.position.x <= 14.0, "arena layout: direction control should hug the left edge")
	_assert.that(aim_rect.size.x <= 220.0 and aim_rect.size.y <= 72.0, "arena layout: direction control should stay compact")
	_assert.that(not aim_rect.intersects(battlefield_rect), "arena layout: direction control should not cover the battlefield")


func _test_top_bottom_spawn_contract() -> void:
	var size: int = 40
	var rows: int = CardfrontBattlefieldInitializerScript.get_spawn_rows(size)
	_assert.gte(rows, 2, "arena spawn: should reserve at least two rows")
	_assert.eq(
		CardfrontBattlefieldInitializerScript.duel_owner_for_cell(0, 0, size),
		CardfrontRulesScript.AI_FACTION,
		"arena spawn: top edge should belong to AI"
	)
	_assert.eq(
		CardfrontBattlefieldInitializerScript.duel_owner_for_cell(size - 1, size - 1, size),
		CardfrontRulesScript.PLAYER_FACTION,
		"arena spawn: bottom edge should belong to player"
	)
	_assert.eq(
		CardfrontBattlefieldInitializerScript.duel_owner_for_cell(size >> 1, size >> 1, size),
		CardfrontRulesScript.NEUTRAL_OWNER,
		"arena spawn: center should remain neutral"
	)


func _test_default_map_declares_vertical_spawns() -> void:
	var definition: Dictionary = CardfrontMapRegistryScript.get_map_definition(CardfrontMapRegistryScript.DEFAULT_DUEL_MAP_ID, 40)
	var spawn_zones: Array = definition.get("spawn_zones", [])
	_assert.eq(spawn_zones.size(), 2, "arena map: default duel should define two spawn zones")
	for raw_zone in spawn_zones:
		var zone: Dictionary = raw_zone
		_assert.that(zone.has("y0") and zone.has("y1"), "arena map: spawn zones should use vertical row bounds")
		_assert.that(not zone.has("x0") and not zone.has("x1"), "arena map: spawn zones should no longer use side columns")
