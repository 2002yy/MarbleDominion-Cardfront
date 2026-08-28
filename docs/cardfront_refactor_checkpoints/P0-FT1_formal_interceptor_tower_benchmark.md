# P0-FT1 Formal Interceptor Tower Cross-Asset Benchmark

Date: 2026-08-21

Accepted source commit: `697dcbe`
Decision: **STEPS 1–9 TEMPORARY VISUAL GO / CLOSED**

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

### Step 1 Evidence — Reusable D22 Validator

Implemented:

- `scripts/cardfront/environment/CardfrontFormalAssetValidator.gd`;
- `scripts/tests/CardfrontFormalAssetValidatorTestRunner.gd`;
- nine positive/negative scene fixtures under
  `scripts/tests/fixtures/formal_assets/`.

Fail-closed coverage:

- root identity and applied visible-mesh transforms;
- frozen node prefixes and required Tower semantic nodes;
- D21 `CF_<SURFACE>__<CHANNEL>` materials;
- Collision, Camera, and Light rejection;
- null/missing resources;
- explicit proof that validation does not mutate or heal invalid input.

Evidence:

- `CardfrontFormalAssetValidatorTestRunner`: **32 PASS**;
- `CardfrontEnvironmentAssetTestRunner`: **149 PASS** after correcting its
  stale KayKit/Custom/Formal registry grouping assertion;
- current `hq_common.glb`: importable, but intentionally rejected by D22 due
  legacy root/node/material names. It is migration input, not Contract PASS.

### Step 2 Evidence — Tower Reference Kit

Implemented in the current working tree:

- `art_source/cardfront_3d/Cardfront_Tower_Master.blend`;
- `tools/blender/cardfront_asset_runner.py` deterministic build, contact,
  validation, seven-view inspection, and Camera/Light cleanup helper;
- `tools/blender/build_cardfront_tower_reference.py` cumulative
  Common → Interceptor → Castle → Damage recipe;
- two compact review sheets and a machine-readable report under
  `artifacts/formal-tower-reference/`.

Admission evidence:

- exact bounds: **2.0 × 2.0 × 2.7553 m**; no geometry below ground;
- **45** single-user meshes, **980** triangles, applied mesh rotation/scale;
- all node/material roles pass the recipe-side D21/D22 preflight;
- required `PIV_Turret`, `SOCKET_Muzzle`, and `VFX_Intercept` present;
- **23/23** grounded/interface/arm/muzzle/structural-damage/rubble contact
  assertions PASS;
- Level grammar records 2/3/3 interception elements and an L3-only counter
  muzzle without changing footprint or height class;
- HP 4/3/2/1/0 are mutually exclusive complete/light/heavy/critical/rubble
  states; HP2 removes one intact buttress, HP1 additionally removes the intact
  dome and one arm/plate, and HP0 uses five individually grounded
  presentation-only pieces;
- six orthographic sides plus isometric inspection PASS; no Camera or Light is
  retained in the `.blend` master.

The first damage visualization was rejected during review because HP3/2/1
overlays appeared simultaneously and obscured the faction/core band. The
recipe now renders mutually exclusive damage states, applies the same intact
part visibility contract to Blender evidence and Godot, and keeps all damage
objects hidden by default in the source master.

### Steps 3–4 Evidence — Production Modules and Godot Admission

Exported and imported:

- `tower_common.glb` → `CF_TowerCommon`;
- `tower_interceptor.glb` → `CF_TowerInterceptor`;
- `tower_theme_castle.glb` → `CF_TowerThemeCastle`;
- `tower_damage_common.glb` → `CF_TowerDamageCommon`.

All four files pass the executable validator and import as independent
`PackedScene` resources. Godot's GLTF import does not preserve the Blender
custom properties used by the source recipe, so runtime state mapping uses the
frozen semantic node names instead: `GEO_Intercept*`, `GEO_Counter*`, and
`DMG_Light/Heavy/Critical/Rubble*`. This does not relax D21/D22 admission.

Evidence:

- `CardfrontFormalAssetValidatorTestRunner`: **32 PASS**;
- `CardfrontFormalTowerAssetTestRunner`: **34 PASS**;
- `CardfrontEnvironmentAssetTestRunner`: **165 PASS**;
- no Collision, Camera, Light, invalid root, unknown material role, unapplied
  visible transform, or missing required socket admitted.

### Steps 5–6 Evidence — Registry, Runtime Assembly, and State Binding

The environment registry now exposes the four Formal Tower modules. The 3D
presenter assembles per-instance Common + Interceptor + Castle + Damage modules
and applies faction materials without sharing overrides between player and AI.

Bound presentation states:

- L1/L2/L3 → 2/3/3 large interception plates; L3 counter module;
- HP4/3/2/1 → complete/light/heavy/critical mutually exclusive geometry,
  including exact HP2 buttress loss and HP1 dome/arm/plate replacement;
- Active, Unpowered, Suppressed, and Quota Empty → core/plate visibility;
- explicit level-change signal → upper-module Snap–Settle;
- interception and counter results → bounded pulse plus **0.24 m**
  Snap-Recoil and one short-lived emissive muzzle flash;
- destruction → immediate Registry removal plus a one-second presentation
  snapshot that never enters Registry authority.

