# P0-03B2 Connectivity Truth Fixtures

Source commit: `c9b825e`
Original intent: Freeze the eight required Support connectivity truths against the pure resolver.
Engineering Spec sections: 4.3 Support Graph; Batch A P0-03B2.
Old authority: Resolver mechanics existed without the complete frozen scenario matrix.
Target authority: `CardfrontSupportConnectivityTruthTestRunner.gd` is the deterministic truth fixture authority.
Allowed mutation surface: Focused fixtures, workflow, checkpoint.
Read-only surface: Authored topology and pure resolver.
Forbidden changes: Resolver exceptions, runtime cache, capture, deployment, map, UI, save.
Test evidence authority: `CardfrontSupportConnectivityTruthTestRunner.gd` on Godot 4.7.1.

## Frozen truths

The runner verifies: Core only; Core-to-main online; Core-to-branch online; main upstream disabled; branch survival; isolated backline Claim offline; upstream reconnect restores connectivity without recapture; opponent Claim excluded from traversal.

```text
Stable IDs introduced/used: all default_duel support_id fixtures
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

Only allowed next step: **P0-03C1 Revisioned Connectivity Cache**.
