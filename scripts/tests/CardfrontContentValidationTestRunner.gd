extends SceneTree

const CardCatalogScript = preload("res://scripts/cardfront/cards/CardCatalog.gd")
const CardPlaySystemScript = preload("res://scripts/cardfront/cards/CardPlaySystem.gd")
const CardTargetTypeScript = preload("res://scripts/cardfront/cards/CardTargetType.gd")
const CardTypeScript = preload("res://scripts/cardfront/cards/CardType.gd")
const CardVisualRegistryScript = preload("res://scripts/cardfront/ui/CardVisualRegistry.gd")
const CardfrontContentManifestScript = preload("res://scripts/cardfront/content/CardfrontContentManifest.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontContentValidationTest] Starting Cardfront content validation tests")
	await process_frame

	_test_manifest_self_validation()
	_test_catalog_reads_manifest()
	_test_effect_registry_covers_manifest()
	_test_target_types_are_declared()
	_test_visuals_are_declared()
	_test_default_hand_refs_exist()

	GameConfig.reset_runtime_defaults()
	await process_frame

	_assert.report("[CardfrontContentValidationTest]")
	if _assert.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _test_manifest_self_validation() -> void:
	var errors: Array = CardfrontContentManifestScript.validate_all()
	_assert.eq(errors, [], "content manifest: validate_all should have no errors")


func _test_catalog_reads_manifest() -> void:
	var catalog = CardCatalogScript.new()
	for card_id in CardfrontContentManifestScript.get_card_ids():
		var definition: Dictionary = CardfrontContentManifestScript.get_card_definition(int(card_id))
		var card = catalog.get_card(int(card_id))
		_assert.that(card != null, "catalog: manifest card %d should exist" % int(card_id))
		if card == null:
			continue
		_assert.eq(card.id, int(definition.get("id", 0)), "catalog: card id should match manifest")
		_assert.eq(card.card_name, str(definition.get("name", "")), "catalog: card name should match manifest")
		_assert.eq(card.card_type, str(definition.get("type", "")), "catalog: card type should match manifest")
		_assert.eq(card.energy_cost, int(definition.get("energy_cost", 0)), "catalog: energy cost should match manifest")
		_assert.eq(card.parts_cost, int(definition.get("parts_cost", 0)), "catalog: parts cost should match manifest")
		_assert.eq(card.target_type, str(definition.get("target_type", "")), "catalog: target type should match manifest")
		_assert.eq(card.effect_id, str(definition.get("effect_id", "")), "catalog: effect id should match manifest")
		_assert.eq(card.visual_id, str(definition.get("visual_id", "")), "catalog: visual id should match manifest")
		_assert.eq(card.params, definition.get("params", {}), "catalog: params should match manifest")


func _test_effect_registry_covers_manifest() -> void:
	var system = CardPlaySystemScript.new()
	for effect_id in CardfrontContentManifestScript.get_declared_effect_ids():
		_assert.that(system.has_effect_handler(str(effect_id)), "effects: manifest effect should be registered: %s" % str(effect_id))


func _test_target_types_are_declared() -> void:
	var system = CardPlaySystemScript.new()
	for card_id in CardfrontContentManifestScript.get_card_ids():
		var definition: Dictionary = CardfrontContentManifestScript.get_card_definition(int(card_id))
		var card_type: String = str(definition.get("type", ""))
		var target_type: String = str(definition.get("target_type", ""))
		_assert.that(CardTypeScript.is_valid(card_type), "content: card type should be valid for %d" % int(card_id))
		_assert.that(CardTargetTypeScript.is_valid(target_type), "content: target type should be valid for %d" % int(card_id))
		_assert.that(system.has_target_rule(target_type), "targets: current card target type should have a rule: %s" % target_type)


func _test_visuals_are_declared() -> void:
	for card_id in CardfrontContentManifestScript.get_card_ids():
		var definition: Dictionary = CardfrontContentManifestScript.get_card_definition(int(card_id))
		var visual_id: String = str(definition.get("visual_id", ""))
		var visual: Dictionary = CardfrontContentManifestScript.get_visual(visual_id)
		_assert.that(not visual.is_empty(), "visuals: manifest visual should exist for %d" % int(card_id))
		_assert.that(CardVisualRegistryScript.has_texture(int(card_id)), "visuals: registry should expose full texture for %d" % int(card_id))
		_assert.that(CardVisualRegistryScript.has_thumbnail(int(card_id)), "visuals: registry should expose thumbnail for %d" % int(card_id))
		_assert.that(CardVisualRegistryScript.get_texture_path(int(card_id)) != "", "visuals: full texture path should be non-empty")
		_assert.that(CardVisualRegistryScript.get_thumbnail_path(int(card_id)) != "", "visuals: thumbnail path should be non-empty")


func _test_default_hand_refs_exist() -> void:
	var hand_ids: Array = CardfrontContentManifestScript.get_default_hand_ids()
	_assert.eq(hand_ids.size(), 4, "default hand: content foundation should still expose the existing 4-card hand")
	for card_id in hand_ids:
		_assert.that(CardfrontContentManifestScript.has_card(int(card_id)), "default hand: referenced card should exist %d" % int(card_id))
