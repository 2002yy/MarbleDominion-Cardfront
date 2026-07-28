extends Node2D
class_name CardfrontBattlefieldEntityRuntime

signal entity_spawned(entity_id, entity_kind, owner_id, cell)
signal entity_removed(entity_id, entity_kind, owner_id, cell)
signal entity_contact_resolved(result)
signal creature_repaired(entity_id, cell, restored_points)
signal tower_power_changed(entity_id, powered)
signal projectile_guided(tower_entity_id, owner_id, projectile_type)
signal building_volley_fired(owner_id, tower_entity_id, shot_count)
signal heavy_charge_exploded(owner_id, cell, center_target_id)
signal sapper_detonated(owner_id, target_kind, cell, damage)

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const MapRegistryScript = preload("res://scripts/cardfront/maps/CardfrontMapRegistry.gd")
const ProjectileTypeScript = preload("res://scripts/cardfront/volley/CardfrontProjectileType.gd")
const BattlefieldEntityScript = preload("res://scripts/cardfront/entities/CardfrontBattlefieldEntity.gd")
const CreatureStateScript = preload("res://scripts/cardfront/entities/CardfrontCreatureState.gd")
const RegistryScript = preload("res://scripts/cardfront/entities/CardfrontBattlefieldEntityRegistry.gd")
const InteractionScript = preload("res://scripts/cardfront/entities/CardfrontProjectileEntityInteraction.gd")
const DebugLayerScript = preload("res://scripts/cardfront/entities/CardfrontEntityDebugLayer.gd")
const SapperSystemScript = preload("res://scripts/cardfront/entities/CardfrontSapperSystem.gd")

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
var debug_layer = null
var _entity_serial: int = 0
var _repaired_cells_this_round: Dictionary = {}
var _sapper_system = SapperSystemScript.new()


func _init() -> void:
	name = "CardfrontBattlefieldEntityRuntime"
	process_physics_priority = -100
	set_physics_process(true)


func setup(new_battlefield, new_map_definition: Dictionary = {}) -> bool:
	if new_battlefield == null or not is_instance_valid(new_battlefield):
		return false
	battlefield = new_battlefield
	_sapper_system.setup(self)
	registry.clear()
	map_definition = new_map_definition.duplicate(true)
	if map_definition.is_empty():
		map_definition = MapRegistryScript.get_map_definition(
			MapRegistryScript.DEFAULT_DUEL_MAP_ID,
			int(battlefield.grid_size)
		)
	_register_map_building_slots()
	_ensure_debug_layer()
	_mark_visuals_dirty()
	return true


func configure_map_definition(new_map_definition: Dictionary) -> void:
	map_definition = new_map_definition.duplicate(true)
	registry.clear()
	_register_map_building_slots()
	_mark_visuals_dirty()


func configure_dependencies(new_round_director, new_territory_defense_system) -> void:
	round_director = new_round_director
	territory_defense_system = new_territory_defense_system
	_resolve_bullet_pool()
	if round_director == null or not is_instance_valid(round_director):
		return
	if round_director.has_method("set_battlefield_entity_runtime"):
		round_director.set_battlefield_entity_runtime(self)
	var volley_callable := Callable(self, "_on_volley_launched")
	if round_director.has_signal("volley_launched") and not round_director.volley_launched.is_connected(volley_callable):
		round_director.volley_launched.connect(volley_callable)


