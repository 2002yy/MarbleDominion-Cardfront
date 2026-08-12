# P0-07B4 Timeout-in-Preview Regression

Source commit: `02beda3c515243340f41c7c559655fea5e726c95`

Decision: **GO**

Only allowed next step: **P0-07B5 — Setup / Signal Lifecycle**.

## Result

The real formal runtime now completes the required chain:

```text
open Draft
 -> enter read-only preview
 -> real timer expires
 -> fallback locks from current Offer
 -> reveal forces DRAFT_VISIBLE
 -> both results are visible
 -> volley launches
 -> preview state resets
 -> next Draft opens with three visible cards
```

`choices_revealed`, `volley_launched`, and `director_stopped` now route reset behavior through the single display-state authority. No timeout, fallback, resolution, volley, or Offer implementation was replaced.

## Evidence

- `CardfrontDraftLifecycleSnapshotTestRunner.gd` — **PASS (170 checks)**.
- `CardfrontDraftGeometrySnapshotTestRunner.gd` — **PASS (84 checks)**.
- `CardfrontThreeChoiceRuntimeTestRunner.gd` — **PASS (58 checks)**.
- `CardfrontRoundCombatTestRunner.gd` — **PASS (19 checks)**.
- `CardfrontModeSmokeTestRunner.gd` — **PASS (38 checks)**.

Total P0-07 focused assertions: **369 passed**.

## Mandatory audit fields

```text
Timeout fallback still comes from visible Offer: YES
Reveal returns to DRAFT_VISIBLE: YES
Both results visible: YES
Volley launches: YES
World resumes: YES
Next Draft opens normally: YES
Preview state leaks across lifecycle: NO
Offer/timing/gameplay rules changed: NO
Decision: GO
```
