extends RefCounted
class_name CardfrontRuntimeBuilder

const Rules = preload("res://scripts/cardfront/CardfrontRules.gd")
const RegionMapScript = preload("res://scripts/cardfront/regions/RegionMap.gd")
const RegionOverlayLayerScript = preload("res://scripts/cardfront/regions/RegionOverlayLayer.gd")
const RegionControlBlockLayerScript = preload("res://scripts/cardfront/regions/RegionControlBlockLayer.gd")
const CardfrontStrongholdSystemScript = preload("res://scripts/cardfront/strongholds/CardfrontStrongholdSystem.gd")
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
const CardfrontTargetPreviewLayerScript = preload("res://scripts/cardfront/ui/CardfrontTargetPreviewLayer.gd")
const CardfrontArenaBuilderScript = preload("res://scripts/cardfront/arena/CardfrontArenaBuilder.gd")
const CardfrontPresentationModeControllerScript = preload("res://scripts/cardfront/arena/CardfrontPresentationModeController.gd")
const CardfrontRoundDirectorScript = preload("res://scripts/cardfront/run/CardfrontRoundDirector.gd")
const CardfrontTerritoryDefenseSystemScript = preload("res://scripts/cardfront/defense/CardfrontTerritoryDefenseSystem.gd")
const CardfrontHeroRegistryScript = preload("res://scripts/cardfront/heroes/CardfrontHeroRegistry.gd")
const CardfrontGateConnectivitySystemScript = preload("res://scripts/cardfront/gates/CardfrontGateConnectivitySystem.gd")
const SystemRegistryScript = preload("res://scripts/cardfront/runtime/CardfrontSystemRegistry.gd")

var registry = SystemRegistryScript.new()


func clear() -> void:
	registry.clear()


func build_core_systems(game_layer: Node, runtime, yield_callback: Callable = Callable()) -> Dictionary:
	clear()
	if runtime == null:
		return _failure("core", "missing_runtime")
	_clear_core_refs(runtime)

	if not _record_or_fail("regions", create_regions(game_layer, runtime.battlefield, str(runtime.current_config.get("map_id", "default_duel"))), runtime):
		return _build_result(false)
	if not _record_or_fail("region_control_blocks", create_region_control_blocks(game_layer, runtime.region_map, runtime.battlefield), runtime):
		return _build_result(false)
	if not _record_or_fail("economy", create_economy(game_layer, runtime.battlefield, runtime.region_map), runtime):
		return _build_result(false)
	_connect_yield_tick(runtime, yield_callback)
	if not _record_or_fail("morale", create_morale(game_layer, runtime.battlefield, runtime.region_map), runtime):
		return _build_result(false)
	if not _record_or_fail("fortify", create_fortify(game_layer, runtime.battlefield, runtime.region_map), runtime):
		return _build_result(false)
	if not _record_or_fail("target_bias", create_target_bias(game_layer, runtime.region_map), runtime):
		return _build_result(false)
	if not _record_or_fail("card_system", create_card_system(runtime.resource_states, runtime.region_map, runtime.battlefield, runtime.fortify_layer, runtime.morale_system, runtime.region_overlay, runtime.target_bias_system), runtime):
		return _build_result(false)
	return _build_result(true)


func build_live_core_systems(game_layer: Node, runtime) -> Dictionary:
	clear()
	if runtime == null:
		return _failure("live_core", "missing_runtime")
	_clear_core_refs(runtime)

	if not _record_or_fail("regions", create_regions(game_layer, runtime.battlefield, str(runtime.current_config.get("map_id", "default_duel"))), runtime):
		return _build_result(false)
	if not _record_or_fail("region_control_blocks", create_region_control_blocks(game_layer, runtime.region_map, runtime.battlefield), runtime):
		return _build_result(false)
	if not _record_or_fail("strongholds", create_stronghold_system(game_layer, runtime.region_map, runtime.battlefield), runtime):
		return _build_result(false)
	if not _record_or_fail("fortify", create_fortify(game_layer, runtime.battlefield, runtime.region_map), runtime):
		return _build_result(false)
	return _build_result(true)


