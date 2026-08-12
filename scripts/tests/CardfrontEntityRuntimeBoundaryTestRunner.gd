extends SceneTree

const RuntimeScript = preload(
	"res://scripts/cardfront/entities/CardfrontBattlefieldEntityRuntime.gd"
)
const PresentationLayerScript = preload(
	"res://scripts/cardfront/entities/CardfrontEntityPresentationLayer.gd"
)
const DebugLayerScript = preload(
	"res://scripts/cardfront/entities/CardfrontEntityDebugLayer.gd"
)

const RUNTIME_PATH := "res://scripts/cardfront/entities/CardfrontBattlefieldEntityRuntime.gd"
const PRESENTATION_PATH := "res://scripts/cardfront/entities/CardfrontEntityPresentationLayer.gd"
const DEBUG_PATH := "res://scripts/cardfront/entities/CardfrontEntityDebugLayer.gd"
const AUTHORITATIVE_CREATURE_COORDINATOR_PATH := "res://scripts/cardfront/entities/CardfrontAuthoritativeCreatureActionCoordinator.gd"
const AUTOMATIC_SPAWN_COORDINATOR_PATH := "res://scripts/cardfront/entities/CardfrontAutomaticSpawnCoordinator.gd"

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	_test_coordinator_boundary()
	_test_deployment_boundary()
	_test_presentation_boundary()
	_test_debug_boundary()
	_test_runtime_module_assembly()
	_assert.report("[CardfrontEntityRuntimeBoundaryTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_coordinator_boundary() -> void:
	var source := _read_source(RUNTIME_PATH)
	_assert.that(not source.is_empty(), "entity boundary: runtime source is readable")
	_assert.that(
		source.split("\n").size() <= 650,
		"entity boundary: main coordinator remains at or below 650 lines"
	)
	for module_name in [
		"CardfrontEntityProjectileBridge.gd",
		"CardfrontTowerRuntime.gd",
		"CardfrontAuthoritativeCreatureActionCoordinator.gd",
		"CardfrontAutomaticSpawnCoordinator.gd",
	]:
		_assert.that(
			source.contains(module_name),
			"entity boundary: runtime assembles %s" % module_name
		)


func _test_deployment_boundary() -> void:
	var runtime_source := _read_source(RUNTIME_PATH)
	var creature_source := _read_source(AUTHORITATIVE_CREATURE_COORDINATOR_PATH)
	var automatic_spawn_source := _read_source(AUTOMATIC_SPAWN_COORDINATOR_PATH)
	_assert.that(
		not runtime_source.contains("DeploymentRules.gd"),
		"entity boundary: runtime does not directly depend on DeploymentRules"
	)
	_assert.that(
		creature_source.contains("CardfrontCreatureActionCoordinator.gd"),
		"entity boundary: authoritative creature coordinator preserves base creature behavior"
	)
	_assert.that(
		automatic_spawn_source.contains("DeploymentPlacementResolver.gd"),
		"entity boundary: automatic spawn delegates placement to DeploymentPlacementResolver"
	)
	_assert.that(
		not automatic_spawn_source.contains("DeploymentRules.gd"),
		"entity boundary: automatic spawn does not create a second direct DeploymentRules consumer"
	)


func _test_presentation_boundary() -> void:
	var source := _read_source(PRESENTATION_PATH)
	_assert.that(
		source.contains("CardfrontEntityVisualActor.gd"),
		"entity boundary: presentation layer owns animated actors"
	)
	_assert.that(
		source.contains("_actors_by_entity_id"),
		"entity boundary: presentation layer owns actor lifecycle"
	)
	_assert.that(
		source.contains("entity_contact_resolved"),
		"entity boundary: presentation layer receives combat feedback"
	)


func _test_debug_boundary() -> void:
	var source := _read_source(DEBUG_PATH)
	for forbidden in [
		"CardfrontEntityVisualActor.gd",
		"CardfrontEntityVisualRegistry.gd",
		"AnimatedSprite2D",
		"_actors_by_entity_id",
	]:
		_assert.that(
			not source.contains(forbidden),
			"entity boundary: debug layer excludes %s" % forbidden
		)
	for debug_feature in [
		"show_building_slots",
		"show_collision_shapes",
		"show_health_bars",
	]:
		_assert.that(
			source.contains(debug_feature),
			"entity boundary: debug layer retains %s" % debug_feature
		)


func _test_runtime_module_assembly() -> void:
	var runtime = RuntimeScript.new()
	_assert.that(
		runtime._projectile_bridge != null,
		"entity boundary: projectile bridge is assembled"
	)
	_assert.that(runtime._tower_runtime != null, "entity boundary: tower runtime is assembled")
	_assert.that(
		runtime._creature_action_coordinator != null,
		"entity boundary: creature coordinator is assembled"
	)
	_assert.that(
		runtime._automatic_spawn_coordinator != null,
		"entity boundary: automatic spawn coordinator is assembled"
	)
	var presentation = PresentationLayerScript.new()
	var debug = DebugLayerScript.new()
	_assert.that(
		presentation.get_script() != debug.get_script(),
		"entity boundary: presentation and debug layers are distinct"
	)
	runtime.free()
	presentation.free()
	debug.free()


func _read_source(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()