func resolve_capture_contact(cell: Vector2i, incoming_owner_id: int, capture_context: Dictionary) -> Dictionary:
	var empty_result: Dictionary = {
		"valid": false,
		"block_territory": false,
		"consume_projectile": false,
		"bounce_projectile": false,
	}
	if registry == null:
		return empty_result
	var targets: Array = registry.get_collision_targets(cell, incoming_owner_id)
	if targets.is_empty():
		return empty_result
	var target = targets[0]
	var projectile_type: String = ProjectileTypeScript.sanitize(
		str(capture_context.get("projectile_type", ProjectileTypeScript.STANDARD))
	)

	var result: Dictionary
	if (
		str(target.entity_kind) == BattlefieldEntityScript.KIND_DEFENSE_TOWER
		and projectile_type == ProjectileTypeScript.STANDARD
		and target.has_method("can_intercept")
		and target.can_intercept()
	):
		target.consume_intercept()
		result = {
			"valid": true,
			"projectile_type": projectile_type,
			"target_id": str(target.entity_id),
			"target_kind": str(target.entity_kind),
			"damage": 0,
			"damage_applied": 0,
			"intercepted": true,
			"block_territory": true,
			"consume_projectile": true,
			"bounce_projectile": false,
			"push_cells": 0,
		}
	else:
		result = InteractionScript.apply(projectile_type, target)

	if not bool(result.get("valid", false)):
		return empty_result

	var push_cells: int = maxi(0, int(result.get("push_cells", 0)))
	if push_cells > 0 and str(target.entity_kind) == BattlefieldEntityScript.KIND_CREATURE:
		var direction: Vector2 = capture_context.get("projectile_direction", Vector2.ZERO) as Vector2
		result["pushed"] = _push_creature(target, direction, push_cells)

	if str(target.entity_kind) == BattlefieldEntityScript.KIND_DEFENSE_TOWER:
		if bool(result.get("intercepted", false)) and int(target.tower_level) >= 3 and int(target.intercepts_remaining) <= 0:
			var incoming_direction: Vector2 = capture_context.get("projectile_direction", Vector2.RIGHT) as Vector2
			_spawn_counter_projectile(target, -incoming_direction)
		if not bool(result.get("intercepted", false)):
			_try_apply_heavy_charge(cell, incoming_owner_id, target, capture_context, result)

	_cleanup_dead_entities()

	capture_context["entity_contact_target_id"] = str(result.get("target_id", ""))
	capture_context["entity_consume_projectile"] = bool(result.get("consume_projectile", false))
	if bool(result.get("bounce_projectile", false)):
		var incoming_direction: Vector2 = capture_context.get("projectile_direction", Vector2.RIGHT) as Vector2
		if incoming_direction.length() <= 0.001:
			incoming_direction = Vector2.RIGHT
		capture_context["entity_bounce_direction"] = (-incoming_direction).normalized()
	else:
		capture_context.erase("entity_bounce_direction")

	entity_contact_resolved.emit(result.duplicate(true))
	_mark_visuals_dirty()
	return result


func advance_round() -> void:
	_repaired_cells_this_round.clear()
	_update_tower_power_states()
	_run_creature_actions()
	_process_tower_summons()
	registry.tick_round()
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
		match str(action.get("action", "")):
			"summon_repair_units":
				var spawned: Array = spawn_repair_units(owner_id, int(action.get("amount", 2)))
				results.append({"action": "summon_repair_units", "spawned": spawned.size()})
			"summon_armored_guard":
				var guard = spawn_armored_guard(owner_id)
				results.append({
					"action": "summon_armored_guard",
					"spawned": 1 if guard != null else 0,
				})
			"summon_sapper_unit":
				var sapper = spawn_sapper_unit(owner_id)
				results.append({
					"action": "summon_sapper_unit",
					"spawned": 1 if sapper != null else 0,
				})
			"build_or_upgrade_tower":
				var tower_result: Dictionary = build_or_upgrade_tower(owner_id, str(action.get("tower_id", "")))
				results.append(tower_result)
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
	if plan == null:
		return
	plan.building_sources.clear()
	plan.building_shot_count = 0
	var level: int = clampi(int(plan.building_volley_level), 0, 3)
	if level <= 0:
		return
	var shots_per_tower: int = level + 1
	var remaining_budget: int = maxi(0, BUILDING_VOLLEY_TOTAL_CAP - int(plan.shot_count))
	var towers: Array = _owner_towers(owner_id)
	for tower in towers:
		if remaining_budget <= 0:
			break
		if tower == null or not tower.can_act():
			continue
		var source_shots: int = mini(shots_per_tower, remaining_budget)
		plan.building_sources.append({
			"entity_id": str(tower.entity_id),
			"cell": tower.cell,
			"shot_count": source_shots,
		})
		plan.building_shot_count += source_shots
		remaining_budget -= source_shots


func debug_spawn_repair_units(owner_id: int, amount: int = 2) -> Array:
	return spawn_repair_units(owner_id, amount)


func spawn_repair_units(owner_id: int, amount: int = 2) -> Array:
	var spawned: Array = []
	for index in range(maxi(0, int(amount))):
		var spawn_cell: Vector2i = _find_owner_spawn_cell(owner_id, index)
		var entity_id: String = _next_entity_id("repair")
		var creature = registry.spawn_creature(
			entity_id,
			CREATURE_REPAIR_UNIT,
			owner_id,
			spawn_cell,
			1,
			CreatureStateScript.ARMOR_NORMAL,
			1,
			"repair_frontline",
			3
		)
		if creature == null:
			continue
		spawned.append(creature)
		entity_spawned.emit(creature.entity_id, creature.entity_kind, creature.owner_id, creature.cell)
	_mark_visuals_dirty()
	return spawned


func spawn_armored_guard(owner_id: int):
	var spawn_cell: Vector2i = _find_owner_spawn_cell(owner_id, 0)
	var guard = registry.spawn_creature(
		_next_entity_id("guard"),
		CREATURE_ARMORED_GUARD,
		owner_id,
		spawn_cell,
		4,
		CreatureStateScript.ARMOR_ARMORED,
		1,
		"guard_frontline",
		-1
	)
	if guard != null:
		entity_spawned.emit(guard.entity_id, guard.entity_kind, guard.owner_id, guard.cell)
	_mark_visuals_dirty()
	return guard


