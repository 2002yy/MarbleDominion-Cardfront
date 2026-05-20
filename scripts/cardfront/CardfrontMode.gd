extends RefCounted
class_name CardfrontMode

const Rules = preload("res://scripts/cardfront/CardfrontRules.gd")
const BattlefieldInitializer = preload("res://scripts/cardfront/CardfrontBattlefieldInitializer.gd")
const RegionMapScript = preload("res://scripts/cardfront/regions/RegionMap.gd")
const RegionOverlayLayerScript = preload("res://scripts/cardfront/regions/RegionOverlayLayer.gd")
const CardfrontResourceStateScript = preload("res://scripts/cardfront/economy/CardfrontResourceState.gd")
const EconomyTickSystemScript = preload("res://scripts/cardfront/economy/EconomyTickSystem.gd")
const CardfrontEconomyDebugPanelScript = preload("res://scripts/cardfront/economy/CardfrontEconomyDebugPanel.gd")
const RegionMoraleSystemScript = preload("res://scripts/cardfront/morale/RegionMoraleSystem.gd")
const FortifyLayerScript = preload("res://scripts/cardfront/fortify/FortifyLayer.gd")
const FortifyOverlayLayerScript = preload("res://scripts/cardfront/fortify/FortifyOverlayLayer.gd")
const CardfrontCaptureInterceptorScript = preload("res://scripts/cardfront/fortify/CardfrontCaptureInterceptor.gd")
const CardPlaySystemScript = preload("res://scripts/cardfront/cards/CardPlaySystem.gd")
const CardfrontTargetBiasSystemScript = preload("res://scripts/cardfront/effects/CardfrontTargetBiasSystem.gd")
const CardfrontFireDirectorScript = preload("res://scripts/cardfront/fire/CardfrontFireDirector.gd")
const CardfrontShotGuideLayerScript = preload("res://scripts/cardfront/effects/CardfrontShotGuideLayer.gd")
const DeviceLayerScript = preload("res://scripts/cardfront/devices/DeviceLayer.gd")
const AbsorberCoreEffectSystemScript = preload("res://scripts/cardfront/devices/effects/AbsorberCoreEffectSystem.gd")
const EngineerBotEffectSystemScript = preload("res://scripts/cardfront/devices/effects/EngineerBotEffectSystem.gd")
const DurablePioneerBeaconEffectSystemScript = preload("res://scripts/cardfront/devices/effects/DurablePioneerBeaconEffectSystem.gd")
const CardfrontDeviceOverlayLayerScript = preload("res://scripts/cardfront/devices/CardfrontDeviceOverlayLayer.gd")
const CardfrontVfxLayerScript = preload("res://scripts/cardfront/vfx/CardfrontVfxLayer.gd")
const CardfrontDebugActionPanelScript = preload("res://scripts/cardfront/debug/CardfrontDebugActionPanel.gd")

const FIRE_STATUS_TEXT: String = "自动射击中 / 卡牌改写射击"


static func is_selected(mode_name: String) -> bool:
	return Rules.is_cardfront_mode(mode_name)


static func is_active() -> bool:
	return is_selected(GameConfig.get_game_mode_name())


static func uses_control_chambers() -> bool:
	return false


static func get_active_factions() -> Array:
	return Rules.get_duel_factions()


static func get_match_duration_seconds() -> float:
	return Rules.MATCH_DURATION_SECONDS


static func configure_battlefield(battlefield) -> Dictionary:
	var result: Dictionary = BattlefieldInitializer.configure_duel(battlefield)
	if not bool(result.get("configured", false)):
		return result
	result.merge({
		"configured": true,
		"mode_name": GameConfig.GAME_MODE_CARDFRONT,
		"active_factions": get_active_factions(),
		"match_duration_seconds": get_match_duration_seconds(),
		"capture_target_percent": Rules.CAPTURE_TARGET_PERCENT,
	}, true)
	return result


static func create_regions(game_layer: Node, battlefield) -> Dictionary:
	if game_layer == null or not is_instance_valid(game_layer):
		return {"configured": false, "reason": "missing_game_layer"}
	if battlefield == null or not is_instance_valid(battlefield):
		return {"configured": false, "reason": "missing_battlefield"}

	var region_map = RegionMapScript.new()
	region_map.configure(int(battlefield.grid_size))
	region_map.generate_default_layout()

	var overlay = RegionOverlayLayerScript.new()
	overlay.setup(region_map, battlefield, GameConfig.GAME_MODE_CARDFRONT)
	game_layer.add_child(overlay)

	return {
		"configured": true,
		"region_map": region_map,
		"region_overlay": overlay,
	}


