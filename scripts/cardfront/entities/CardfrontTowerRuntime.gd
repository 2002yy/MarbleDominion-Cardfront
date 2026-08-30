extends RefCounted
class_name CardfrontTowerRuntime

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const ProjectileTypeScript = preload("res://scripts/cardfront/volley/CardfrontProjectileType.gd")
const BattlefieldEntityScript = preload("res://scripts/cardfront/entities/CardfrontBattlefieldEntity.gd")
const CreatureStateScript = preload("res://scripts/cardfront/entities/CardfrontCreatureState.gd")
const UpgradeManifestScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeManifest.gd")

var runtime = null


func setup(new_runtime) -> void:
	runtime = new_runtime


func decorate_volley_plan(owner_id: int, plan) -> void:
	if plan == null:
		return
	plan.building_sources.clear()
	plan.building_shot_count = 0
	var level: int = clampi(int(plan.building_volley_level), 0, 3)
	if level <= 0:
		return
	var shots_per_tower: int = UpgradeManifestScript.building_volley_shots_per_tower(level)
	var remaining_budget: int = maxi(0, runtime.BUILDING_VOLLEY_TOTAL_CAP - int(plan.shot_count))
	for tower in owner_towers(owner_id):
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


func build_or_upgrade(owner_id: int, tower_id: String) -> Dictionary:
	var safe_tower_id: String = str(tower_id)
	if safe_tower_id not in [runtime.TOWER_FIRE_CONTROL_BEACON, runtime.TOWER_INTERCEPTOR]:
		return {"action": "build_or_upgrade_tower", "success": false, "reason": "unknown_tower"}
	var existing = find_owner_tower(owner_id, safe_tower_id)
	if existing != null:
		if int(existing.tower_level) >= 3:
			return {
				"action": "build_or_upgrade_tower",
				"success": false,
				"reason": "tower_max_level",
			}
		var previous_level := int(existing.tower_level)
		configure_level(existing, previous_level + 1)
		runtime.tower_level_changed.emit(
			str(existing.entity_id),
			int(existing.owner_id),
			previous_level,
			int(existing.tower_level)
		)
		runtime._mark_visuals_dirty()
		return {
			"action": "build_or_upgrade_tower",
			"success": true,
			"built": false,
			"tower_id": safe_tower_id,
			"level": int(existing.tower_level),
		}
	var lane_index: int = first_free_lane(owner_id)
	if lane_index < 0:
		return {
			"action": "build_or_upgrade_tower",
			"success": false,
			"reason": "no_free_tower_slot",
		}
	var tower = spawn_tower(owner_id, safe_tower_id, lane_index)
	return {
		"action": "build_or_upgrade_tower",
		"success": tower != null,
		"built": tower != null,
		"tower_id": safe_tower_id,
		"level": 1 if tower != null else 0,
		"reason": "" if tower != null else "spawn_failed",
	}


func spawn_tower(owner_id: int, tower_id: String, lane_index: int):
	var safe_lane: int = clampi(int(lane_index), 0, 1)
	var slot_id: String = runtime._route_slot_id(owner_id, safe_lane)
	var tower_hp: int = (
		runtime.DEFAULT_FIRE_CONTROL_HP
		if tower_id == runtime.TOWER_FIRE_CONTROL_BEACON
		else runtime.DEFAULT_INTERCEPTOR_HP
	)
	var tower = runtime.registry.spawn_defense_tower(
		runtime._next_entity_id(str(tower_id)),
		tower_id,
		owner_id,
		slot_id,
		tower_hp
	)
	if tower == null:
		return null
	tower.metadata["lane_index"] = safe_lane
	tower.metadata["prototype_only"] = false
	configure_level(tower, 1)
	runtime.entity_spawned.emit(tower.entity_id, tower.entity_kind, tower.owner_id, tower.cell)
	runtime._mark_visuals_dirty()
	return tower


func configure_level(tower, level: int) -> void:
	if tower == null:
		return
	var safe_level: int = clampi(int(level), 1, 3)
	tower.set_tower_level(safe_level)
	match str(tower.tower_id):
		runtime.TOWER_FIRE_CONTROL_BEACON:
			var guidance_by_level: Array = [6, 8, 10]
			tower.configure_guidance(
				int(guidance_by_level[safe_level - 1]),
				runtime._lane_center_ratio(int(tower.metadata.get("lane_index", 0))),
				runtime.DEFAULT_GUIDANCE_STRENGTH,
				runtime.DEFAULT_GUIDANCE_RADIUS_CELLS
			)
			if safe_level >= 2:
				tower.configure_summoner(runtime.CREATURE_SCOUT_UNIT, 3 if safe_level == 2 else 2)
			else:
				tower.configure_summoner("", 0)
		runtime.TOWER_INTERCEPTOR:
			var intercepts_by_level: Array = [2, 3, 3]
			tower.configure_interceptor(int(intercepts_by_level[safe_level - 1]))


func owner_towers(owner_id: int) -> Array:
	var towers: Array = []
	for entity in runtime.registry.entities_by_id.values():
		if (
			entity != null
			and entity.is_alive()
			and int(entity.owner_id) == int(owner_id)
			and str(entity.entity_kind) == BattlefieldEntityScript.KIND_DEFENSE_TOWER
		):
			towers.append(entity)
	towers.sort_custom(func(a, b): return str(a.entity_id) < str(b.entity_id))
	return towers


