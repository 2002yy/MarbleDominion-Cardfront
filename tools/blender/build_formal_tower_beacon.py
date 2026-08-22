"""Build formal Beacon function-module for the interceptor tower family.

Shares the canonical tower space (glTF Y-up, ground origin at tower base):
  PIV_BeaconHead sits at y=1.80 matching SOCKET_FunctionModule on common.
All visible parts are children of the pivot with local translations and
identity basis (rotation applied). Materials are strict D21 names.

Outputs:
  <desktop>/blender_models/exports/Cardfront_Tower_Beacon_Master.blend
  <desktop>/blender_models/exports/tower_beacon/tower_beacon.glb
Import-time nodes/root_name must be set to CF_TowerBeacon in .import.
"""

import os

import bpy
import math

DESKTOP_EXPORTS = r"C:\Users\Zhang\Desktop\blender_models\exports"

PIVOT_Z = 1.80


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


def make_material(name, color, roughness=0.7, metallic=0.0, emission=None, emission_strength=0.0):
    material = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    material.use_nodes = True
    bsdf = material.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    if emission is not None:
        bsdf.inputs["Emission Color"].default_value = (*emission, 1.0)
        bsdf.inputs["Emission Strength"].default_value = emission_strength
    return material


MATS = {}


def build_materials():
    MATS["metal"] = make_material("CF_METAL__STATIC", (0.16, 0.19, 0.22), 0.38, 0.72)
    MATS["trim"] = make_material("CF_METAL__FACTION_TRIM", (0.16, 0.40, 0.62), 0.42, 0.35)
    MATS["stone"] = make_material("CF_STONE__STATIC", (0.44, 0.43, 0.39), 0.84)
    MATS["core"] = make_material("CF_ENERGY__CORE", (1.0, 0.56, 0.10), 0.20, 0.0,
                                 emission=(1.0, 0.48, 0.06), emission_strength=3.0)


def assign(obj, material):
    if obj.data.materials:
        obj.data.materials[0] = material
    else:
        obj.data.materials.append(material)


def add_part(name, dimensions, location, material, parent=None, bevel=0.02,
             rotation=None):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.0, 0.0, 0.0))
    obj = bpy.context.object
    obj.name = name
    move_to_collection(obj, _current_collection)
    obj.dimensions = dimensions
    obj.location = location
    if rotation is not None:
        obj.rotation_euler = rotation
    bpy.context.view_layer.objects.active = obj
    # Bake world rot/scale so exported node basis is identity; keep location.
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    assign(obj, material)
    if bevel > 0.0:
        modifier = obj.modifiers.new("Bevel", "BEVEL")
        modifier.width = bevel
        modifier.segments = 2
        modifier.limit_method = "ANGLE"
        bpy.ops.object.modifier_apply(modifier=modifier.name)
    if parent is not None:
        obj.parent = parent
    return obj


def add_cylinder(name, radius, depth, location, material,
                 vertices=14, parent=None, bevel=0.015):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius,
                                        depth=depth,
                                        location=(0.0, 0.0, 0.0))
    obj = bpy.context.object
    obj.name = name
    move_to_collection(obj, _current_collection)
    obj.location = location
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    assign(obj, material)
    if bevel > 0.0:
        modifier = obj.modifiers.new("Bevel", "BEVEL")
        modifier.width = bevel
        modifier.segments = 2
        modifier.limit_method = "ANGLE"
        bpy.ops.object.modifier_apply(modifier=modifier.name)
    if parent is not None:
        obj.parent = parent
    return obj


def add_sphere(name, radius, location, material, segments=12, rings=6, parent=None):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings,
                                         radius=radius, location=(0.0, 0.0, 0.0))
    obj = bpy.context.object
    obj.name = name
    move_to_collection(obj, _current_collection)
    obj.location = location
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    assign(obj, material)
    if parent is not None:
        obj.parent = parent
    return obj


