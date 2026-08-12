# P0-07A1 Draft Geometry Golden Snapshot

Source commit: `e560503295864dddedc6440f5aa61770055437d9`

Decision: **GO**

Only allowed next step: **P0-07A2 — Lifecycle Event Matrix**.

## Scope

This checkpoint freezes the existing formal Draft geometry before any preview visibility fix. It adds a headless golden-snapshot runner and registers it in the existing three-choice CI batch.

No production scene, layout, visibility, input, Draft offer, timeout, or gameplay code changed.

## Runtime geometry snapshot

Godot: `4.7.1.stable.official.a13da4feb`

The fixture opens a real `CardfrontThreeChoicePanel`, binds a signal-compatible director, emits a real three-definition offer, and waits for container layout before reading rectangles.

### Default desktop — 1120 x 720

| Item | Rect / value |
|---|---|
| viewport | `Rect2(0, 0, 1120, 720)` |
| `DraftRoot` | `Rect2(0, 0, 1120, 720)` |
| `DraftRoot` anchors | `(0, 0, 0, 0)` |
| `DraftRoot` offsets | `(0, 0, 1120, 720)` |
| `ChoiceShell` | `Rect2(88, 116, 944, 488)` |
| `ChoiceShell` anchors | `(0, 0, 0, 0)` |
| `ChoiceShell` offsets | `(88, 116, 1032, 604)` |
| `CardBox` | `Rect2(18, 124, 908, 266)` relative to `ChoiceShell` |
| `CardBox` anchors / offsets | `(0, 0, 0, 0)` / `(18, 124, 926, 390)` |
| cards | IDs below; rects `Rect2(14, 0, 280, 266)`, `Rect2(314, 0, 280, 266)`, `Rect2(614, 0, 280, 266)` relative to `CardBox` |
| `PeekButton` | parent `DraftRoot/ChoiceShell`; `Rect2(812, 8, 120, 32)` |
| `Dimmer` | `Rect2(0, 0, 1120, 720)`; anchors `(0, 0, 0, 0)`; offsets `(0, 0, 1120, 720)` |

### Narrow landscape — 760 x 540

| Item | Rect / value |
|---|---|
| viewport | `Rect2(0, 0, 760, 540)` |
| `DraftRoot` | `Rect2(0, 0, 760, 540)` |
| `DraftRoot` anchors / offsets | `(0, 0, 0, 0)` / `(0, 0, 760, 540)` |
| `ChoiceShell` | `Rect2(-92, 116, 944, 488)` |
| `ChoiceShell` anchors / offsets | `(0, 0, 0, 0)` / `(-92, 116, 852, 604)` |
| `CardBox` | unchanged local rect `Rect2(18, 124, 908, 266)` |
| cards | unchanged local rects and IDs |
| `PeekButton` | unchanged parent and local rect `Rect2(812, 8, 120, 32)` |
| `Dimmer` | `Rect2(0, 0, 760, 540)` |

The negative narrow-screen `ChoiceShell.x` and bottom edge at `604` are existing baseline behavior. P0-07A1 records them; it does not silently redesign or correct responsive layout.

## Frozen card identities

The deterministic fixture uses these three real definitions in this exact order:

1. `volley_plus_5`
2. `attack_level_plus_1`
3. `frontline_repair`

The snapshot verifies both stable IDs and the three explicit 280-pixel card columns.

## Signal connection snapshot

Calling `setup()` twice with the same director leaves exactly one panel connection on each audited signal:

- `countdown_updated`
- `draft_opened`
- `draft_time_updated`
- `strongholds_sampled`
- `choice_locked`
- `choices_revealed`
- `volley_launched`
- `director_stopped`

This confirms the current same-director production lifecycle has no duplicate connection. Whether a different director may replace the first one remains an A2 lifecycle question; A1 does not refactor signal ownership without evidence.

## Existing bug facts retained for P0-07B

- `PeekButton` is dynamically created as a `ChoiceShell` child.
- `_toggle_peek()` stores `_saved_shell_position` and moves `ChoiceShell.position` at runtime.
- `_reset_peek_state()` does not itself restore `ChoiceShell.position`.
- P0-07A1 does not change any of these facts.

## Evidence

- `CardfrontDraftGeometrySnapshotTestRunner.gd` — **PASS (78 checks)**.
- `CardfrontThreeChoiceRuntimeTestRunner.gd` — **PASS (58 checks)**.
- `CardfrontRoundCombatTestRunner.gd` — **PASS (19 checks)**.
- `CardfrontModeSmokeTestRunner.gd` — **PASS (38 checks)**.

Total focused assertions: **193 passed**.

## Mandatory audit fields

```text
Mandatory audit gate touched: P0-07 Draft Preview Bug — pre-fix geometry freeze
Audit status: PASS
Evidence bound to source commit: YES — e560503295864dddedc6440f5aa61770055437d9
Highest-priority evidence used: real Godot 4.7.1 headless scene/container layout
Default desktop captured: YES — 1120x720
Narrow viewport captured: YES — 760x540
DraftRoot / ChoiceShell / CardBox / card / PeekButton / Dimmer rects captured: YES
Anchors and offsets captured: YES
Three card IDs captured: YES
Director connection counts captured: YES
Existing narrow overflow treated as fixed: NO — recorded only
Preview visibility behavior changed: NO
ChoiceShell movement changed: NO
Draft offer or timeout behavior changed: NO
Gameplay changed: NO
Manual/video evidence required before GO: NO for geometry-freeze gate
```
