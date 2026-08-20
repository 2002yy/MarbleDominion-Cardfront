extends Node2D
class_name CardfrontBattlefieldEntityRuntime

@warning_ignore("unused_signal")
signal entity_spawned(entity_id, entity_kind, owner_id, cell)
signal entity_removed(entity_id, entity_kind, owner_id, cell)
@warning_ignore("unused_signal")
signal entity_contact_resolved(result)
@warning_ignore("unused_signal")
signal creature_repaired(entity_id, cell, restored_points)
@warning_ignore("unused_signal")
signal tower_power_changed(entity_id, powered)
@warning_ignore("unused_signal")
signal tower_level_changed(entity_id, owner_id, previous_level, new_level)
@warning_ignore("unused_signal")
signal projectile_guided(tower_entity_id, owner_id, projectile_type)
@warning_ignore("unused_signal")
signal building_volley_fired(owner_id, tower_entity_id, shot_count)
@warning_ignore("unused_signal")
signal tower_counter_fired(tower_entity_id, owner_id)
@warning_ignore("unused_signal")
signal heavy_charge_exploded(owner_id, cell, center_target_id)
@warning_ignore("unused_signal")
signal sapper_detonated(owner_id, target_kind, cell, damage)
@warning_ignore("unused_signal")
signal neutral_creature_attacked(result)

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const MapRegistryScript = preload("res://scripts/cardfront/maps/CardfrontMapRegistry.gd")
const BattlefieldEntityScript = preload("res://scripts/cardfront/entities/CardfrontBattlefieldEntity.gd")
const RegistryScript = preload("res://scripts/cardfront/entities/CardfrontBattlefieldEntityRegistry.gd")
const DebugLayerScript = preload("res://scripts/cardfront/entities/CardfrontEntityDebugLayer.gd")
const PresentationLayerScript = preload("res://scripts/cardfront/entities/CardfrontEntityPresentationLayer.gd")
const SapperSystemScript = preload("res://scripts/cardfront/entities/CardfrontSapperSystem.gd")
const NeutralCreatureSystemScript = preload("res://scripts/cardfront/entities/CardfrontNeutralCreatureSystem.gd")
const ProjectileBridgeScript = preload("res://scripts/cardfront/entities/CardfrontEntityProjectileBridge.gd")
const TowerRuntimeScript = preload("res://scripts/cardfront/entities/CardfrontTowerRuntime.gd")
const CreatureCoordinatorScript = preload("res://scripts/cardfront/entities/CardfrontAuthoritativeCreatureActionCoordinator.gd")
const AutomaticSpawnCoordinatorScript = preload("res://scripts/cardfront/entities/CardfrontAutomaticSpawnCoordinator.gd")

const CREATURE_REPAIR_UNIT: String = "repair_unit"
const CREATURE_SCOUT_UNIT: String = "scout_unit"
const CREATURE_ARMORED_GUARD: String = "armored_guard"
const CREATURE_SAPPER_UNIT: String = "sapper_unit"
const TOWER_FIRE_CONTROL_BEACON: String = "fire_control_beacon"
const TOWER_INTERCEPTOR: String = "interceptor_tower"
const DEFAULT_FIRE_CONTROL_HP: int = 5
const DEFAULT_GUIDANCE_CAPACITY: int = 6
const DEFAULT_GUIDANCE_STRENGTH: float = 0.35
const DEFAULT_GUIDANCE_RADIUS_CELLS: int = 3
const DEFAULT_INTERCEPTOR_HP: int = 4
const BUILDING_VOLLEY_TOTAL_CAP: int = 32

var battlefield = null
var round_director = null
var territory_defense_system = null
var bullet_pool = null
var registry = RegistryScript.new()
var map_definition: Dictionary = {}
var deployment_context_provider = null
var presentation_layer = null
var debug_layer = null
var _entity_serial: int = 0
var _sapper_system = SapperSystemScript.new()
var _neutral_creature_system = NeutralCreatureSystemScript.new()
var _projectile_bridge = ProjectileBridgeScript.new()
var _tower_runtime = TowerRuntimeScript.new()
var _creature_action_coordinator = CreatureCoordinatorScript.new()
var _automatic_spawn_coordinator = AutomaticSpawnCoordinatorScript.new()


