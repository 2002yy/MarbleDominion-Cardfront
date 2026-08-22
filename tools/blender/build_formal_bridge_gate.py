"""Build formal Bridge + GateFrame assets (D21/D22 contract compliant).

Contract rules enforced (CardfrontFormalAssetValidator):
  root name supplied at import via nodes/root_name (CF_Bridge / CF_GateFrame)
  flat node hierarchy, every node scale == 1,1,1
  visible meshes rotation-applied (basis identity)
  materials exactly CF_<SURFACE>__<CHANNEL>
  ground-contact centered origin: lowest geometry touches y=0

Blender is Z-up: dimensions tuples are (X width, Y length, Z height).

Outputs:
  <desktop>/blender_models/exports/Cardfront_Bridge_Gate_Master.blend
  <desktop>/blender_models/exports/bridge/bridge.glb
  <desktop>/blender_models/exports/gate/gate_frame.glb
Copy GLBs into assets/cardfront_environment/formal/{bridge,gate}/ afterwards.
"""

import os

import bpy

DESKTOP_EXPORTS = r"C:\Users\Zhang\Desktop\blender_models\exports"

Z_SCALE = 1.28


def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    try:
        scene.view_settings.look = "AgX - Medium High Contrast"
    except Exception:
        pass
    return scene


def make_collection(name):
    collection = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(collection)
    return collection


def move_to_collection(obj, collection):
    for old_collection in list(obj.users_collection):
        old_collection.objects.unlink(obj)
    collection.objects.link(obj)


def make_material(name, color, roughness=0.7, metallic=0.0):
    material = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    material.use_nodes = True
    bsdf = material.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    return material


MATS = {}


def build_materials():
    MATS["wood"] = make_material("CF_WOOD__STATIC", (0.47, 0.32, 0.19), 0.72)
    MATS["wood_dark"] = make_material("CF_WOOD__STATIC", (0.33, 0.22, 0.13), 0.78)
    MATS["stone"] = make_material("CF_STONE__STATIC", (0.44, 0.43, 0.39), 0.84)
    MATS["trim"] = make_material("CF_METAL__FACTION_TRIM", (0.16, 0.40, 0.62), 0.42, 0.35)


def assign(obj, material):
    if obj.data.materials:
        obj.data.materials[0] = material
    else:
        obj.data.materials.append(material)


def add_part(name, collection, dimensions, location, material, bevel=0.03):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.0, 0.0, 0.0))
    obj = bpy.context.object
    obj.name = name
    move_to_collection(obj, collection)
    obj.dimensions = dimensions
    obj.location = location
    bpy.context.view_layer.objects.active = obj
    # Validator: node scale must be 1,1,1 and visible basis identity -> bake rot/scale.
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    assign(obj, material)
    if bevel > 0.0:
        modifier = obj.modifiers.new("Bevel", "BEVEL")
        modifier.width = bevel
        modifier.segments = 2
        modifier.limit_method = "ANGLE"
        bpy.ops.object.modifier_apply(modifier=modifier.name)
    return obj


def add_socket(name, collection, location, size=0.14):
    obj = bpy.data.objects.new(name, None)
    collection.objects.link(obj)
    obj.empty_display_type = "PLAIN_AXES"
    obj.empty_display_size = size
    obj.location = location
    return obj


def export_glb(objects, path):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.ops.export_scene.gltf(
        filepath=path,
        export_format="GLB",
        export_yup=True,
        export_apply=False,
    )
    print("EXPORTED", path)


