extends RefCounted
class_name CardTargetRuleRegistry

var _rules: Dictionary = {}


func register(target_type: String, rule) -> void:
	if str(target_type).is_empty() or rule == null:
		return
	if not rule.has_method("validate"):
		return
	_rules[str(target_type)] = rule


func get_rule(target_type: String):
	return _rules.get(str(target_type), null)


func has_rule(target_type: String) -> bool:
	return _rules.has(str(target_type))


func get_registered_target_types() -> Array:
	var ids: Array = _rules.keys()
	ids.sort()
	return ids


func clear() -> void:
	_rules.clear()
