"""Build the first modular Cardfront HQ benchmark.

The model is authored at the same scale as the Godot presentation layer:
one Blender unit is one Godot meter, Z-up in Blender, and the front faces -Y.
The glTF exporter converts the scene to Godot's Y-up / -Z-forward convention.

Outputs:
  blender_models/exports/cardfront_hq_master.blend
  blender_models/exports/hq_common.glb
  blender_models/exports/hq_hero_balanced.glb
  blender_models/exports/hq_theme_castle.glb
  blender_models/exports/hq_damage.glb
  blender_models/renders/hq_benchmark_preview.png
"""

import math
import os

import bpy
from mathutils import Vector


BASE = r"C:\Users\Zhang\Desktop\blender_models"
EXPORTS = os.path.join(BASE, "exports")
RENDERS = os.path.join(BASE, "renders")

HQ_WIDTH = 6.20
HQ_DEPTH = 3.45
HQ_BASE_HEIGHT = 0.86
TOWER_REFERENCE_HEIGHT = 3.00
HQ_TARGET_HEIGHT = 4.10
HQ_PIVOT_Z = 2.75
BEVEL = 0.055


def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = 1200
    scene.render.resolution_y = 900
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.film_transparent = False
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


def make_material(name, color, roughness=0.72, metallic=0.0, emission=None):
    material = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    material.use_nodes = True
    nodes = material.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    if emission is not None:
        bsdf.inputs["Emission Color"].default_value = (*emission, 1.0)
        bsdf.inputs["Emission Strength"].default_value = 3.0
    return material


def assign_material(obj, material):
    if obj.data.materials:
        obj.data.materials[0] = material
    else:
        obj.data.materials.append(material)


def apply_bevel(obj, width=BEVEL, segments=2):
    if obj.type != "MESH":
        return
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    modifier = obj.modifiers.new("Soft toy bevel", "BEVEL")
    modifier.width = width
    modifier.segments = segments
    modifier.limit_method = "ANGLE"
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    obj.select_set(False)


def parent_local(obj, parent, location, rotation=None):
    obj.parent = parent
    obj.location = location
    if rotation is not None:
        obj.rotation_euler = rotation
    return obj


def add_empty(name, collection, location=(0.0, 0.0, 0.0), parent=None, size=0.16):
    obj = bpy.data.objects.new(name, None)
    collection.objects.link(obj)
    obj.empty_display_type = "PLAIN_AXES"
    obj.empty_display_size = size
    if parent is not None:
        parent_local(obj, parent, location)
    else:
        obj.location = location
    return obj


def add_box(name, collection, dimensions, location, material, bevel=BEVEL, parent=None):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.0, 0.0, 0.0))
    obj = bpy.context.object
    obj.name = name
    move_to_collection(obj, collection)
    if parent is not None:
        parent_local(obj, parent, location)
    else:
        obj.location = location
    obj.dimensions = dimensions
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if material is not None:
        assign_material(obj, material)
    if bevel > 0.0:
        apply_bevel(obj, bevel, 2 if bevel >= 0.045 else 1)
    return obj


def add_cylinder(
    name,
    collection,
    radius,
    depth,
    location,
    material,
    vertices=12,
    rotation=None,
    bevel=0.0,
    parent=None,
):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=(0.0, 0.0, 0.0))
    obj = bpy.context.object
    obj.name = name
    move_to_collection(obj, collection)
    if parent is not None:
        parent_local(obj, parent, location, rotation)
    else:
        obj.location = location
        if rotation is not None:
            obj.rotation_euler = rotation
    if material is not None:
        assign_material(obj, material)
    if bevel > 0.0:
        apply_bevel(obj, bevel, 1)
    return obj


def add_ico(name, collection, radius, location, material, subdivisions=2, parent=None):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=subdivisions, radius=radius, location=(0.0, 0.0, 0.0))
    obj = bpy.context.object
    obj.name = name
    move_to_collection(obj, collection)
    if parent is not None:
        parent_local(obj, parent, location)
    else:
        obj.location = location
    if material is not None:
        assign_material(obj, material)
    return obj