func find_owner_tower(owner_id: int, tower_id: String):
	for tower in owner_towers(owner_id):
		if str(tower.tower_id) == str(tower_id):
			return tower
	return null


func first_free_lane(owner_id: int) -> int:
	for lane_index in range(2):
		var slot: Dictionary = runtime.registry.building_slots.get(
			runtime._route_slot_id(owner_id, lane_index),
			{}
		) as Dictionary
		if not slot.is_empty() and str(slot.get("entity_id", "")) == "":
			return lane_index
	return -1


func spawn_building_volley(owner_id: int, plan) -> void:
	if (
		plan == null
		or runtime.bullet_pool == null
		or not is_instance_valid(runtime.bullet_pool)
	):
		return
	var target_turrets: Dictionary = _target_turrets()
	var heavy_pool: Dictionary = plan.heavy_charge_pool
	for raw_source in plan.building_sources:
		if not (raw_source is Dictionary):
			continue
		var source: Dictionary = raw_source as Dictionary
		var tower = runtime.registry.get_entity(str(source.get("entity_id", "")))
		if tower == null or not tower.can_act():
			continue
		var shot_count: int = maxi(0, int(source.get("shot_count", 0)))
		var base_direction := (
			Vector2.UP if int(owner_id) == RulesScript.PLAYER_FACTION else Vector2.DOWN
		)
		var source_position: Vector2 = runtime.battlefield.to_global(
			(Vector2(tower.cell) + Vector2(0.5, 0.5)) * float(runtime.battlefield.cell_size)
		)
		for shot_index in range(shot_count):
			var spread_index: float = float(shot_index) - float(shot_count - 1) * 0.5
			var direction: Vector2 = base_direction.rotated(spread_index * 0.035)
			runtime.bullet_pool.spawn_bullet(
				owner_id,
				source_position + direction * maxf(4.0, float(runtime.battlefield.cell_size) * 0.38),
				direction,
				runtime.battlefield,
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
			runtime.building_volley_fired.emit(owner_id, tower.entity_id, shot_count)


func spawn_counter_projectile(tower, incoming_direction: Vector2) -> void:
	if (
		tower == null
		or runtime.bullet_pool == null
		or not is_instance_valid(runtime.bullet_pool)
	):
		return
	var direction: Vector2 = incoming_direction.normalized()
	if direction.length() <= 0.001:
		direction = (
			Vector2.UP
			if int(tower.owner_id) == RulesScript.PLAYER_FACTION
			else Vector2.DOWN
		)
	var source_position: Vector2 = runtime.battlefield.to_global(
		(Vector2(tower.cell) + Vector2(0.5, 0.5)) * float(runtime.battlefield.cell_size)
	)
	runtime.bullet_pool.spawn_bullet(
		int(tower.owner_id),
		source_position + direction * maxf(4.0, float(runtime.battlefield.cell_size) * 0.38),
		direction,
		runtime.battlefield,
		_target_turrets(),
		1,
		4,
		{
			"projectile_type": ProjectileTypeScript.STANDARD,
			"projectile_defense_pierce_remaining": 0,
			"armor_pierce_pool": {"remaining": 0},
		}
	)
	runtime.tower_counter_fired.emit(tower.entity_id, tower.owner_id)


func update_power_states() -> void:
	if runtime.battlefield == null or not is_instance_valid(runtime.battlefield):
		return
	for entity in runtime.registry.entities_by_id.values():
		if (
			entity == null
			or not entity.is_alive()
			or str(entity.entity_kind) != BattlefieldEntityScript.KIND_DEFENSE_TOWER
		):
			continue
		var previous_powered: bool = bool(entity.powered)
		var cell_owner: int = RulesScript.NEUTRAL_OWNER
		if runtime.battlefield.is_inside(entity.cell):
			cell_owner = int(runtime.battlefield.owners[entity.cell.x][entity.cell.y])
		entity.powered = cell_owner == int(entity.owner_id)
		if cell_owner != RulesScript.NEUTRAL_OWNER and cell_owner != int(entity.owner_id):
			entity.apply_damage(1)
		if previous_powered != bool(entity.powered):
			runtime.tower_power_changed.emit(entity.entity_id, entity.powered)


func process_summons() -> void:
	for entity in runtime.registry.entities_by_id.values():
		if (
			entity == null
			or not entity.is_alive()
			or str(entity.entity_kind) != BattlefieldEntityScript.KIND_DEFENSE_TOWER
			or not entity.should_summon()
		):
			continue
		if (
			str(entity.summon_creature_id) == runtime.CREATURE_SCOUT_UNIT
			and runtime._has_owner_creature_id(entity.owner_id, runtime.CREATURE_SCOUT_UNIT)
		):
			entity.acknowledge_summon()
			continue
		var spawn_cell: Vector2i = runtime._find_adjacent_spawn_cell(entity.owner_id, entity.cell)
		var is_scout: bool = str(entity.summon_creature_id) == runtime.CREATURE_SCOUT_UNIT
		var creature = runtime.registry.spawn_creature(
			runtime._next_entity_id("summoned"),
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
			runtime.entity_spawned.emit(
				creature.entity_id,
				creature.entity_kind,
				creature.owner_id,
				creature.cell
			)


func _target_turrets() -> Dictionary:
	if runtime.round_director == null or not is_instance_valid(runtime.round_director):
		return {}
	var raw_turrets = runtime.round_director.get("turrets")
	return raw_turrets as Dictionary if raw_turrets is Dictionary else {}
