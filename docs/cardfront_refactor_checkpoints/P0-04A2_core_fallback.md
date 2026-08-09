# P0-04A2 Core Fallback

Source commit: `156b2c7`
Original intent: Guarantee legal deployment survives when every non-Core Support is offline.
Engineering Spec sections: 4.4 Deployment; Freeze Addendum section 2.6; Batch A P0-04A2.
Old authority: Existing spawn zones existed but were not exposed through the Support-network Deployment rule.
Target authority: `DeploymentSupportContext.core_only()` projects authored spawn zones; `DeploymentRules` performs final evaluation.
Allowed mutation surface: Core-only immutable context, Support-network Core evaluation, focused tests/workflow, checkpoint.
Read-only surface: `default_duel.spawn_zones` and existing owned-cell legality.
Forbidden changes: New Core circle, Support geometry, consumers, AI placement, preview, automatic spawn, map, movement, capture.
Test evidence authority: `CardfrontDeploymentCoreFallbackTestRunner.gd` plus existing DeploymentRules regression on Godot 4.7.1.

## Result

With `support_sources=[]`, player and AI each retain legal cells from their existing authored faction spawn zone. Results identify stable `core_player`/`core_ai` and `source_kind=core`. Candidate geometry alone is insufficient: the existing owned-cell rule remains required. Missing or side-mismatched context fails closed.

```text
Stable IDs introduced/used: core_player/core_ai
Runtime numeric IDs used as identity? NO
Territory capture touched? NO
Creature movement legality touched? NO
All spawn paths checked: pure authority only; consumers unchanged
Derived states persisted as authority? NO
Legacy stronghold active consumers remaining: unchanged
Save compatibility impact: NONE
Amendment required? NO
```

Decision: **GO**

Only allowed next step: **P0-04A3 Directional Support Zone**.
