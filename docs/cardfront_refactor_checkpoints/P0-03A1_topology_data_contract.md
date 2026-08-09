# P0-03A1 Topology Data Contract

Source commit: `419bda7f307899b6c3e3568aad40c6caaee15e90`
Original intent: Project authored Support definitions into a deterministic graph-only data contract.
Engineering Spec sections: 4.3 Support Graph; Batch A P0-03A1.
Old authority: Default-map authored neighbor metadata existed, but no graph input contract separated topology from runtime state.
Target authority: `SupportTopologyContract.from_support_definitions()` owns the pure structural projection.
Allowed mutation surface: New pure topology projection, focused test/workflow, checkpoint.
Read-only surface: Existing authored Support definitions and stable IDs.
Forbidden changes: Capture, Claim/operational state, connectivity resolution, deployment evaluation, region mapping, maps, UI, save.
Old behaviors that must survive: All current map/runtime/gameplay behavior.
Explicitly not solving: Graph validation, connectivity traversal, revision/cache, live integration.
Test evidence authority: `CardfrontSupportTopologyContractTestRunner.gd` on Godot 4.7.1.
Expected checkpoint: `P0-03A1_topology_data_contract.md`

## Contract

The topology contains only deterministic stable nodes, per-side Core roots, normalized authored edges, route roles, deployment profile references, and per-side deployment directions. It contains no Claim, operational, capture progress, connectivity, runtime region ID, bonus, Gate openness, rarity, route tendency, or AI profile.

`default_duel` projects to seven nodes and ten normalized edges. Definition and neighbor ordering do not affect the result.

## Audit fields

```text
Stable IDs introduced/used: existing support_id and Core root IDs
Runtime numeric IDs used as identity? NO
Territory capture touched? NO
Creature movement legality touched? NO
All spawn paths checked: unchanged/read-only
Derived states persisted as authority? NO
Legacy stronghold active consumers remaining: unchanged
Save compatibility impact: NONE
Amendment required? NO
Decision evidence: focused pure projection runner
```

Decision: **GO**

Only allowed next step: **P0-03A2 Graph Validation**.