func build_world_layers(game_layer: Node, runtime) -> Dictionary:
	clear()
	if runtime == null:
		return _failure("world_layers", "missing_runtime")
	_clear_world_layer_refs(runtime)
	runtime.hero_assignments = CardfrontHeroRegistryScript.assignments_from_config(runtime.current_config)

	if not _record_or_fail("arena_presentation", CardfrontArenaBuilderScript.create_presentation(game_layer, runtime.battlefield, runtime.current_layout), runtime):
		return _build_result(false)
	if not _record_or_fail("command_chambers", CardfrontArenaBuilderScript.create_command_chambers(game_layer, runtime.turrets, runtime.hero_assignments), runtime):
		return _build_result(false)
	if not _record_or_fail("fire_director", create_fire_director(game_layer, runtime.region_map, runtime.battlefield, runtime.turrets, runtime.target_bias_system), runtime):
		return _build_result(false)
	if not _record_or_fail("direction_control", CardfrontArenaBuilderScript.create_direction_control(game_layer, runtime.battlefield, runtime.turrets, runtime.fire_director, runtime.current_layout), runtime):
		return _build_result(false)
	if not _record_or_fail("round_director", create_round_director(game_layer, runtime.fire_director, runtime.turrets, runtime.direction_controller, runtime.stronghold_system, runtime.hero_assignments), runtime):
		return _build_result(false)
	if not _record_or_fail("shot_guide", create_shot_guide(game_layer, runtime.battlefield, runtime.target_bias_system, runtime.turrets, runtime.region_map), runtime):
		return _build_result(false)
	if not _record_or_fail("device_layer", create_device_layer(game_layer, runtime.battlefield, runtime.region_map), runtime):
		return _build_result(false)
	if not _record_or_fail("target_preview", create_target_preview_layer(game_layer, runtime.battlefield, runtime.region_map), runtime):
		return _build_result(false)
	if not _record_or_fail("vfx_layer", create_vfx_layer(game_layer, runtime.battlefield, runtime.region_map), runtime):
		return _build_result(false)
	if not _record_or_fail("debug_action_panel", create_debug_action_panel(game_layer, runtime.device_layer, runtime.card_system, runtime.battlefield, runtime.region_map), runtime):
		return _build_result(false)
	if not _record_or_fail("absorber_core_effect", create_absorber_core_effect_system(game_layer, runtime.device_layer, runtime.bullet_pool, runtime.resource_states, runtime.battlefield, runtime.cardfront_vfx_layer), runtime):
		return _build_result(false)
	if not _record_or_fail("engineer_bot_effect", create_engineer_bot_effect_system(game_layer, runtime.device_layer, runtime.fortify_layer, runtime.battlefield, runtime.region_map, runtime.cardfront_vfx_layer), runtime):
		return _build_result(false)
	if not _record_or_fail("durable_pioneer_beacon_effect", create_durable_pioneer_beacon_effect_system(game_layer, runtime.device_layer, runtime.battlefield, runtime.region_map, runtime.cardfront_vfx_layer), runtime):
		return _build_result(false)
	return _build_result(true)


func build_live_world_layers(game_layer: Node, runtime) -> Dictionary:
	clear()
	if runtime == null:
		return _failure("live_world_layers", "missing_runtime")
	_clear_world_layer_refs(runtime)
	runtime.hero_assignments = CardfrontHeroRegistryScript.assignments_from_config(runtime.current_config)

	if not _record_or_fail("arena_presentation", CardfrontArenaBuilderScript.create_presentation(game_layer, runtime.battlefield, runtime.current_layout), runtime):
		return _build_result(false)
	if not _record_or_fail("command_chambers", CardfrontArenaBuilderScript.create_command_chambers(game_layer, runtime.turrets, runtime.hero_assignments), runtime):
		return _build_result(false)
	var arena_layout: Dictionary = runtime.current_layout.duplicate(true)
	arena_layout["map_id"] = str(runtime.current_config.get("map_id", "default_duel"))
	if not _record_or_fail("orthographic_arena", CardfrontArenaBuilderScript.create_orthographic_view(game_layer, runtime.battlefield, runtime.region_map, runtime.bullet_pool, runtime.turrets, arena_layout), runtime):
		return _build_result(false)
	if not _record_or_fail("gate_connectivity", create_gate_connectivity_system(game_layer, runtime.battlefield, runtime.bullet_pool, runtime.orthographic_arena_view), runtime):
		return _build_result(false)
	if not _record_or_fail("fire_director", create_fire_director(game_layer, runtime.region_map, runtime.battlefield, runtime.turrets), runtime):
		return _build_result(false)
	if not _record_or_fail("direction_control", CardfrontArenaBuilderScript.create_direction_control(game_layer, runtime.battlefield, runtime.turrets, runtime.fire_director, runtime.current_layout), runtime):
		return _build_result(false)
	if not _record_or_fail("round_director", create_round_director(game_layer, runtime.fire_director, runtime.turrets, runtime.direction_controller, runtime.stronghold_system, runtime.hero_assignments, runtime.gate_connectivity_system), runtime):
		return _build_result(false)
	if not _record_or_fail("territory_defense", create_territory_defense_system(game_layer, runtime.battlefield, runtime.region_map, runtime.fortify_layer, runtime.round_director), runtime):
		return _build_result(false)
	if not _record_or_fail("target_preview", create_target_preview_layer(game_layer, runtime.battlefield, runtime.region_map), runtime):
		return _build_result(false)
	var capture_interceptor = runtime.battlefield.capture_interceptor
	if (
		runtime.orthographic_arena_view != null
		and is_instance_valid(runtime.orthographic_arena_view)
		and capture_interceptor != null
		and capture_interceptor.entity_runtime != null
	):
		runtime.orthographic_arena_view.set_entity_runtime(capture_interceptor.entity_runtime)
		var support_authority = capture_interceptor.get_support_deployment_authority()
		if support_authority != null:
			runtime.orthographic_arena_view.set_support_presentation_source(support_authority)
			runtime.target_preview_layer.configure_deployment_authority(
				Callable(support_authority, "deployment_context"),
				Callable(support_authority, "deployment_revision")
			)
	if runtime.orthographic_arena_view != null and runtime.target_preview_layer != null:
		runtime.orthographic_arena_view.set_deployment_zone_source(runtime.target_preview_layer)
	CardfrontPresentationModeControllerScript.activate_orthographic(runtime)
	return _build_result(true)