func spawn_sapper_unit(owner_id: int):
	var spawn_cell: Vector2i = _find_owner_spawn_cell(owner_id, 1)
	var sapper = registry.spawn_creature(
		_next_entity_id("sapper"),
		CREATURE_SAPPER_UNIT,
		owner_id,
		spawn_cell,
		3,
		CreatureStateScript.ARMOR_ARMORED,
		1,
		"sapper_assault",
		-1
	)
	if sapper != null:
		entity_spawned.emit(sapper.entity_id, sapper.entity_kind, sapper.owner_id, sapper.cell)
	_mark_visuals_dirty()
	return sapper


func debug_spawn_fire_control_beacon(owner_id: int, lane_index: int = 0):
	return _spawn_tower(owner_id, TOWER_FIRE_CONTROL_BEACON, lane_index)


func build_or_upgrade_tower(owner_id: int, tower_id: String) -> Dictionary:
	var safe_tower_id: String = str(tower_id)
	if safe_tower_id not in [TOWER_FIRE_CONTROL_BEACON, TOWER_INTERCEPTOR]:
		return {"action": "build_or_upgrade_tower", "success": false, "reason": "unknown_tower"}
	var existing = _find_owner_tower(owner_id, safe_tower_id)
	if existing != null:
		if int(existing.tower_level) >= 3:
			return {"action": "build_or_upgrade_tower", "success": false, "reason": "tower_max_level"}
		_configure_tower_level(existing, int(existing.tower_level) + 1)
		_mark_visuals_dirty()
		return {
			"action": "build_or_upgrade_tower",
			"success": true,
			"built": false,
			"tower_id": safe_tower_id,
			"level": int(existing.tower_level),
		}
	var lane_index: int = _first_free_lane(owner_id)
	if lane_index < 0:
		return {"action": "build_or_upgrade_tower", "success": false, "reason": "no_free_tower_slot"}
	var tower = _spawn_tower(owner_id, safe_tower_id, lane_index)
	return {
		"action": "build_or_upgrade_tower",
		"success": tower != null,
		"built": tower != null,
		"tower_id": safe_tower_id,
		"level": 1 if tower != null else 0,
		"reason": "" if tower != null else "spawn_failed",
	}


func _spawn_tower(owner_id: int, tower_id: String, lane_index: int):
	var safe_lane: int = clampi(int(lane_index), 0, 1)
	var slot_id: String = _route_slot_id(owner_id, safe_lane)
	var entity_id: String = _next_entity_id(str(tower_id))
	var tower_hp: int = DEFAULT_FIRE_CONTROL_HP if tower_id == TOWER_FIRE_CONTROL_BEACON else DEFAULT_INTERCEPTOR_HP
	var tower = registry.spawn_defense_tower(
		entity_id,
		tower_id,
		owner_id,
		slot_id,
		tower_hp
	)
	if tower == null:
		return null
	tower.metadata["lane_index"] = safe_lane
	tower.metadata["prototype_only"] = false
	_configure_tower_level(tower, 1)
	entity_spawned.emit(tower.entity_id, tower.entity_kind, tower.owner_id, tower.cell)
	_mark_visuals_dirty()
	return tower


func _configure_tower_level(tower, level: int) -> void:
	if tower == null:
		return
	var safe_level: int = clampi(int(level), 1, 3)
	tower.set_tower_level(safe_level)
	match str(tower.tower_id):
		TOWER_FIRE_CONTROL_BEACON:
			var guidance_by_level: Array = [6, 8, 10]
			tower.configure_guidance(
				int(guidance_by_level[safe_level - 1]),
				_lane_center_ratio(int(tower.metadata.get("lane_index", 0))),
				DEFAULT_GUIDANCE_STRENGTH,
				DEFAULT_GUIDANCE_RADIUS_CELLS
			)
			if safe_level >= 2:
				tower.configure_summoner(CREATURE_SCOUT_UNIT, 3 if safe_level == 2 else 2)
			else:
				tower.configure_summoner("", 0)
		TOWER_INTERCEPTOR:
			var intercepts_by_level: Array = [2, 3, 3]
			tower.configure_interceptor(int(intercepts_by_level[safe_level - 1]))


func _owner_towers(owner_id: int) -> Array:
	var towers: Array = []
	for entity in registry.entities_by_id.values():
		if (
			entity != null
			and entity.is_alive()
			and int(entity.owner_id) == int(owner_id)
			and str(entity.entity_kind) == BattlefieldEntityScript.KIND_DEFENSE_TOWER
		):
			towers.append(entity)
	towers.sort_custom(func(a, b): return str(a.entity_id) < str(b.entity_id))
	return towers


func _find_owner_tower(owner_id: int, tower_id: String):
	for tower in _owner_towers(owner_id):
		if str(tower.tower_id) == str(tower_id):
			return tower
	return null


