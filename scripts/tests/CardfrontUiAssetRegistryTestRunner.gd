extends SceneTree

const CardfrontUiAssetRegistryScript = preload("res://scripts/cardfront/ui/CardfrontUiAssetRegistry.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontUiAssetRegistryTest] Starting UI asset registry tests")
	await process_frame

	_test_registered_paths_have_fallbacks()
	_test_missing_asset_fallback_safe()
	_test_texture_and_font_loads_do_not_crash()

	GameConfig.reset_runtime_defaults()
	await _flush()

	_assert.report("[CardfrontUiAssetRegistryTest]")
	if _assert.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _flush() -> void:
	await process_frame
	await process_frame


func _test_registered_paths_have_fallbacks() -> void:
	var ids: Array = CardfrontUiAssetRegistryScript.get_asset_ids()
	_assert.gte(ids.size(), 8, "ui registry: should register core UI assets")
	for asset_id in ids:
		var path: String = CardfrontUiAssetRegistryScript.get_asset_path(str(asset_id))
		var fallback: String = CardfrontUiAssetRegistryScript.get_fallback(str(asset_id))
		_assert.neq(path, "", "ui registry: path should not be empty for %s" % str(asset_id))
		_assert.neq(fallback, "", "ui registry: fallback should not be empty for %s" % str(asset_id))
		_assert.that(CardfrontUiAssetRegistryScript.has_asset(str(asset_id)) or fallback != "", "ui registry: %s should exist or declare fallback" % str(asset_id))


func _test_missing_asset_fallback_safe() -> void:
	_assert.eq(CardfrontUiAssetRegistryScript.get_asset_path("missing_asset_for_test"), "", "ui registry: missing path should be empty")
	_assert.that(not CardfrontUiAssetRegistryScript.has_asset("missing_asset_for_test"), "ui registry: missing asset should report false")
	_assert.eq(CardfrontUiAssetRegistryScript.load_texture("missing_asset_for_test"), null, "ui registry: missing texture should return null")
	var style = CardfrontUiAssetRegistryScript.make_panel_style("missing_asset_for_test", Color.BLACK, Color.WHITE)
	_assert.that(style != null, "ui registry: missing asset should still return fallback style")


func _test_texture_and_font_loads_do_not_crash() -> void:
	var font = CardfrontUiAssetRegistryScript.load_font()
	_assert.that(font != null or CardfrontUiAssetRegistryScript.get_fallback("font_kenney_future") != "", "ui registry: font should load or fallback")
	var texture = CardfrontUiAssetRegistryScript.load_texture("detail_popup_panel")
	_assert.that(texture != null or CardfrontUiAssetRegistryScript.get_fallback("detail_popup_panel") != "", "ui registry: texture should load or fallback")
