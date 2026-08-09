# P0-04C Preview Cutover

Source commit: `e2f8cc3`
Original intent: Make frontline deployment Preview consume the same DeploymentRules authority as player Commit.
Engineering Spec sections: 4.4 Deployment; Guardrails P0-04C; Freeze Addendum section 6.4.
Old authority: Target preview had no Support-network target type or context/revision seam.
Target authority: `CardfrontTargetPreviewLayer` enumerates its cells exclusively through `DeploymentRules.evaluate()` using a current immutable context snapshot.
Allowed mutation surface: Preview authority provider/revision seam, target-type branch, focused parity test/workflow, checkpoint.
Read-only surface: Existing preview branches and CardPlaySystem Commit transaction.
Forbidden changes: New production card, cached preview as permission, AI, automatic/upgrade spawn, map or gameplay changes.
Test evidence authority: `CardfrontDeploymentPreviewParityTestRunner.gd` on Godot 4.7.1.

## Result

The frontline Preview branch checks every battlefield cell through DeploymentRules. The focused fixture compares all 1,600 cells against direct authority evaluation. A recorded revision is diagnostic only: after the context changes, Commit revalidates against current state and rejects the stale visual; refreshing Preview consumes the new revision and removes the offline Support cells.

```text
Stable IDs introduced/used: requested support_id
Runtime numeric IDs used as identity? NO
Territory capture touched? NO
Creature movement legality touched? NO
All spawn paths checked: Preview only; AI/automatic unchanged
Derived states persisted as authority? NO
Legacy stronghold active consumers remaining: unchanged
Save compatibility impact: NONE
Amendment required? NO
```

Decision: **GO**

Only allowed next step: **P0-04D AI Cutover**.
