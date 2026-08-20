"""Build the P0-FT1 Formal Interceptor Tower source and production modules.

The deterministic recipe creates a measured Blender source master with four
responsibility modules and semantic anchors. Passing ``--export-dir`` also
exports the normalized production GLBs. Run one cumulative step at a time:
common, interceptor, theme, damage.
"""

from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
from cardfront_asset_runner import CardfrontAssetRunner


REPO_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_MASTER = REPO_ROOT / "art_source/cardfront_3d/Cardfront_Tower_Master.blend"
DEFAULT_RENDERS = REPO_ROOT / "artifacts/formal-tower-reference"
STEP_ORDER = ("common", "interceptor", "theme", "damage")

TOWER_HEIGHT_LIMIT = 3.00
TOWER_FOOTPRINT = 2.00
PIVOT_Z = 1.80

BASE_LOWER_TOP = 0.22
BASE_UPPER_BOTTOM = 0.21
BASE_UPPER_TOP = 0.37
BODY_BOTTOM = 0.36
BODY_TOP = 1.52
COLLAR_BOTTOM = 1.51
COLLAR_TOP = 1.69
DOME_BOTTOM = 1.67
DOME_TOP = 2.01


def materials(runner):
    return {
        "stone": runner.material("CF_STONE__STATIC", (0.48, 0.50, 0.53), 0.86),
        "stone_theme": runner.material("CF_STONE__THEME", (0.62, 0.58, 0.49), 0.84),
        "metal": runner.material("CF_METAL__STATIC", (0.18, 0.22, 0.26), 0.58, 0.34),
        "trim": runner.material("CF_METAL__FACTION_TRIM", (0.12, 0.38, 0.66), 0.48, 0.22),
        "core": runner.material("CF_ENERGY__CORE", (0.25, 0.72, 1.0), 0.22, 0.0, (0.12, 0.52, 1.0)),
        "damage": runner.material("CF_METAL__DAMAGE", (0.11, 0.09, 0.09), 0.92),
        "banner": runner.material("CF_CLOTH__FACTION_TRIM", (0.15, 0.42, 0.70), 0.78),
    }


def setup_collections(runner):
    return {
        "reference": runner.collection("00_REFERENCE"),
        "common": runner.collection("01_COMMON"),
        "interceptor": runner.collection("02_INTERCEPTOR"),
        "theme": runner.collection("03_THEME"),
        "damage": runner.collection("04_DAMAGE"),
    }


def build_reference_guides(runner, collection, mats):
    guide = runner.empty("Reference_TowerEnvelope", collection)
    guide["cf_height_limit"] = TOWER_HEIGHT_LIMIT
    guide["cf_footprint"] = TOWER_FOOTPRINT
    guide["cf_height_vs_hq"] = "3.0 / 4.3 = 0.698"
    guide["cf_levels"] = "L1/L2/L3 same footprint and height class"


def build_common(runner, collection, mats):
    root = runner.empty("CF_TowerCommon", collection)
    root["cf_responsibility"] = "common"
    root["cf_origin"] = "ground_contact_center"

    runner.cylinder_z("GEO_BaseLower", collection, 1.00, 0.22, (0.0, 0.0, 0.11), mats["stone"], 8, root)
    runner.cylinder_z("GEO_BaseUpper", collection, 0.88, 0.16, (0.0, 0.0, 0.29), mats["metal"], 8, root)
    runner.cylinder_z("GEO_CommonBody", collection, 0.72, 1.16, (0.0, 0.0, 0.94), mats["stone"], 8, root)
    runner.cylinder_z("GEO_FactionBand", collection, 0.735, 0.16, (0.0, 0.0, 1.10), mats["trim"], 8, root)
    runner.cylinder_z("GEO_TopCollar", collection, 0.82, 0.18, (0.0, 0.0, 1.60), mats["metal"], 8, root)
    runner.cone_z("GEO_TopDome", collection, 0.70, 0.48, 0.34, (0.0, 0.0, 1.84), mats["stone"], 12, root)
    runner.cylinder_between(
        "GEO_StatusCore",
        collection,
        (0.0, -0.62, 1.14),
        (0.0, -0.76, 1.14),
        0.18,
        mats["core"],
        12,
        root,
    )
    runner.empty("SOCKET_FunctionModule", collection, (0.0, 0.0, PIVOT_Z), root)
    runner.empty("VFX_Build", collection, (0.0, 0.0, 0.04), root)

    runner.contact("ground -> BaseLower.bottom", 0.0, 0.0)
    runner.contact("BaseLower.top -> BaseUpper.bottom", BASE_LOWER_TOP, BASE_UPPER_BOTTOM, -0.01)
    runner.contact("BaseUpper.top -> CommonBody.bottom", BASE_UPPER_TOP, BODY_BOTTOM, -0.01)
    runner.contact("CommonBody.top -> TopCollar.bottom", BODY_TOP, COLLAR_BOTTOM, -0.01)
    runner.contact("TopCollar.top -> TopDome.bottom", COLLAR_TOP, DOME_BOTTOM, -0.02)
    runner.log_step(
        "common",
        "octagonal 2.0 m footprint, grounded five-interface stack, persistent status core, shared module socket",
    )
    return root


