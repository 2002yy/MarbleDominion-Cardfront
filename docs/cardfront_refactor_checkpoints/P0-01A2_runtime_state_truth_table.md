# P0-01A2 Runtime State Truth Table

Source commit: `b57a6b9d3be6ff90806d01769f29e339e0421f56`
Original intent: Define the pure Support runtime truth fields and prove that Online remains derived.
Engineering Spec sections: 2.1 terminology; 3.2 runtime model; 3.3 display states; 3.4 disconnect/reconnect; Batch A P0-01A2.
Old authority: No Support runtime-state authority existed; legacy Stronghold state remains unrelated live gameplay authority.
Target authority: `DeploymentSupportState` owns Support Claim, operational flag, capture persistence, and runtime connectivity cache; methods derive Online/deployment contribution.
Allowed mutation surface: New pure state DTO, focused test, workflow enumeration, and checkpoint.
Read-only surface: Maps, RegionMap, Stronghold, GateConnectivity, DeploymentRules, capture/entity runtime, save controller, UI, AI, and gameplay consumers.
Forbidden changes: Production wiring, map changes, graph calculation, capture progression behavior, deployment behavior, Stronghold changes, UI/cards/resources.
Old behaviors that must survive: Entire current match; the DTO has no production caller.
Explicitly not solving: Region mapping, metadata validation, graph resolver, suppression/capture state machine, live save integration, or deployment.
Test evidence authority: `CardfrontSupportStateTestRunner.gd` under Godot 4.7.1.
Expected checkpoint: `P0-01A2_runtime_state_truth_table.md`

## Truth table

| Claim relative to queried side | Operational | Connected | Derived result | Deployment contribution |
|---|---:|---:|---|---:|
| own | true | true | Online | yes |
| own | true | false | CapturedOffline | no |
| own | false | any | Disabled | no |
| neutral | any | any | NotOwned | no |
| enemy | true | true for enemy | NotOwned for us / Online for enemy | no for us |

`Online` is exactly `claim_owner == side && operational && network_connected`. There is no writable `online` member and it is absent from snapshots.

## Persistence boundary

Persistent snapshot fields are `support_id`, `claim_owner`, `operational`, `capture_side`, and `capture_progress`. `network_connected` and `contested` are runtime-derived observations and are excluded. Restore ignores same-named injected data and resets both to false so future graph/occupancy owners must rebuild them before deployment can become available.

This is a DTO-level contract only. No live save owner consumes it yet.

## Freeze impact declaration

```text
Pre-Implementation Freeze reference: CARDFRONT_P0_PRE_IMPLEMENTATION_FREEZE_ADDENDUM_2026-08-08.md
Frozen support topology affected? NO
Frozen deployment geometry affected? NO
Suppression/capture contract affected? YES — state fields only; no transition behavior implemented.
Automatic placement contract affected? NO
Deployment revision contract affected? NO
Amendment required? NO
```

## Mandatory audit fields

```text
Mandatory audit gates touched: P0-01 runtime truth, derived Online, save/restore boundary
Audit status per gate: PASS
Evidence bound to source commit: YES
Unverified assumptions remaining: Live capture, graph, deployment, and save integration remain future checkpoints and are not assumed working.
Legacy authority still reachable: YES, unchanged.
Second-authority risk: Controlled; Online is derived and serialized connectivity cannot override future graph truth.
Save/restore risk: Bounded at DTO level; live integration remains unimplemented and unclaimed.
Cross-system regression evidence: Focused pure runner; no production caller exists.
Manual evidence required before GO: NO
```

## Gate result

Decision: **GO**

Only allowed next step: **P0-01B1 Anchor to Runtime Region Mapping**.