func _init() -> void:
	name = "CardfrontBattlefieldEntityRuntime"
	process_physics_priority = -100
	set_physics_process(true)
	_sapper_system.setup(self)
	_neutral_creature_system.setup(self)
	_projectile_bridge.setup(self)
	_tower_runtime.setup(self)
	_creature_action_coordinator.setup(self)
	_automatic_spawn_coordinator.setup(self)


func setup(new_battlefield, new_map_definition: Dictionary = {}) -> bool:
	if new_battlefield == null or not is_instance_valid(new_battlefield):
		return false
	battlefield = new_battlefield
	registry.clear()
	map_definition = new_map_definition.duplicate(true)
	if map_definition.is_empty():
		map_definition = MapRegistryScript.get_map_definition(
			MapRegistryScript.DEFAULT_DUEL_MAP_ID,
			battlefield.grid_extent
		)
	_register_map_building_slots()
	_ensure_visual_layers()
	_mark_visuals_dirty()
	return true


func configure_map_definition(new_map_definition: Dictionary) -> void:
	map_definition = new_map_definition.duplicate(true)
	registry.clear()
	_register_map_building_slots()
	_mark_visuals_dirty()


func configure_deployment_context_provider(new_provider) -> void:
	deployment_context_provider = new_provider


func configure_dependencies(new_round_director, new_territory_defense_system) -> void:
	round_director = new_round_director
	territory_defense_system = new_territory_defense_system
	_resolve_bullet_pool()
	if round_director == null or not is_instance_valid(round_director):
		return
	if round_director.has_method("set_battlefield_entity_runtime"):
		round_director.set_battlefield_entity_runtime(self)
	var callback := Callable(self, "_on_volley_launched")
	if (
		round_director.has_signal("volley_launched")
		and not round_director.volley_launched.is_connected(callback)
	):
		round_director.volley_launched.connect(callback)


func resolve_capture_contact(
	cell: Vector2i,
	incoming_owner_id: int,
	capture_context: Dictionary
) -> Dictionary:
	return _projectile_bridge.resolve_capture_contact(
		cell,
		incoming_owner_id,
		capture_context
	)


func advance_round() -> void:
	_creature_action_coordinator.begin_round()
	_update_tower_power_states()
	_run_creature_actions()
	_process_tower_summons()
	var expired_entities: Array = registry.tick_round()
	for entity in expired_entities:
		entity_removed.emit(
			str(entity.entity_id),
			str(entity.entity_kind),
			int(entity.owner_id),
			entity.cell
		)
	_cleanup_dead_entities()
	_mark_visuals_dirty()


func prepare_draft(run_states: Dictionary) -> void:
	advance_round()
	sync_run_state_entity_summaries(run_states)


func apply_pending_upgrade_actions(owner_id: int, run_state) -> Array:
	var results: Array = []
	if run_state == null or not run_state.has_method("consume_pending_entity_actions"):
		return results
	for raw_action in run_state.consume_pending_entity_actions():
		if not (raw_action is Dictionary):
			continue
		var action: Dictionary = raw_action as Dictionary
		var placement_request: Dictionary = _automatic_spawn_coordinator.placement_request_from_action(action)
		match str(action.get("action", "")):
			"summon_repair_units":
				var repair_result: Dictionary = _automatic_spawn_coordinator.spawn_repair_units(
					owner_id,
					int(action.get("amount", 2)),
					placement_request
				)
				results.append(
					_automatic_spawn_coordinator.public_spawn_result(
						"summon_repair_units",
						repair_result
					)
				)
			"summon_armored_guard":
				var guard_result: Dictionary = _automatic_spawn_coordinator.spawn_single_creature(
					owner_id,
					CREATURE_ARMORED_GUARD,
					placement_request
				)
				results.append(
					_automatic_spawn_coordinator.public_spawn_result(
						"summon_armored_guard",
						guard_result
					)
				)
			"summon_sapper_unit":
				var sapper_result: Dictionary = _automatic_spawn_coordinator.spawn_single_creature(
					owner_id,
					CREATURE_SAPPER_UNIT,
					placement_request
				)
				results.append(
					_automatic_spawn_coordinator.public_spawn_result(
						"summon_sapper_unit",
						sapper_result
					)
				)
			"summon_gate_colossus":
				results.append(
					_spawn_result(
						"summon_gate_colossus",
						_neutral_creature_system.spawn(owner_id)
					)
				)
			"build_or_upgrade_tower":
				results.append(
					build_or_upgrade_tower(owner_id, str(action.get("tower_id", "")))
				)
	sync_run_state_entity_summary(run_state)
	return results