static func create_economy(game_layer: Node, battlefield, region_map) -> Dictionary:
	if game_layer == null or not is_instance_valid(game_layer):
		return {"configured": false, "reason": "missing_game_layer"}
	if battlefield == null or not is_instance_valid(battlefield):
		return {"configured": false, "reason": "missing_battlefield"}
	if region_map == null:
		return {"configured": false, "reason": "missing_region_map"}

	var resource_states: Dictionary = {
		Rules.PLAYER_FACTION: CardfrontResourceStateScript.new(),
		Rules.AI_FACTION: CardfrontResourceStateScript.new(),
	}
	var economy_system = EconomyTickSystemScript.new()
	economy_system.setup(region_map, battlefield, resource_states)
	game_layer.add_child(economy_system)
	var debug_panel = CardfrontEconomyDebugPanelScript.new()
	debug_panel.setup(region_map, battlefield, economy_system, resource_states, GameConfig.GAME_MODE_CARDFRONT)
	game_layer.add_child(debug_panel)

	return {
		"configured": true,
		"economy_system": economy_system,
		"resource_states": resource_states,
		"economy_debug_panel": debug_panel,
	}


static func create_morale(game_layer: Node, battlefield, region_map) -> Dictionary:
	if game_layer == null or not is_instance_valid(game_layer):
		return {"configured": false, "reason": "missing_game_layer"}
	if battlefield == null or not is_instance_valid(battlefield):
		return {"configured": false, "reason": "missing_battlefield"}
	if region_map == null:
		return {"configured": false, "reason": "missing_region_map"}

	var morale_system = RegionMoraleSystemScript.new()
	morale_system.setup(region_map, battlefield)
	game_layer.add_child(morale_system)

	return {
		"configured": true,
		"morale_system": morale_system,
	}


static func create_fortify(game_layer: Node, battlefield, region_map) -> Dictionary:
	if game_layer == null or not is_instance_valid(game_layer):
		return {"configured": false, "reason": "missing_game_layer"}
	if battlefield == null or not is_instance_valid(battlefield):
		return {"configured": false, "reason": "missing_battlefield"}
	if region_map == null:
		return {"configured": false, "reason": "missing_region_map"}

	var fortify_layer = FortifyLayerScript.new()
	fortify_layer.configure(int(battlefield.grid_size))

	var overlay = FortifyOverlayLayerScript.new()
	overlay.setup(fortify_layer, battlefield, GameConfig.GAME_MODE_CARDFRONT)
	game_layer.add_child(overlay)
	fortify_layer.overlay_dirty_callback = Callable(overlay, "mark_dirty")

	var interceptor = CardfrontCaptureInterceptorScript.new()
	interceptor.setup(fortify_layer)
	battlefield.capture_interceptor = interceptor

	return {
		"configured": true,
		"fortify_layer": fortify_layer,
		"fortify_overlay": overlay,
		"capture_interceptor": interceptor,
	}


static func create_target_bias(game_layer: Node, region_map) -> Dictionary:
	if game_layer == null or not is_instance_valid(game_layer):
		return {"configured": false, "reason": "missing_game_layer"}
	if region_map == null:
		return {"configured": false, "reason": "missing_region_map"}

	var target_bias_system = CardfrontTargetBiasSystemScript.new()
	target_bias_system.setup(region_map)
	game_layer.add_child(target_bias_system)

	return {
		"configured": true,
		"target_bias_system": target_bias_system,
	}


static func create_card_system(resource_states: Dictionary, region_map, battlefield, fortify_layer, morale_system, region_overlay, target_bias_system = null) -> Dictionary:
	var card_system = CardPlaySystemScript.new()
	card_system.setup(resource_states, region_map, battlefield, fortify_layer, morale_system, region_overlay, target_bias_system)
	return {
		"configured": true,
		"card_system": card_system,
	}


static func create_fire_director(game_layer: Node, region_map, battlefield, turrets: Dictionary, target_bias_system = null) -> Dictionary:
	if game_layer == null or not is_instance_valid(game_layer):
		return {"configured": false, "reason": "missing_game_layer"}
	if region_map == null:
		return {"configured": false, "reason": "missing_region_map"}
	if battlefield == null or not is_instance_valid(battlefield):
		return {"configured": false, "reason": "missing_battlefield"}
	if turrets.is_empty():
		return {"configured": false, "reason": "missing_turrets"}

	var fire_director = CardfrontFireDirectorScript.new()
	fire_director.setup(region_map, battlefield, turrets, target_bias_system, get_active_factions())
	game_layer.add_child(fire_director)

	return {
		"configured": true,
		"fire_director": fire_director,
	}


static func create_shot_guide(game_layer: Node, battlefield, target_bias_system, turrets: Dictionary, region_map) -> Dictionary:
	if game_layer == null or not is_instance_valid(game_layer):
		return {"configured": false, "reason": "missing_game_layer"}
	if battlefield == null or not is_instance_valid(battlefield):
		return {"configured": false, "reason": "missing_battlefield"}
	if target_bias_system == null:
		return {"configured": false, "reason": "missing_target_bias_system"}

	var guide_layer = CardfrontShotGuideLayerScript.new()
	guide_layer.setup(battlefield, target_bias_system, turrets, region_map)
	game_layer.add_child(guide_layer)

	return {
		"configured": true,
		"shot_guide_layer": guide_layer,
	}


