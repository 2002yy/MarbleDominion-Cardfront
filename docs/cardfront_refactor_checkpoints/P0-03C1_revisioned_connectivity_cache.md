# P0-03C1 Revisioned Connectivity Cache

Source commit: `d6726af`
Original intent: Cache pure Support connectivity and invalidate only on graph-relevant mutations.
Engineering Spec sections: 4.3 Support Graph; Batch A P0-03C1.
Old authority: Every resolver call recomputed traversal and exposed neutral revision `0`.
Target authority: `SupportConnectivityCache` owns revision, lazy recomputation, and per-side cached results.
Allowed mutation surface: New cache, focused test/workflow, checkpoint.
Read-only surface: Pure topology and resolver.
Forbidden changes: Frame/hover-driven invalidation, live gameplay integration, capture, deployment, map, UI behavior, save.
Test evidence authority: `CardfrontSupportConnectivityCacheTestRunner.gd` on Godot 4.7.1.

## Invalidation result

`topology_loaded`, changed Claim, and changed operational state each create exactly one logical revision increment and clear cached side results. Identical state writes are no-ops. Recompute remains lazy until the next side query. One hundred idle-frame queries and one hundred hover queries reuse the same result without increasing `recompute_count`.

```text
Stable IDs introduced/used: support_id
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

Only allowed next step: **P0-04A1 Extend Existing Deployment Query/Result Contract**.