func sync_run_state_entity_summaries(run_states: Dictionary) -> void:
	for owner_id in run_states.keys():
		var run_state = run_states[owner_id]
		if run_state != null:
			sync_run_state_entity_summary(run_state)


func sync_run_state_entity_summary(run_state) -> void:
	if run_state == null or not run_state.has_method("sync_entity_summary"):
		return
	var owner_id: int = int(run_state.owner_id)
	var levels: Dictionary = {}
	for entity in registry.entities_by_id.values():
		if (
			entity != null
			and entity.is_alive()
			and int(entity.owner_id) == owner_id
			and str(entity.entity_kind) == BattlefieldEntityScript.KIND_DEFENSE_TOWER
		):
			levels[str(entity.tower_id)] = int(entity.tower_level)
	run_state.sync_entity_summary(
		registry.count_owner_entities(owner_id, BattlefieldEntityScript.KIND_CREATURE),
		registry.count_owner_entities(owner_id, BattlefieldEntityScript.KIND_DEFENSE_TOWER),
		levels
	)


func decorate_volley_plan(owner_id: int, plan) -> void:
	_tower_runtime.decorate_volley_plan(owner_id, plan)


func debug_spawn_repair_units(owner_id: int, amount: int = 2) -> Array:
	return spawn_repair_units(owner_id, amount)


func spawn_repair_units(owner_id: int, amount: int = 2, placement_request: Dictionary = {}) -> Array:
	var result: Dictionary = _automatic_spawn_coordinator.spawn_repair_units(
		owner_id,
		amount,
		placement_request
	)
	return result.get("entities", []) as Array


func spawn_armored_guard(owner_id: int, placement_request: Dictionary = {}):
	var result: Dictionary = _automatic_spawn_coordinator.spawn_single_creature(
		owner_id,
		CREATURE_ARMORED_GUARD,
		placement_request
	)
	return result.get("entity", null)


func spawn_sapper_unit(owner_id: int, placement_request: Dictionary = {}):
	var result: Dictionary = _automatic_spawn_coordinator.spawn_single_creature(
		owner_id,
		CREATURE_SAPPER_UNIT,
		placement_request
	)
	return result.get("entity", null)


func resolve_automatic_spawn_cell(
	owner_id: int,
	placement_request: Dictionary = {},
	availability: Callable = Callable()
) -> Dictionary:
	return _automatic_spawn_coordinator.resolve_cell(owner_id, placement_request, availability)


func debug_spawn_fire_control_beacon(owner_id: int, lane_index: int = 0):
	return _spawn_tower(owner_id, TOWER_FIRE_CONTROL_BEACON, lane_index)


func build_or_upgrade_tower(owner_id: int, tower_id: String) -> Dictionary:
	return _tower_runtime.build_or_upgrade(owner_id, tower_id)


func snapshot() -> Dictionary:
	return {
		"map_id": str(map_definition.get("id", "")),
		"registry": registry.snapshot(),
		"entity_serial": _entity_serial,
	}


func restore(data: Dictionary) -> void:
	registry.restore(data.get("registry", {}))
	_entity_serial = maxi(0, int(data.get("entity_serial", 0)))
	_mark_visuals_dirty()


func _physics_process(_delta: float) -> void:
	_projectile_bridge.process_active_bullets(false)


func _on_volley_launched(plans: Dictionary, _issued_intents: Dictionary) -> void:
	registry.begin_volley()
	for entity in registry.entities_by_id.values():
		if (
			entity != null
			and entity.is_alive()
			and str(entity.entity_kind) == BattlefieldEntityScript.KIND_CREATURE
			and str(entity.creature_id) == CREATURE_SCOUT_UNIT
		):
			entity.metadata["guidance_remaining"] = 3
	for owner_id in plans.keys():
		_spawn_building_volley(int(owner_id), plans[owner_id])
	_mark_visuals_dirty()


