extends RefCounted
class_name CardfrontMapBalanceTargetEvaluator

const MapRegistryScript = preload("res://scripts/cardfront/maps/CardfrontMapRegistry.gd")
const ConfigScript = preload("res://scripts/cardfront/simulation/CardfrontBalanceSimulationConfig.gd")

const METRIC_PATHS: Dictionary = {
	"median_round": ["pacing", "median_round"],
	"p90_round": ["pacing", "p90_round"],
	"timeout_rate": ["pacing", "timeout_rate"],
	"blue_point_rate": ["blue_point_rate"],
	"lane0_share": ["route_metrics", "lane_share", "0"],
	"route_rejection_rate": ["route_metrics", "route_rejection_rate"],
}


static func evaluate(map_reports: Dictionary) -> Dictionary:
	var evaluations: Dictionary = {}
	var overall_passed: bool = true
	for raw_map_id in MapRegistryScript.get_registered_map_ids():
		var map_id: String = str(raw_map_id)
		var definition: Dictionary = MapRegistryScript.get_map_definition(map_id, ConfigScript.GRID_SIZE)
		var targets: Dictionary = definition.get("balance_targets", {}) as Dictionary
		var map_report: Dictionary = map_reports.get(map_id, {}) as Dictionary
		var checks: Dictionary = {}
		var map_passed: bool = not map_report.is_empty() and not targets.is_empty()
		for metric_id in METRIC_PATHS.keys():
			var actual: float = _read_path(map_report, METRIC_PATHS[metric_id] as Array)
			var minimum: float = float(targets.get("%s_min" % metric_id, -INF))
			var maximum: float = float(targets.get("%s_max" % metric_id, INF))
			var passed: bool = actual >= minimum and actual <= maximum
			checks[metric_id] = {
				"actual": actual,
				"minimum": minimum,
				"maximum": maximum,
				"passed": passed,
			}
			map_passed = map_passed and passed
		evaluations[map_id] = {
			"pacing_identity": str(targets.get("pacing_identity", "")),
			"passed": map_passed,
			"checks": checks,
		}
		overall_passed = overall_passed and map_passed
	return {
		"passed": overall_passed,
		"maps": evaluations,
	}


static func format_summary(evaluation: Dictionary) -> String:
	var lines: Array[String] = ["Map balance targets passed=%s" % str(bool(evaluation.get("passed", false)))]
	var maps: Dictionary = evaluation.get("maps", {}) as Dictionary
	var map_ids: Array = maps.keys()
	map_ids.sort()
	for raw_map_id in map_ids:
		var map_id: String = str(raw_map_id)
		var map_evaluation: Dictionary = maps[raw_map_id] as Dictionary
		var parts: Array[String] = []
		var checks: Dictionary = map_evaluation.get("checks", {}) as Dictionary
		for metric_id in METRIC_PATHS.keys():
			var check: Dictionary = checks.get(metric_id, {}) as Dictionary
			parts.append("%s=%.2f[%.2f,%.2f]%s" % [
				str(metric_id),
				float(check.get("actual", 0.0)),
				float(check.get("minimum", 0.0)),
				float(check.get("maximum", 0.0)),
				"✓" if bool(check.get("passed", false)) else "✗",
			])
		lines.append("%s %s passed=%s %s" % [
			map_id,
			str(map_evaluation.get("pacing_identity", "")),
			str(bool(map_evaluation.get("passed", false))),
			" ".join(parts),
		])
	return "\n".join(lines)


static func _read_path(source: Dictionary, path: Array) -> float:
	var current: Variant = source
	for raw_key in path:
		if not current is Dictionary:
			return 0.0
		current = (current as Dictionary).get(str(raw_key), 0.0)
	return float(current)
