# P0-04D AI Cutover

Source commit: `c12d374`
Original intent: Require AI deployment validation and candidate filtering to use the same authority as player Commit and Preview.
Engineering Spec sections: 4.4 Deployment; Guardrails P0-04D; Execution Detail P0-04B/C/D.
Old authority: The existing AI commander chooses Draft upgrades; there was no AI frontline-placement consumer seam.
Target authority: `CardfrontAiDeploymentPlanner` evaluates and filters candidates only through `DeploymentRules.evaluate()` with the same owner/context/cell inputs used by the target validator.
Allowed mutation surface: Dedicated AI deployment consumer adapter, shared allowed-reason exposure, focused parity test/workflow, checkpoint.
Read-only surface: Existing Draft AI commander, spawn coordinator, maps, movement and production card catalog.
Forbidden changes: AI legality exception, direct AI spawn, automatic/upgrade spawn integration, ranking gameplay, map or movement changes.
Test evidence authority: `CardfrontDeploymentAiParityTestRunner.gd` on Godot 4.7.1.

## Result

The AI adapter contains no geometry or ownership legality. It obtains one immutable context snapshot, delegates each candidate to DeploymentRules, and exposes only legal cells to later ranking. The parity fixture compares validity and authority reason for all 1,600 cells against the generic card target validator with the same AI owner/context/cell. Offline Support produces the same explicit denial and no candidate reaches ranking.

There is no existing AI frontline-card placement call site to replace: `CardfrontAiCommander` currently selects Draft upgrades. This step establishes the required AI consumer boundary without entering P0-04E's automatic/upgrade spawn path.

```text
Stable IDs introduced/used: requested support_id
Runtime numeric IDs used as identity? NO
Territory capture touched? NO
Creature movement legality touched? NO
All spawn paths checked: AI candidate validation only; automatic/upgrade unchanged
Derived states persisted as authority? NO
Legacy stronghold active consumers remaining: unchanged
Save compatibility impact: NONE
Amendment required? NO
```

Decision: **GO**

Only allowed next step: **P0-04E Automatic Spawn Path**.