func _first_free_lane(owner_id: int) -> int:
	for lane_index in range(2):
		var slot: Dictionary = registry.building_slots.get(
			_route_slot_id(owner_id, lane_index),
			{}
		) as Dictionary
		if not slot.is_empty() and str(slot.get("entity_id", "")) == "":
			return lane_index
	return -1


func _spawn_building_volley(owner_id: int, plan) -> void:
	if plan == null or bullet_pool == null or not is_instance_valid(bullet_pool):
		return
	var target_turrets: Dictionary = {}
	if round_director != null and is_instance_valid(round_director):
		var raw_turrets = round_director.get("turrets")
		if raw_turrets is Dictionary:
			target_turrets = raw_turrets as Dictionary
	var heavy_pool: Dictionary = plan.heavy_charge_pool
	for raw_source in plan.building_sources:
		if not (raw_source is Dictionary):
			continue
		var source: Dictionary = raw_source as Dictionary
		var tower = registry.get_entity(str(source.get("entity_id", "")))
		if tower == null or not tower.can_act():
			continue
		var shot_count: int = maxi(0, int(source.get("shot_count", 0)))
		var base_direction := Vector2.UP if int(owner_id) == RulesScript.PLAYER_FACTION else Vector2.DOWN
		var source_position: Vector2 = battlefield.to_global(
			(Vector2(tower.cell) + Vector2(0.5, 0.5)) * float(battlefield.cell_size)
		)
		for shot_index in range(shot_count):
			var spread_index: float = float(shot_index) - float(shot_count - 1) * 0.5
			var direction: Vector2 = base_direction.rotated(spread_index * 0.035)
			bullet_pool.spawn_bullet(
				owner_id,
				source_position + direction * maxf(4.0, float(battlefield.cell_size) * 0.38),
				direction,
				battlefield,
				target_turrets,
				int(plan.projectile_power),
				int(plan.chamber_damage_quarters),
				{
					"projectile_type": ProjectileTypeScript.STANDARD,
					"projectile_defense_pierce_remaining": 0,
					"armor_pierce_pool": {"remaining": 0},
					"heavy_charge_pool": heavy_pool,
					"building_source_id": str(tower.entity_id),
				}
			)
		if shot_count > 0:
			building_volley_fired.emit(owner_id, tower.entity_id, shot_count)


func _spawn_counter_projectile(tower, incoming_direction: Vector2) -> void:
	if tower == null or bullet_pool == null or not is_instance_valid(bullet_pool):
		return
	var direction: Vector2 = incoming_direction.normalized()
	if direction.length() <= 0.001:
		direction = Vector2.UP if int(tower.owner_id) == RulesScript.PLAYER_FACTION else Vector2.DOWN
	var target_turrets: Dictionary = {}
	if round_director != null and is_instance_valid(round_director):
		var raw_turrets = round_director.get("turrets")
		if raw_turrets is Dictionary:
			target_turrets = raw_turrets as Dictionary
	var source_position: Vector2 = battlefield.to_global(
		(Vector2(tower.cell) + Vector2(0.5, 0.5)) * float(battlefield.cell_size)
	)
	bullet_pool.spawn_bullet(
		int(tower.owner_id),
		source_position + direction * maxf(4.0, float(battlefield.cell_size) * 0.38),
		direction,
		battlefield,
		target_turrets,
		1,
		4,
		{
			"projectile_type": ProjectileTypeScript.STANDARD,
			"projectile_defense_pierce_remaining": 0,
			"armor_pierce_pool": {"remaining": 0},
		}
	)


