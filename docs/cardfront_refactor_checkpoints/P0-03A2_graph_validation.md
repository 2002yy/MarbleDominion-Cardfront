# P0-03A2 Graph Validation

Source commit: `697b34e`
Original intent: Fail fast on structurally invalid Support graphs before connectivity resolution.
Engineering Spec sections: 4.3 Support Graph; Batch A P0-03A2.
Old authority: Map metadata validation protected `default_duel`, but the projected topology had no independent consumer-side validator.
Target authority: `SupportTopologyValidator.validate()` owns pure graph-contract validation.
Allowed mutation surface: New validator, focused test/workflow, checkpoint.
Read-only surface: Topology projection and authored default-map fixture.
Forbidden changes: Runtime state, traversal/connectivity result, cache, deployment, maps, capture, UI, save.
Explicitly not solving: Connectivity resolution and revision ownership.
Test evidence authority: `CardfrontSupportTopologyValidatorTestRunner.gd` on Godot 4.7.1.

## Validation result

Validation rejects duplicate/empty stable IDs, invalid nodes, missing or duplicate Core roots, non-Core roots, unknown/self/duplicate edges, invalid per-side cardinal directions, missing deployment profile references, and a graph without at least two distinct simple Core-to-Core paths. `default_duel` passes unchanged.

```text
Stable IDs introduced/used: existing support_id/Core roots
Runtime numeric IDs used as identity? NO
Territory capture touched? NO
Creature movement legality touched? NO
All spawn paths checked: unchanged/read-only
Derived states persisted as authority? NO
Legacy stronghold active consumers remaining: unchanged
Save compatibility impact: NONE
Amendment required? NO
```

Decision: **GO**

Only allowed next step: **P0-03B1 Pure Connectivity Resolver**.
