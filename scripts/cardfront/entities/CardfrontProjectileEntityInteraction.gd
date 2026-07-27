extends RefCounted
class_name CardfrontProjectileEntityInteraction

const ProjectileTypeScript = preload("res://scripts/cardfront/volley/CardfrontProjectileType.gd")
const BattlefieldEntityScript = preload("res://scripts/cardfront/entities/CardfrontBattlefieldEntity.gd")
const CreatureStateScript = preload("res://scripts/cardfront/entities/CardfrontCreatureState.gd")


static func preview(projectile_type: String, target) -> Dictionary:
	var safe_type: String = ProjectileTypeScript.sanitize(projectile_type)
	var result: Dictionary = {
		"projectile_type": safe_type,
		"target_id": "" if target == null else str(target.entity_id),
		"target_kind": "" if target == null else str(target.entity_kind),
		"damage": 0,
		"stun_rounds": 0,
		"disable_rounds": 0,
		"push_cells": 0,
		"consume_projectile": target != null,
		"bounce_projectile": false,
		"block_territory": target != null,
		"valid": target != null,
	}
	if target == null or not target.is_alive():
		result["valid"] = false
		result["consume_projectile"] = false
		result["block_territory"] = false
		return result

	match str(target.entity_kind):
		BattlefieldEntityScript.KIND_CREATURE:
			_resolve_creature(safe_type, target, result)
		BattlefieldEntityScript.KIND_DEFENSE_TOWER:
			_resolve_tower(safe_type, result)
		BattlefieldEntityScript.KIND_COMMAND_CHAMBER:
			_resolve_chamber(safe_type, result)
		_:
			result["valid"] = false
			result["consume_projectile"] = false
			result["block_territory"] = false
	return result


static func apply(projectile_type: String, target) -> Dictionary:
	var result: Dictionary = preview(projectile_type, target)
	if not bool(result.get("valid", false)):
		return result
	var damage_applied: int = target.apply_damage(maxi(0, int(result.get("damage", 0))))
	result["damage_applied"] = damage_applied
	var stun_rounds: int = maxi(0, int(result.get("stun_rounds", 0)))
	if stun_rounds > 0:
		target.add_status("stunned", stun_rounds)
	var disable_rounds: int = maxi(0, int(result.get("disable_rounds", 0)))
	if disable_rounds > 0:
		target.add_status("disabled", disable_rounds)
	return result


static func _resolve_creature(projectile_type: String, target, result: Dictionary) -> void:
	match projectile_type:
		ProjectileTypeScript.SUPPRESSION:
			result["stun_rounds"] = 1
			result["push_cells"] = 1
			result["consume_projectile"] = true
		ProjectileTypeScript.SIEGE:
			result["damage"] = 2 if str(target.armor_type) == CreatureStateScript.ARMOR_ARMORED else 1
			result["consume_projectile"] = true
		_:
			result["damage"] = 1
			result["consume_projectile"] = false
			result["bounce_projectile"] = true


static func _resolve_tower(projectile_type: String, result: Dictionary) -> void:
	match projectile_type:
		ProjectileTypeScript.SUPPRESSION:
			result["disable_rounds"] = 1
			result["consume_projectile"] = true
		ProjectileTypeScript.SIEGE:
			result["damage"] = 3
			result["consume_projectile"] = true
		_:
			result["damage"] = 1
			result["consume_projectile"] = false
			result["bounce_projectile"] = true


static func _resolve_chamber(projectile_type: String, result: Dictionary) -> void:
	result["consume_projectile"] = true
	match projectile_type:
		ProjectileTypeScript.SUPPRESSION:
			result["damage"] = 0
		ProjectileTypeScript.SIEGE:
			result["damage"] = 2
		_:
			result["damage"] = 1
