extends RefCounted
class_name CardfrontHeroDefinition

const REQUIRED_KEYS: Array[String] = [
	"id",
	"name",
	"base_volley_count",
	"command_chamber_health",
	"starting_territory_defense",
	"starting_contact_front_defense",
	"territory_defense_cap",
	"strategic_identity",
]


static func validate(definition: Dictionary) -> Array:
	var errors: Array = []
	var hero_id: String = str(definition.get("id", ""))
	for key in REQUIRED_KEYS:
		if not definition.has(key):
			errors.append("missing_key:%s:%s" % [hero_id, key])
	if hero_id == "":
		errors.append("missing_id")
	if str(definition.get("name", "")) == "":
		errors.append("missing_name:%s" % hero_id)
	if int(definition.get("base_volley_count", 0)) <= 0:
		errors.append("invalid_base_volley:%s" % hero_id)
	if int(definition.get("command_chamber_health", 0)) <= 0:
		errors.append("invalid_chamber_health:%s" % hero_id)
	var starting_defense: int = int(definition.get("starting_territory_defense", -1))
	var contact_front_defense: int = int(definition.get("starting_contact_front_defense", -1))
	var defense_cap: int = int(definition.get("territory_defense_cap", 0))
	if starting_defense < 0:
		errors.append("invalid_starting_defense:%s" % hero_id)
	if contact_front_defense < 0:
		errors.append("invalid_contact_front_defense:%s" % hero_id)
	if defense_cap <= 0:
		errors.append("invalid_defense_cap:%s" % hero_id)
	if starting_defense > defense_cap:
		errors.append("starting_defense_exceeds_cap:%s" % hero_id)
	if contact_front_defense < starting_defense:
		errors.append("contact_front_below_starting_defense:%s" % hero_id)
	if contact_front_defense > defense_cap:
		errors.append("contact_front_defense_exceeds_cap:%s" % hero_id)
	return errors