func get_refs() -> Dictionary:
	return registry.snapshot()


func get_failures() -> Array:
	return registry.failure_snapshot()


func _record_or_fail(stage: String, result: Dictionary, runtime) -> bool:
	var ok: bool = registry.record_result(stage, result)
	if ok:
		registry.apply_to(runtime)
	return ok


func _build_result(configured: bool) -> Dictionary:
	return {
		"configured": configured,
		"refs": registry.snapshot(),
		"failures": registry.failure_snapshot(),
	}


func _failure(stage: String, reason: String) -> Dictionary:
	return {
		"configured": false,
		"refs": {},
		"failures": [{"stage": stage, "reason": reason}],
	}


func _connect_yield_tick(runtime, yield_callback: Callable) -> void:
	if not yield_callback.is_valid():
		return
	if runtime.economy_system == null or not is_instance_valid(runtime.economy_system):
		return
	if not runtime.economy_system.yield_tick.is_connected(yield_callback):
		runtime.economy_system.yield_tick.connect(yield_callback)


func _clear_core_refs(runtime) -> void:
	runtime.region_map = null
	runtime.region_overlay = null
	runtime.region_control_block_layer = null
	runtime.stronghold_system = null
	runtime.economy_system = null
	runtime.economy_debug_panel = null
	runtime.resource_states.clear()
	runtime.last_yield_snapshot.clear()
	runtime.morale_system = null
	runtime.fortify_layer = null
	runtime.fortify_overlay = null
	runtime.territory_defense_system = null
	if runtime.battlefield != null and is_instance_valid(runtime.battlefield):
		runtime.battlefield.capture_interceptor = null
	runtime.target_bias_system = null
	runtime.card_system = null


func _clear_world_layer_refs(runtime) -> void:
	runtime.fire_director = null
	runtime.shot_guide_layer = null
	runtime.device_layer = null
	runtime.device_overlay_layer = null
	runtime.target_preview_layer = null
	runtime.cardfront_vfx_layer = null
	runtime.debug_action_panel = null
	runtime.absorber_core_effect_system = null
	runtime.engineer_bot_effect_system = null
	runtime.durable_pioneer_beacon_effect_system = null
	runtime.arena_presentation_layer = null
	runtime.orthographic_arena_view = null
	if runtime.gate_connectivity_system != null and is_instance_valid(runtime.gate_connectivity_system):
		runtime.gate_connectivity_system.detach()
	runtime.gate_connectivity_system = null
	runtime.command_chambers.clear()
	runtime.direction_controller = null
	runtime.aim_guide_layer = null
	runtime.round_director = null
	runtime.hero_assignments.clear()
	runtime.faction_run_states.clear()
	runtime.territory_defense_system = null


