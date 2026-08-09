extends SceneTree

const ProfilesScript = preload("res://scripts/cardfront/support/capture/SupportCaptureProfiles.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontSupportCaptureProfileTest] Checking centralized profile mapping")
	await process_frame

	_test_profile_definitions()
	_test_representative_creature_mapping()
	_test_unknowns_are_non_control()
	_test_mapping_does_not_accept_combat_or_mobility_inputs()

	_assert.report("[CardfrontSupportCaptureProfileTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_profile_definitions() -> void:
	_assert.eq(ProfilesScript.validate_all(), [], "capture profiles: centralized registry validates")
	_assert.eq(ProfilesScript.weight_for_profile(ProfilesScript.PROFILE_LIGHT_CONTROL), 2.0, "capture profiles: light weight")
	_assert.eq(ProfilesScript.weight_for_profile(ProfilesScript.PROFILE_STANDARD_CONTROL), 1.0, "capture profiles: standard weight")
	_assert.eq(ProfilesScript.weight_for_profile(ProfilesScript.PROFILE_HEAVY_CONTROL), 0.5, "capture profiles: heavy weight")
	_assert.eq(ProfilesScript.weight_for_profile(ProfilesScript.PROFILE_NON_CONTROL), 0.0, "capture profiles: non-control weight")


func _test_representative_creature_mapping() -> void:
	_assert.eq(ProfilesScript.profile_for_creature("scout_unit"), ProfilesScript.PROFILE_LIGHT_CONTROL, "capture profiles: Scout is explicit light control")
	_assert.eq(ProfilesScript.profile_for_creature("repair_unit"), ProfilesScript.PROFILE_STANDARD_CONTROL, "capture profiles: Repair Unit is explicit standard control")
	_assert.eq(ProfilesScript.profile_for_creature("sapper_unit"), ProfilesScript.PROFILE_STANDARD_CONTROL, "capture profiles: Sapper is explicit standard control")
	_assert.eq(ProfilesScript.profile_for_creature("armored_guard"), ProfilesScript.PROFILE_HEAVY_CONTROL, "capture profiles: Armored Guard is explicit heavy control")
	_assert.eq(ProfilesScript.profile_for_creature("gate_colossus"), ProfilesScript.PROFILE_NON_CONTROL, "capture profiles: neutral Gate Colossus cannot capture")


func _test_unknowns_are_non_control() -> void:
	_assert.eq(ProfilesScript.profile_for_creature("unknown_creature"), ProfilesScript.PROFILE_NON_CONTROL, "capture profiles: unknown creature fails closed")
	_assert.eq(ProfilesScript.weight_for_profile("unknown_profile"), 0.0, "capture profiles: unknown profile has zero weight")
	_assert.eq(ProfilesScript.tag_for_profile("unknown_profile"), ProfilesScript.TAG_CANNOT_CAPTURE, "capture profiles: unknown profile exposes cannot-capture tag")


func _test_mapping_does_not_accept_combat_or_mobility_inputs() -> void:
	for forbidden_key in ["armor_type", "movement", "size_slots", "damage", "dps"]:
		_assert.that(not ProfilesScript.CREATURE_PROFILE_BY_ID.has(forbidden_key), "capture profiles: no implicit %s mapping" % forbidden_key)