def add_socket(name, location, parent=None, size=0.14):
    obj = bpy.data.objects.new(name, None)
    move_to_collection(obj, _current_collection)
    obj.empty_display_type = "PLAIN_AXES"
    obj.empty_display_size = size
    obj.location = location
    if parent is not None:
        obj.parent = parent
    return obj


_current_collection = None


def build_beacon():
    global _current_collection
    collection = make_collection("01_BEACON_MODULE")
    _current_collection = collection
    parts = []

    # Ground-anchored seat: keeps a real footprint at the shared base plane
    # so the module alone still satisfies ground-contact contracts.
    parts.append(add_part("GEO_BaseSeat", (0.62, 0.62, 0.10), (0.0, 0.0, 0.05),
                          MATS["stone"], bevel=0.02))

    pivot = add_socket("PIV_BeaconHead", (0.0, 0.0, PIVOT_Z), size=0.2)
    parts.append(pivot)

    # Collar trim right above the dome junction.
    parts.append(add_part("GEO_HubTrim", (0.46, 0.46, 0.10), (0.0, 0.0, 0.03),
                          MATS["trim"], parent=pivot, bevel=0.018))

    # Brazier: wide disc + stem, holding the emissive core.
    dish = add_cylinder("GEO_DishBowl", 0.36, 0.10, (0.0, 0.0, 0.30),
                        MATS["metal"], vertices=14, parent=pivot)
    dish = add_cylinder("GEO_DishStem", 0.13, 0.20, (0.0, 0.0, 0.15),
                        MATS["metal"], vertices=12, parent=pivot)

    # Forward emitter slot (+Z = model forward).
    parts.append(add_part("GEO_EmitterSlot", (0.10, 0.30, 0.09),
                          (0.0, 0.30, 0.30), MATS["metal"], parent=pivot,
                          bevel=0.012))

    # Emissive guidance core inside the cup.
    parts.append(add_sphere("GEO_BeaconCore", 0.17, (0.0, 0.0, 0.40),
                            MATS["core"], segments=12, rings=6, parent=pivot))

    # Three chunky ring fins for silhouette read at strategy zoom.
    fin_angles = [0.0, 2.0 * math.pi / 3.0, 4.0 * math.pi / 3.0]
    for index, angle in enumerate(fin_angles):
        offset_x = math.sin(angle) * 0.42
        offset_y = math.cos(angle) * 0.42
        rotation = (0.0, 0.0, angle)
        parts.append(add_part("GEO_Fin_%s" % "ABC"[index],
                              (0.07, 0.20, 0.44),
                              (offset_x, offset_y, 0.16),
                              MATS["metal"], parent=pivot, bevel=0.014,
                              rotation=rotation))

    parts.append(add_socket("SOCKET_Guidance", (0.0, 0.34, 0.40), parent=pivot,
                            size=0.16))
    parts.append(add_socket("VFX_BeaconPulse", (0.0, 0.0, 0.58), parent=pivot,
                            size=0.16))
    return parts


def count_tris(objects):
    tris = 0
    for obj in objects:
        if obj.type != "MESH":
            continue
        for polygon in obj.data.polygons:
            tris += max(1, len(polygon.vertices) - 2)
    return tris


def main():
    reset_scene()
    build_materials()
    beacon_parts = build_beacon()

    master_path = os.path.join(DESKTOP_EXPORTS, "Cardfront_Tower_Beacon_Master.blend")
    bpy.ops.wm.save_as_mainfile(filepath=master_path, copy=False)
    print("MASTER", master_path)

    out_dir = os.path.join(DESKTOP_EXPORTS, "tower_beacon")
    os.makedirs(out_dir, exist_ok=True)
    export_path = os.path.join(out_dir, "tower_beacon.glb")
    bpy.ops.object.select_all(action="DESELECT")
    for obj in beacon_parts:
        obj.select_set(True)
    bpy.ops.export_scene.gltf(filepath=export_path, export_format="GLB",
                              export_yup=True, export_apply=False)
    print("EXPORTED", export_path)
    print("TRI_BEACON", count_tris(beacon_parts))
    print("DONE")


main()