def add_torus(name, collection, major, minor, location, material, rotation=None, parent=None):
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor, major_segments=16, minor_segments=6, location=(0.0, 0.0, 0.0))
    obj = bpy.context.object
    obj.name = name
    move_to_collection(obj, collection)
    if parent is not None:
        parent_local(obj, parent, location, rotation)
    else:
        obj.location = location
        if rotation is not None:
            obj.rotation_euler = rotation
    if material is not None:
        assign_material(obj, material)
    return obj


def look_at(obj, target):
    direction = Vector(target) - obj.location
    obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def make_materials():
    return {
        "stone": make_material("MAT_NEUTRAL_STONE", (0.52, 0.49, 0.43), 0.82),
        "stone_light": make_material("MAT_NEUTRAL_CREAM", (0.72, 0.67, 0.56), 0.78),
        "stone_dark": make_material("MAT_NEUTRAL_STONE_DARK", (0.31, 0.30, 0.28), 0.88),
        "wood": make_material("MAT_NEUTRAL_WOOD", (0.37, 0.22, 0.12), 0.82),
        "metal": make_material("MAT_METAL_DARK", (0.12, 0.16, 0.18), 0.34, 0.78),
        "faction": make_material("MAT_FACTION_PRIMARY", (0.10, 0.42, 0.68), 0.46, 0.18),
        "faction_secondary": make_material("MAT_FACTION_SECONDARY", (0.07, 0.23, 0.38), 0.54, 0.25),
        "core": make_material("MAT_CORE", (0.92, 0.58, 0.12), 0.24, 0.12, (1.0, 0.42, 0.05)),
        "damage": make_material("MAT_DAMAGE_DARK", (0.08, 0.07, 0.07), 0.92),
    }


