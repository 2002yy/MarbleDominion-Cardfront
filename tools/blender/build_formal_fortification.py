"""Build the formal Fortification module (cumulative L1-L4, D13).

Per-cell 3D fortification for the orthographic arena. Levels are cumulative:
show GEO_Fort_L{n} parts where part_level <= current stack (mirrors the
tower level-gating pattern). Flat hierarchy, identity bases, strict D21
material names, ground-contact centered origin.

Footprint is one canonical cell: X=1.06, Y(length)=1.16 (Z_SCALE=1.28).
Heights: L1 wall 0.10 / L2 course to 0.20 / L3 corner posts to 0.36 /
L4 faction cap plate to 0.46.

Outputs:
  <desktop>/blender_models/exports/Cardfront_Fortification_Master.blend
  <desktop>/blender_models/exports/fortification/fortification.glb
Import-time nodes/root_name must be set to CF_Fortification in .import.
"""

import os

import bpy

DESKTOP_EXPORTS = r"C:\Users\Zhang\Desktop\blender_models\exports"


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
    MATS["stone"] = make_material("CF_STONE__STATIC", (0.47, 0.455, 0.41), 0.82)
    MATS["wood"] = make_material("CF_WOOD__STATIC", (0.40, 0.27, 0.15), 0.74)
    MATS["trim"] = make_material("CF_METAL__FACTION_TRIM", (0.16, 0.40, 0.62), 0.42, 0.35)


def assign(obj, material):
    if obj.data.materials:
        obj.data.materials[0] = material
    else:
        obj.data.materials.append(material)


def add_part(name, dimensions, location, material, bevel=0.02):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.0, 0.0, 0.0))
    obj = bpy.context.object
    obj.name = name
    move_to_collection(obj, _current_collection)
    obj.dimensions = dimensions
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
    return obj


_current_collection = None

FX = 1.06          # footprint x
FY = 1.16          # footprint y (canonical length)
WALL_T = 0.14      # wall thickness
WALL_X = FX - 0.10 # wall ring outer slightly inset


def wall_ring(name_prefix, z_center, height, material, inset=0.0):
    parts = []
    hx = WALL_X / 2.0 - inset
    hy = FY / 2.0 - inset
    long_dim = (WALL_X - inset * 2.0 - WALL_T * 2.0, WALL_T, height)
    short_dim = (WALL_T, FY - inset * 2.0, height)
    parts.append(add_part("%s_N" % name_prefix, long_dim,
                          (0.0, hy - WALL_T / 2.0, z_center), material))
    parts.append(add_part("%s_S" % name_prefix, long_dim,
                          (0.0, -hy + WALL_T / 2.0, z_center), material))
    parts.append(add_part("%s_E" % name_prefix, short_dim,
                          (hx - WALL_T / 2.0, 0.0, z_center), material))
    parts.append(add_part("%s_W" % name_prefix, short_dim,
                          (-hx + WALL_T / 2.0, 0.0, z_center), material))
    return parts


def build_fortification():
    global _current_collection
    collection = make_collection("01_FORTIFICATION")
    _current_collection = collection
    parts = []

    # L1: low perimeter wall (top at 0.10)
    parts += wall_ring("GEO_Fort_L1", 0.05, 0.10, MATS["stone"])

    # L2: second stone course (top at 0.20) + thin faction trim band
    parts += wall_ring("GEO_Fort_L2", 0.155, 0.11, MATS["stone"])
    parts += wall_ring("GEO_Fort_L2Trim", 0.222, 0.034, MATS["trim"], inset=-0.02)

    # L3: four corner posts (top at 0.38)
    px = WALL_X / 2.0 - 0.07
    py = FY / 2.0 - 0.07
    for sx in (-1, 1):
        for sy in (-1, 1):
            tag = "%s%s" % ("N" if sy > 0 else "S", "E" if sx > 0 else "W")
            parts.append(add_part("GEO_Fort_L3_Post_%s" % tag,
                                  (0.14, 0.14, 0.20),
                                  (sx * (px - 0.02), sy * (py - 0.02), 0.28),
                                  MATS["wood"]))

    # L4: faction cap plate + center keel (top at 0.48)
    parts.append(add_part("GEO_Fort_L4_Cap", (WALL_X - 0.04, FY - 0.30, 0.06),
                          (0.0, 0.0, 0.43), MATS["trim"]))
    parts.append(add_part("GEO_Fort_L4_Keel", (0.22, 0.62, 0.10),
                          (0.0, 0.0, 0.50), MATS["wood"]))
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
    fort_parts = build_fortification()

    master_path = os.path.join(DESKTOP_EXPORTS, "Cardfront_Fortification_Master.blend")
    bpy.ops.wm.save_as_mainfile(filepath=master_path, copy=False)
    print("MASTER", master_path)

    out_dir = os.path.join(DESKTOP_EXPORTS, "fortification")
    os.makedirs(out_dir, exist_ok=True)
    export_path = os.path.join(out_dir, "fortification.glb")
    bpy.ops.object.select_all(action="DESELECT")
    for obj in fort_parts:
        obj.select_set(True)
    bpy.ops.export_scene.gltf(filepath=export_path, export_format="GLB",
                              export_yup=True, export_apply=False)
    print("EXPORTED", export_path)
    print("TRI_FORT", count_tris(fort_parts))
    print("DONE")


main()
