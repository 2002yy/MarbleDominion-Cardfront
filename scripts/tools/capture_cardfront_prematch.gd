extends SceneTree

const PrematchScene = preload("res://scenes/ui/cardfront/CardfrontPrematchScreen.tscn")


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	root.size = Vector2i(1120, 720)
	var screen = PrematchScene.instantiate()
	root.add_child(screen)
	screen.setup("default_duel", "balanced_commander")
	await process_frame
	await process_frame
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
	var map_error: Error = root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://artifacts/cardfront-prematch-map.png"))
	screen.advance_for_test()
	await process_frame
	await process_frame
	var hero_error: Error = root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://artifacts/cardfront-prematch-hero.png"))
	screen.choose_hero_for_test("rapid_gunner")
	screen.advance_for_test()
	await process_frame
	await process_frame
	var reveal_error: Error = root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://artifacts/cardfront-prematch-reveal.png"))
	quit(0 if map_error == OK and hero_error == OK and reveal_error == OK else 1)