def build_common(collection, sockets, damage_collection, mats):
    root = add_empty("HQ_Root", collection)
    base = add_empty("Base", collection, parent=root)
    add_box("Base_Main", collection, (HQ_WIDTH, HQ_DEPTH, 0.44), (0.0, 0.0, 0.22), mats["stone"], parent=base)
    add_box("Base_Trim", collection, (HQ_WIDTH - 0.26, HQ_DEPTH - 0.22, 0.18), (0.0, 0.0, 0.53), mats["stone_dark"], bevel=0.04, parent=base)
    add_box("Base_Top", collection, (HQ_WIDTH - 0.58, HQ_DEPTH - 0.48, 0.24), (0.0, 0.0, 0.74), mats["stone_light"], bevel=0.045, parent=base)

    # Faction panels are deliberately small; runtime recolors these by material name.
    add_box("FactionPanel_Front", collection, (3.7, 0.07, 0.42), (0.0, -HQ_DEPTH * 0.5 - 0.04, 0.47), mats["faction"], bevel=0.015, parent=base)
    add_box("FactionPanel_Back", collection, (3.7, 0.07, 0.42), (0.0, HQ_DEPTH * 0.5 + 0.04, 0.47), mats["faction_secondary"], bevel=0.015, parent=base)

    core = add_empty("Core", collection, parent=root)
    add_box("Core_Housing", collection, (3.45, 1.84, 0.92), (0.0, 0.0, 1.28), mats["stone_dark"], bevel=0.075, parent=core)
    add_box("Core_Frame_Front", collection, (2.15, 0.12, 0.84), (0.0, -0.98, 1.36), mats["stone_light"], bevel=0.035, parent=core)
    add_box("Core_Frame_Left", collection, (0.22, 1.92, 0.92), (-1.72, 0.0, 1.34), mats["stone_light"], bevel=0.025, parent=core)
    add_box("Core_Frame_Right", collection, (0.22, 1.92, 0.92), (1.72, 0.0, 1.34), mats["stone_light"], bevel=0.025, parent=core)
    add_box("Core_UpperHousing", collection, (2.72, 1.48, 0.92), (0.0, 0.04, 2.08), mats["stone_dark"], bevel=0.065, parent=core)
    add_box("Core_UpperTrim", collection, (2.92, 1.58, 0.18), (0.0, 0.04, 2.57), mats["stone_light"], bevel=0.035, parent=core)
    add_cylinder("Core_Emitter", collection, 0.54, 0.20, (0.0, -1.08, 1.72), mats["core"], vertices=12, rotation=(math.radians(90.0), 0.0, 0.0), parent=core)
    add_ico("Core_Glow", collection, 0.33, (0.0, -1.22, 1.72), mats["core"], subdivisions=2, parent=core)

    # The pivot is a real separate node. Its local children rotate with it in Godot.
    pivot = add_empty("TurretPivot", collection, (0.0, 0.0, HQ_PIVOT_Z), root, size=0.22)
    add_cylinder("Turret_Base", collection, 0.96, 0.26, (0.0, 0.0, 0.14), mats["metal"], vertices=12, bevel=0.035, parent=pivot)
    add_cylinder("Turret_Collar", collection, 0.72, 0.16, (0.0, 0.0, 0.34), mats["faction_secondary"], vertices=12, bevel=0.02, parent=pivot)

    # Matching anchors are exported in both common and module files.
    add_empty("Socket_Weapon", sockets, (0.0, 0.0, 0.0), pivot)
    add_empty("Socket_HeroModule_Top", sockets, (0.0, 0.0, HQ_PIVOT_Z), root)
    add_empty("Socket_HeroModule_Shoulder_L", sockets, (-1.62, -0.06, 1.54), root)
    add_empty("Socket_HeroModule_Shoulder_R", sockets, (1.62, -0.06, 1.54), root)
    add_empty("Socket_ThemeModule", sockets, (0.0, 0.0, 0.0), root)
    add_empty("Socket_Muzzle", sockets, (0.0, -1.78, 0.58), pivot)
    add_empty("Socket_Hit_L", sockets, (-1.90, -0.90, 1.40), root)
    add_empty("Socket_Hit_R", sockets, (1.90, -0.90, 1.40), root)
    add_empty("Socket_Smoke_L", sockets, (-2.10, 0.0, 2.10), root)
    add_empty("Socket_Smoke_R", sockets, (2.10, 0.0, 2.10), root)
    add_empty("Socket_Destroy_Core", sockets, (0.0, -1.25, 1.72), root)

    # Damage geometry is a separate export, but uses the same HQ coordinates.
    damage_root = add_empty("Damage", damage_collection)
    add_box("Damage_01", damage_collection, (0.52, 0.12, 0.68), (-1.12, -1.04, 1.25), mats["damage"], bevel=0.02, parent=damage_root)
    add_box("Damage_02", damage_collection, (0.44, 0.14, 0.56), (1.15, -1.05, 1.16), mats["damage"], bevel=0.02, parent=damage_root)
    add_box("Damage_03", damage_collection, (0.34, 0.18, 0.42), (0.0, -1.12, 1.78), mats["damage"], bevel=0.02, parent=damage_root)
    add_box("Armor_L", damage_collection, (0.20, 1.16, 0.62), (-1.88, 0.0, 1.36), mats["stone_light"], bevel=0.025, parent=damage_root)
    add_box("Armor_R", damage_collection, (0.20, 1.16, 0.62), (1.88, 0.0, 1.36), mats["stone_light"], bevel=0.025, parent=damage_root)
    add_torus("CoreCover", damage_collection, 0.61, 0.075, (0.0, -1.13, 1.48), mats["stone_light"], rotation=(math.radians(90.0), 0.0, 0.0), parent=damage_root)

    return root


