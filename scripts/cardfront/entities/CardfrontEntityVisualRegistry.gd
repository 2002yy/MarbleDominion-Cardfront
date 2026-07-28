extends RefCounted
class_name CardfrontEntityVisualRegistry

const NEUTRAL_BASE: String = (
	"res://assets/cardfront_runtime/中立生物_neutral_creatures/256/"
)
const ENTITY_BASE: String = (
	"res://assets/cardfront_runtime/战场实体_battlefield_entities/256/"
)

const GATE_COLOSSUS: String = "gate_colossus"
const REPAIR_UNIT: String = "repair_unit"
const ARMORED_GUARD: String = "armored_guard"
const SAPPER_UNIT: String = "sapper_unit"
const SCOUT_UNIT: String = "scout_unit"

var _visual_specs: Dictionary = {
	GATE_COLOSSUS: {
		"root": NEUTRAL_BASE + "gate_colossus/",
		"static": NEUTRAL_BASE + "闸门巨像_gate_colossus_v01_256.png",
		"default_action": "attack",
		"animations": {
			"idle": {"count": 4, "fps": 5.0, "loop": true},
			"move": {"count": 6, "fps": 8.0, "loop": true},
			"attack": {"count": 6, "fps": 10.0, "loop": false},
			"hit": {"count": 4, "fps": 12.0, "loop": false},
			"death": {"count": 6, "fps": 10.0, "loop": false},
		},
	},
	REPAIR_UNIT: {
		"root": ENTITY_BASE + "repair_unit/",
		"default_action": "repair",
		"animations": {
			"idle": {"count": 4, "fps": 5.0, "loop": true},
			"move": {"count": 6, "fps": 8.0, "loop": true},
			"repair": {"count": 6, "fps": 10.0, "loop": false},
			"hit": {"count": 4, "fps": 12.0, "loop": false},
			"death": {"count": 6, "fps": 10.0, "loop": false},
		},
	},
	ARMORED_GUARD: {
		"root": ENTITY_BASE + "armored_guard/",
		"default_action": "block",
		"animations": {
			"idle": {"count": 4, "fps": 5.0, "loop": true},
			"move": {"count": 6, "fps": 8.0, "loop": true},
			"block": {"count": 6, "fps": 12.0, "loop": false},
			"hit": {"count": 4, "fps": 12.0, "loop": false},
			"death": {"count": 6, "fps": 10.0, "loop": false},
		},
	},
	SAPPER_UNIT: {
		"root": ENTITY_BASE + "sapper_unit/",
		"default_action": "attack",
		"terminal_action": "detonate",
		"animations": {
			"idle": {"count": 4, "fps": 5.0, "loop": true},
			"move": {"count": 6, "fps": 8.0, "loop": true},
			"attack": {"count": 6, "fps": 10.0, "loop": false},
			"detonate": {"count": 6, "fps": 12.0, "loop": false},
			"hit": {"count": 4, "fps": 12.0, "loop": false},
			"death": {"count": 6, "fps": 10.0, "loop": false},
		},
	},
	SCOUT_UNIT: {
		"root": ENTITY_BASE + "scout_unit/",
		"default_action": "guide",
		"animations": {
			"idle": {"count": 4, "fps": 5.0, "loop": true},
			"move": {"count": 6, "fps": 8.0, "loop": true},
			"guide": {"count": 6, "fps": 12.0, "loop": false},
			"hit": {"count": 4, "fps": 12.0, "loop": false},
			"death": {"count": 6, "fps": 10.0, "loop": false},
		},
	},
}
var _sprite_frames_cache: Dictionary = {}


func get_visual_ids() -> Array:
	return _visual_specs.keys()


func get_texture_path(visual_id: String) -> String:
	var spec: Dictionary = _visual_specs.get(str(visual_id), {}) as Dictionary
	if spec.is_empty():
		return ""
	var static_path: String = str(spec.get("static", ""))
	if not static_path.is_empty():
		return static_path
	return str(spec.get("root", "")) + "idle/frame_01.png"


func load_texture(visual_id: String) -> Texture2D:
	var path := get_texture_path(visual_id)
	return _load_texture_path(path)


func resource_path_exists(path: String) -> bool:
	return ResourceLoader.exists(path) or FileAccess.file_exists(path)


func get_animation_names(visual_id: String) -> Array:
	var spec: Dictionary = _visual_specs.get(str(visual_id), {}) as Dictionary
	return (spec.get("animations", {}) as Dictionary).keys()


func get_animation_frame_paths(visual_id: String, animation_name: String) -> Array:
	var visual_spec: Dictionary = _visual_specs.get(str(visual_id), {}) as Dictionary
	var animation_spec: Dictionary = (
		visual_spec.get("animations", {}) as Dictionary
	).get(str(animation_name), {}) as Dictionary
	var frame_count: int = maxi(0, int(animation_spec.get("count", 0)))
	var paths: Array = []
	for frame_index in range(frame_count):
		paths.append(
			str(visual_spec.get("root", ""))
			+ "%s/frame_%02d.png" % [str(animation_name), frame_index + 1]
		)
	return paths


func get_default_action(visual_id: String) -> String:
	var spec: Dictionary = _visual_specs.get(str(visual_id), {}) as Dictionary
	return str(spec.get("default_action", "attack"))


func get_terminal_action(visual_id: String) -> String:
	var spec: Dictionary = _visual_specs.get(str(visual_id), {}) as Dictionary
	return str(spec.get("terminal_action", "death"))


func load_sprite_frames(visual_id: String) -> SpriteFrames:
	var safe_id := str(visual_id)
	if _sprite_frames_cache.has(safe_id):
		return _sprite_frames_cache[safe_id] as SpriteFrames
	var visual_spec: Dictionary = _visual_specs.get(safe_id, {}) as Dictionary
	var animation_specs: Dictionary = visual_spec.get("animations", {}) as Dictionary
	if animation_specs.is_empty():
		return null
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for animation_name in animation_specs.keys():
		var spec: Dictionary = animation_specs[animation_name] as Dictionary
		var paths: Array = get_animation_frame_paths(safe_id, str(animation_name))
		if paths.is_empty():
			return null
		frames.add_animation(str(animation_name))
		frames.set_animation_speed(str(animation_name), float(spec.get("fps", 8.0)))
		frames.set_animation_loop(str(animation_name), bool(spec.get("loop", false)))
		for path_value in paths:
			var path := str(path_value)
			var texture := _load_texture_path(path)
			if texture == null:
				return null
			frames.add_frame(str(animation_name), texture)
	_sprite_frames_cache[safe_id] = frames
	return frames


func _load_texture_path(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	if not FileAccess.file_exists(path):
		return null
	var image := Image.new()
	if image.load(path) != OK:
		return null
	return ImageTexture.create_from_image(image)
