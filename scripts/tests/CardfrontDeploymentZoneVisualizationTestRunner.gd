extends SceneTree

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const CardTargetTypeScript = preload("res://scripts/cardfront/cards/CardTargetType.gd")
const DefaultMapScript = preload("res://scripts/cardfront/maps/maps/DefaultDuelMap.gd")
const AuthorityScript = preload("res://scripts/cardfront/support/CardfrontSupportDeploymentAuthority.gd")
const PreviewScript = preload("res://scripts/cardfront/ui/CardfrontTargetPreviewLayer.gd")
const ZoneLayerScript = preload(
	"res://scripts/cardfront/support/presentation/CardfrontDeploymentZoneLayer3D.gd"
)

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontDeploymentZoneVisualizationTest] Checking DeploymentRules result projection")
	await process_frame

	var battlefield := Battlefield.new()
	battlefield.configure_extent(Vector2i(40, 50))
	get_root().add_child(battlefield)
	await process_frame
	var map_definition: Dictionary = DefaultMapScript.make(Vector2i(40, 50))
	var authority = AuthorityScript.new()
	_assert.that(authority.setup(map_definition), "deployment zone: real map authority configures")
	var preview = PreviewScript.new()
	preview.setup(battlefield, null, GameConfig.GAME_MODE_CARDFRONT)
	preview.configure_deployment_authority(
		Callable(authority, "deployment_context"),
		Callable(authority, "deployment_revision")
	)
	var zone = ZoneLayerScript.new()
	_assert.that(zone.setup(Callable(self, "_cell_to_world"), Vector2(1.18, 1.0)), "deployment zone: 3D visualizer configures")
	preview.deployment_zone_changed.connect(Callable(zone, "show_cells"))

	_assert.that(not zone.visible, "deployment zone: hidden by default")
	_assert.eq(zone.get_visible_cells_for_test(), [], "deployment zone: default cell cache is empty")
	_assert.that(not zone.has_collision_authority(), "deployment zone: visualizer has no collision authority")

	var core_context: Dictionary = authority.deployment_context(RulesScript.PLAYER_FACTION)
	for raw_cell in (core_context.get("core_source", {}) as Dictionary).get("candidate_cells", []) as Array:
		var cell: Vector2i = raw_cell as Vector2i
		battlefield.owners[cell.x][cell.y] = RulesScript.PLAYER_FACTION
	var frontline_card := {
		"target_type": CardTargetTypeScript.FRONTLINE_DEPLOYMENT,
		"params": {},
	}
	preview.show_for_card(9001, frontline_card)
	var legal_cells: Array[Vector2i] = zone.get_visible_cells_for_test()
	_assert.that(not legal_cells.is_empty(), "deployment zone: frontline targeting projects current allowed results")
	_assert.eq(legal_cells.size(), preview._valid_cells.size(), "deployment zone: visualizer consumes every preview result")
	_assert.that(legal_cells.all(func(cell: Vector2i) -> bool: return cell in preview._valid_cells), "deployment zone: visualizer adds no independently computed cells")
	_assert.that(zone.visible, "deployment zone: legal frontline targeting reveals the visual")
	_assert.eq(zone.last_revision, authority.deployment_revision(), "deployment zone: visual binds the evaluated authority revision")
	_assert.eq(zone.multimesh.visible_instance_count, legal_cells.size(), "deployment zone: one translucent marker per allowed result")

	preview.show_for_card(9002, {"target_type": CardTargetTypeScript.OWNED_BORDER, "params": {}})
	_assert.that(not zone.visible, "deployment zone: non-frontline card hides Support deployment zone")
	_assert.eq(zone.get_visible_cells_for_test(), [], "deployment zone: non-frontline selection clears cells")

	preview.show_for_card(9001, frontline_card)
	_assert.that(zone.visible, "deployment zone: frontline re-selection restores current result")
	preview.clear_preview()
	_assert.that(not zone.visible, "deployment zone: cancel/clear hides the visual")
	_assert.eq(zone.last_revision, -1, "deployment zone: clear drops the authority revision")

	var visual_source: String = FileAccess.get_file_as_string(
		"res://scripts/cardfront/support/presentation/CardfrontDeploymentZoneLayer3D.gd"
	)
	_assert.that(not visual_source.contains("DeploymentRules"), "deployment zone: visualizer cannot become legality authority")
	_assert.that(not visual_source.contains("deployment_context"), "deployment zone: visualizer cannot query Support runtime context")

	TestFixtures.cleanup_node(preview)
	TestFixtures.cleanup_node(zone)
	TestFixtures.cleanup_node(battlefield)
	await process_frame
	_assert.report("[CardfrontDeploymentZoneVisualizationTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _cell_to_world(cell: Vector2i, height: float) -> Vector3:
	return Vector3(float(cell.x), height, float(cell.y))