def arm_points(angle_degrees):
    angle = math.radians(angle_degrees)
    start = Vector((math.cos(angle) * 0.28, math.sin(angle) * 0.28, 1.91))
    end = Vector((math.cos(angle) * 0.62, math.sin(angle) * 0.62, 2.58))
    return start, end


def build_interceptor(runner, collection, mats):
    root = runner.empty("CF_TowerInterceptor", collection)
    root["cf_responsibility"] = "interceptor_function"
    pivot = runner.empty("PIV_Turret", collection, (0.0, 0.0, PIVOT_Z), root)
    runner.cylinder_z("GEO_TurretHub", collection, 0.43, 0.22, (0.0, 0.0, 0.11), mats["metal"], 12, pivot)

    arm_specs = (("A", 225.0, 1), ("B", 315.0, 1), ("C", 90.0, 2))
    for suffix, angle, min_level in arm_specs:
        start_world, end_world = arm_points(angle)
        start = start_world - Vector((0.0, 0.0, PIVOT_Z))
        end = end_world - Vector((0.0, 0.0, PIVOT_Z))
        arm = runner.cylinder_between(
            f"GEO_InterceptArm_{suffix}", collection, start, end, 0.105, mats["metal"], 10, pivot
        )
        arm["cf_min_level"] = min_level
        direction = (end - start).normalized()
        plate = runner.cylinder_between(
            f"GEO_InterceptPlate_{suffix}",
            collection,
            end - direction * 0.09,
            end + direction * 0.09,
            0.21,
            mats["core"],
            10,
            pivot,
        )
        plate["cf_min_level"] = min_level
        runner.contact(f"Arm_{suffix}.end -> Plate_{suffix}.center", 0.0, 0.0)

    mount = runner.box("GEO_CounterMount", collection, (0.56, 0.46, 0.30), (0.0, -0.08, 0.34), mats["metal"], pivot)
    mount["cf_min_level"] = 3
    barrel = runner.cylinder_between(
        "GEO_CounterBarrel",
        collection,
        (0.0, -0.24, 0.34),
        (0.0, -0.88, 0.34),
        0.105,
        mats["metal"],
        10,
        pivot,
    )
    barrel["cf_min_level"] = 3
    muzzle = runner.cylinder_between(
        "GEO_CounterMuzzle",
        collection,
        (0.0, -0.82, 0.34),
        (0.0, -0.98, 0.34),
        0.15,
        mats["trim"],
        10,
        pivot,
    )
    muzzle["cf_min_level"] = 3
    socket = runner.empty(
        "SOCKET_Muzzle",
        collection,
        (0.0, -0.98, 0.34),
        pivot,
    )
    socket["cf_forward"] = "local +Z = Godot +Z model front after glTF import"
    runner.empty("VFX_Intercept", collection, (0.0, 0.0, 0.54), pivot)
    runner.contact("CounterMount.front -> CounterBarrel.start", -0.23, -0.24, -0.01)
    runner.contact("CounterBarrel.end -> CounterMuzzle.start", -0.88, -0.82, 0.06)
    runner.log_step(
        "interceptor",
        "first arm module measured then repeated as single-user A/B/C; L1=2, L2/L3=3, L3 counter muzzle",
    )
    return root


