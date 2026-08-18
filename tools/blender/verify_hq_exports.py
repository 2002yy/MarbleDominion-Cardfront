"""Validate modular HQ GLB dimensions and triangle budgets."""

import os

import bpy
from mathutils import Vector


BASE = r"C:\Users\Zhang\Desktop\blender_models\exports"
NAMES = ["hq_common.glb", "hq_hero_balanced.glb", "hq_theme_castle.glb", "hq_damage.glb"]


for name in NAMES:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=os.path.join(BASE, name))
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    corners = [obj.matrix_world @ Vector(corner) for obj in meshes for corner in obj.bound_box]
    mins = [min(vector[index] for vector in corners) for index in range(3)]
    maxs = [max(vector[index] for vector in corners) for index in range(3)]
    triangles = sum(
        max(0, len(polygon.vertices) - 2)
        for obj in meshes
        for polygon in obj.data.polygons
    )
    dimensions = [round(maxs[index] - mins[index], 2) for index in range(3)]
    highest = max(
        ((obj.name, max((obj.matrix_world @ Vector(corner)).z for corner in obj.bound_box)) for obj in meshes),
        key=lambda item: item[1],
    )
    print(name, "dims", dimensions, "tris", triangles, "meshes", len(meshes), "highest", highest)
