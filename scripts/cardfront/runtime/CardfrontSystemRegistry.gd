extends RefCounted
class_name CardfrontSystemRegistry

const RuntimeRefsScript = preload("res://scripts/cardfront/runtime/CardfrontRuntimeRefs.gd")

const RUNTIME_FIELD_BY_RESULT_KEY: Dictionary = {
	"region_map": "region_map",
	"region_overlay": "region_overlay",
	"region_control_block_layer": "region_control_block_layer",
	"stronghold_system": "stronghold_system",
	"fortify_layer": "fortify_layer",
	"fortify_overlay": "fortify_overlay",
	"territory_defense_system": "territory_defense_system",
	"support_capture_runtime": "support_capture_runtime",
	"fire_director": "fire_director",
	"region_info_panel": "region_info_panel",
	"arena_presentation_layer": "arena_presentation_layer",
	"orthographic_arena_view": "orthographic_arena_view",
	"gate_connectivity_system": "gate_connectivity_system",
	"command_chambers": "command_chambers",
	"direction_controller": "direction_controller",
	"aim_guide_layer": "aim_guide_layer",
	"round_director": "round_director",
	"faction_run_states": "faction_run_states",
}

var refs = RuntimeRefsScript.new()
var failures: Array = []


func clear() -> void:
	refs.clear()
	failures.clear()


func record_result(stage: String, result: Dictionary) -> bool:
	if not bool(result.get("configured", false)):
		failures.append({
			"stage": stage,
			"reason": str(result.get("reason", "unknown")),
		})
		return false
	refs.merge_result(result)
	return true


func apply_to(runtime) -> void:
	if runtime == null:
		return
	var refs_snapshot: Dictionary = refs.snapshot()
	for key in refs_snapshot.keys():
		var runtime_field: String = str(RUNTIME_FIELD_BY_RESULT_KEY.get(str(key), ""))
		if runtime_field == "":
			continue
		runtime.set(runtime_field, refs_snapshot[key])


func snapshot() -> Dictionary:
	return refs.snapshot()


func failure_snapshot() -> Array:
	return failures.duplicate(true)


func has_failures() -> bool:
	return not failures.is_empty()