static func create_device_layer(game_layer: Node, battlefield, region_map) -> Dictionary:
	if game_layer == null or not is_instance_valid(game_layer):
		return {"configured": false, "reason": "missing_game_layer"}
	if battlefield == null or not is_instance_valid(battlefield):
		return {"configured": false, "reason": "missing_battlefield"}
	if region_map == null:
		return {"configured": false, "reason": "missing_region_map"}

	var device_layer = DeviceLayerScript.new()
	device_layer.setup(battlefield, region_map)
	game_layer.add_child(device_layer)

	var device_overlay = CardfrontDeviceOverlayLayerScript.new()
	device_overlay.setup(device_layer, battlefield, GameConfig.GAME_MODE_CARDFRONT)
	game_layer.add_child(device_overlay)

	return {
		"configured": true,
		"device_layer": device_layer,
		"device_overlay": device_overlay,
	}


static func create_absorber_core_effect_system(game_layer: Node, device_layer, bullet_pool, resource_states: Dictionary, battlefield, vfx_layer = null) -> Dictionary:
	if game_layer == null or not is_instance_valid(game_layer):
		return {"configured": false, "reason": "missing_game_layer"}
	if device_layer == null:
		return {"configured": false, "reason": "missing_device_layer"}
	if bullet_pool == null:
		return {"configured": false, "reason": "missing_bullet_pool"}

	var absorber_system = AbsorberCoreEffectSystemScript.new()
	absorber_system.setup(device_layer, bullet_pool, resource_states, battlefield, vfx_layer)
	game_layer.add_child(absorber_system)

	return {
		"configured": true,
		"absorber_core_effect_system": absorber_system,
	}


static func create_engineer_bot_effect_system(game_layer: Node, device_layer, fortify_layer, battlefield, region_map, vfx_layer = null) -> Dictionary:
	if game_layer == null or not is_instance_valid(game_layer):
		return {"configured": false, "reason": "missing_game_layer"}
	if device_layer == null:
		return {"configured": false, "reason": "missing_device_layer"}
	if fortify_layer == null:
		return {"configured": false, "reason": "missing_fortify_layer"}

	var engineer_system = EngineerBotEffectSystemScript.new()
	engineer_system.setup(device_layer, fortify_layer, battlefield, region_map, vfx_layer)
	game_layer.add_child(engineer_system)

	return {
		"configured": true,
		"engineer_bot_effect_system": engineer_system,
	}


static func create_durable_pioneer_beacon_effect_system(game_layer: Node, device_layer, battlefield, region_map, vfx_layer = null) -> Dictionary:
	if game_layer == null or not is_instance_valid(game_layer):
		return {"configured": false, "reason": "missing_game_layer"}
	if device_layer == null:
		return {"configured": false, "reason": "missing_device_layer"}

	var beacon_system = DurablePioneerBeaconEffectSystemScript.new()
	beacon_system.setup(device_layer, battlefield, region_map, vfx_layer)
	game_layer.add_child(beacon_system)

	return {
		"configured": true,
		"durable_pioneer_beacon_effect_system": beacon_system,
	}


static func create_vfx_layer(game_layer: Node, battlefield, region_map) -> Dictionary:
	if game_layer == null or not is_instance_valid(game_layer):
		return {"configured": false, "reason": "missing_game_layer"}
	if battlefield == null or not is_instance_valid(battlefield):
		return {"configured": false, "reason": "missing_battlefield"}

	var vfx_layer = CardfrontVfxLayerScript.new()
	vfx_layer.setup(battlefield, region_map, GameConfig.GAME_MODE_CARDFRONT)
	game_layer.add_child(vfx_layer)

	return {
		"configured": true,
		"vfx_layer": vfx_layer,
	}


static func create_debug_action_panel(game_layer: Node, device_layer, card_system, battlefield, region_map) -> Dictionary:
	if game_layer == null or not is_instance_valid(game_layer):
		return {"configured": false, "reason": "missing_game_layer"}

	var panel = CardfrontDebugActionPanelScript.new()
	panel.setup(device_layer, card_system, battlefield, region_map, GameConfig.GAME_MODE_CARDFRONT)
	game_layer.add_child(panel)

	return {
		"configured": true,
		"debug_action_panel": panel,
	}


static func configure_runtime_hud(hud_nodes: Dictionary) -> void:
	var event_label = hud_nodes.get("event_label", null)
	if event_label == null or not is_instance_valid(event_label):
		return
	event_label.text = FIRE_STATUS_TEXT
	event_label.tooltip_text = "Cardfront FireDirector active; cards can bias target selection."
	event_label.add_theme_color_override("font_color", Color(0.62, 0.90, 1.0))
	event_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	var fps_label = hud_nodes.get("fps_label", null)
	if fps_label != null and is_instance_valid(fps_label):
		fps_label.visible = true

	RuntimeHudController.set_performance_visible(true)


static func restore_ballwar_hud(hud_nodes: Dictionary) -> void:
	var fps_label = hud_nodes.get("fps_label", null)
	if fps_label != null and is_instance_valid(fps_label):
		fps_label.visible = true
	RuntimeHudController.set_performance_visible(true)