def build_bridge():
    collection = make_collection("01_BRIDGE")
    parts = []
    parts.append(add_part("GEO_Underbody", collection,
                          (3.80, 3.84 * Z_SCALE, 0.38), (0.0, 0.0, 0.19),
                          MATS["wood_dark"], bevel=0.025))
    parts.append(add_part("GEO_Deck", collection,
                          (3.40, 3.39 * Z_SCALE, 0.24), (0.0, 0.0, 0.50),
                          MATS["wood"], bevel=0.035))
    for side in (-1, 1):
        parts.append(add_part("GEO_Rail_%s" % ("L" if side < 0 else "R"), collection,
                              (0.18, 3.56 * Z_SCALE, 0.32),
                              (side * 1.61, 0.0, 0.67),
                              MATS["trim"], bevel=0.02))
    corners = [(-1.55, -1.70, "FL"), (1.55, -1.70, "FR"),
               (-1.55, 1.70, "BL"), (1.55, 1.70, "BR")]
    for cx, cy, tag in corners:
        parts.append(add_part("GEO_Post_%s" % tag, collection,
                              (0.30, 0.30, 0.52),
                              (cx, cy * Z_SCALE, 0.26),
                              MATS["stone"], bevel=0.02))
    parts.append(add_socket("VFX_WaterLine_L", collection, (-1.85, 0.0, 0.06)))
    parts.append(add_socket("VFX_WaterLine_R", collection, (1.85, 0.0, 0.06)))
    return parts


def build_gate_frame():
    collection = make_collection("02_GATE_FRAME")
    parts = []
    for side in (-1, 1):
        tag = "L" if side < 0 else "R"
        parts.append(add_part("GEO_Post_%s" % tag, collection,
                              (0.38, 0.66, 1.42), (side * 1.72, 0.0, 0.71),
                              MATS["stone"], bevel=0.035))
        parts.append(add_part("GEO_Cap_%s" % tag, collection,
                              (0.54, 0.82, 0.24), (side * 1.72, 0.0, 1.57),
                              MATS["trim"], bevel=0.02))
    parts.append(add_socket("SOCKET_BarAnchor", collection, (0.0, 0.0, 0.41), size=0.18))
    return parts


def count_tris(objects):
    tris = 0
    for obj in objects:
        if obj.type != "MESH":
            continue
        for polygon in obj.data.polygons:
            tris += max(1, len(polygon.vertices) - 2)
    return tris


def delete_collection_objects(collection_name):
    collection = bpy.data.collections.get(collection_name)
    if collection is None:
        return
    bpy.ops.object.select_all(action="DESELECT")
    for obj in list(collection.all_objects):
        obj.select_set(True)
    if collection.all_objects:
        bpy.context.view_layer.objects.active = collection.all_objects[0]
    bpy.ops.object.delete(use_global=False)


def main():
    reset_scene()
    build_materials()

    bridge_parts = build_bridge()
    gate_parts = build_gate_frame()

    master_path = os.path.join(DESKTOP_EXPORTS, "Cardfront_Bridge_Gate_Master.blend")
    bpy.ops.wm.save_as_mainfile(filepath=master_path, copy=False)
    print("MASTER", master_path)

    bridge_out = os.path.join(DESKTOP_EXPORTS, "bridge")
    gate_out = os.path.join(DESKTOP_EXPORTS, "gate")
    os.makedirs(bridge_out, exist_ok=True)
    os.makedirs(gate_out, exist_ok=True)

    # Export each asset from a fresh reopen of the master, deleting the sibling.
    bpy.ops.wm.open_mainfile(filepath=master_path)
    delete_collection_objects("02_GATE_FRAME")
    export_glb(list(bpy.data.collections["01_BRIDGE"].all_objects),
               os.path.join(bridge_out, "bridge.glb"))
    print("TRI_BRIDGE", count_tris(bpy.data.collections["01_BRIDGE"].all_objects))

    bpy.ops.wm.open_mainfile(filepath=master_path)
    delete_collection_objects("01_BRIDGE")
    export_glb(list(bpy.data.collections["02_GATE_FRAME"].all_objects),
               os.path.join(gate_out, "gate_frame.glb"))
    print("TRI_GATE", count_tris(bpy.data.collections["02_GATE_FRAME"].all_objects))

    print("DONE")


main()