func _try_apply_heavy_charge(
	cell: Vector2i,
	incoming_owner_id: int,
	center_target,
	capture_context: Dictionary,
	result: Dictionary
) -> void:
	var raw_pool = capture_context.get("heavy_charge_pool", null)
	if not (raw_pool is Dictionary):
		return
	var pool: Dictionary = raw_pool as Dictionary
	if int(pool.get("remaining", 0)) <= 0:
		return
	var spec: Dictionary = pool.get("spec", {}) as Dictionary
	if spec.is_empty():
		return
	pool["remaining"] = 0
	var center_damage: int = center_target.apply_damage(maxi(0, int(spec.get("center_bonus", 1))))
	var entity_radius: int = maxi(0, int(spec.get("entity_radius", 2)))
	var entity_damage: int = maxi(0, int(spec.get("entity_damage", 1)))
	var splash_hits: Array = []
	for entity in registry.entities_by_id.values():
		if (
			entity == null
			or entity == center_target
			or not entity.is_alive()
			or int(entity.owner_id) == int(incoming_owner_id)
			or _manhattan_distance(cell, entity.cell) > entity_radius
		):
			continue
		var applied: int = entity.apply_damage(entity_damage)
		if applied > 0:
			splash_hits.append({"entity_id": str(entity.entity_id), "damage": applied})
	var defense_hits: Array = []
	var defense_radius: int = maxi(0, int(spec.get("defense_radius", 1)))
	var defense_damage: int = maxi(0, int(spec.get("defense_damage", 1)))
	if (
		defense_damage > 0
		and territory_defense_system != null
		and is_instance_valid(territory_defense_system)
		and territory_defense_system.fortify_layer != null
	):
		for x in range(cell.x - defense_radius, cell.x + defense_radius + 1):
			for y in range(cell.y - defense_radius, cell.y + defense_radius + 1):
				var target_cell := Vector2i(x, y)
				if (
					not battlefield.is_inside(target_cell)
					or _manhattan_distance(cell, target_cell) > defense_radius
					or int(battlefield.owners[x][y]) == int(incoming_owner_id)
					or int(battlefield.owners[x][y]) == RulesScript.NEUTRAL_OWNER
				):
					continue
				var removed: int = 0
				for _damage_index in range(defense_damage):
					if territory_defense_system.fortify_layer.get_fortify_stack(target_cell) <= 0:
						break
					territory_defense_system.fortify_layer.consume_hit(target_cell)
					removed += 1
				if removed > 0:
					defense_hits.append({"cell": target_cell, "damage": removed})
	result["heavy_charge"] = {
		"center_damage": center_damage,
		"splash_hits": splash_hits,
		"defense_hits": defense_hits,
	}
	heavy_charge_exploded.emit(incoming_owner_id, cell, str(center_target.entity_id))


func snapshot() -> Dictionary:
	return {
		"map_id": str(map_definition.get("id", "")),
		"registry": registry.snapshot(),
	}


func _physics_process(_delta: float) -> void:
	if bullet_pool == null or not is_instance_valid(bullet_pool):
		_resolve_bullet_pool()
	if bullet_pool == null or not is_instance_valid(bullet_pool) or not bullet_pool.has_method("get_active_bullets"):
		return
	for bullet in bullet_pool.get_active_bullets():
		if bullet == null or not is_instance_valid(bullet) or not bool(bullet.get("is_active")):
			continue
		var context: Dictionary = bullet.capture_context
		if bool(context.get("entity_consume_projectile", false)):
			context.erase("entity_consume_projectile")
			context.erase("entity_bounce_direction")
			if bullet.has_method("_despawn"):
				bullet.call("_despawn")
			continue
		if context.has("entity_bounce_direction"):
			var bounce_direction: Vector2 = context.get("entity_bounce_direction", Vector2.RIGHT) as Vector2
			context.erase("entity_bounce_direction")
			if bounce_direction.length() > 0.001:
				bullet.direction = bounce_direction.normalized()
		_apply_fire_control_guidance(bullet)
		context["projectile_direction"] = bullet.direction


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


func _resolve_bullet_pool() -> void:
	bullet_pool = null
	if round_director == null or not is_instance_valid(round_director):
		return
	for turret in round_director.turrets.values():
		if turret == null or not is_instance_valid(turret):
			continue
		var candidate = turret.get("bullet_container")
		if candidate != null and is_instance_valid(candidate) and candidate.has_method("get_active_bullets"):
			bullet_pool = candidate
			return


func _apply_fire_control_guidance(bullet) -> void:
	if ProjectileTypeScript.sanitize(str(bullet.projectile_type)) != ProjectileTypeScript.STANDARD:
		return
	if battlefield == null or not is_instance_valid(battlefield):
		return
	var cell: Vector2i = battlefield.world_to_cell(bullet.global_position)
	if not battlefield.is_inside(cell):
		return
	var context: Dictionary = bullet.capture_context
	var guided_ids: Array = (context.get("guided_by_tower_ids", []) as Array).duplicate()
	for entity in registry.entities_by_id.values():
		if entity == null or not entity.is_alive():
			continue
		if str(entity.entity_kind) != BattlefieldEntityScript.KIND_DEFENSE_TOWER:
			continue
		if str(entity.tower_id) != TOWER_FIRE_CONTROL_BEACON or int(entity.owner_id) != int(bullet.faction_id):
			continue
		if str(entity.entity_id) in guided_ids or not entity.can_guide():
			continue
		if _manhattan_distance(cell, entity.cell) > int(entity.guidance_radius_cells):
			continue
		var lane_x: float = float(entity.guidance_lane_center_ratio) * float(maxi(1, int(battlefield.grid_size) - 1))
		var horizontal_error: float = clampf(
			(lane_x - float(cell.x)) / float(maxi(1, int(entity.guidance_radius_cells) * 2)),
			-1.0,
			1.0
		)
		var current_direction: Vector2 = bullet.direction.normalized()
		var desired_direction := Vector2(
			current_direction.x + horizontal_error * 0.65,
			current_direction.y
		).normalized()
		if desired_direction.length() <= 0.001:
			continue
		bullet.direction = current_direction.lerp(desired_direction, float(entity.guidance_strength)).normalized()
		entity.consume_guidance()
		guided_ids.append(str(entity.entity_id))
		context["guided_by_tower_ids"] = guided_ids
		projectile_guided.emit(entity.entity_id, entity.owner_id, bullet.projectile_type)
		_mark_visuals_dirty()
		return
	for entity in registry.entities_by_id.values():
		if (
			entity == null
			or not entity.can_act()
			or str(entity.entity_kind) != BattlefieldEntityScript.KIND_CREATURE
			or str(entity.creature_id) != CREATURE_SCOUT_UNIT
			or int(entity.owner_id) != int(bullet.faction_id)
			or str(entity.entity_id) in guided_ids
			or int(entity.metadata.get("guidance_remaining", 0)) <= 0
			or _manhattan_distance(cell, entity.cell) > 2
		):
			continue
		var lane_x: float = float(entity.metadata.get("lane_center_ratio", 0.5)) * float(
			maxi(1, int(battlefield.grid_size) - 1)
		)
		var horizontal_error: float = clampf((lane_x - float(cell.x)) / 4.0, -1.0, 1.0)
		var current_direction: Vector2 = bullet.direction.normalized()
		var desired_direction := Vector2(
			current_direction.x + horizontal_error * 0.45,
			current_direction.y
		).normalized()
		if desired_direction.length() <= 0.001:
			continue
		bullet.direction = current_direction.lerp(desired_direction, 0.18).normalized()
		entity.metadata["guidance_remaining"] = int(entity.metadata.get("guidance_remaining", 0)) - 1
		guided_ids.append(str(entity.entity_id))
		context["guided_by_tower_ids"] = guided_ids
		projectile_guided.emit(entity.entity_id, entity.owner_id, bullet.projectile_type)
		_mark_visuals_dirty()
		return


