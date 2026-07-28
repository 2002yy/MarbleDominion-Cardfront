extends SceneTree

const EntityRegistryScript = preload(
	"res://scripts/cardfront/entities/CardfrontBattlefieldEntityRegistry.gd"
)
const PresentationLayerScript = preload(
	"res://scripts/cardfront/entities/CardfrontEntityPresentationLayer.gd"
)


class PreviewBattlefield:
	extends Node2D

	var cell_size: int = 80
	var grid_size: int = 10

	func is_inside(cell: Vector2i) -> bool:
		return cell.x >= 0 and cell.y >= 0 and cell.x < grid_size and cell.y < 7

	func _draw() -> void:
		for x in range(grid_size):
			for y in range(7):
				var color := Color("#b9d96b") if (x + y) % 2 == 0 else Color("#a9cc5d")
				if y <= 2:
					color = color.lerp(Color("#dc6675"), 0.14)
				elif y >= 4:
					color = color.lerp(Color("#55aee8"), 0.16)
				draw_rect(
					Rect2(Vector2(x, y) * cell_size, Vector2.ONE * cell_size),
					color,
					true
				)
		draw_rect(
			Rect2(Vector2(0, 3) * cell_size, Vector2(grid_size, 1) * cell_size),
			Color("#62bfd0"),
			true
		)
		for x in range(grid_size + 1):
			draw_line(
				Vector2(x * cell_size, 0),
				Vector2(x * cell_size, 7 * cell_size),
				Color(0.12, 0.20, 0.16, 0.10),
				1.0
			)
		for y in range(8):
			draw_line(
				Vector2(0, y * cell_size),
				Vector2(grid_size * cell_size, y * cell_size),
				Color(0.12, 0.20, 0.16, 0.10),
				1.0
			)


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	root.size = Vector2i(1120, 720)
	var background := ColorRect.new()
	background.color = Color("#e9f3d1")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)

	var battlefield := PreviewBattlefield.new()
	battlefield.position = Vector2(160, 82)
	root.add_child(battlefield)

	var registry = EntityRegistryScript.new()
	var repair = registry.spawn_creature(
		"preview_repair", "repair_unit", 0, Vector2i(1, 4), 1, "normal", 1, "repair", 3
	)
	var guard = registry.spawn_creature(
		"preview_guard", "armored_guard", 0, Vector2i(3, 4), 4, "armored", 1, "guard"
	)
	var sapper = registry.spawn_creature(
		"preview_sapper", "sapper_unit", 1, Vector2i(6, 2), 3, "armored", 1, "sapper"
	)
	var scout = registry.spawn_creature(
		"preview_scout", "scout_unit", 1, Vector2i(8, 2), 1, "normal", 1, "scout"
	)
	registry.register_building_slot("preview_beacon_slot", Vector2i(1, 1))
	registry.register_building_slot("preview_interceptor_slot", Vector2i(8, 5))
	var beacon = registry.spawn_defense_tower(
		"preview_beacon", "fire_control_beacon", 1, "preview_beacon_slot", 5
	)
	var interceptor = registry.spawn_defense_tower(
		"preview_interceptor", "interceptor_tower", 0, "preview_interceptor_slot", 4
	)
	interceptor.configure_interceptor(3)

	var layer = PresentationLayerScript.new()
	battlefield.add_child(layer)
	layer.setup(battlefield, registry, null)
	await process_frame
	layer._actors_by_entity_id[repair.entity_id].play_action("repair")
	layer._actors_by_entity_id[guard.entity_id].play_action("block")
	layer._actors_by_entity_id[sapper.entity_id].play_action("attack")
	layer._actors_by_entity_id[scout.entity_id].play_action("guide")
	layer._tower_actors_by_entity_id[beacon.entity_id].play_guidance()
	layer._tower_actors_by_entity_id[interceptor.entity_id].play_intercept()
	await create_timer(0.16).timeout
	await process_frame

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
	var save_error := root.get_texture().get_image().save_png(
		ProjectSettings.globalize_path("res://artifacts/cardfront-entity-presentation.png")
	)
	quit(0 if save_error == OK else 1)