func _spawn_tower(owner_id: int, tower_id: String, lane_index: int):
	return _tower_runtime.spawn_tower(owner_id, tower_id, lane_index)


func _configure_tower_level(tower, level: int) -> void:
	_tower_runtime.configure_level(tower, level)


func _owner_towers(owner_id: int) -> Array:
	return _tower_runtime.owner_towers(owner_id)


func _find_owner_tower(owner_id: int, tower_id: String):
	return _tower_runtime.find_owner_tower(owner_id, tower_id)


func _first_free_lane(owner_id: int) -> int:
	return _tower_runtime.first_free_lane(owner_id)


func _spawn_building_volley(owner_id: int, plan) -> void:
	_tower_runtime.spawn_building_volley(owner_id, plan)


func _spawn_counter_projectile(tower, incoming_direction: Vector2) -> void:
	_tower_runtime.spawn_counter_projectile(tower, incoming_direction)


func _try_apply_heavy_charge(
	cell: Vector2i,
	incoming_owner_id: int,
	center_target,
	capture_context: Dictionary,
	result: Dictionary
) -> void:
	_projectile_bridge.try_apply_heavy_charge(
		cell,
		incoming_owner_id,
		center_target,
		capture_context,
		result
	)


func _resolve_bullet_pool() -> void:
	_projectile_bridge.resolve_bullet_pool()


func _apply_fire_control_guidance(bullet) -> void:
	_projectile_bridge.apply_fire_control_guidance(bullet)


func _update_tower_power_states() -> void:
	_tower_runtime.update_power_states()


func _run_creature_actions() -> void:
	_creature_action_coordinator.run_actions()


func _run_repair_unit(creature) -> void:
	_creature_action_coordinator.run_repair_unit(creature)


func _run_armored_guard(creature) -> void:
	_creature_action_coordinator.run_armored_guard(creature)


func _run_sapper_unit(creature) -> void:
	_creature_action_coordinator.run_sapper_unit(creature)


func _repair_frontline_cell(creature, cell: Vector2i) -> bool:
	return _creature_action_coordinator.repair_frontline_cell(creature, cell)


func _process_tower_summons() -> void:
	_tower_runtime.process_summons()


func _has_owner_creature_id(owner_id: int, creature_id: String) -> bool:
	return _creature_action_coordinator.has_owner_creature_id(owner_id, creature_id)


func _find_owner_creature_id(owner_id: int, creature_id: String):
	return _creature_action_coordinator.find_owner_creature_id(owner_id, creature_id)


func _push_creature(creature, direction: Vector2, distance: int) -> bool:
	return _creature_action_coordinator.push_creature(creature, direction, distance)


func _find_nearest_repairable_frontline(owner_id: int, origin: Vector2i) -> Vector2i:
	return _creature_action_coordinator.find_nearest_repairable_frontline(owner_id, origin)


func _find_nearest_guard_post(owner_id: int, origin: Vector2i) -> Vector2i:
	return _creature_action_coordinator.find_nearest_guard_post(owner_id, origin)


func _command_chamber_cell(owner_id: int) -> Vector2i:
	return _creature_action_coordinator.command_chamber_cell(owner_id)


func _next_owned_step_toward(owner_id: int, origin: Vector2i, target: Vector2i) -> Vector2i:
	return _creature_action_coordinator.next_owned_step_toward(owner_id, origin, target)


func _is_frontline_cell(cell: Vector2i, owner_id: int) -> bool:
	return _creature_action_coordinator.is_frontline_cell(cell, owner_id)


func _find_owner_spawn_cell(owner_id: int, _index: int) -> Vector2i:
	var result: Dictionary = resolve_automatic_spawn_cell(owner_id)
	return result.get("cell", Vector2i(-1, -1)) as Vector2i if bool(result.get("allowed", false)) else Vector2i(-1, -1)


func _find_adjacent_spawn_cell(owner_id: int, origin: Vector2i) -> Vector2i:
	return _creature_action_coordinator.find_adjacent_spawn_cell(owner_id, origin)