static func create_regions(game_layer: Node, battlefield, map_id: String = "default_duel") -> Dictionary:
	if game_layer == null or not is_instance_valid(game_layer):
		return {"configured": false, "reason": "missing_game_layer"}
	if battlefield == null or not is_instance_valid(battlefield):
		return {"configured": false, "reason": "missing_battlefield"}

	var region_map = RegionMapScript.new()
	region_map.configure_extent(battlefield.grid_extent)
	region_map.generate_layout(map_id)

	var overlay = RegionOverlayLayerScript.new()
	overlay.setup(region_map, battlefield, GameConfig.GAME_MODE_CARDFRONT)
	game_layer.add_child(overlay)

	return {
		"configured": true,
		"region_map": region_map,
		"region_overlay": overlay,
	}


static func create_region_control_blocks(game_layer: Node, region_map, battlefield) -> Dictionary:
	if game_layer == null or not is_instance_valid(game_layer):
		return {"configured": false, "reason": "missing_game_layer"}
	if region_map == null:
		return {"configured": false, "reason": "missing_region_map"}
	if battlefield == null or not is_instance_valid(battlefield):
		return {"configured": false, "reason": "missing_battlefield"}
	var layer = RegionControlBlockLayerScript.new()
	layer.setup(region_map, battlefield, GameConfig.GAME_MODE_CARDFRONT)
	game_layer.add_child(layer)
	return {"configured": true, "region_control_block_layer": layer}


static func create_stronghold_system(game_layer: Node, region_map, battlefield) -> Dictionary:
	if game_layer == null or not is_instance_valid(game_layer):
		return {"configured": false, "reason": "missing_game_layer"}
	var system = CardfrontStrongholdSystemScript.new()
	game_layer.add_child(system)
	if not system.setup(region_map, battlefield):
		system.queue_free()
		return {"configured": false, "reason": "stronghold_setup_failed"}
	return {
		"configured": true,
		"stronghold_system": system,
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
	fortify_layer.configure_extent(battlefield.grid_extent)

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
	fire_director.setup(region_map, battlefield, turrets, target_bias_system, Rules.get_duel_factions())
	game_layer.add_child(fire_director)

	return {
		"configured": true,
		"fire_director": fire_director,
	}


static func create_round_director(
	game_layer: Node,
	fire_director,
	turrets: Dictionary,
	direction_controller = null,
	stronghold_system = null,
	hero_assignments: Dictionary = {},
	gate_connectivity_system = null
) -> Dictionary:
	if game_layer == null or not is_instance_valid(game_layer):
		return {"configured": false, "reason": "missing_game_layer"}
	var director = CardfrontRoundDirectorScript.new()
	game_layer.add_child(director)
	if not director.setup(
		fire_director,
		turrets,
		direction_controller,
		stronghold_system,
		hero_assignments,
		gate_connectivity_system
	):
		director.queue_free()
		return {"configured": false, "reason": "round_director_setup_failed"}
	return {
		"configured": true,
		"round_director": director,
		"faction_run_states": director.run_states,
	}


static func create_gate_connectivity_system(game_layer: Node, battlefield, bullet_pool, arena_view = null) -> Dictionary:
	if game_layer == null or not is_instance_valid(game_layer):
		return {"configured": false, "reason": "missing_game_layer"}
	var system = CardfrontGateConnectivitySystemScript.new()
	game_layer.add_child(system)
	if not system.setup(battlefield, bullet_pool, arena_view):
		system.queue_free()
		return {"configured": false, "reason": "gate_connectivity_setup_failed"}
	return {
		"configured": true,
		"gate_connectivity_system": system,
	}


static func create_territory_defense_system(game_layer: Node, battlefield, region_map, fortify_layer, round_director) -> Dictionary:
	if game_layer == null or not is_instance_valid(game_layer):
		return {"configured": false, "reason": "missing_game_layer"}
	var system = CardfrontTerritoryDefenseSystemScript.new()
	game_layer.add_child(system)
	if not system.setup(battlefield, region_map, fortify_layer, round_director):
		system.queue_free()
		return {"configured": false, "reason": "territory_defense_setup_failed"}
	return {
		"configured": true,
		"territory_defense_system": system,
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
	device_layer.overlay_dirty_callback = Callable(device_overlay, "mark_dirty")

	return {
		"configured": true,
		"device_layer": device_layer,
		"device_overlay": device_overlay,
	}


static func create_target_preview_layer(game_layer: Node, battlefield, region_map) -> Dictionary:
	if game_layer == null or not is_instance_valid(game_layer):
		return {"configured": false, "reason": "missing_game_layer"}

	var layer = CardfrontTargetPreviewLayerScript.new()
	layer.setup(battlefield, region_map, GameConfig.GAME_MODE_CARDFRONT)
	game_layer.add_child(layer)

	return {
		"configured": true,
		"target_preview_layer": layer,
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
