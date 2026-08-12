# P0-06B1–B3 Support Battlefield Visuals

Source commit: `390f95a38690d5fce81d5533c2a5b77aac0acf15`

Decision: **GO**

Only allowed next step: **P0-06B4 — Deployment-Zone Visualization Gate**.

## Scope completed

- P0-06B1: `CardfrontSupportPresentationLayer3D` owns exactly one visual instance per authored stable `support_id`, updates it on presentation revision, and disposes it on map/layer teardown.
- P0-06B2: Support placement follows `anchor_cell -> CardfrontOrthographicArenaView.cell_to_world() -> visual position`; no pixel, region-centroid, or copied coordinate formula was introduced.
- P0-06B3: each visual is presentation-only and limited to a ground mark, low beacon, small flag, and compact capture progress. The visual subtree contains no collision authority.

## Runtime ownership and data flow

```text
DefaultDuelMap.deployment_supports (stable support_id + anchor_cell)
  -> CardfrontSupportDeploymentAuthority.presentation_snapshots()
  -> presentation_snapshots_changed
  -> CardfrontOrthographicArenaView
  -> CardfrontSupportPresentationLayer3D
  -> CardfrontSupportVisual3D
```

`runtime region_id` is not emitted by the presentation source and is not used as visual identity. Visuals receive detached dictionaries only; they do not receive mutable Support runtime, graph, capture, deployment, or territory authority.

The live builder binds the same Support authority already owned by the territory/projectile capture interceptor boundary. This does not broaden `CardfrontCaptureInterceptor` into Support capture authority and does not change territory/projectile capture behavior.

## Verified lifecycle

- real `default_duel` metadata produces seven stable snapshots and seven visual instances;
- repeated sync updates the existing instances without recreation;
- stable instance identity survives a state revision;
- removing one snapshot disposes only that visual;
- layer teardown disposes the remaining instances;
- the view disconnects the presentation signal when leaving the tree;
- no `_process()` visual construction/free loop exists.

## State truth boundary

The current live Support deployment authority exposes Core Active and non-Core Neutral/Disabled truth. The pure capture state machine is not yet a live runtime state owner, so this batch does **not** fabricate live Capturing, Contested, or CapturedOffline transitions.

The detached presentation contract and visual lifecycle runner do verify projection and rendering behavior for Capturing progress and Active progress teardown. A later authorized runtime-capture integration must provide those states before they can appear during real play.

## Evidence on the source commit

Godot: `4.7.1.stable.official.a13da4feb`

Automated and integration evidence:

- `CardfrontSupportPresentationContractTestRunner.gd` — PASS (32 checks)
- `CardfrontSupportPresentationLifecycleTestRunner.gd` — PASS (30 checks)
- `CardfrontOrthographicArenaTestRunner.gd` — PASS (58 checks)
- `CardfrontSupportMapMetadataTestRunner.gd` — PASS (135 checks)
- `CardfrontSupportStateTestRunner.gd` — PASS (22 checks)
- `CardfrontSupportCaptureStateMachineTestRunner.gd` — PASS (25 checks)
- `CardfrontSupportConnectivityTruthTestRunner.gd` — PASS (14 checks)
- `DeploymentRulesTestRunner.gd` — PASS (26 checks)
- `CardfrontDeploymentAutomaticSpawnTestRunner.gd` — PASS (58 checks)
- project headless boot — PASS

Total focused assertions: **400 passed**.

The active GitHub Actions P0 Support identity batch now includes the new lifecycle runner.

Visual evidence:

- deterministic real-render capture on source commit `390f95a38690d5fce81d5533c2a5b77aac0acf15`;
- extent `40x50`, viewport `1120x720`, Compatibility renderer on RTX 5060 Laptop GPU;
- generated locally as `artifacts/cardfront-full-battle-40x50-viewport-1120x720.png` and intentionally not committed;
- review result: authored Support anchors remain visible, visuals do not cover either bridge, combat units, projectile routes, or deployment lanes, and no permanent network lines or large blocking structures appear.

Human product-owner art acceptance remains optional follow-up; it is not represented as completed by the automated review.

## Findings and non-goals

- No gameplay rule, map geometry, territory capture, Creature movement, automatic/upgrade spawn, Draft, AI, save/snapshot schema, bridge, gate, or Stronghold behavior changed.
- Deployment-zone visualization was not started.
- No Support capture runtime integration was invented.
- Existing untracked artifacts and `screenshot.png` were preserved and excluded from commits.

## Mandatory audit fields

```text
Mandatory audit gates touched: P0-06B1 visual lifecycle; P0-06B2 coordinate contract; P0-06B3 low-occlusion/non-collision presentation
Audit status per gate: PASS / PASS / PASS
Evidence bound to source commit: YES — 390f95a38690d5fce81d5533c2a5b77aac0acf15
Highest-priority evidence used: focused tests + live runtime construction + deterministic real-render screenshot
Unverified assumptions remaining: final product-owner visual preference; live Support capture transitions remain intentionally unwired
Legacy authority still reachable: territory RegionInfoPanel remains territory UI only; no Support identity inferred from it
Second-authority risk: NONE introduced; one layer cache keyed only by support_id
Save/restore risk: NONE; no schema or persistence path changed
Cross-system regression evidence: map metadata, state, capture pure state machine, connectivity, DeploymentRules, automatic spawn, and live orthographic integration all passed
Manual evidence required before GO: NO for engineering B1-B3; optional product-owner art acceptance remains
Video requested explicitly by product owner: NO
Stable IDs introduced/changed: NO; existing authored support_id values consumed
Runtime region_id used as stable identity: NO
CardfrontCaptureInterceptor scope broadened: NO
Creature movement legality touched: NO
Automatic/upgrade spawn path changed: NO
Map geometry changed: NO
Bridge/gate behavior changed: NO
Gameplay collision introduced by visuals: NO
```