func _register_map_building_slots() -> void:
	if battlefield == null or not is_instance_valid(battlefield):
		return
	var width: int = int(battlefield.grid_extent.x)
	var height: int = int(battlefield.grid_extent.y)
	var lanes: Array = (
		(map_definition.get("route_layout", {}) as Dictionary).get("lanes", [])
		as Array
	)
	if lanes.size() < 2:
		lanes = [{"center_ratio": 0.30}, {"center_ratio": 0.70}]
	for owner_id in RulesScript.get_duel_factions():
		var y: int = 3 if int(owner_id) == RulesScript.AI_FACTION else maxi(0, height - 4)
		for lane_index in range(2):
			var lane: Dictionary = lanes[lane_index] as Dictionary
			var x: int = clampi(
				roundi(float(width - 1) * float(lane.get("center_ratio", 0.5))),
				0,
				width - 1
			)
			var slot_id: String = _route_slot_id(owner_id, lane_index)
			registry.register_building_slot(slot_id, Vector2i(x, y), "defense_tower")
			var slot: Dictionary = registry.building_slots[slot_id] as Dictionary
			slot["owner_id"] = int(owner_id)
			slot["lane_index"] = lane_index
			registry.building_slots[slot_id] = slot
		var chamber_slot_id: String = "%d_chamber_facility" % int(owner_id)
		var chamber_y: int = 1 if int(owner_id) == RulesScript.AI_FACTION else maxi(0, height - 2)
		registry.register_building_slot(
			chamber_slot_id,
			Vector2i(width >> 1, chamber_y),
			"chamber_facility"
		)
		var chamber_slot: Dictionary = registry.building_slots[chamber_slot_id] as Dictionary
		chamber_slot["owner_id"] = int(owner_id)
		registry.building_slots[chamber_slot_id] = chamber_slot


func _route_slot_id(owner_id: int, lane_index: int) -> String:
	return "%d_route_%d" % [int(owner_id), int(lane_index)]


func _lane_center_ratio(lane_index: int) -> float:
	var lanes: Array = (
		(map_definition.get("route_layout", {}) as Dictionary).get("lanes", [])
		as Array
	)
	if lane_index >= 0 and lane_index < lanes.size():
		return clampf(
			float((lanes[lane_index] as Dictionary).get("center_ratio", 0.5)),
			0.0,
			1.0
		)
	return 0.30 if lane_index <= 0 else 0.70


func _cleanup_dead_entities() -> void:
	var dead_ids: Array = []
	for entity_id in registry.entities_by_id.keys():
		var entity = registry.entities_by_id[entity_id]
		if entity == null or not entity.is_alive():
			dead_ids.append(str(entity_id))
	for entity_id in dead_ids:
		_remove_entity(entity_id)


func _remove_entity(entity_id: String) -> void:
	var entity = registry.get_entity(entity_id)
	if entity == null:
		return
	var kind: String = str(entity.entity_kind)
	var owner_id: int = int(entity.owner_id)
	var cell: Vector2i = entity.cell
	if registry.remove_entity(entity_id):
		entity_removed.emit(entity_id, kind, owner_id, cell)


func _ensure_visual_layers() -> void:
	if presentation_layer == null or not is_instance_valid(presentation_layer):
		presentation_layer = PresentationLayerScript.new()
		add_child(presentation_layer)
	presentation_layer.setup(battlefield, registry, self)
	if debug_layer == null or not is_instance_valid(debug_layer):
		debug_layer = DebugLayerScript.new()
		add_child(debug_layer)
	debug_layer.setup(battlefield, registry)


func _ensure_debug_layer() -> void:
	_ensure_visual_layers()


func _mark_visuals_dirty() -> void:
	if presentation_layer != null and is_instance_valid(presentation_layer):
		presentation_layer.mark_dirty()
	if debug_layer != null and is_instance_valid(debug_layer):
		debug_layer.mark_dirty()


func _resolve_spawn_cells(owner_id: int, amount: int, placement_request: Dictionary) -> Dictionary:
	return _automatic_spawn_coordinator.resolve_cells(owner_id, amount, placement_request)


func _spawn_result(action: String, entity) -> Dictionary:
	return {"action": action, "spawned": 1 if entity != null else 0}


func _next_entity_id(prefix: String) -> String:
	_entity_serial += 1
	return "%s_%d" % [str(prefix), _entity_serial]


func _manhattan_distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


func _cell_key(cell: Vector2i) -> String:
	return "%d:%d" % [cell.x, cell.y]
