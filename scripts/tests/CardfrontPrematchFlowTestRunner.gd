extends SceneTree

const PrematchScene = preload("res://scenes/ui/cardfront/CardfrontPrematchScreen.tscn")
const BattleHeroHudScene = preload("res://scenes/ui/cardfront/CardfrontBattleHeroHud.tscn")
const HeroRegistry = preload("res://scripts/cardfront/heroes/CardfrontHeroRegistry.gd")
const MapRegistry = preload("res://scripts/cardfront/maps/CardfrontMapRegistry.gd")
const RegionMapScript = preload("res://scripts/cardfront/regions/RegionMap.gd")
const OrthographicViewScript = preload("res://scripts/cardfront/arena/CardfrontOrthographicArenaView.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontPrematchFlowTest] Starting formal prematch tests")
	await process_frame
	await _test_main_routes_cardfront_to_prematch()
	await _test_three_step_selection()
	await _test_battle_identity_hud()
	_test_map_selection_changes_runtime_definition()
	_test_environment_themes_are_distinct()
	_assert.report("[CardfrontPrematchFlowTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_main_routes_cardfront_to_prematch() -> void:
	GameConfig.reset_runtime_defaults()
	var scene: PackedScene = load("res://scenes/Main.tscn")
	var main = scene.instantiate()
	root.add_child(main)
	await process_frame
	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main._request_start_from_menu()
	await process_frame
	_assert.that(
		main.cardfront_prematch_screen != null and is_instance_valid(main.cardfront_prematch_screen),
		"main route: Cardfront start should open prematch before constructing the battle"
	)
	_assert.eq(main.game_layer, null, "main route: battle should remain unbuilt until prematch confirmation")
	main._on_cardfront_prematch_cancelled()
	await process_frame
	_assert.eq(main.cardfront_prematch_screen, null, "main route: cancelling prematch should clear its runtime reference")
	TestFixtures.cleanup_node(main)
	await process_frame
	GameConfig.reset_runtime_defaults()


func _test_three_step_selection() -> void:
	var screen = PrematchScene.instantiate()
	root.add_child(screen)
	await process_frame
	screen.setup(MapRegistry.DEFAULT_DUEL_MAP_ID, HeroRegistry.DEFAULT_PLAYER_HERO_ID)
	await process_frame
	_assert.eq(screen.map_cards.get_child_count(), MapRegistry.get_registered_map_ids().size(), "prematch: should show every registered map")
	_assert.eq(screen.hero_cards.get_child_count(), HeroRegistry.get_hero_ids().size(), "prematch: should show all three heroes")
	_assert.eq(screen.get_phase_for_test(), 0, "prematch: should begin with map selection")
	screen.choose_map_for_test(MapRegistry.CENTRAL_LAB_MAP_ID)
	screen.advance_for_test()
	_assert.eq(screen.get_phase_for_test(), 1, "prematch: map confirmation should advance to hero selection")
	screen.choose_hero_for_test(HeroRegistry.HERO_RAPID_GUNNER)
	screen.advance_for_test()
	await process_frame
	_assert.eq(screen.get_phase_for_test(), 2, "prematch: hero confirmation should reveal the matchup")
	_assert.eq(screen.selected_map_id, MapRegistry.CENTRAL_LAB_MAP_ID, "prematch: selected map should persist through reveal")
	_assert.eq(screen.selected_player_hero_id, HeroRegistry.HERO_RAPID_GUNNER, "prematch: selected hero should persist through reveal")
	_assert.that(HeroRegistry.has_hero(screen.selected_ai_hero_id), "prematch: AI reveal should resolve to a registered hero")
	_assert.that(screen.player_stats.text.contains("基础齐射"), "prematch: comparison should show player base attributes")
	_assert.that(screen.ai_stats.text.contains("控制舱"), "prematch: comparison should show AI base attributes")
	screen.queue_free()
	await process_frame


func _test_battle_identity_hud() -> void:
	var hud = BattleHeroHudScene.instantiate()
	root.add_child(hud)
	await process_frame
	hud.configure({
		GameConfig.Faction.BLUE: HeroRegistry.HERO_FORTIFICATION_ENGINEER,
		GameConfig.Faction.RED: HeroRegistry.HERO_RAPID_GUNNER,
	})
	_assert.that(hud.player_name.text.contains("工程师"), "battle HUD: player plate should identify the selected hero")
	_assert.that(hud.ai_name.text.contains("炮手"), "battle HUD: AI plate should identify the revealed hero")
	_assert.that(hud.player_stats.text.contains("齐射 5"), "battle HUD: player plate should show base volley")
	_assert.that(hud.ai_stats.text.contains("舱体 36"), "battle HUD: AI plate should show chamber health")
	hud.queue_free()
	await process_frame


func _test_map_selection_changes_runtime_definition() -> void:
	var default_map = RegionMapScript.new()
	default_map.configure(40)
	default_map.generate_layout(MapRegistry.DEFAULT_DUEL_MAP_ID)
	var central_map = RegionMapScript.new()
	central_map.configure(40)
	central_map.generate_layout(MapRegistry.CENTRAL_LAB_MAP_ID)
	_assert.neq(
		JSON.stringify(default_map.snapshot(), "", true, true),
		JSON.stringify(central_map.snapshot(), "", true, true),
		"prematch: choosing a different map should produce a different live region layout"
	)


func _test_environment_themes_are_distinct() -> void:
	var view = OrthographicViewScript.new()
	view.map_id = MapRegistry.DEFAULT_DUEL_MAP_ID
	var default_ground: Color = view._theme_color("ground")
	view.map_id = MapRegistry.CROSS_RESOURCE_MAP_ID
	var cross_ground: Color = view._theme_color("ground")
	view.map_id = MapRegistry.CENTRAL_LAB_MAP_ID
	var lab_ground: Color = view._theme_color("ground")
	_assert.neq(default_ground, cross_ground, "environment: cross-resource map should have its own palette")
	_assert.neq(default_ground, lab_ground, "environment: central-lab map should have its own palette")
	view.free()