def build_balanced(collection, sockets, mats):
    root = add_empty("HeroModuleRoot", collection)
    # Module sockets live inside this GLB so their parent transforms survive export.
    top = add_empty("HeroModuleSocket_Top", collection, (0.0, 0.0, HQ_PIVOT_Z), root)
    left = add_empty("HeroModuleSocket_Shoulder_L", collection, (-1.62, -0.06, 1.54), root)
    right = add_empty("HeroModuleSocket_Shoulder_R", collection, (1.62, -0.06, 1.54), root)

    # Balanced commander: symmetric, chunky, medium-length single cannon.
    add_box("Balanced_TurretMount", collection, (1.18, 0.84, 0.32), (0.0, 0.0, 0.22), mats["stone_light"], bevel=0.055, parent=top)
    barrel_rot = (math.radians(90.0), 0.0, 0.0)
    add_cylinder("Balanced_Cannon", collection, 0.17, 1.48, (0.0, -0.78, 0.34), mats["metal"], vertices=12, rotation=barrel_rot, bevel=0.025, parent=top)
    add_cylinder("Balanced_CannonBand", collection, 0.21, 0.12, (0.0, -0.40, 0.34), mats["faction"], vertices=12, rotation=barrel_rot, bevel=0.015, parent=top)
    add_cylinder("Balanced_Muzzle", collection, 0.23, 0.14, (0.0, -1.54, 0.34), mats["stone_dark"], vertices=12, rotation=barrel_rot, bevel=0.02, parent=top)
    add_torus("Balanced_MuzzleRing", collection, 0.23, 0.045, (0.0, -1.62, 0.34), mats["faction"], rotation=barrel_rot, parent=top)
    add_box("Balanced_CommandCrest", collection, (1.45, 0.62, 0.62), (0.0, 0.12, 1.00), mats["stone_light"], bevel=0.05, parent=top)
    add_cylinder("Balanced_CrestCore", collection, 0.18, 0.18, (0.0, -0.22, 1.00), mats["core"], vertices=12, rotation=(math.radians(90.0), 0.0, 0.0), parent=top)
    add_box("Balanced_Shoulder_L", collection, (0.54, 1.28, 0.62), (0.0, 0.0, 0.0), mats["faction_secondary"], bevel=0.045, parent=left)
    add_box("Balanced_Shoulder_R", collection, (0.54, 1.28, 0.62), (0.0, 0.0, 0.0), mats["faction_secondary"], bevel=0.045, parent=right)
    add_empty("Socket_Muzzle", collection, (0.0, -1.70, 0.34), top)
    return root


def build_castle(collection, sockets, mats):
    root = add_empty("ThemeModuleRoot", collection)
    add_empty("ThemeModuleSocket", sockets, (0.0, 0.0, 0.0), root)

    # Low castle language: broad shoulders, short crenels, and flags.
    for x in (-2.36, 2.36):
        add_box("Castle_Shoulder_%s" % ("L" if x < 0 else "R"), collection, (0.72, 1.42, 0.76), (x, 0.02, 1.10), mats["stone"], bevel=0.06, parent=root)
        for y in (-0.50, 0.0, 0.50):
            add_box("Castle_Merlon", collection, (0.20, 0.24, 0.26), (x, y, 1.62), mats["stone_light"], bevel=0.025, parent=root)
        add_cylinder("Castle_FlagPole", collection, 0.035, 1.18, (x, -0.35, 2.30), mats["wood"], vertices=8, parent=root)
        add_box("Castle_Flag", collection, (0.56, 0.045, 0.30), (x + (0.26 if x < 0 else -0.26), -0.35, 2.68), mats["faction"], bevel=0.015, parent=root)

    add_box("Castle_CommandCrown", collection, (2.55, 1.20, 0.56), (0.0, 0.08, 3.22), mats["stone"], bevel=0.055, parent=root)
    add_box("Castle_CommandCrownTrim", collection, (1.90, 1.30, 0.16), (0.0, -0.02, 3.53), mats["stone_light"], bevel=0.025, parent=root)
    add_cylinder("Castle_CommandStandard", collection, 0.045, 0.90, (0.0, 0.12, 3.82), mats["wood"], vertices=8, parent=root)
    add_box("Castle_CommandFlag", collection, (0.82, 0.05, 0.34), (0.35, 0.12, 4.08), mats["faction"], bevel=0.015, parent=root)

    for x in (-1.82, -0.91, 0.0, 0.91, 1.82):
        add_box("Castle_FrontCrenel", collection, (0.48, 0.22, 0.24), (x, -1.62, 1.03), mats["stone_light"], bevel=0.025, parent=root)
    add_box("Castle_WoodBeam_Front", collection, (4.15, 0.16, 0.16), (0.0, -1.56, 1.00), mats["wood"], bevel=0.02, parent=root)
    add_box("Castle_WoodBeam_Back", collection, (4.15, 0.16, 0.16), (0.0, 1.56, 1.00), mats["wood"], bevel=0.02, parent=root)
    return root


def all_objects(collection):
    return list(collection.all_objects)


def export_collections(collections, filename):
    bpy.ops.object.select_all(action="DESELECT")
    objects = []
    for collection in collections:
        objects.extend(all_objects(collection))
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0] if objects else None
    path = os.path.join(EXPORTS, filename)
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True, export_apply=True)
    print("EXPORTED", path, "objects", len(objects))


