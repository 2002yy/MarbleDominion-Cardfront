"""Build formal Rapid Gunner + Fortification Engineer HQ hero modules.

Shares the canonical HQ space used by hq_hero_balanced.glb:
  SOCKET_HeroModule_Top at (0, 0, PIVOT_Z=2.85)
  SOCKET_HeroModule_Shoulder_L/R at (+/-1.62, -0.06, 1.82)
All head geometry parents the Top socket with local offsets; identity
bases; strict CF_*__* materials. Blender is Z-up.

Outputs under <desktop>/blender_models/exports/hq_heroes/.
Import-time nodes/root_name: CF_HeroRapid / CF_HeroEngineer.
"""

import math
import os
import re

import bpy

DESKTOP_EXPORTS = r"C:\Users\Zhang\Desktop\blender_models\exports"

PIVOT_Z = 2.85
SHOULDER_Z = 1.82

_current_collection = None
BARREL_ROT = (math.radians(90.0), 0.0, 0.0)


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
    MATS["metal"] = make_material("CF_METAL__STATIC", (0.16, 0.19, 0.22), 0.36, 0.72)
    MATS["cream"] = make_material("CF_STONE__STATIC", (0.72, 0.67, 0.56), 0.78)
    MATS["stone_dark"] = make_material("CF_STONE__STATIC", (0.31, 0.30, 0.28), 0.86)
    MATS["wood"] = make_material("CF_WOOD__STATIC", (0.37, 0.22, 0.12), 0.82)
    MATS["faction"] = make_material("CF_STONE__FACTION_PRIMARY", (0.10, 0.42, 0.68), 0.46, 0.18)
    MATS["trim"] = make_material("CF_METAL__FACTION_TRIM", (0.16, 0.40, 0.62), 0.42, 0.35)
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


def add_cylinder(name, radius, depth, location, material, vertices=12,
                 parent=None, bevel=0.015, rotation=None):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius,
                                        depth=depth, location=(0.0, 0.0, 0.0))
    obj = bpy.context.object
    obj.name = name
    move_to_collection(obj, _current_collection)
    obj.location = location
    if rotation is not None:
        obj.rotation_euler = rotation
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


def add_socket(name, location, parent=None, size=0.16):
    obj = bpy.data.objects.new(name, None)
    move_to_collection(obj, _current_collection)
    obj.empty_display_type = "PLAIN_AXES"
    obj.empty_display_size = size
    obj.location = location
    if parent is not None:
        obj.parent = parent
    return obj


def build_rapid():
    global _current_collection
    collection = make_collection("01_RAPID")
    _current_collection = collection
    parts = []
    top = add_socket("SOCKET_HeroModule_Top", (0.0, 0.0, PIVOT_Z))
    parts.append(top)
    left = add_socket("SOCKET_HeroModule_Shoulder_L", (-1.62, -0.06, SHOULDER_Z))
    right = add_socket("SOCKET_HeroModule_Shoulder_R", (1.62, -0.06, SHOULDER_Z))
    parts += [left, right]

    parts.append(add_part("GEO_Rapid_Mount", (1.00, 0.80, 0.30), (0.0, 0.0, 0.18),
                          MATS["cream"], parent=top, bevel=0.04))
    for side in (-1, 1):
        tag = "L" if side < 0 else "R"
        parts.append(add_cylinder("GEO_Rapid_Barrel_%s" % tag, 0.12, 1.30,
                                  (side * 0.28, -0.62, 0.34), MATS["metal"],
                                  vertices=10, parent=top, rotation=BARREL_ROT))
        parts.append(add_cylinder("GEO_Rapid_Muzzle_%s" % tag, 0.15, 0.12,
                                  (side * 0.28, -1.30, 0.34), MATS["stone_dark"],
                                  vertices=10, parent=top, rotation=BARREL_ROT))
    parts.append(add_cylinder("GEO_Rapid_BarrelBand", 0.17, 0.10, (0.0, -0.30, 0.34),
                              MATS["trim"], vertices=12, parent=top,
                              rotation=BARREL_ROT))
    parts.append(add_part("GEO_Rapid_Visor_Lower", (1.30, 0.50, 0.26),
                          (0.0, 0.10, 0.62), MATS["stone_dark"], parent=top,
                          bevel=0.03))
    parts.append(add_part("GEO_Rapid_Visor_Upper", (0.90, 0.34, 0.22),
                          (0.0, 0.22, 0.84), MATS["cream"], parent=top,
                          bevel=0.03))
    parts.append(add_cylinder("GEO_Rapid_CoreDot", 0.10, 0.10, (0.0, -0.12, 0.84),
                              MATS["core"], vertices=10, parent=top,
                              rotation=BARREL_ROT))
    for side in (-1, 1):
        tag = "L" if side < 0 else "R"
        parts.append(add_part("GEO_Rapid_Fin_%s" % tag, (0.06, 0.52, 0.46),
                              (side * 0.62, 0.10, 0.52), MATS["faction"],
                              parent=top, bevel=0.015))
    for socket, side, tag in ((left, -1, "L"), (right, 1, "R")):
        parts.append(add_part("GEO_Rapid_Shoulder_%s" % tag, (0.50, 1.10, 0.58),
                              (0.0, 0.0, 0.0), MATS["trim"], parent=socket,
                              bevel=0.04))
    parts.append(add_socket("SOCKET_Muzzle", (0.0, -1.42, 0.34), parent=top))
    return parts


