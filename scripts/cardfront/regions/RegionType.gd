extends RefCounted
class_name RegionType

const NORMAL: String = "normal"
const ENERGY: String = "energy"
const FACTORY: String = "factory"
const LAB: String = "lab"


static func all_types() -> Array:
	return [NORMAL, ENERGY, FACTORY, LAB]


static func is_valid(region_type: String) -> bool:
	return region_type in all_types()
