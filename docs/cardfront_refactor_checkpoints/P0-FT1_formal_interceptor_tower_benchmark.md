# P0-FT1 Formal Interceptor Tower Cross-Asset Benchmark

Date: 2026-08-20

Source commit: `3f3c8a6`
Decision: **NOT STARTED**

## Step Contract

Original intent: prove the D21/D22 Formal production system can cross from the
Balanced Castle HQ into one complete gameplay-identified Tower vertical slice.

Old authority:

- existing procedural/legacy Interceptor Tower presentation;
- existing 4-HP, L1–L3, 2/3/3 interception and L3 counterfire runtime;
- existing fixed-slot build/upgrade authority.

Target authority:

- gameplay authority remains unchanged;
- Formal GLB validator owns asset admission checks;
- Formal 3D presenter mirrors tower identity, faction, level, HP, operation,
  interception availability, actions, and death snapshot.

Allowed mutation surface:

- reusable Formal GLB validator and focused tests;
- Tower Blender source master and four Formal runtime GLBs;
- environment/formal asset registration;
- presentation-only 3D Tower assembly, state mapping, motion, and bounded VFX;
- explicit presentation notification for Tower level change;
- deterministic state-board and live-battle capture tooling;
- focused tests and current authority/status documentation.

Read-only surface:

- projectile simulation and collision;
- tower combat rules and numeric configuration;
- fixed building slots and build legality;
- AI choice policy and upgrade eligibility;
- save authority except compatibility tests required by added presentation signal.

Forbidden changes:

- tower HP, level cap, interception capacity, counterfire rules, costs, balance,
  ownership/power authority, or build timing;
- new Tower cards or other Formal asset families;
- formal audio/D26 expansion;
- gameplay collision or occupancy inside presentation GLBs;
- runtime healing of invalid Formal asset contracts.

## Locked Asset Contract

```text
tower_common.glb
tower_interceptor.glb
tower_theme_castle.glb
tower_damage_common.glb
```

Required semantic nodes include `CF_` root, `GEO_` geometry,
`PIV_Turret`, `SOCKET_Muzzle`, and `VFX_Intercept`. Materials use
`CF_<SURFACE>__<CHANNEL>`.

## Locked State Contract

- L1/L2/L3 preserve footprint and height class; use 2/3/3 large interception
  elements plus Level-3 counterfire distinction.
- HP 4/3/2/1/0 maps to complete/light/heavy/critical/destroyed geometry.
- Active/Unpowered/Suppressed/Quota Empty/Level-3 Counter are included in the
  formal state board.
- Build presentation lasts approximately 0.6–0.9 seconds without delaying
  gameplay availability.
- Upgrades use upper-module Snap–Settle and an explicit presentation event.
- Destroyed entity authority is removed immediately; a non-authoritative death
  snapshot may persist for about one second.

## Required Execution Order

1. Add reusable D22 Formal GLB validator and failing fixtures/tests.
2. Author Tower reference kit and module/socket layout.
3. Build Common, Interceptor, Castle Theme, and Damage modules.
4. Validate and export normalized GLBs.
5. Register and assemble the Formal Tower in Godot.
6. Bind faction, L1–L3, HP, operational, quota, intercept, counter, upgrade,
   build, and destruction presentation states.
7. Generate the deterministic state board and live desktop/narrow captures.
8. Run affected automated, import, runtime, save, performance, and log checks.
9. Obtain product-owner screenshot GO / NO-GO.

## Acceptance Evidence

Contract:

- structural and semantic validator PASS;
- invalid transforms, nodes, materials, collision/Camera/Light, and missing
  sockets fail closed;
- module and faction instance isolation PASS.

Runtime:

- all locked state mappings and action cues are bound to current authority;
- presentation animations do not delay or modify gameplay;
- death snapshot never enters Registry, occupancy, targeting, collision, or save;
- existing Interceptor Tower runtime and entity-card tests remain green.

Visual:

- state board covers faction, level, HP, and operational/action rows;
- desktop and narrow captures contain both HQs, Formal Tower, bridge/frontline,
  and both projectile factions;
- Tower reads as the 1.0 vertical reference, below HQ priority, without hiding
  active combat;
- product-owner screenshot decision is explicit.

Performance/log:

- no new parse/import/runtime errors or warnings;
- remains inside the existing arena performance budget.

## Gate

Current result: **NOT STARTED**

GO evidence bound to source commit: **NO**
Manual evidence required: **YES**

Only allowed next step inside the Art Production track:

> Implement the reusable D22 Formal GLB validator with negative fixtures and
> focused tests. Do not start Tower modeling before the validator contract is
> executable.
