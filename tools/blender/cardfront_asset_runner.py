"""Reusable deterministic Blender helpers for Cardfront Formal assets."""

from __future__ import annotations

import math
import os
import re
from pathlib import Path

import bpy
from mathutils import Vector


MATERIAL_PATTERN = re.compile(
    r"^CF_(STONE|WOOD|METAL|CERAMIC|CLOTH|FOLIAGE|WATER|ENERGY)__"
    r"(STATIC|THEME|FACTION_PRIMARY|FACTION_TRIM|OWNERSHIP|CORE|DAMAGE)$"
)
NODE_PREFIXES = ("CF_", "GEO_", "PIV_", "SOCKET_", "VFX_", "DMG_")


class CardfrontAssetRunner:
    def __init__(self, asset_prefix: str):
        self.asset_prefix = asset_prefix
        self.collections: dict[str, bpy.types.Collection] = {}
        self.contacts: list[dict] = []
        self.step_log: list[str] = []

    def reset_scene(self) -> None:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        scene = bpy.context.scene
        scene.unit_settings.system = "METRIC"
        scene.unit_settings.scale_length = 1.0
        scene["cf_units"] = "1 BU = 1 m"
        scene["cf_up"] = "+Z"
        scene["cf_model_front"] = "-Y"

    def collection(self, name: str) -> bpy.types.Collection:
        existing = bpy.data.collections.get(name)
        if existing is not None:
            self.collections[name] = existing
            return existing
        collection = bpy.data.collections.new(name)
        bpy.context.scene.collection.children.link(collection)
        self.collections[name] = collection
        return collection

    @staticmethod
    def move_to_collection(obj: bpy.types.Object, collection: bpy.types.Collection) -> None:
        for previous in list(obj.users_collection):
            previous.objects.unlink(obj)
        collection.objects.link(obj)

    @staticmethod
    def material(name: str, color, roughness=0.72, metallic=0.0, emission=None):
        if not MATERIAL_PATTERN.fullmatch(name):
            raise ValueError(f"Invalid D21 material role: {name}")
        material = bpy.data.materials.get(name) or bpy.data.materials.new(name)
        material.diffuse_color = (*color, 1.0)
        material.use_nodes = True
        bsdf = material.node_tree.nodes.get("Principled BSDF")
        bsdf.inputs["Base Color"].default_value = (*color, 1.0)
        bsdf.inputs["Roughness"].default_value = roughness
        bsdf.inputs["Metallic"].default_value = metallic
        if emission is not None:
            bsdf.inputs["Emission Color"].default_value = (*emission, 1.0)
            bsdf.inputs["Emission Strength"].default_value = 2.5
        return material

    @staticmethod
    def assign_material(obj: bpy.types.Object, material: bpy.types.Material) -> None:
        obj.data.materials.clear()
        obj.data.materials.append(material)

    def empty(self, name, collection, location=(0.0, 0.0, 0.0), parent=None, rotation=None):
        obj = bpy.data.objects.new(name, None)
        collection.objects.link(obj)
        obj.empty_display_type = "PLAIN_AXES"
        obj.empty_display_size = 0.12
        obj.location = location
        if rotation is not None:
            obj.rotation_euler = rotation
        if parent is not None:
            obj.parent = parent
        return obj

    def box(self, name, collection, dimensions, location, material, parent=None, rotation=None):
        bpy.ops.mesh.primitive_cube_add(size=1.0)
        obj = bpy.context.object
        obj.name = name
        self.move_to_collection(obj, collection)
        obj.location = location
        obj.dimensions = dimensions
        if rotation is not None:
            obj.rotation_euler = rotation
        if parent is not None:
            obj.parent = parent
        self._apply_mesh_transform(obj)
        self.assign_material(obj, material)
        return obj

    def cylinder_z(self, name, collection, radius, depth, location, material, vertices=12, parent=None):
        bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth)
        obj = bpy.context.object
        obj.name = name
        self.move_to_collection(obj, collection)
        obj.location = location
        if parent is not None:
            obj.parent = parent
        self._apply_mesh_transform(obj)
        self.assign_material(obj, material)
        return obj

    def cone_z(self, name, collection, radius1, radius2, depth, location, material, vertices=12, parent=None):
        bpy.ops.mesh.primitive_cone_add(
            vertices=vertices,
            radius1=radius1,
            radius2=radius2,
            depth=depth,
        )
        obj = bpy.context.object
        obj.name = name
        self.move_to_collection(obj, collection)
        obj.location = location
        if parent is not None:
            obj.parent = parent
        self._apply_mesh_transform(obj)
        self.assign_material(obj, material)
        return obj

    def cylinder_between(self, name, collection, start, end, radius, material, vertices=10, parent=None):
        start_v = Vector(start)
        end_v = Vector(end)
        vector = end_v - start_v
        if vector.length <= 1e-6:
            raise ValueError(f"Zero-length cylinder: {name}")
        bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=vector.length)
        obj = bpy.context.object
        obj.name = name
        self.move_to_collection(obj, collection)
        obj.location = (start_v + end_v) * 0.5
        obj.rotation_euler = vector.to_track_quat("Z", "Y").to_euler()
        if parent is not None:
            obj.parent = parent
        self._apply_mesh_transform(obj)
        self.assign_material(obj, material)
        return obj

    @staticmethod
    def _apply_mesh_transform(obj: bpy.types.Object) -> None:
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
        obj.select_set(False)
        for polygon in obj.data.polygons:
            polygon.use_smooth = False

    def contact(self, label: str, face_a: float, face_b: float, expected_gap: float = 0.0, tolerance: float = 1e-4) -> None:
        actual_gap = face_b - face_a
        passed = abs(actual_gap - expected_gap) <= tolerance
        self.contacts.append(
            {
                "label": label,
                "actual_gap": actual_gap,
                "expected_gap": expected_gap,
                "passed": passed,
            }
        )
        if not passed:
            raise AssertionError(
                f"Contact {label} failed: expected {expected_gap:.4f}, actual {actual_gap:.4f}"
            )

    def log_step(self, name: str, detail: str) -> None:
        message = f"STEP {name}: {detail}"
        self.step_log.append(message)
        print(message)

    @staticmethod
    def objects_in(collections) -> list[bpy.types.Object]:
        result = []
        seen = set()
        for collection in collections:
            for obj in collection.all_objects:
                if obj.name not in seen:
                    result.append(obj)
                    seen.add(obj.name)
        return result

    def validate(self, module_collections, max_footprint=2.05, max_height=3.0) -> dict:
        objects = self.objects_in(module_collections)
        meshes = [obj for obj in objects if obj.type == "MESH"]
        errors = []
        for obj in objects:
            if not obj.name.startswith(NODE_PREFIXES):
                errors.append(f"unknown node prefix: {obj.name}")
            if obj.type in {"CAMERA", "LIGHT"}:
                errors.append(f"forbidden export object: {obj.name} ({obj.type})")
            if obj.type == "MESH":
                if not obj.name.startswith(("GEO_", "DMG_")):
                    errors.append(f"visible node prefix: {obj.name}")
                if any(abs(value - 1.0) > 1e-5 for value in obj.scale):
                    errors.append(f"unapplied scale: {obj.name} {tuple(obj.scale)}")
                if any(abs(value) > 1e-5 for value in obj.rotation_euler):
                    errors.append(f"unapplied rotation: {obj.name} {tuple(obj.rotation_euler)}")
                if obj.data.users != 1:
                    errors.append(f"shared mesh datablock: {obj.name} users={obj.data.users}")
                for material in obj.data.materials:
                    if material is None or not MATERIAL_PATTERN.fullmatch(material.name):
                        errors.append(f"invalid material role: {obj.name}/{getattr(material, 'name', None)}")
        corners = [obj.matrix_world @ Vector(corner) for obj in meshes for corner in obj.bound_box]
        if not corners:
            errors.append("no visible geometry")
            mins = maxs = Vector((0.0, 0.0, 0.0))
        else:
            mins = Vector(tuple(min(point[index] for point in corners) for index in range(3)))
            maxs = Vector(tuple(max(point[index] for point in corners) for index in range(3)))
            if mins.z < -1e-4:
                errors.append(f"geometry below ground: {mins.z:.4f}")
            if (maxs.z - mins.z) > max_height + 1e-4:
                errors.append(f"height budget exceeded: {(maxs.z - mins.z):.4f}")
            if max(maxs.x - mins.x, maxs.y - mins.y) > max_footprint + 1e-4:
                errors.append(
                    f"footprint budget exceeded: {(maxs.x - mins.x):.4f} x {(maxs.y - mins.y):.4f}"
                )
        for item in self.contacts:
            if not item["passed"]:
                errors.append(f"contact failed: {item['label']}")
        result = {
            "valid": not errors,
            "errors": errors,
            "bounds_min": tuple(round(value, 4) for value in mins),
            "bounds_max": tuple(round(value, 4) for value in maxs),
            "dimensions": tuple(round(maxs[index] - mins[index], 4) for index in range(3)),
            "mesh_count": len(meshes),
            "triangles": sum(
                max(0, len(polygon.vertices) - 2)
                for obj in meshes
                for polygon in obj.data.polygons
            ),
            "contacts": self.contacts,
        }
        print("VALIDATION", result)
        if errors:
            raise AssertionError("; ".join(errors))
        return result

    @staticmethod
    def render_views(output_dir: Path, module_collections, target=(0.0, 0.0, 1.35), ortho_scale=3.7) -> None:
        output_dir.mkdir(parents=True, exist_ok=True)
        scene = bpy.context.scene
        for collection in bpy.data.collections:
            collection.hide_render = collection not in module_collections
        scene.render.engine = "BLENDER_WORKBENCH"
        scene.display.shading.light = "STUDIO"
        scene.display.shading.show_shadows = True
        scene.display.shading.show_cavity = True
        scene.display.shading.cavity_type = "BOTH"
        scene.display.shading.color_type = "MATERIAL"
        scene.render.resolution_x = 800
        scene.render.resolution_y = 800
        scene.render.resolution_percentage = 100
        scene.render.image_settings.file_format = "PNG"
        scene.render.film_transparent = False

        bpy.ops.object.camera_add()
        camera = bpy.context.object
        camera.name = "TEMP_InspectionCamera"
        camera.data.type = "ORTHO"
        camera.data.ortho_scale = ortho_scale
        scene.camera = camera
        center = Vector(target)
        distance = 8.0
        views = {
            "front": center + Vector((0.0, -distance, 0.0)),
            "back": center + Vector((0.0, distance, 0.0)),
            "left": center + Vector((-distance, 0.0, 0.0)),
            "right": center + Vector((distance, 0.0, 0.0)),
            "top": center + Vector((0.0, 0.0, distance)),
            "bottom": center + Vector((0.0, 0.0, -distance)),
            "iso": center + Vector((distance, -distance, distance * 0.75)),
        }
        for name, location in views.items():
            camera.location = location
            direction = center - camera.location
            camera.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
            scene.render.filepath = str(output_dir / f"{name}.png")
            bpy.ops.render.render(write_still=True)
        bpy.data.objects.remove(camera, do_unlink=True)
        scene.camera = None
        for collection in bpy.data.collections:
            collection.hide_render = False

    @staticmethod
    def export_collection_glb(collection: bpy.types.Collection, path: Path) -> None:
        objects = list(collection.all_objects)
        roots = [obj for obj in objects if obj.parent is None]
        if len(roots) != 1 or not roots[0].name.startswith("CF_"):
            raise AssertionError(
                f"Export collection {collection.name} must contain exactly one CF_ root; "
                f"found {[obj.name for obj in roots]}"
            )
        if any(obj.type in {"CAMERA", "LIGHT"} for obj in objects):
            raise AssertionError(f"Export collection {collection.name} contains Camera/Light")

        previous_hide = {
            obj.name: (obj.hide_get(), obj.hide_viewport, obj.hide_render)
            for obj in objects
        }
        authoring_root = roots[0]
        direct_children = [obj for obj in objects if obj.parent == authoring_root]
        child_world_transforms = {obj.name: obj.matrix_world.copy() for obj in direct_children}
        for obj in direct_children:
            obj.parent = None
            obj.matrix_world = child_world_transforms[obj.name]

        bpy.ops.object.select_all(action="DESELECT")
        for obj in objects:
            obj.hide_set(False)
            obj.hide_viewport = False
            obj.hide_render = False
            obj.select_set(obj != authoring_root)
        bpy.context.view_layer.objects.active = direct_children[0]
        path.parent.mkdir(parents=True, exist_ok=True)
        bpy.ops.export_scene.gltf(
            filepath=str(path),
            export_format="GLB",
            use_selection=True,
            export_extras=True,
            export_cameras=False,
            export_lights=False,
            export_yup=True,
        )
        for obj in objects:
            obj.select_set(False)
            hide_get, hide_viewport, hide_render = previous_hide[obj.name]
            obj.hide_set(hide_get)
            obj.hide_viewport = hide_viewport
            obj.hide_render = hide_render
        for obj in direct_children:
            world_transform = child_world_transforms[obj.name]
            obj.parent = authoring_root
            obj.matrix_world = world_transform
        if not path.exists() or path.stat().st_size == 0:
            raise AssertionError(f"GLB export missing or empty: {path}")
        print("EXPORTED", path)

    @staticmethod
    def save(path: Path) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        if any(obj.type in {"CAMERA", "LIGHT"} for obj in bpy.context.scene.objects):
            raise AssertionError("Reference master must not retain Camera or Light objects")
        bpy.context.preferences.filepaths.save_version = 0
        bpy.ops.wm.save_as_mainfile(filepath=str(path))
        print("SAVED", path)