func _update_tower_power_states() -> void:
	if battlefield == null or not is_instance_valid(battlefield):
		return
	for entity in registry.entities_by_id.values():
		if entity == null or not entity.is_alive() or str(entity.entity_kind) != BattlefieldEntityScript.KIND_DEFENSE_TOWER:
			continue
		var previous_powered: bool = bool(entity.powered)
		var cell_owner: int = RulesScript.NEUTRAL_OWNER
		if battlefield.is_inside(entity.cell):
			cell_owner = int(battlefield.owners[entity.cell.x][entity.cell.y])
		entity.powered = cell_owner == int(entity.owner_id)
		if cell_owner != RulesScript.NEUTRAL_OWNER and cell_owner != int(entity.owner_id):
			entity.apply_damage(1)
		if previous_powered != bool(entity.powered):
			tower_power_changed.emit(entity.entity_id, entity.powered)


func _run_creature_actions() -> void:
	for entity in registry.entities_by_id.values():
		if entity == null or not entity.is_alive() or str(entity.entity_kind) != BattlefieldEntityScript.KIND_CREATURE:
			continue
		if not entity.can_act():
			continue
		match str(entity.behavior_type):
			"repair_frontline":
				_run_repair_unit(entity)
			"guard_frontline":
				_run_armored_guard(entity)
			"sapper_assault":
				_run_sapper_unit(entity)


func _run_repair_unit(creature) -> void:
	var target: Vector2i = _find_nearest_repairable_frontline(creature.owner_id, creature.cell)
	if target.x < 0:
		return
	if _manhattan_distance(creature.cell, target) <= 1:
		if _repair_frontline_cell(creature, target):
			return
	var next_cell: Vector2i = _next_owned_step_toward(creature.owner_id, creature.cell, target)
	if next_cell != creature.cell:
		registry.move_entity(creature.entity_id, next_cell)


func _run_armored_guard(creature) -> void:
	var target: Vector2i = _find_nearest_guard_post(creature.owner_id, creature.cell)
	if target.x < 0 or target == creature.cell:
		return
	var next_cell: Vector2i = _next_owned_step_toward(creature.owner_id, creature.cell, target)
	if next_cell != creature.cell:
		registry.move_entity(creature.entity_id, next_cell)


func _run_sapper_unit(creature) -> void:
	_sapper_system.run(creature)


func _repair_frontline_cell(creature, cell: Vector2i) -> bool:
	var key: String = _cell_key(cell)
	if _repaired_cells_this_round.has(key):
		return false
	if territory_defense_system == null or not is_instance_valid(territory_defense_system):
		return false
	var cap: int = territory_defense_system.get_owner_cap(creature.owner_id)
	var current: int = territory_defense_system.get_cell_defense(cell)
	if cap <= 0 or current >= cap:
		return false
	var fortify_layer = territory_defense_system.fortify_layer
	if fortify_layer == null:
		return false
	fortify_layer.add_fortify_stack(cell, 1)
	_repaired_cells_this_round[key] = true
	creature_repaired.emit(creature.entity_id, cell, 1)
	return true


