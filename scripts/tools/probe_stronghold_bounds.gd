extends SceneTree
const DefaultDuelMapScript = preload("res://scripts/cardfront/maps/maps/DefaultDuelMap.gd")
func _initialize() -> void:
    var def := DefaultDuelMapScript.make(Vector2i(40, 60))
    var regions: Array = def.get("regions", [])
    for r_value in regions:
        var r: Dictionary = r_value
        print(r["type"], " ", int(r["x1"]) - int(r["x0"]) + 1, " x ", int(r["y1"]) - int(r["y0"]) + 1)
    quit(0)
