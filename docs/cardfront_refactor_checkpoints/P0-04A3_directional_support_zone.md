# P0-04A3 Directional Support Zone

Source commit: `5648abe`
Original intent: Implement the single frozen P0 normal Support deployment geometry and deterministic overlap resolution.
Engineering Spec sections: 4.4 Deployment; Freeze Addendum sections 2.1-2.7; Batch A P0-04A3.
Old authority: Online Support sources had no candidate geometry.
Target authority: `DeploymentGeometry` owns centralized dimensions/classification; `DeploymentSupportContext` projects authored Online sources; `DeploymentRules` owns final legality/source resolution.
Allowed mutation surface: Pure geometry/context/evaluation, focused tests/workflow, checkpoint.
Read-only surface: Authored anchors, directions, profiles, Core spawn zones, owned-cell rule.
Forbidden changes: Dynamic direction, circles/cones, consumers, AI, preview, automatic spawn, map, movement, capture.
Test evidence authority: `CardfrontDeploymentDirectionalZoneTestRunner.gd` plus prior Deployment runners on Godot 4.7.1.

## Result

Only `directional_rear_rect_v1` is implemented. Dimensions use the frozen min-axis formula (40-series: half-width 3/depth 4; 50x50: 4/5). Player rear is south of the anchor and AI rear is north; the forward first cell is rejected. Support zones form a union. Overlaps resolve by squared anchor distance, then lexical stable `support_id`. Geometry still requires the existing owned-cell legality, and Online Supports do not remove Core fallback.

```text
Stable IDs introduced/used: authored/resolved support_id
Runtime numeric IDs used as identity? NO
Territory capture touched? NO
Creature movement legality touched? NO
All spawn paths checked: pure authority ready; consumers unchanged
Derived states persisted as authority? NO
Legacy stronghold active consumers remaining: unchanged
Save compatibility impact: NONE
Amendment required? NO
```

Decision: **GO**

Only allowed next step: **P0-04B Player Commit Cutover**.
