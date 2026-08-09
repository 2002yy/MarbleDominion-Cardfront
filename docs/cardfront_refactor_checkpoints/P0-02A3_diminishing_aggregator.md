# P0-02A3 Diminishing Aggregator

Source commit: `6ea509c`
Original intent: Resolve same-side eligible Support capture contributors with explicit diminishing returns.
Engineering Spec sections: 4.2 capture aggregation; Batch A P0-02A3.
Old authority: No Support capture aggregation authority existed.
Target authority: `SupportCaptureAggregator` owns pure aggregation; `SupportCaptureTuning` owns all Yellow coefficients.
Allowed mutation surface: New pure tuning/aggregator, focused test/workflow, checkpoint.
Read-only surface: SceneTree, entity registry, support runtime state, territory capture, movement, deployment, UI.
Forbidden changes: Runtime occupancy reads, projectile/territory interception, combat-derived weights, gameplay integration.
Old behaviors that must survive: All existing territory capture, Creature movement/combat, spawn, and Stronghold behavior.
Explicitly not solving: Capture transitions, contributor extraction, occupancy, balancing acceptance.
Test evidence authority: `CardfrontSupportCaptureAggregatorTestRunner.gd` on Godot 4.7.1.
Expected checkpoint: `P0-02A3_diminishing_aggregator.md`

## Contract

Positive eligible weights are sorted descending for deterministic resolution. The first contributor receives full weight, the second receives 0.60, and third-plus multipliers begin at 0.25 and decay geometrically by 0.50. Resolved power has a hard cap of 3.00. All coefficients live in one Yellow-tuning class.

The result exposes `raw_weight`, `resolved_capture_power`, `contributor_count`, and `capped_or_diminished`. Zero-weight and ineligible entries contribute nothing.

## Freeze and audit fields

```text
Pre-Implementation Freeze reference: CARDFRONT_P0_PRE_IMPLEMENTATION_FREEZE_ADDENDUM_2026-08-08.md
Frozen support topology affected? NO
Frozen deployment geometry affected? NO
Suppression/capture contract affected? YES - pure diminishing aggregation only.
Automatic placement contract affected? NO
Deployment revision contract affected? NO
Amendment required? NO
Mandatory audit gates touched: P0-02 diminishing and bounded capture power
Audit status per gate: PASS
Evidence bound to source commit: YES
Unverified assumptions remaining: Yellow coefficients require later human balance acceptance.
Legacy authority still reachable: YES, unchanged.
Second-authority risk: NO; coefficients are centralized.
Save/restore risk: NOT APPLICABLE
Cross-system regression evidence: Focused pure runner; no production caller.
Manual evidence required before GO: NO for the pure contract; balance remains Yellow.
Test evidence authority: scripts/tests/CardfrontSupportCaptureAggregatorTestRunner.gd
Stable IDs introduced/used: NONE
Runtime numeric IDs used as identity? NO
Territory capture touched? NO
Creature movement legality touched? NO
All spawn paths checked: unchanged/read-only
Derived states persisted as authority? NO
Legacy stronghold active consumers remaining: unchanged
Save compatibility impact: NONE
```

Decision: **GO**

Only allowed next step: **P0-02B1 Support Capture State Machine**.