def add_preview(scene, collections, mats):
    preview = make_collection("98_PREVIEW")
    ground = add_box("Preview_Ground", preview, (10.5, 8.5, 0.18), (0.0, 0.0, -0.10), mats["stone_light"], bevel=0.08)
    ground.data.materials[0] = make_material("PREVIEW_GROUND", (0.32, 0.43, 0.35), 0.95)

    # Use the same broad elevated read as the fixed Godot orthographic arena camera.
    bpy.ops.object.camera_add(location=(9.1, -12.6, 9.0))
    camera = bpy.context.object
    camera.name = "PreviewCamera"
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 10.0
    look_at(camera, (0.0, 0.0, 1.45))
    scene.camera = camera
    move_to_collection(camera, preview)

    bpy.ops.object.light_add(type="AREA", location=(2.5, -5.0, 10.0))
    key = bpy.context.object
    key.name = "PreviewKey"
    key.data.energy = 900.0
    key.data.shape = "DISK"
    key.data.size = 7.0
    look_at(key, (0.0, 0.0, 0.8))
    move_to_collection(key, preview)

    bpy.ops.object.light_add(type="AREA", location=(-6.0, 3.0, 5.5))
    fill = bpy.context.object
    fill.name = "PreviewFill"
    fill.data.energy = 320.0
    fill.data.size = 6.0
    look_at(fill, (0.0, 0.0, 1.0))
    move_to_collection(fill, preview)

    scene.render.filepath = os.path.join(RENDERS, "hq_benchmark_preview.png")
    bpy.ops.render.render(write_still=True)


def tri_count(objects):
    total = 0
    for obj in objects:
        if obj.type != "MESH" or obj.data is None:
            continue
        total += sum(max(0, len(poly.vertices) - 2) for poly in obj.data.polygons)
    return total


def main():
    os.makedirs(EXPORTS, exist_ok=True)
    os.makedirs(RENDERS, exist_ok=True)
    scene = reset_scene()
    mats = make_materials()

    common = make_collection("01_COMMON")
    hero = make_collection("02_HERO")
    theme = make_collection("03_THEME")
    damage = make_collection("04_DAMAGE")
    sockets = make_collection("05_SOCKETS")
    reference = make_collection("00_REFERENCE")
    exports = make_collection("99_EXPORT")

    reference_tower = add_box("Reference_TowerHeight", reference, (0.06, 0.06, TOWER_REFERENCE_HEIGHT), (-4.0, 2.5, TOWER_REFERENCE_HEIGHT * 0.5), mats["faction"], bevel=0.01)
    reference_hq = add_box("Reference_HqHeight", reference, (0.06, 0.06, HQ_TARGET_HEIGHT), (-3.6, 2.5, HQ_TARGET_HEIGHT * 0.5), mats["core"], bevel=0.01)
    reference_footprint = add_box("Reference_HqFootprint", reference, (HQ_WIDTH, HQ_DEPTH, 0.04), (0.0, 0.0, 0.02), mats["damage"], bevel=0.01)
    for reference_object in (reference_tower, reference_hq, reference_footprint):
        reference_object.hide_render = True
        reference_object.hide_set(True)

    build_common(common, sockets, damage, mats)
    build_balanced(hero, sockets, mats)
    build_castle(theme, sockets, mats)
    add_preview(scene, [common, hero, theme], mats)

    # Keep non-export preview/reference objects out of all GLBs.
    export_collections([common, sockets], "hq_common.glb")
    export_collections([hero], "hq_hero_balanced.glb")
    export_collections([theme], "hq_theme_castle.glb")
    export_collections([damage], "hq_damage.glb")

    scene.render.filepath = os.path.join(RENDERS, "hq_benchmark_preview.png")
    master_path = os.path.join(EXPORTS, "cardfront_hq_master.blend")
    bpy.ops.wm.save_as_mainfile(filepath=master_path)

    print("TRI_COMMON", tri_count(all_objects(common)))
    print("TRI_HERO", tri_count(all_objects(hero)))
    print("TRI_THEME", tri_count(all_objects(theme)))
    print("TRI_DAMAGE", tri_count(all_objects(damage)))
    print("MASTER", master_path)


if __name__ == "__main__":
    main()
