extends SceneTree

const ValidatorScript = preload("res://scripts/cardfront/environment/CardfrontFormalAssetValidator.gd")
const ROOT := "res://assets/cardfront_environment/formal/tower/"

const MODULES := {
	"tower_common.glb": {
		"root": "CF_TowerCommon",
		"contract": {
			"require_ground_contact": true,
			"require_visible_geometry": true,
		},
	},
	"tower_interceptor.glb": {
		"root": "CF_TowerInterceptor",
		"contract": {
			"required_nodes": ["PIV_Turret", "SOCKET_Muzzle", "VFX_Intercept"],
			"forward_nodes": ["SOCKET_Muzzle"],
			"require_ground_contact": false,
			"require_visible_geometry": true,
		},
	},
	"tower_theme_castle.glb": {
		"root": "CF_TowerThemeCastle",
		"contract": {
			"require_ground_contact": false,
			"require_visible_geometry": true,
		},
	},
	"tower_damage_common.glb": {
		"root": "CF_TowerDamageCommon",
		"contract": {
			"require_ground_contact": true,
			"require_ground_center": false,
			"require_visible_geometry": true,
		},
	},
}

var _assert: TestAssert
var _validator


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	_validator = ValidatorScript.new()
	print("[CardfrontFormalTowerAssetTest] Starting exported Tower module admission")

	for file_name: String in MODULES:
		_validate_module(file_name, MODULES[file_name])

	_assert.report("[CardfrontFormalTowerAssetTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _validate_module(file_name: String, specification: Dictionary) -> void:
	var path := ROOT + file_name
	_assert.that(ResourceLoader.exists(path), "%s: imported PackedScene should exist" % file_name)
	if not ResourceLoader.exists(path):
		return

	var resource := load(path)
	_assert.that(resource is PackedScene, "%s: GLB should import as PackedScene" % file_name)
	if not resource is PackedScene:
		return

	var instance := (resource as PackedScene).instantiate()
	_assert.eq(str(instance.name), str(specification["root"]), "%s: exact module root should be preserved" % file_name)
	if file_name == "tower_interceptor.glb":
		var level_two := instance.find_child("GEO_InterceptPlate_C", true, false)
		var level_three := instance.find_child("GEO_CounterMuzzle", true, false)
		_assert.that(level_two != null, "%s: L2 third interception plate semantic name should survive import" % file_name)
		_assert.that(level_three != null, "%s: L3 counter muzzle semantic name should survive import" % file_name)
	elif file_name == "tower_damage_common.glb":
		var critical := instance.find_child("DMG_Critical_A", true, false)
		var heavy_buttress := instance.find_child("DMG_Heavy_FallenButtress", true, false)
		var critical_roof := instance.find_child("DMG_Critical_RoofSlab_A", true, false)
		var critical_arm_stub := instance.find_child("DMG_Critical_ArmStub_A", true, false)
		var critical_detached_plate := instance.find_child("DMG_Critical_DetachedPlate_A", true, false)
		var rubble := instance.find_child("DMG_Rubble_1", true, false)
		_assert.that(critical != null, "%s: critical damage semantic name should survive import" % file_name)
		_assert.that(heavy_buttress != null, "%s: HP2 grounded fallen-buttress replacement should survive import" % file_name)
		_assert.that(critical_roof != null, "%s: HP1 collapsed-roof replacement should survive import" % file_name)
		_assert.that(critical_arm_stub != null, "%s: HP1 connected broken-arm stub should survive import" % file_name)
		_assert.that(critical_detached_plate != null, "%s: HP1 grounded detached plate should survive import" % file_name)
		_assert.that(rubble != null, "%s: rubble snapshot semantic name should survive import" % file_name)
		_assert.eq(instance.find_children("DMG_Rubble_*", "MeshInstance3D", true, false).size(), 5, "%s: HP0 snapshot should retain the five-piece readable rubble cluster" % file_name)
	instance.free()

	var result: Dictionary = _validator.validate_resource_path(path, specification["contract"])
	_assert.that(bool(result.get("valid", false)), "%s: executable D21/D22 contract should pass; errors=%s facts=%s" % [file_name, result.get("errors", []), result.get("facts", {})])
	var facts: Dictionary = result.get("facts", {})
	_assert.that(int(facts.get("visible_geometry_count", 0)) > 0, "%s: visible geometry should be counted" % file_name)
	_assert.that(int(facts.get("material_slot_count", 0)) > 0, "%s: D21 material slots should be counted" % file_name)
	if file_name == "tower_interceptor.glb":
		_assert.eq(int(facts.get("required_node_count", 0)), 3, "%s: all functional semantic nodes should be audited" % file_name)
