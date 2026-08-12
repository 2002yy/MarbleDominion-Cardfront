# P0-06B4 / P0-06C Deployment Zone and Region UI Separation

Source commit: `3902ddad243a40fcb30edd0c28799a44f2157160`

Decision: **GO**

Only allowed next step: **P0-07A1 — Geometry Golden Snapshot**.

## P0-06B4 result

The pre-existing `CardfrontTargetPreviewLayer` remains the preview-side consumer of `DeploymentRules.evaluate()`. It now emits only the already-evaluated legal cell result and the deployment authority revision.

`CardfrontDeploymentZoneLayer3D` consumes that result as a detached cell array and renders one translucent, non-colliding marker per legal cell in the active orthographic battlefield. It does not import or call `DeploymentRules`, inspect Support graph/runtime context, infer ownership, or implement another legality predicate.

Lifecycle:

```text
default / no selection / Draft
  -> empty result -> 3D zone hidden

frontline deployment targeting
  -> current DeploymentRules results + revision
  -> 3D translucent legal cells visible

non-frontline selection / cancel / clear
  -> empty result -> 3D zone hidden
```

The live runtime now constructs the existing target-preview authority even while its legacy 2D drawing surface remains hidden by orthographic presentation. It binds that authority to the real Support deployment context provider and forwards only evaluated results to the 3D arena.

## Current product-entry limitation

The formal live three-choice run does not construct the legacy targeted-card hand/CardPlaySystem and currently contains no player-facing targeted deployment card. Therefore there is no honest current manual click path for a player to enter frontline deployment targeting.

This checkpoint does not re-enable the retired compatibility hand, invent a new card, or claim such a click was performed. The activation path is verified with the real `default_duel` map, real Support authority, real `DeploymentRules` evaluation, real preview owner, and real 3D visualizer in the focused integration runner.

## P0-06C result

No production UI change was required. Audit confirms:

- `CardfrontRegionInfoPanel` calculates territory percentages through `RegionControlCalculator`;
- the 80% line is status-only and does not promise a Factory/Energy/Lab reward;
- the panel may show current territory-defense information;
- it does not consume `support_id`, Support claim/connectivity/operational state, deployment context, or presentation snapshots;
- Support state remains owned by the Support authority/presenter path;
- territory region and Support identity remain separate authorities.

## Evidence on source commit

Godot: `4.7.1.stable.official.a13da4feb`

P0-06B4 focused and adjacent regression:

- `CardfrontDeploymentZoneVisualizationTestRunner.gd` — PASS (18 checks)
- `CardfrontOrthographicArenaTestRunner.gd` — PASS (61 checks)
- `CardfrontTargetPreviewTestRunner.gd` — PASS (13 checks)
- `CardfrontDeploymentDirectionalZoneTestRunner.gd` — PASS (17 checks)
- `CardfrontDeploymentPreviewParityTestRunner.gd` — PASS (8 checks)
- `CardfrontDeploymentFourConsumerParityTestRunner.gd` — PASS (28 checks)
- `CardfrontDeploymentAutomaticSpawnTestRunner.gd` — PASS (58 checks)

P0-06C and Support separation regression:

- `CardfrontRegionInfoPanelVisibilityTestRunner.gd` — PASS (26 checks)
- `CardfrontStrongholdSystemTestRunner.gd` — PASS (2377 checks)
- `CardfrontThreeChoiceRuntimeTestRunner.gd` — PASS (58 checks)
- `CardfrontSupportPresentationContractTestRunner.gd` — PASS (32 checks)
- `CardfrontSupportPresentationLifecycleTestRunner.gd` — PASS (30 checks)
- `DeploymentRulesTestRunner.gd` — PASS (26 checks)
- project headless boot — PASS

Total focused assertions: **2,752 passed**.

The active Support identity workflow includes `CardfrontDeploymentZoneVisualizationTestRunner.gd`.

## Scope and non-goals

- no map or route geometry changed;
- no territory/projectile capture changed;
- no Support capture runtime integration added;
- no Creature movement legality changed;
- no automatic/upgrade spawn changed;
- no Draft behavior, offer, card, or gameplay rule added;
- no save/snapshot schema changed;
- no legacy targeted-card hand was re-enabled;
- P0-07 was not started.

## Mandatory audit fields

```text
Mandatory audit gates touched: P0-06B4 Deployment-zone visualization; P0-06C legacy Region UI separation
Audit status per gate: PASS / PASS
Evidence bound to source commit: YES — 3902ddad243a40fcb30edd0c28799a44f2157160
Highest-priority evidence used: focused integration tests + live orthographic construction + source authority audit
Unverified assumptions remaining: no current formal player-facing targeted deployment card exists for manual click evidence
Legacy authority still reachable: legacy 2D preview remains the single preview rules consumer but its drawing is hidden in orthographic mode
Second-authority risk: NONE; 3D visualizer accepts only evaluated cell results
Save/restore risk: NONE
Cross-system regression evidence: preview parity, four-consumer parity, automatic spawn, Stronghold, three-choice, Support presentation and RegionInfoPanel passed
Manual evidence required before GO: NO for current engineering gate; no current formal product entry exists to exercise manually
Video requested explicitly by product owner: NO
Runtime region_id used as stable identity: NO
CardfrontCaptureInterceptor scope broadened: NO
Creature movement legality touched: NO
Automatic/upgrade spawn path changed: NO
Map geometry changed: NO
Bridge/gate behavior changed: NO
Gameplay collision introduced: NO
RegionInfoPanel infers Support truth: NO
```
