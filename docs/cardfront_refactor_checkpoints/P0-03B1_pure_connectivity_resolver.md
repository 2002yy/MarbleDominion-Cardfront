# P0-03B1 Pure Connectivity Resolver

Source commit: `7d590f3`
Original intent: Resolve side-specific Support connectivity from validated topology and explicit Claim/operational truth.
Engineering Spec sections: 4.3 Support Graph; Batch A P0-03B1.
Old authority: No Support graph traversal existed.
Target authority: `SupportConnectivityResolver.resolve()` owns pure Core-root traversal.
Allowed mutation surface: New pure resolver, focused test/workflow, checkpoint.
Read-only surface: Validated topology contract.
Forbidden changes: Runtime cache/invalidation, capture, territory share, Gate openness, card rarity, AI profile, deployment, UI, save.
Explicitly not solving: Full eight-case truth matrix and revisioned runtime cache.
Test evidence authority: `CardfrontSupportConnectivityResolverTestRunner.gd` on Godot 4.7.1.

## Result contract

The resolver returns `connected_support_ids`, `unconnected_claimed_support_ids`, optional deterministic `reachable_parent`, validation errors, and neutral revision `0` until the future cache owns revisions. Traversal requires every visited node to be both claimed by the requested side and operational. Opponent Claims never bridge traversal. Invalid topology fails closed.

```text
Stable IDs introduced/used: support_id/Core root
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

Only allowed next step: **P0-03B2 Connectivity Truth Fixtures**.