func _process_tower_summons() -> void:
	for entity in registry.entities_by_id.values():
		if entity == null or not entity.is_alive() or str(entity.entity_kind) != BattlefieldEntityScript.KIND_DEFENSE_TOWER:
			continue
		if not entity.should_summon():
			continue
		if (
			str(entity.summon_creature_id) == CREATURE_SCOUT_UNIT
			and _has_owner_creature_id(entity.owner_id, CREATURE_SCOUT_UNIT)
		):
			entity.acknowledge_summon()
			continue
		var spawn_cell: Vector2i = _find_adjacent_spawn_cell(entity.owner_id, entity.cell)
		var is_scout: bool = str(entity.summon_creature_id) == CREATURE_SCOUT_UNIT
		var creature = registry.spawn_creature(
			_next_entity_id("summoned"),
			str(entity.summon_creature_id),
			entity.owner_id,
			spawn_cell,
			1,
			CreatureStateScript.ARMOR_NORMAL,
			1,
			"scout_guidance" if is_scout else "hold_frontline",
			-1
		)
		if creature != null:
			if is_scout:
				creature.metadata["lane_center_ratio"] = float(entity.guidance_lane_center_ratio)
				creature.metadata["guidance_remaining"] = 3
			entity.acknowledge_summon()
			entity_spawned.emit(creature.entity_id, creature.entity_kind, creature.owner_id, creature.cell)


func _has_owner_creature_id(owner_id: int, creature_id: String) -> bool:
	return _find_owner_creature_id(owner_id, creature_id) != null


func _find_owner_creature_id(owner_id: int, creature_id: String):
	for entity in registry.entities_by_id.values():
		if (
			entity != null
			and entity.is_alive()
			and str(entity.entity_kind) == BattlefieldEntityScript.KIND_CREATURE
			and int(entity.owner_id) == int(owner_id)
			and str(entity.creature_id) == str(creature_id)
		):
			return entity
	return null


func _push_creature(creature, projectile_direction: Vector2, distance: int) -> bool:
	var step := Vector2i.ZERO
	if absf(projectile_direction.x) >= absf(projectile_direction.y):
		step.x = 1 if projectile_direction.x >= 0.0 else -1
	else:
		step.y = 1 if projectile_direction.y >= 0.0 else -1
	if step == Vector2i.ZERO:
		step = Vector2i.UP
	var current: Vector2i = creature.cell
	var moved: bool = false
	for _index in range(maxi(0, int(distance))):
		var target: Vector2i = current + step
		if not battlefield.is_inside(target) or not registry.move_entity(creature.entity_id, target):
			break
		current = target
		moved = true
	return moved


func _find_nearest_repairable_frontline(owner_id: int, origin: Vector2i) -> Vector2i:
	if territory_defense_system == null or not is_instance_valid(territory_defense_system):
		return Vector2i(-1, -1)
	var cap: int = territory_defense_system.get_owner_cap(owner_id)
	var best := Vector2i(-1, -1)
	var best_distance: int = 1 << 30
	for x in range(int(battlefield.grid_size)):
		for y in range(int(battlefield.grid_size)):
			var cell := Vector2i(x, y)
			if int(battlefield.owners[x][y]) != int(owner_id):
				continue
			if territory_defense_system.get_cell_defense(cell) >= cap or not _is_frontline_cell(cell, owner_id):
				continue
			var distance: int = _manhattan_distance(origin, cell)
			if distance < best_distance:
				best = cell
				best_distance = distance
	return best


func _find_nearest_guard_post(owner_id: int, origin: Vector2i) -> Vector2i:
	var candidates: Array[Vector2i] = []
	var size: int = int(battlefield.grid_size)
	var river_y: int = size >> 1
	var gate_y: int = river_y - 1 if int(owner_id) == RulesScript.AI_FACTION else river_y
	var lanes: Array = ((map_definition.get("route_layout", {}) as Dictionary).get("lanes", []) as Array)
	if lanes.size() < 2:
		lanes = [{"center_ratio": 0.30}, {"center_ratio": 0.70}]
	for lane in lanes:
		var lane_definition: Dictionary = lane as Dictionary
		var gate_x: int = clampi(
			roundi(float(size - 1) * float(lane_definition.get("center_ratio", 0.5))),
			0,
			size - 1
		)
		var gate_cell := Vector2i(gate_x, gate_y)
		if (
			battlefield.is_inside(gate_cell)
			and int(battlefield.owners[gate_cell.x][gate_cell.y]) == int(owner_id)
		):
			candidates.append(gate_cell)
	for x in range(size):
		for y in range(size):
			var cell := Vector2i(x, y)
			if (
				int(battlefield.owners[x][y]) == int(owner_id)
				and _is_frontline_cell(cell, owner_id)
			):
				candidates.append(cell)
	var best := Vector2i(-1, -1)
	var best_distance: int = 1 << 30
	for candidate in candidates:
		var distance: int = _manhattan_distance(origin, candidate)
		if distance < best_distance:
			best = candidate
			best_distance = distance
	return best