The build animation targets the model only and does not delay entity
availability. The visual presenter reads current tower state and never writes
HP, level, power, quota, occupancy, collision, targeting, or save authority.

Focused evidence:

- `CardfrontOrthographicArenaTestRunner`: **166 PASS**;
- `CardfrontBattlefieldEntityRuntimeTestRunner`: **26 PASS** with its stale
  expiry-fixture cap collision corrected, eliminating a prior false-green
  script error;
- player/AI material override isolation, suppressed/disabled plate shutdown,
  explicit upgrade event, HP selection, and non-authoritative death snapshot
  are asserted.

### Step 7 Evidence — Deterministic Visual Matrix

Capture tooling:

- `scripts/tools/capture_cardfront_formal_tower_state_board.gd`;
- `scripts/tools/capture_cardfront_formal_tower_live.gd`;
- `scripts/tools/run_cardfront_formal_tower_capture.ps1`.

Generated review evidence:

- `artifacts/formal-tower-state-board/formal-tower-state-board.png`;
- `artifacts/formal-tower-state-board/formal-tower-state-board-manifest.json`;
- desktop and narrow live captures plus manifests under
  `artifacts/formal-tower-live/`.

The **15-card Chinese board** uses a **22 px minimum text floor** and covers faction,
L1–L3, a dedicated continuous HP4/3/2/1/0 damage sequence, Active, Unpowered, Suppressed, Quota Empty, Intercept
Pulse, L3 Counter, and Death Snapshot. Each live capture fails closed unless it
contains both HQ proxies, both bridges, two four-module Formal Towers, all six
faction/type projectile combinations, and both Towers inside the logical
screen boundary. Desktop and 760×540 narrow captures both PASS.

The full-arena captures are combat hierarchy/occlusion evidence, not close-up
art evidence: the Tower is intentionally small in a 40×50 overview. The state
board is the authoritative close visual review surface.

The first product-owner review returned **NO-GO** because HP0 rubble read too
small and the L3 Counter action lacked a strong instantaneous focus. Revision 1
replaced three tiny pieces with a five-piece grounded rubble cluster and froze
the Counter card on its brighter muzzle-flash/recoil frame. The refreshed board
records `visible_damage_meshes=5` for HP0 and `counter_flash_count=1` for L3;
the revised screenshots still require a new product-owner decision. Revision 2
responds to the follow-up readability review: all visible board copy is Chinese,
the board expands without shrinking its 22 px text floor, and HP4/3/2/1/0 now
form a dedicated two-row damage sequence instead of hiding HP4 under level
coverage and HP0 under action coverage. A second HP1 card confirms the same
critical-damage geometry remains readable with the opposing faction treatment.

Revision 3 structural-damage decision is product-owner approved:

- HP3 remains a surface-crack state;
- HP2 hides one intact front buttress and exposes a breach plus one grounded
  fallen buttress chunk;
- HP1 additionally replaces the complete dome with seated collapsed roof
  fragments and replaces one intact interception arm/plate with a connected
  arm stub, a fallen arm section, and a grounded detached plate;
- HP0 remains the five-piece grounded death snapshot;
- all replacements are presentation-only and must not change HP, interception
  quota, counter rules, collision, occupancy, Registry, save, or AI authority.

Rejected implementation: dark overlays on top of the still-complete silhouette.
Acceptance requires exact named-part visibility assertions, grounded/seated
contact checks, mutually exclusive damage geometry, refreshed five-stage board,
and unchanged gameplay/runtime regression results.

Revision 3 implementation evidence now records HP2 with five visible damage
meshes and exactly `GEO_CastleButtress_1` hidden; HP1 records eleven visible
damage meshes with `GEO_CastleButtress_1`, `GEO_TopDome`,
`GEO_InterceptArm_A`, and `GEO_InterceptPlate_A` hidden. Blender and Godot use
the same deterministic visibility mapping, and the refreshed Chinese board,
desktop capture, and narrow capture all PASS.

### Step 8 Evidence — Regression, Save, Performance, and Logs

All runs completed sequentially with non-zero exits and `SCRIPT ERROR`, parse
errors, and runtime `ERROR` treated as failures:

- Arena Layout **45**, Arena Runtime **24**, Battlefield Scale **57**, Click
  Selection **16**;
- Entity Animation **54**, Entity Card Runtime **27**, Entity Foundation **23**,
  Entity Runtime Boundary **25**, Entity Presentation Feedback **161**;
- Restore Plan **11**, Save Flow **190**;
- Cardfront Performance Smoke **10**;
- Formal validator/import/registry and Orthographic Arena counts listed above.

No new parse, import, runtime, or performance-budget error remains in the
accepted evidence run. The refreshed focused matrix totals **17 suites / 1066
PASS**.

Current result: **STEPS 1–9 TEMPORARY VISUAL GO / P0-FT1 CLOSED**

GO evidence bound to source commit: **YES — `697dcbe`**
Manual evidence required: **COMPLETED by product-owner screenshot review on 2026-08-21**

Product-owner review result:

> Temporary visual GO. Structural damage may become more visually significant
> in a future art pass, especially the HP2 buttress loss and HP1 collapsed
> dome/broken arm silhouette, but that improvement is non-blocking.

Only allowed program step after this closed gate is selected by
`docs/PROJECT_STATUS.md`; this checkpoint does not authorize another Art asset
family by itself.
