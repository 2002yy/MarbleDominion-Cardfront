# P0-04A1 Deployment Query/Result Contract

Source commit: `badb8da`
Original intent: Extend the existing authoritative Deployment seam for Core/Support network evaluation without replacing legacy rules.
Engineering Spec sections: 4.4 Deployment; Batch A P0-04A1.
Old authority: Query/result exposed owner, cell, region rule and percentage only.
Target authority: Existing `DeploymentQuery`, `DeploymentResult`, `DeploymentRuleType`, and `DeploymentRules` remain the single seam with additive Support fields/reasons.
Allowed mutation surface: Additive contract fields/constants, fail-closed unconfigured rule, focused tests/workflow, checkpoint.
Read-only surface: Existing legacy rule evaluation.
Forbidden changes: Geometry, Core candidates, consumer integration, AI, preview, automatic spawn, map, movement, capture.
Explicitly not solving: Core fallback and directional Support zones.
Test evidence authority: `CardfrontDeploymentContractTestRunner.gd` plus existing `DeploymentRulesTestRunner.gd` on Godot 4.7.1.

## Contract result

Query adds optional stable `requested_support_id`, `spawn_profile_id`, and immutable `support_network_context`. Result adds `resolved_support_id`, `source_kind` (`core`/`support`), and deterministic `debug_explanation`. New denial reasons are centralized. A missing/unconfigured Support context fails closed with `no_valid_deployment_source`.

```text
Stable IDs introduced/used: requested/resolved support_id
Runtime numeric IDs used as identity? NO
Territory capture touched? NO
Creature movement legality touched? NO
All spawn paths checked: contracts only; consumers unchanged
Derived states persisted as authority? NO
Legacy stronghold active consumers remaining: unchanged
Save compatibility impact: NONE
Amendment required? NO
```

Decision: **GO**

Only allowed next step: **P0-04A2 Core Fallback**.
