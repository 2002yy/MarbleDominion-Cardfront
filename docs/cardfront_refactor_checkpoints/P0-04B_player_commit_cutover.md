# P0-04B Player Commit Cutover

Source commit: `086b9b5`
Original intent: Route frontline card Commit through the existing CardPlaySystem validator facade and current DeploymentRules state.
Engineering Spec sections: 4.4 Deployment; Guardrails P0-04B; Freeze Addendum section 6.4.
Old authority: No frontline deployment target rule existed in the card validator facade.
Target authority: `FrontlineDeploymentTargetRule` delegates current-state validation to `DeploymentRules.evaluate()` before CardPlaySystem pays or consumes.
Allowed mutation surface: New target type/rule, additive current-context provider, authority reason, focused tests/workflow, checkpoint.
Read-only surface: Existing card payment/consume/effect transaction order.
Forbidden changes: New production card, graph logic in CardPlaySystem, effect-side legality, Preview, AI, automatic spawn.
Test evidence authority: `CardfrontDeploymentPlayerCommitTestRunner.gd` on Godot 4.7.1.

## Result

No new card was added. The facade now supports a declared `frontline_deployment` target type. Commit asks the provider for current context every validation. A previously legal target that becomes offline is rejected with the current Deployment reason before payment, hand consumption, or effect execution. A currently legal target pays and resolves once.

```text
Stable IDs introduced/used: requested support_id
Runtime numeric IDs used as identity? NO
Territory capture touched? NO
Creature movement legality touched? NO
All spawn paths checked: Player Commit only; Preview/AI/automatic unchanged
Derived states persisted as authority? NO
Legacy stronghold active consumers remaining: unchanged
Save compatibility impact: NONE
Amendment required? NO
```

Decision: **GO**

Only allowed next step: **P0-04C Preview Cutover**.
