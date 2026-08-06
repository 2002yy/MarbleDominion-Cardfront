extends RefCounted
class_name CardfrontArenaBuilder

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const CardfrontArenaPresentationLayerScript = preload("res://scripts/cardfront/arena/CardfrontArenaPresentationLayer.gd")
const CardfrontOrthographicArenaViewScript = preload("res://scripts/cardfront/arena/CardfrontOrthographicArenaView.gd")
const CardfrontCommandChamberViewScript = preload("res://scripts/cardfront/arena/CardfrontCommandChamberView.gd")
const CardfrontDirectionControllerScript = preload("res://scripts/cardfront/arena/CardfrontDirectionController.gd")
const CardfrontAimGuideLayerScript = preload("res://scripts/cardfront/arena/CardfrontAimGuideLayer.gd")
const CardfrontHeroRegistryScript = preload("res://scripts/cardfront/heroes/CardfrontHeroRegistry.gd")


static func create_presentation(game_layer: Node, battlefield, layout: Dictionary) -> Dictionary:
	if game_layer == null or not is_instance_valid(game_layer):
		return {"configured": false, "reason": "missing_game_layer"}
	var layer = CardfrontArenaPresentationLayerScript.new()
	if not layer.setup(battlefield, layout):
		layer.free()
		return {"configured": false, "reason": "invalid_arena_layout"}
	game_layer.add_child(layer)
	return {"configured": true, "arena_presentation_layer": layer}


static func create_orthographic_view(game_layer: Node, battlefield, region_map, bullet_pool, turrets: Dictionary, layout: Dictionary) -> Dictionary:
	if game_layer == null or not is_instance_valid(game_layer):
		return {"configured": false, "reason": "missing_game_layer"}
	var view = CardfrontOrthographicArenaViewScript.new()
	if not view.setup(battlefield, region_map, bullet_pool, turrets, layout):
		view.free()
		return {"configured": false, "reason": "orthographic_view_setup_failed"}
	game_layer.add_child(view)
	return {"configured": true, "orthographic_arena_view": view}


static func create_command_chambers(game_layer: Node, turrets: Dictionary, hero_assignments: Dictionary = {}) -> Dictionary:
	if game_layer == null or not is_instance_valid(game_layer):
		return {"configured": false, "reason": "missing_game_layer"}
	var command_chambers: Dictionary = {}
	for owner_id in CardfrontRulesScript.get_duel_factions():
		var turret = turrets.get(owner_id, null)
		var fallback_hero_id: String = (
			CardfrontHeroRegistryScript.DEFAULT_PLAYER_HERO_ID
			if int(owner_id) == CardfrontRulesScript.PLAYER_FACTION
			else CardfrontHeroRegistryScript.DEFAULT_AI_HERO_ID
		)
		var hero_id: String = CardfrontHeroRegistryScript.sanitize_hero_id(
			str(hero_assignments.get(int(owner_id), fallback_hero_id)),
			fallback_hero_id
		)
		var hero_definition: Dictionary = CardfrontHeroRegistryScript.get_definition(hero_id)
		if turret != null and is_instance_valid(turret) and turret.has_method("configure_health_pool"):
			turret.configure_health_pool(
				int(hero_definition.get("command_chamber_health", 40)),
				true
			)
		var view = CardfrontCommandChamberViewScript.new()
		if not view.setup(int(owner_id), turret, int(owner_id) == CardfrontRulesScript.PLAYER_FACTION):
			view.free()
			return {"configured": false, "reason": "missing_turret:%s" % str(owner_id)}
		view.name = "CommandChamber_%s" % str(owner_id)
		game_layer.add_child(view)
		command_chambers[int(owner_id)] = view
	return {"configured": true, "command_chambers": command_chambers}


static func create_direction_control(game_layer: Node, battlefield, turrets: Dictionary, fire_director, layout: Dictionary) -> Dictionary:
	if game_layer == null or not is_instance_valid(game_layer):
		return {"configured": false, "reason": "missing_game_layer"}
	var player_id: int = CardfrontRulesScript.PLAYER_FACTION
	var player_turret = turrets.get(player_id, null)
	var center_angles: Dictionary = layout.get("turret_center_angles", {})
	var center_angle: float = float(center_angles.get(player_id, -PI * 0.5))
	var controller = CardfrontDirectionControllerScript.new()
	if not controller.setup(player_id, player_turret, fire_director, center_angle):
		controller.free()
		return {"configured": false, "reason": "missing_player_turret"}
	if battlefield != null and battlefield.get("grid_extent") != null:
		controller.set_grid_extent(battlefield.grid_extent)
	game_layer.add_child(controller)

	var guide = CardfrontAimGuideLayerScript.new()
	if not guide.setup(player_turret, battlefield):
		controller.queue_free()
		guide.free()
		return {"configured": false, "reason": "missing_aim_guide_refs"}
	game_layer.add_child(guide)
	controller.angle_changed.connect(Callable(guide, "set_angle"))
	guide.set_angle(player_id, controller.get_current_angle(), controller.get_offset_degrees())
	return {
		"configured": true,
		"direction_controller": controller,
		"aim_guide_layer": guide,
	}
