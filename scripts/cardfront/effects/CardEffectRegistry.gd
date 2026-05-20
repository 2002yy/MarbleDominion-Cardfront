extends RefCounted

var _effects: Dictionary = {}


func register(effect_id: String, effect) -> void:
	if effect_id.is_empty() or effect == null:
		return
	if not effect.has_method("resolve"):
		return
	_effects[str(effect_id)] = effect


func get_effect(effect_id: String):
	return _effects.get(str(effect_id), null)


func has_effect(effect_id: String) -> bool:
	return _effects.has(str(effect_id))


func get_registered_effect_ids() -> Array:
	var ids: Array = _effects.keys()
	ids.sort()
	return ids


func clear() -> void:
	_effects.clear()
