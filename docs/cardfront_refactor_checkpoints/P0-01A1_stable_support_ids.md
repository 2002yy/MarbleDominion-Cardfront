# P0-01A1 Stable Support IDs

Source commit: `f30cd581a54dc3900227d5ef9a7d0d2f8e255dc8`
Original intent: Establish a static authored Support identity schema without connecting Support to live gameplay.
Engineering Spec sections: 3.2 runtime/static model separation; P0-01 Support Domain Model; Batch A P0-01A1.
Old authority: No Support identity authority existed. Runtime `region_id`, region array position, legacy Stronghold type, screen position, and lane index remain unsuitable identity inputs.
Target authority: `CardfrontSupportIds` owns the seven frozen `default_duel` identity strings; `DeploymentSupportDefinition` owns the static authored schema and structural validation.
Allowed mutation surface: New support data/schema files, focused test runner, active test workflow entry, and this checkpoint.
Read-only surface: `DefaultDuelMap`, `RegionMap`, Stronghold runtime, deployment, capture, entity movement/spawn, UI, save/runtime snapshot, and all current gameplay consumers.
Forbidden changes: Map changes, gameplay wiring, runtime Support state, deployment/capture/graph behavior, Stronghold retirement, bonuses, UI, cards, resource income, and automatic spawn migration.
Old behaviors that must survive: All current match behavior; the new classes have no production caller.
Explicitly not solving: P0-01A2 runtime truth table/state, P0-01B anchor-to-region mapping, topology resolution, suppression, capture, deployment geometry, save/restore, or legacy retirement.
Test evidence authority: `CardfrontSupportIdentityTestRunner.gd` on Godot 4.7.1 plus static forbidden-field search.
Expected checkpoint: `P0-01A1_stable_support_ids.md`

## Implemented schema

The static definition contains only authored structure:

```text
support_id
anchor_cell
is_core
authored_neighbors
route_role
player_deploy_direction
ai_deploy_direction
deployment_profile_id
capture_profile_id
suppression_profile_id
```

It deliberately contains no `region_id`, runtime state, online flag, capture progress, deployment result, or gameplay bonus. `authored_neighbors` is copied on construction so caller mutation cannot silently rewrite the definition.

The seven `default_duel` IDs are frozen exactly as approved in P0-00F. This step does not create their map definitions or infer anchors from the current region list; that remains P0-01B work.

## Forbidden field audit

The validator rejects every forbidden legacy bonus key:

```text
shot_bonus
attack_bonus
draft_choice_bonus
resource_income
rarity_bonus
```

No Support file references Factory, Energy, Lab, Stronghold bonuses, runtime numeric region IDs, or live gameplay systems.

## Freeze impact declaration

```text
Pre-Implementation Freeze reference: CARDFRONT_P0_PRE_IMPLEMENTATION_FREEZE_ADDENDUM_2026-08-08.md and P0-00F_PRE_IMPLEMENTATION_BATTLELINE_FREEZE.md
Frozen support topology affected? YES — stable node IDs and authored-neighbor schema only; no edges are instantiated or resolved.
Frozen deployment geometry affected? NO — profile and direction IDs are metadata only.
Suppression/capture contract affected? NO — profile IDs are metadata only; no state or behavior exists.
Automatic placement contract affected? NO
Deployment revision contract affected? NO
Amendment required? NO
```

## Mandatory audit fields

```text
Mandatory audit gates touched: P0-01 stable identity and second-authority prevention
Audit status per gate: PASS
Evidence bound to source commit: YES
Unverified assumptions remaining: None for A1 schema scope. Runtime state, mapping, graph, capture, deployment, and save behavior remain explicitly future steps.
Legacy authority still reachable: YES, unchanged; legacy Stronghold behavior remains the live gameplay authority until its scheduled retirement.
Second-authority risk: Controlled; support_id is authored and no region_id/type/position/lane identity fallback exists.
Save/restore risk: NOT APPLICABLE; A1 adds no runtime or saved state.
Cross-system regression evidence: New files have no production caller; focused identity runner is required. P0-00E remains the most recent structural baseline.
Manual evidence required before GO: NO; no live gameplay or visual behavior changed.
```

## Gate result

Decision: **GO**

Only allowed next step: **P0-01A2 Runtime State Truth Table**.
