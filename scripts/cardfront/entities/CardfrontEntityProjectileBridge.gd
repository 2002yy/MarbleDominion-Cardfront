extends RefCounted
class_name CardfrontEntityProjectileBridge

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const ProjectileTypeScript = preload("res://scripts/cardfront/volley/CardfrontProjectileType.gd")
const BattlefieldEntityScript = preload("res://scripts/cardfront/entities/CardfrontBattlefieldEntity.gd")
const InteractionScript = preload("res://scripts/cardfront/entities/CardfrontProjectileEntityInteraction.gd")

var runtime = null


func setup(new_runtime) -> void:
	runtime = new_runtime


func resolve_capture_contact(
	cell: Vector2i,
	incoming_owner_id: int,
	capture_context: Dictionary
) -> Dictionary:
	var empty_result: Dictionary = {
		"valid": false,
		"block_territory": false,
		"consume_projectile": false,
		"bounce_projectile": false,
	}
	if runtime.registry == null:
		return empty_result
	var targets: Array = runtime.registry.get_collision_targets(cell, incoming_owner_id)
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
	result["cell"] = cell

	var push_cells: int = maxi(0, int(result.get("push_cells", 0)))
	if push_cells > 0 and str(target.entity_kind) == BattlefieldEntityScript.KIND_CREATURE:
		var direction: Vector2 = capture_context.get("projectile_direction", Vector2.ZERO) as Vector2
		result["pushed"] = runtime._push_creature(target, direction, push_cells)

	if str(target.entity_kind) == BattlefieldEntityScript.KIND_DEFENSE_TOWER:
		if (
			bool(result.get("intercepted", false))
			and int(target.tower_level) >= 3
			and int(target.intercepts_remaining) <= 0
		):
			var incoming_direction: Vector2 = capture_context.get(
				"projectile_direction",
				Vector2.RIGHT
			) as Vector2
			runtime._spawn_counter_projectile(target, -incoming_direction)
		if not bool(result.get("intercepted", false)):
			try_apply_heavy_charge(cell, incoming_owner_id, target, capture_context, result)

	runtime._cleanup_dead_entities()
	capture_context["entity_contact_target_id"] = str(result.get("target_id", ""))
	capture_context["entity_consume_projectile"] = bool(result.get("consume_projectile", false))
	if bool(result.get("bounce_projectile", false)):
		var incoming_direction: Vector2 = capture_context.get(
			"projectile_direction",
			Vector2.RIGHT
		) as Vector2
		if incoming_direction.length() <= 0.001:
			incoming_direction = Vector2.RIGHT
		capture_context["entity_bounce_direction"] = (-incoming_direction).normalized()
	else:
		capture_context.erase("entity_bounce_direction")
	runtime.entity_contact_resolved.emit(result.duplicate(true))
	runtime._mark_visuals_dirty()
	return result


func process_active_bullets(resolve_live_contacts: bool) -> void:
	if runtime.bullet_pool == null or not is_instance_valid(runtime.bullet_pool):
		resolve_bullet_pool()
	if (
		runtime.bullet_pool == null
		or not is_instance_valid(runtime.bullet_pool)
		or not runtime.bullet_pool.has_method("get_active_bullets")
	):
		return
	for bullet in runtime.bullet_pool.get_active_bullets():
		if bullet == null or not is_instance_valid(bullet) or not bool(bullet.get("is_active")):
			continue
		var context: Dictionary = bullet.capture_context
		context["projectile_direction"] = bullet.direction
		if resolve_live_contacts:
			_resolve_live_contact(bullet, context)
		if bool(context.get("entity_consume_projectile", false)):
			context.erase("entity_consume_projectile")
			context.erase("entity_bounce_direction")
			if bullet.has_method("_despawn"):
				bullet.call("_despawn")
			continue
		if context.has("entity_bounce_direction"):
			var bounce_direction: Vector2 = context.get(
				"entity_bounce_direction",
				Vector2.RIGHT
			) as Vector2
			context.erase("entity_bounce_direction")
			if bounce_direction.length() > 0.001:
				bullet.direction = bounce_direction.normalized()
		apply_fire_control_guidance(bullet)
		context["projectile_direction"] = bullet.direction


func resolve_bullet_pool() -> void:
	runtime.bullet_pool = null
	if runtime.round_director == null or not is_instance_valid(runtime.round_director):
		return
	var raw_turrets = runtime.round_director.get("turrets")
	if not (raw_turrets is Dictionary):
		return
	for turret in (raw_turrets as Dictionary).values():
		if turret == null or not is_instance_valid(turret):
			continue
		var candidate = turret.get("bullet_container")
		if (
			candidate != null
			and is_instance_valid(candidate)
			and candidate.has_method("get_active_bullets")
		):
			runtime.bullet_pool = candidate
			return


