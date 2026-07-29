extends SceneTree

const DraftSystemScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeDraftSystem.gd")
const RunStateScript = preload("res://scripts/cardfront/run/CardfrontFactionRunState.gd")
const UpgradeManifestScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeManifest.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontEighteenCardReadabilityTest] Starting live-pool readability tests")
	await process_frame

	await _test_all_live_cards_render_in_the_formal_scene()
	_test_seeded_drafts_can_reach_the_full_live_pool()

	_assert.report("[CardfrontEighteenCardReadabilityTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_all_live_cards_render_in_the_formal_scene() -> void:
	var card_scene: PackedScene = load("res://scenes/ui/cardfront/CardfrontUpgradeChoiceCard.tscn")
	var live_ids: Array = UpgradeManifestScript.get_upgrade_ids()
	_assert.eq(live_ids.size(), 18, "live pool: formal catalog should contain eighteen cards")
	for raw_id in live_ids:
		var upgrade_id: String = str(raw_id)
		var definition: Dictionary = UpgradeManifestScript.get_definition(upgrade_id)
		var card = card_scene.instantiate()
		get_root().add_child(card)
		await process_frame
		card.setup(definition)
		await process_frame

		_assert.eq(card.upgrade_id, upgrade_id, "live pool: scene should bind the requested upgrade id")
		_assert.eq(card.name_label.text, str(definition.get("name", "")), "live pool: scene should display the manifest name")
		_assert.eq(card.symbol_label.text, str(definition.get("symbol", "")), "live pool: scene should display the direct symbol")
		_assert.that(not _contains_ascii_letters(card.symbol_label.text), "live pool: symbol should not expose unexplained English shorthand")
		_assert.that(card.description_label.text.length() >= 4, "live pool: description should explain the effect")
		_assert.gte(card.custom_minimum_size.x, 210.0, "live pool: formal card should keep a readable width")
		_assert.gte(card.custom_minimum_size.y, 260.0, "live pool: formal card should keep a readable height")
		_assert.that(card.symbol_label.get_theme_font_size("font_size") >= 29, "live pool: primary number or symbol should remain visually dominant")
		_assert.eq(card.mouse_filter, Control.MOUSE_FILTER_STOP, "live pool: formal card should remain clickable")

		TestFixtures.cleanup_node(card)
		await process_frame


func _test_seeded_drafts_can_reach_the_full_live_pool() -> void:
	var state = RunStateScript.new()
	state.setup(0)
	var draft = DraftSystemScript.new()
	var seen: Dictionary = {}
	for seed_value in range(1, 501):
		draft.set_seed(seed_value)
		for raw_definition in draft.draw_three(state):
			if raw_definition is Dictionary:
				seen[str((raw_definition as Dictionary).get("id", ""))] = true
	state.sync_entity_summary(0, 1, {"interceptor_tower": 1})
	for seed_value in range(501, 701):
		draft.set_seed(seed_value)
		for raw_definition in draft.draw_three(state):
			if raw_definition is Dictionary:
				seen[str((raw_definition as Dictionary).get("id", ""))] = true
	_assert.eq(seen.size(), UpgradeManifestScript.get_upgrade_ids().size(), "live pool: seeded formal drafts should reach every implemented card")
	for raw_id in UpgradeManifestScript.get_upgrade_ids():
		_assert.that(seen.has(str(raw_id)), "live pool: every implemented card should be reachable through the live draft")


func _contains_ascii_letters(value: String) -> bool:
	for index in range(value.length()):
		var codepoint: int = value.unicode_at(index)
		if (codepoint >= 65 and codepoint <= 90) or (codepoint >= 97 and codepoint <= 122):
			return true
	return false