def build_engineer():
    global _current_collection
    collection = make_collection("02_ENGINEER")
    _current_collection = collection
    parts = []
    top = add_socket("SOCKET_HeroModule_Top", (0.0, 0.0, PIVOT_Z))
    parts.append(top)
    left = add_socket("SOCKET_HeroModule_Shoulder_L", (-1.62, -0.06, SHOULDER_Z))
    right = add_socket("SOCKET_HeroModule_Shoulder_R", (1.62, -0.06, SHOULDER_Z))
    parts += [left, right]

    parts.append(add_part("GEO_Engi_Mount", (1.30, 0.95, 0.36), (0.0, 0.0, 0.20),
                          MATS["cream"], parent=top, bevel=0.05))
    parts.append(add_part("GEO_Engi_Shield", (1.10, 0.18, 0.92), (0.0, 0.42, 0.66),
                          MATS["metal"], parent=top, bevel=0.035))
    for index in range(3):
        parts.append(add_part("GEO_Engi_Tool_%d" % index, (0.16, 0.12, 0.44),
                              (-0.34 + 0.34 * index, 0.34, 0.66),
                              MATS["wood"], parent=top, bevel=0.012))
    parts.append(add_part("GEO_Engi_CranePost", (0.18, 0.18, 0.78), (0.42, 0.18, 0.72),
                          MATS["metal"], parent=top, bevel=0.02))
    parts.append(add_part("GEO_Engi_CraneBoom", (0.14, 1.05, 0.14), (0.42, -0.34, 1.06),
                          MATS["metal"], parent=top, bevel=0.02))
    parts.append(add_part("GEO_Engi_CraneHook", (0.20, 0.20, 0.24), (0.42, -0.78, 0.88),
                          MATS["trim"], parent=top, bevel=0.02))
    parts.append(add_part("GEO_Engi_EmitterHousing", (0.44, 0.30, 0.30),
                          (0.0, -0.52, 0.42), MATS["stone_dark"], parent=top,
                          bevel=0.03))
    parts.append(add_cylinder("GEO_Engi_EmitterCore", 0.11, 0.10, (0.0, -0.68, 0.42),
                              MATS["core"], vertices=10, parent=top,
                              rotation=BARREL_ROT))
    parts.append(add_part("GEO_Engi_Badge", (0.52, 0.08, 0.20), (0.0, -0.30, 0.72),
                          MATS["faction"], parent=top, bevel=0.012))
    for socket, side, tag in ((left, -1, "L"), (right, 1, "R")):
        parts.append(add_part("GEO_Engi_Shoulder_%s" % tag, (0.68, 1.30, 0.68),
                              (0.0, 0.0, 0.0), MATS["cream"], parent=socket,
                              bevel=0.045))
    parts.append(add_socket("SOCKET_Muzzle", (0.0, -0.86, 0.42), parent=top))
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


def export_collection_objects(collection_name, out_dir, filename):
    suffix_pattern = re.compile(r"\.\d{3}$")
    for obj in bpy.data.collections[collection_name].all_objects:
        if suffix_pattern.search(obj.name):
            obj.name = suffix_pattern.sub("", obj.name)
    os.makedirs(out_dir, exist_ok=True)
    path = os.path.join(out_dir, filename)
    parts = list(bpy.data.collections[collection_name].all_objects)
    bpy.ops.object.select_all(action="DESELECT")
    for obj in parts:
        obj.select_set(True)
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB",
                              export_yup=True, export_apply=False)
    print("EXPORTED", path)
    print("TRI_" + collection_name, count_tris(parts))


def main():
    reset_scene()
    build_materials()
    build_rapid()
    build_engineer()

    master_path = os.path.join(DESKTOP_EXPORTS, "Cardfront_HQ_Heroes_Master.blend")
    bpy.ops.wm.save_as_mainfile(filepath=master_path, copy=False)
    print("MASTER", master_path)

    out_base = os.path.join(DESKTOP_EXPORTS, "hq_heroes")

    bpy.ops.wm.open_mainfile(filepath=master_path)
    delete_collection_objects("02_ENGINEER")
    export_collection_objects("01_RAPID", out_base, "hq_hero_rapid.glb")

    bpy.ops.wm.open_mainfile(filepath=master_path)
    delete_collection_objects("01_RAPID")
    export_collection_objects("02_ENGINEER", out_base, "hq_hero_engineer.glb")
    print("DONE")


main()