def build_theme(runner, collection, mats):
    root = runner.empty("CF_TowerThemeCastle", collection)
    root["cf_responsibility"] = "castle_theme"
    positions = (
        (-0.66, -0.34, 0.88),
        (0.66, -0.34, 0.88),
        (-0.66, 0.34, 0.88),
        (0.66, 0.34, 0.88),
    )
    for index, position in enumerate(positions, 1):
        buttress = runner.box(
            f"GEO_CastleButtress_{index}", collection, (0.24, 0.34, 1.02), position, mats["stone_theme"], root
        )
        buttress["cf_module_pattern"] = "castle_buttress"
    runner.box("GEO_CastleBanner", collection, (0.62, 0.06, 0.42), (0.0, 0.70, 1.22), mats["banner"], root)
    runner.contact("BaseUpper.top -> CastleButtress.bottom", BASE_UPPER_TOP, 0.37, 0.0)
    runner.log_step("theme", "four single-user seated buttresses and one restrained rear faction banner")
    return root


def build_damage(runner, collection, mats):
    root = runner.empty("CF_TowerDamageCommon", collection)
    root["cf_responsibility"] = "damage_states"
    root["cf_visibility"] = "mutually exclusive; runtime selects exactly one HP state"

    crack_sets = {
        3: (
            ("A", (0.07, 0.045, 0.34), (-0.30, -0.6875, 1.31), 18.0),
            ("B", (0.06, 0.045, 0.22), (-0.20, -0.6875, 1.12), -24.0),
        ),
        2: (
            ("A", (0.09, 0.050, 0.48), (0.26, -0.6900, 1.30), -22.0),
            ("B", (0.08, 0.050, 0.34), (0.10, -0.6900, 1.03), 28.0),
            ("C", (0.07, 0.050, 0.28), (0.39, -0.6900, 1.01), 16.0),
        ),
        1: (
            ("A", (0.11, 0.055, 0.58), (-0.18, -0.6925, 1.31), 28.0),
            ("B", (0.10, 0.055, 0.50), (0.18, -0.6925, 1.23), -26.0),
            ("C", (0.09, 0.055, 0.36), (-0.40, -0.6925, 0.98), -18.0),
            ("D", (0.09, 0.055, 0.34), (0.38, -0.6925, 0.91), 20.0),
        ),
    }
    state_names = {3: "Light", 2: "Heavy", 1: "Critical"}
    for hp_state, cracks in crack_sets.items():
        for suffix, dimensions, location, angle in cracks:
            crack = runner.box(
                f"DMG_{state_names[hp_state]}_{suffix}",
                collection,
                dimensions,
                location,
                mats["damage"],
                root,
                rotation=(0.0, math.radians(angle), 0.0),
            )
            crack["cf_hp_state"] = hp_state
    rubble_specs = (
        ((0.58, 0.42, 0.34), (-0.48, -0.22, 0.17), 18.0),
        ((0.52, 0.38, 0.30), (0.46, -0.30, 0.15), -22.0),
        ((0.46, 0.40, 0.28), (0.12, 0.34, 0.14), 12.0),
        ((0.40, 0.30, 0.22), (-0.08, -0.48, 0.11), -10.0),
        ((0.34, 0.30, 0.20), (0.44, 0.28, 0.10), 25.0),
    )
    for index, (dimensions, position, angle) in enumerate(rubble_specs, 1):
        rubble = runner.box(
            f"DMG_Rubble_{index}",
            collection,
            dimensions,
            position,
            mats["damage"],
            root,
            rotation=(0.0, 0.0, math.radians(angle)),
        )
        rubble["cf_hp_state"] = 0
        rubble["cf_authority"] = "presentation_snapshot_only"
        runner.contact(f"Rubble_{index}.bottom -> ground", position[2] - dimensions[2] * 0.5, 0.0)
    runner.empty("VFX_DamageSmoke", collection, (0.0, -0.58, 1.48), root)
    runner.log_step(
        "damage",
        "mutually exclusive HP 3/2/1 crack clusters plus five grounded HP0 snapshot rubble anchors",
    )
    return root