func _command_chamber_cell(owner_id: int) -> Vector2i:
	return _sapper_system.command_chamber_cell(owner_id)


func _next_owned_step_toward(owner_id: int, origin: Vector2i, target: Vector2i) -> Vector2i:
	var best: Vector2i = origin
	var best_distance: int = _manhattan_distance(origin, target)
	for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var candidate: Vector2i = origin + offset
		if not battlefield.is_inside(candidate):
			continue
		if int(battlefield.owners[candidate.x][candidate.y]) != int(owner_id):
			continue
		var distance: int = _manhattan_distance(candidate, target)
		if distance < best_distance and registry.move_entity("__probe__", candidate) == false:
			best = candidate
			best_distance = distance
	return best


func _is_frontline_cell(cell: Vector2i, owner_id: int) -> bool:
	for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var neighbor: Vector2i = cell + offset
		if battlefield.is_inside(neighbor) and int(battlefield.owners[neighbor.x][neighbor.y]) != int(owner_id):
			return true
	return false


func _find_owner_spawn_cell(owner_id: int, index: int) -> Vector2i:
	var lane_index: int = index % 2
	var slot: Dictionary = registry.building_slots.get(_route_slot_id(owner_id, lane_index), {}) as Dictionary
	var origin: Vector2i = slot.get("cell", Vector2i.ZERO) as Vector2i
	return _find_adjacent_spawn_cell(owner_id, origin)


func _find_adjacent_spawn_cell(owner_id: int, origin: Vector2i) -> Vector2i:
	for offset in [Vector2i.ZERO, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var candidate: Vector2i = origin + offset
		if not battlefield.is_inside(candidate):
			continue
		if int(battlefield.owners[candidate.x][candidate.y]) != int(owner_id):
			continue
		if registry.get_entities_at(candidate).size() < 2:
			return candidate
	return origin


func _register_map_building_slots() -> void:
	if battlefield == null or not is_instance_valid(battlefield):
		return
	var size: int = int(battlefield.grid_size)
	var lanes: Array = ((map_definition.get("route_layout", {}) as Dictionary).get("lanes", []) as Array)
	if lanes.size() < 2:
		lanes = [{"center_ratio": 0.30}, {"center_ratio": 0.70}]
	for owner_id in RulesScript.get_duel_factions():
		var y: int = 3 if int(owner_id) == RulesScript.AI_FACTION else maxi(0, size - 4)
		for lane_index in range(2):
			var lane: Dictionary = lanes[lane_index] as Dictionary
			var x: int = clampi(roundi(float(size - 1) * float(lane.get("center_ratio", 0.5))), 0, size - 1)
			var slot_id: String = _route_slot_id(owner_id, lane_index)
			registry.register_building_slot(slot_id, Vector2i(x, y), "defense_tower")
			var slot: Dictionary = registry.building_slots[slot_id] as Dictionary
			slot["owner_id"] = int(owner_id)
			slot["lane_index"] = lane_index
			registry.building_slots[slot_id] = slot
		var chamber_slot_id: String = "%d_chamber_facility" % int(owner_id)
		var chamber_y: int = 1 if int(owner_id) == RulesScript.AI_FACTION else maxi(0, size - 2)
		registry.register_building_slot(chamber_slot_id, Vector2i(size >> 1, chamber_y), "chamber_facility")
		var chamber_slot: Dictionary = registry.building_slots[chamber_slot_id] as Dictionary
		chamber_slot["owner_id"] = int(owner_id)
		registry.building_slots[chamber_slot_id] = chamber_slot


func _route_slot_id(owner_id: int, lane_index: int) -> String:
	return "%d_route_%d" % [int(owner_id), int(lane_index)]


func _lane_center_ratio(lane_index: int) -> float:
	var lanes: Array = ((map_definition.get("route_layout", {}) as Dictionary).get("lanes", []) as Array)
	if lane_index >= 0 and lane_index < lanes.size():
		return clampf(float((lanes[lane_index] as Dictionary).get("center_ratio", 0.5)), 0.0, 1.0)
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


func _ensure_debug_layer() -> void:
	if debug_layer != null and is_instance_valid(debug_layer):
		debug_layer.setup(battlefield, registry)
		return
	debug_layer = DebugLayerScript.new()
	add_child(debug_layer)
	debug_layer.setup(battlefield, registry)


func _mark_visuals_dirty() -> void:
	if debug_layer != null and is_instance_valid(debug_layer):
		debug_layer.mark_dirty()


func _next_entity_id(prefix: String) -> String:
	_entity_serial += 1
	return "%s_%d" % [str(prefix), _entity_serial]


func _manhattan_distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


func _cell_key(cell: Vector2i) -> String:
	return "%d:%d" % [cell.x, cell.y]
