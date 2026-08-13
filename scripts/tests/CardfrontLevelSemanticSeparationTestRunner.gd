extends SceneTree

const RunStateScript = preload("res://scripts/cardfront/run/CardfrontFactionRunState.gd")
const UpgradeManifestScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeManifest.gd")
const DraftSystemScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeDraftSystem.gd")
const UpgradeResolverScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeResolver.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontLevelSemanticSeparationTest] Starting P0-09A5-A6 semantics")
	await process_frame

	_test_effect_cap_is_not_selected_level_cap()
	_test_rarity_is_not_selected_level()

	_assert.report("[CardfrontLevelSemanticSeparationTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_effect_cap_is_not_selected_level_cap() -> void:
	var draft = DraftSystemScript.new()
	var state = RunStateScript.new()
	state.setup(0, 10)
	var attack_id: String = UpgradeManifestScript.UPGRADE_ATTACK_LEVEL_PLUS_1
	var attack_definition: Dictionary = UpgradeManifestScript.get_definition(attack_id)

	# Selected Level alone does not impose a card max-level rule in P0.
	for _index in range(5):
		state.record_selected_upgrade_resolved(attack_id)
	_assert.eq(state.get_selected_upgrade_level(attack_id), 5, "eligibility: test fixture has Selected Level 5")
	_assert.eq(state.attack_level, 0, "eligibility: recording selection history does not apply attack effect")
	_assert.that(draft.is_upgrade_eligible(attack_definition, state), "eligibility: high Selected Level alone does not disable the card")

	# Existing effect-state cap remains authoritative regardless of Selected Level.
	state.selected_upgrade_levels.clear()
	state.attack_level = RunStateScript.MAX_ATTACK_LEVEL
	_assert.eq(state.get_selected_upgrade_level(attack_id), 0, "eligibility: capped effect can coexist with Selected Level 0")
	_assert.that(not draft.is_upgrade_eligible(attack_definition, state), "eligibility: attack effect cap disables the card independently of Level")

	# An uncapped existing effect remains eligible after repeated selections.
	var volley_id: String = UpgradeManifestScript.UPGRADE_VOLLEY_PLUS_5
	var volley_definition: Dictionary = UpgradeManifestScript.get_definition(volley_id)
	for _index in range(7):
		state.record_selected_upgrade_resolved(volley_id)
	_assert.eq(state.get_selected_upgrade_level(volley_id), 7, "eligibility: repeatable card can have Selected Level 7")
	_assert.that(draft.is_upgrade_eligible(volley_definition, state), "eligibility: no implicit global card-level cap is introduced")


func _test_rarity_is_not_selected_level() -> void:
	var state = RunStateScript.new()
	state.setup(0, 10)
	var resolver = UpgradeResolverScript.new()
	var rarity_id: String = UpgradeManifestScript.UPGRADE_RARITY_PLUS_1
	var rarity_definition: Dictionary = UpgradeManifestScript.get_definition(rarity_id)
	var initial_rarity_tag: String = str(rarity_definition.get("rarity", ""))

	_assert.eq(state.rarity_level, 0, "rarity: run rarity starts at zero")
	_assert.eq(state.get_selected_upgrade_level(rarity_id), 0, "rarity: card Selected Level starts at zero")
	_assert.that(initial_rarity_tag != "", "rarity: definition has an authored rarity label")

	var result: Dictionary = resolver.resolve(state, rarity_id)
	_assert.that(bool(result.get("success", false)), "rarity: rarity upgrade resolves")
	_assert.eq(state.rarity_level, 1, "rarity: effect increases run rarity once")
	_assert.eq(state.get_selected_upgrade_level(rarity_id), 1, "rarity: successful selection independently gives card Level 1")
	_assert.eq(str(UpgradeManifestScript.get_definition(rarity_id).get("rarity", "")), initial_rarity_tag, "rarity: selecting the card does not rewrite its authored rarity label")

	state.rarity_level = RunStateScript.MAX_RARITY_LEVEL
	_assert.eq(state.get_selected_upgrade_level(rarity_id), 1, "rarity: changing run rarity does not rewrite Selected Level")
	_assert.eq(str(UpgradeManifestScript.get_definition(rarity_id).get("rarity", "")), initial_rarity_tag, "rarity: run rarity does not rewrite definition rarity")
