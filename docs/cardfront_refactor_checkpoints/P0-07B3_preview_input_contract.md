# P0-07B3 Preview Input Contract

Source commit: `7fb1af8039682ea69824f066707c557c36da0204`

Decision: **GO**

Only allowed next step: **P0-07B4 — Timeout-in-Preview Regression**.

## Result

`BATTLEFIELD_PREVIEW` is now read-only:

- `ChoiceShell` is hidden;
- the shell ignores pointer input;
- visible card count is zero;
- the test selection seam rejects choice commits while preview is active;
- stable `PeekButton` and Space still return to Draft;
- returning restores the shell and normal pointer filter.

The scene tree remains paused and Direction/Aim input remains disabled. Preview does not restore CardSelection, battle simulation, or create another battlefield interaction mode.

## Evidence

- `CardfrontDraftLifecycleSnapshotTestRunner.gd` — PASS (160 checks on this stage).
- `CardfrontThreeChoiceRuntimeTestRunner.gd` — PASS (58 checks).

## Mandatory audit fields

```text
Preview cards hidden: YES
Preview card input rejected: YES
PeekButton and Space return: YES
Battle remains paused: YES
Aim restored during preview: NO
CardSelection restored during preview: NO
Gameplay changed: NO
Decision: GO
```
