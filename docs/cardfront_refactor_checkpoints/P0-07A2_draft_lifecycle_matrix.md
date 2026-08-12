# P0-07A2 Draft Lifecycle Event Matrix

Source commit: `a9e8adfdd0048c43109681a00a277e7c191bab4e`

Decision: **GO**

Only allowed next step: **P0-07B1 — Stable Peek Chrome**.

## Scope

This checkpoint records the real formal-runtime Draft preview lifecycle before changing visibility behavior. It adds an event-matrix runner to the existing three-choice CI batch.

No production Draft panel, scene hierarchy, input, timing, offer, resolution, volley, or gameplay code changed.

## Runtime event matrix

Godot: `4.7.1.stable.official.a13da4feb`

| Event | Frozen expected state | Actual pre-fix runtime | Status for P0-07B |
|---|---|---|---|
| initial battle | Draft hidden | `DraftRoot.visible=false` | PASS |
| `draft_opened` | `DRAFT_VISIBLE` | Draft visible; `_peeking=false`; button says `查看战场`; three cards shown | PASS |
| Peek click | toggle preview; battle remains paused; no Aim input | `_peeking=true`; battle paused; Aim disabled; current implementation moves `ChoiceShell` but leaves three cards visible/clickable | FIX REQUIRED |
| Space | same toggle contract | returns shell to saved position, then can enter preview again | BASELINE RECORDED |
| timer update | preserve current display mode and Offer | preview flag/position and card IDs remain unchanged | PASS |
| player choice locked | normal resolution flow | selecting a still-visible preview card enters `RESOLVE_CHOICES` | FLOW PASS; INPUT FIX REQUIRED |
| timeout while preview | fallback still locks and resolves | fallback is selected from the visible offer; reveal and launch complete | PASS |
| `choices_revealed` | force `DRAFT_VISIBLE`, display both results | result text appears, but `_peeking=true` and moved shell remain | FIX REQUIRED |
| `volley_launched` | Draft hidden and preview reset | Draft hides; `_peeking` and moved shell remain | FIX REQUIRED |
| `director_stopped` | Draft hidden and preview reset | Draft/status/toast hide; `_peeking` and moved shell remain | FIX REQUIRED |
| next `draft_opened` | begin from `DRAFT_VISIBLE` with golden geometry | `_peeking=false` and text reset, but drifted shell position survives | FIX REQUIRED |

## Timeout-in-preview evidence

The current runtime does not deadlock when the Draft timer expires during preview:

1. a real formal match opens Draft;
2. preview is entered;
3. the real phase controller consumes the full Draft timeout;
4. the player receives a fallback from the current visible offer;
5. phase advances to `RESOLVE_CHOICES`;
6. both results are rendered;
7. volley launches;
8. world pause is released and battle countdown resumes.

The timing/orchestration path is therefore healthy. P0-07B must change presentation state only and must not replace timeout or resolution logic.

## Input and simulation boundary

- Peek keeps the scene tree paused.
- Direction/Aim input stays disabled.
- Preview does not create a battlefield interaction mode.
- Current cards remain visible and can still be selected because the implementation moves the entire shell instead of hiding the content layer. P0-07B3 must close this input leak by display state, without restoring Aim or battle simulation.

## Director signal lifecycle

The live runtime has several legitimate consumers, so total signal connection count is not always one:

| Signal | Total live connections | Connections owned by `CardfrontThreeChoicePanel` |
|---|---:|---:|
| `countdown_updated` | 1 | 1 |
| `draft_opened` | 3 | 1 |
| `draft_time_updated` | 1 | 1 |
| `strongholds_sampled` | 1 | 1 |
| `choice_locked` | 1 | 1 |
| `choices_revealed` | 1 | 1 |
| `volley_launched` | 5 | 1 |
| `director_stopped` | 3 | 1 |

This corrects the interpretation of A1's isolated fixture: repeated same-director setup does not duplicate the panel connection, but the production director also serves other runtime systems. Production constructs the panel once and calls setup once. No evidence was found that a live panel changes director, so A2 does not introduce speculative disconnect/reconnect architecture.

## Required P0-07B corrections now frozen

1. move `PeekButton` to stable sibling chrome in the scene hierarchy;
2. replace `_peeking` plus `_saved_shell_position` movement with one display-state authority;
3. hide and disable Draft card content in battlefield preview while keeping Peek/Space return available;
4. force Draft-visible result state on `choices_revealed`;
5. reset preview state on `volley_launched`, `director_stopped`, and every next `draft_opened`;
6. retain timeout, resolution, world pause, Aim-disable, offer identity, and director orchestration behavior unchanged.

## Evidence

- `CardfrontDraftLifecycleSnapshotTestRunner.gd` — **PASS (57 checks)**.
- `CardfrontDraftGeometrySnapshotTestRunner.gd` — **PASS (78 checks)**.
- `CardfrontThreeChoiceRuntimeTestRunner.gd` — **PASS (58 checks)**.
- `CardfrontRoundCombatTestRunner.gd` — **PASS (19 checks)**.
- `CardfrontModeSmokeTestRunner.gd` — **PASS (38 checks)**.

Total focused assertions: **250 passed**.

## Mandatory audit fields

```text
Mandatory audit gate touched: P0-07 Draft Preview Bug — pre-fix lifecycle matrix
Audit status: PASS
Evidence bound to source commit: YES — a9e8adfdd0048c43109681a00a277e7c191bab4e
Highest-priority evidence used: real formal runtime and real Godot event processing
Draft opened state captured: YES
Peek click and Space captured: YES
Timer update captured: YES
Player choice and reveal captured: YES
Timeout while preview captured: YES
Volley and next Draft captured: YES
Director stop captured: YES
Live signal consumers distinguished from panel connections: YES
Existing lifecycle defects treated as fixed: NO — recorded for P0-07B
Production Draft behavior changed: NO
Gameplay changed: NO
Manual/video evidence required before GO: NO for lifecycle-freeze gate
```