def set_damage_state(collection, hp_state):
    for obj in collection.all_objects:
        if obj.type != "MESH":
            continue
        state = obj.get("cf_hp_state")
        visible = state == hp_state
        obj.hide_render = not visible
        obj.hide_viewport = not visible


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--step", choices=STEP_ORDER, default="damage")
    parser.add_argument("--output-blend", type=Path, default=DEFAULT_MASTER)
    parser.add_argument("--render-dir", type=Path, default=DEFAULT_RENDERS)
    parser.add_argument("--report", type=Path)
    parser.add_argument("--export-dir", type=Path)
    return parser.parse_args(sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else [])


def main():
    args = parse_args()
    runner = CardfrontAssetRunner("CF_Tower")
    runner.reset_scene()
    mats = materials(runner)
    collections = setup_collections(runner)
    build_reference_guides(runner, collections["reference"], mats)

    enabled = []
    build_common(runner, collections["common"], mats)
    enabled.append(collections["common"])
    if STEP_ORDER.index(args.step) >= STEP_ORDER.index("interceptor"):
        build_interceptor(runner, collections["interceptor"], mats)
        enabled.append(collections["interceptor"])
    if STEP_ORDER.index(args.step) >= STEP_ORDER.index("theme"):
        build_theme(runner, collections["theme"], mats)
        enabled.append(collections["theme"])
    if STEP_ORDER.index(args.step) >= STEP_ORDER.index("damage"):
        build_damage(runner, collections["damage"], mats)
        enabled.append(collections["damage"])

    result = runner.validate(enabled, TOWER_FOOTPRINT + 0.05, TOWER_HEIGHT_LIMIT)
    scene = __import__("bpy").context.scene
    scene["cf_asset"] = "Formal Interceptor Tower Reference Kit"
    scene["cf_stage"] = args.step
    scene["cf_validation"] = str(result)
    scene["cf_step_log"] = "\n".join(runner.step_log)
    scene["cf_non_goal"] = "No gameplay authority, balance, collision, or occupancy changes"

    if args.report is not None:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(
            json.dumps(
                {
                    "asset": scene["cf_asset"],
                    "stage": args.step,
                    "validation": result,
                    "step_log": runner.step_log,
                    "non_goal": scene["cf_non_goal"],
                    "hp_states": {
                        "4": "complete",
                        "3": "light",
                        "2": "heavy",
                        "1": "critical",
                        "0": "presentation_snapshot_rubble_only",
                    },
                },
                indent=2,
                sort_keys=True,
            )
            + "\n",
            encoding="utf-8",
        )

    if args.step == "damage":
        damage_collection = collections["damage"]
        for hp_state in (4, 3, 2, 1):
            set_damage_state(damage_collection, hp_state)
            runner.render_views(args.render_dir / f"hp{hp_state}", enabled)
        set_damage_state(damage_collection, 0)
        runner.render_views(
            args.render_dir / "hp0",
            [damage_collection],
            target=(0.0, 0.0, 0.30),
            ortho_scale=2.4,
        )
        set_damage_state(damage_collection, 4)
    else:
        runner.render_views(args.render_dir / args.step, enabled)

    if args.export_dir is not None:
        export_targets = {
            "tower_common.glb": collections["common"],
            "tower_interceptor.glb": collections["interceptor"],
            "tower_theme_castle.glb": collections["theme"],
            "tower_damage_common.glb": collections["damage"],
        }
        missing = [name for name, collection in export_targets.items() if collection not in enabled]
        if missing:
            raise AssertionError(f"Step {args.step} cannot export unbuilt modules: {missing}")
        for filename, collection in export_targets.items():
            runner.export_collection_glb(collection, args.export_dir / filename)
    runner.save(args.output_blend)


if __name__ == "__main__":
    main()