func apply_fire_control_guidance(bullet) -> void:
	if ProjectileTypeScript.sanitize(str(bullet.projectile_type)) != ProjectileTypeScript.STANDARD:
		return
	if runtime.battlefield == null or not is_instance_valid(runtime.battlefield):
		return
	var cell: Vector2i = runtime.battlefield.world_to_cell(bullet.global_position)
	if not runtime.battlefield.is_inside(cell):
		return
	var context: Dictionary = bullet.capture_context
	var guided_ids: Array = (context.get("guided_by_tower_ids", []) as Array).duplicate()
	for entity in runtime.registry.entities_by_id.values():
		if entity == null or not entity.is_alive():
			continue
		if str(entity.entity_kind) != BattlefieldEntityScript.KIND_DEFENSE_TOWER:
			continue
		if (
			str(entity.tower_id) != runtime.TOWER_FIRE_CONTROL_BEACON
			or int(entity.owner_id) != int(bullet.faction_id)
			or str(entity.entity_id) in guided_ids
			or not entity.can_guide()
			or runtime._manhattan_distance(cell, entity.cell) > int(entity.guidance_radius_cells)
		):
			continue
		var lane_x: float = float(entity.guidance_lane_center_ratio) * float(
			maxi(1, int(runtime.battlefield.grid_size) - 1)
		)
		var horizontal_error: float = clampf(
			(lane_x - float(cell.x))
			/ float(maxi(1, int(entity.guidance_radius_cells) * 2)),
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
		bullet.direction = current_direction.lerp(
			desired_direction,
			float(entity.guidance_strength)
		).normalized()
		entity.consume_guidance()
		_emit_guidance(entity, bullet, guided_ids, context)
		return
	for entity in runtime.registry.entities_by_id.values():
		if (
			entity == null
			or not entity.can_act()
			or str(entity.entity_kind) != BattlefieldEntityScript.KIND_CREATURE
			or str(entity.creature_id) != runtime.CREATURE_SCOUT_UNIT
			or int(entity.owner_id) != int(bullet.faction_id)
			or str(entity.entity_id) in guided_ids
			or int(entity.metadata.get("guidance_remaining", 0)) <= 0
			or runtime._manhattan_distance(cell, entity.cell) > 2
		):
			continue
		var lane_x: float = float(entity.metadata.get("lane_center_ratio", 0.5)) * float(
			maxi(1, int(runtime.battlefield.grid_size) - 1)
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
		entity.metadata["guidance_remaining"] = (
			int(entity.metadata.get("guidance_remaining", 0)) - 1
		)
		_emit_guidance(entity, bullet, guided_ids, context)
		return


func try_apply_heavy_charge(
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
	var center_damage: int = center_target.apply_damage(
		maxi(0, int(spec.get("center_bonus", 1)))
	)
	var entity_radius: int = maxi(0, int(spec.get("entity_radius", 2)))
	var entity_damage: int = maxi(0, int(spec.get("entity_damage", 1)))
	var splash_hits: Array = []
	for entity in runtime.registry.entities_by_id.values():
		if (
			entity == null
			or entity == center_target
			or not entity.is_alive()
			or int(entity.owner_id) == int(incoming_owner_id)
			or runtime._manhattan_distance(cell, entity.cell) > entity_radius
		):
			continue
		var applied: int = entity.apply_damage(entity_damage)
		if applied > 0:
			splash_hits.append({"entity_id": str(entity.entity_id), "damage": applied})
	var defense_hits: Array = _damage_defense(cell, incoming_owner_id, spec)
	result["heavy_charge"] = {
		"center_damage": center_damage,
		"splash_hits": splash_hits,
		"defense_hits": defense_hits,
	}
	runtime.heavy_charge_exploded.emit(
		incoming_owner_id,
		cell,
		str(center_target.entity_id)
	)


func _resolve_live_contact(bullet, context: Dictionary) -> void:
	var cell: Vector2i = runtime.battlefield.world_to_cell(bullet.global_position)
	if not runtime.battlefield.is_inside(cell):
		return
	var cell_key: String = runtime._cell_key(cell)
	if str(context.get("entity_contact_cell_key", "")) == cell_key:
		return
	if runtime.registry.get_collision_targets(cell, int(bullet.faction_id)).is_empty():
		context.erase("entity_contact_cell_key")
		return
	var result: Dictionary = resolve_capture_contact(cell, int(bullet.faction_id), context)
	if bool(result.get("valid", false)):
		context["entity_contact_cell_key"] = cell_key


func _emit_guidance(entity, bullet, guided_ids: Array, context: Dictionary) -> void:
	guided_ids.append(str(entity.entity_id))
	context["guided_by_tower_ids"] = guided_ids
	runtime.projectile_guided.emit(entity.entity_id, entity.owner_id, bullet.projectile_type)
	runtime._mark_visuals_dirty()


func _damage_defense(cell: Vector2i, incoming_owner_id: int, spec: Dictionary) -> Array:
	var defense_hits: Array = []
	var radius: int = maxi(0, int(spec.get("defense_radius", 1)))
	var damage: int = maxi(0, int(spec.get("defense_damage", 1)))
	if (
		damage <= 0
		or runtime.territory_defense_system == null
		or not is_instance_valid(runtime.territory_defense_system)
		or runtime.territory_defense_system.fortify_layer == null
	):
		return defense_hits
	for x in range(cell.x - radius, cell.x + radius + 1):
		for y in range(cell.y - radius, cell.y + radius + 1):
			var target_cell := Vector2i(x, y)
			if (
				not runtime.battlefield.is_inside(target_cell)
				or runtime._manhattan_distance(cell, target_cell) > radius
				or int(runtime.battlefield.owners[x][y]) == int(incoming_owner_id)
				or int(runtime.battlefield.owners[x][y]) == RulesScript.NEUTRAL_OWNER
			):
				continue
			var removed: int = 0
			for _damage_index in range(damage):
				if (
					runtime.territory_defense_system.fortify_layer.get_fortify_stack(
						target_cell
					)
					<= 0
				):
					break
				runtime.territory_defense_system.fortify_layer.consume_hit(target_cell)
				removed += 1
			if removed > 0:
				defense_hits.append({"cell": target_cell, "damage": removed})
	return defense_hits
