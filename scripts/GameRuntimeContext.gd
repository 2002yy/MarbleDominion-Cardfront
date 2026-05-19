extends RefCounted
class_name GameRuntimeContext

var battlefield = null
var bullet_pool = null
var turrets: Dictionary = {}
var chambers: Dictionary = {}
var hud: Dictionary = {}
var ui_runtime: Dictionary = {}
var event_controller = null
var event_view = null
var region_map = null
var region_overlay = null
var economy_system = null
var economy_debug_panel = null
var morale_system = null
var fortify_layer = null
var fortify_overlay = null
var resource_states: Dictionary = {}
var last_yield_snapshot: Dictionary = {}
var current_config: Dictionary = {}
var current_layout: Dictionary = {}

func reset() -> void:
    battlefield = null
    bullet_pool = null
    turrets.clear()
    chambers.clear()
    hud.clear()
    ui_runtime.clear()
    event_controller = null
    event_view = null
    region_map = null
    region_overlay = null
    economy_system = null
    economy_debug_panel = null
    morale_system = null
    fortify_layer = null
    fortify_overlay = null
    resource_states.clear()
    last_yield_snapshot.clear()
    current_config.clear()
    current_layout.clear()

func set_config(config: Dictionary) -> void:
    current_config = config.duplicate(true)

func set_layout(layout: Dictionary) -> void:
    current_layout = layout.duplicate(true)

func set_hud_parts(parts: Dictionary) -> void:
    hud = parts.duplicate(false)

func hud_ref(key: String, default_value = null):
    return hud.get(key, default_value)

func set_hud_ref(key: String, value) -> void:
    hud[key] = value

func ui_runtime_ref(key: String, default_value = null):
    return ui_runtime.get(key, default_value)

func set_ui_runtime_ref(key: String, value) -> void:
    ui_runtime[key] = value

func set_ui_runtime_parts(parts: Dictionary) -> void:
    for key in parts.keys():
        ui_runtime[key] = parts[key]
