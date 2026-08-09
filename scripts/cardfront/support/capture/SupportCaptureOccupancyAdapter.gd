extends RefCounted
class_name SupportCaptureOccupancyAdapter

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const BattlefieldEntityScript = preload("res://scripts/cardfront/entities/CardfrontBattlefieldEntity.gd")
const ContributorScript = preload("res://scripts/cardfront/support/capture/SupportCaptureContributor.gd")
const ProfilesScript = preload("res://scripts/cardfront/support/capture/SupportCaptureProfiles.gd")


static func extract(registry, footprint_cells: Array[Vector2i]) -> Array:
	var contributors: Array = []
	if registry == null or not registry.has_method("get_entities_at"):
		return contributors

	var seen_entities: Dictionary = {}
	for cell in footprint_cells:
		for entity in registry.get_entities_at(cell):
			if entity == null:
				continue
			var entity_id: String = str(entity.get("entity_id"))
			if entity_id == "" or seen_entities.has(entity_id):
				continue
			seen_entities[entity_id] = true
			if str(entity.get("entity_kind")) != BattlefieldEntityScript.KIND_CREATURE:
				continue
			if not entity.has_method("is_alive") or not bool(entity.is_alive()):
				continue
			var owner_id: int = int(entity.get("owner_id"))
			if owner_id != RulesScript.PLAYER_FACTION and owner_id != RulesScript.AI_FACTION:
				continue

			var profile_id: String = ProfilesScript.profile_for_creature(str(entity.get("creature_id")))
			var weight: float = ProfilesScript.weight_for_profile(profile_id)
			var contributor = ContributorScript.new()
			contributor.setup(
				entity_id,
				owner_id,
				profile_id,
				weight,
				entity.get("cell") as Vector2i,
				weight > 0.0
			)
			contributors.append(contributor)

	contributors.sort_custom(func(left, right): return str(left.entity_id) < str(right.entity_id))
	return contributors
