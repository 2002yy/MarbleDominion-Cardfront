"""Build formal Stronghold base pads: CENTER island + CORNER (default_duel).

Two fixed-size pads replace the scaled primitive BoxMesh platforms while
respecting D22 (no runtime non-uniform scale):

  corner : 5 x 5 cells   -> 5.074 x 5.504 m  (ARENA_X_SCALE / z_scale x 0.86)
  center : 8 x 8 cells   -> 8.118 x 8.806 m

Height matches legacy STRONGHOLD_PLATFORM_HEIGHT = 0.18 (min.y = 0).
Runtime places instance at y = 0.15 so top surface stays at 0.33.
Flat hierarchy, identity bases, strict CF_*__* materials.

Outputs under <desktop>/blender_models/exports/stronghold_base/.
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
    MATS["stone"] = make_material("CF_STONE__STATIC", (0.52, 0.505, 0.46), 0.80)
    MATS["stone_dark"] = make_material("CF_STONE__STATIC", (0.36, 0.35, 0.32), 0.86)
    MATS["wood"] = make_material("CF_WOOD__STATIC", (0.40, 0.27, 0.15), 0.74)
    MATS["trim"] = make_material("CF_METAL__FACTION_TRIM", (0.16, 0.40, 0.62), 0.42, 0.35)


def assign(obj, material):
    if obj.data.materials:
        obj.data.materials[0] = material
    else:
        obj.data.materials.append(material)


_current_collection = None


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


def build_pad(collection_name, fx, fy, is_center):
    global _current_collection
    collection = make_collection(collection_name)
    _current_collection = collection
    parts = []

    # Lower slab (h 0.10)
    parts.append(add_part("GEO_PadLower", (fx, fy, 0.10), (0.0, 0.0, 0.05),
                          MATS["stone"], bevel=0.03))
    # Upper course inset (top at 0.18)
    ux, uy = fx - 0.26, fy - 0.26
    parts.append(add_part("GEO_PadUpper", (ux, uy, 0.08), (0.0, 0.0, 0.14),
                          MATS["stone_dark"], bevel=0.025))
    # Faction trim band ringing the upper course seam
    band_w = 0.06
    parts.append(add_part("GEO_TrimBand_N", (ux + band_w, band_w, 0.035),
                          (0.0, uy / 2.0 - band_w / 2.0, 0.155),
                          MATS["trim"], bevel=0.012))
    parts.append(add_part("GEO_TrimBand_S", (ux + band_w, band_w, 0.035),
                          (0.0, -uy / 2.0 + band_w / 2.0, 0.155),
                          MATS["trim"], bevel=0.012))
    parts.append(add_part("GEO_TrimBand_E", (band_w, uy - band_w * 2.0, 0.035),
                          (ux / 2.0 - band_w / 2.0, 0.0, 0.155),
                          MATS["trim"], bevel=0.012))
    parts.append(add_part("GEO_TrimBand_W", (band_w, uy - band_w * 2.0, 0.035),
                          (-ux / 2.0 + band_w / 2.0, 0.0, 0.155),
                          MATS["trim"], bevel=0.012))
    # Four corner studs
    px, py = fx / 2.0 - 0.16, fy / 2.0 - 0.16
    for sx in (-1, 1):
        for sy in (-1, 1):
            tag = "%s%s" % ("N" if sy > 0 else "S", "E" if sx > 0 else "W")
            parts.append(add_part("GEO_CornerStud_%s" % tag,
                                  (0.20, 0.20, 0.14),
                                  (sx * px, sy * py, 0.07),
                                  MATS["wood"], bevel=0.015))
    if is_center:
        # Inner research inlay plate (subtle two-tone)
        parts.append(add_part("GEO_InlayPlate", (ux * 0.42, uy * 0.42, 0.02),
                              (0.0, 0.0, 0.185), MATS["stone_dark"],
                              bevel=0.008))
    return parts


def count_tris(objects):
    tris = 0
    for obj in objects:
        if obj.type != "MESH":
            continue
        for polygon in obj.data.polygons:
            tris += max(1, len(polygon.vertices) - 2)
    return tris


def export_parts(parts, out_dir, filename):
    os.makedirs(out_dir, exist_ok=True)
    path = os.path.join(out_dir, filename)
    bpy.ops.object.select_all(action="DESELECT")
    for obj in parts:
        obj.select_set(True)
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB",
                              export_yup=True, export_apply=False)
    print("EXPORTED", path)
    print("TRI", count_tris(parts))


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

    center_fx, center_fy = 8.118, 6.880
    corner_fx, corner_fy = 5.074, 4.300

    master_path = os.path.join(DESKTOP_EXPORTS, "Cardfront_Stronghold_Base_Master.blend")

    build_pad("01_CENTER", center_fx, center_fy, True)
    build_pad("02_CORNER", corner_fx, corner_fy, False)

    bpy.ops.wm.save_as_mainfile(filepath=master_path, copy=False)
    print("MASTER", master_path)

    out_base = os.path.join(DESKTOP_EXPORTS, "stronghold_base")

    # Export each pad from a fresh reopen of the master, deleting the sibling.
    bpy.ops.wm.open_mainfile(filepath=master_path)
    delete_collection_objects("02_CORNER")
    export_collection_objects("01_CENTER", out_base, "stronghold_base_center.glb")

    bpy.ops.wm.open_mainfile(filepath=master_path)
    delete_collection_objects("01_CENTER")
    export_collection_objects("02_CORNER", out_base, "stronghold_base_corner.glb")
    print("DONE")


main()
