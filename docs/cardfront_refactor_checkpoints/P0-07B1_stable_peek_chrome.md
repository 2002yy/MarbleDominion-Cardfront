# P0-07B1 Stable Peek Chrome

Source commit: `c76c34cfebe30c7663b54c4862990fd14bc849a6`

Decision: **GO**

Only allowed next step: **P0-07B2 — Single Display-State Authority**.

## Result

`PeekButton` is no longer created at runtime under `ChoiceShell`. The scene now owns a stable sibling hierarchy:

```text
DraftRoot
  Dimmer
  ChoiceShell
  PeekChrome
    PeekButton
```

`PeekChrome` covers the current Draft viewport and ignores empty-space mouse input. Its button remains a normal stopping control. The button signal is configured once by the panel and guarded against duplicate connections.

The button continues to align with the top-right of the golden `ChoiceShell` on desktop. At the audited narrow viewport, only the chrome is clamped inside the right viewport edge; the pre-existing 944-pixel Draft card shell remains unchanged and is not treated as a responsive-layout redesign.

## Runtime evidence

Godot: `4.7.1.stable.official.a13da4feb`

Stable chrome geometry:

- desktop `1120x720`: `PeekButton Rect2(900, 124, 120, 32)`;
- narrow `760x540`: `PeekButton Rect2(632, 124, 120, 32)`, leaving an 8-pixel right margin;
- parent path in both cases: `DraftRoot/PeekChrome`;
- moving `ChoiceShell` through the current pre-B2 preview behavior does not move the button's global rect.

The production runtime still uses the old `_saved_shell_position` / `ChoiceShell.position` preview mechanism. B1 intentionally leaves that defect visible for the next locked step rather than combining B2 state-authority work into the hierarchy change.

## Evidence

- `CardfrontDraftGeometrySnapshotTestRunner.gd` — **PASS (84 checks)**.
- `CardfrontDraftLifecycleSnapshotTestRunner.gd` — **PASS (58 checks)**.
- `CardfrontThreeChoiceRuntimeTestRunner.gd` — **PASS (58 checks)**.
- `CardfrontRoundCombatTestRunner.gd` — **PASS (19 checks)**.
- `CardfrontModeSmokeTestRunner.gd` — **PASS (38 checks)**.
- `CardfrontLiveRuntimeBoundaryTestRunner.gd` — **PASS (34 checks)**; local compatibility audio import-cache errors remain unrelated to this UI hierarchy change.

Total focused assertions: **291 passed**.

## Scope and non-goals

- no runtime `reparent()`;
- no root anchors or offsets changed during preview;
- no battle-HUD ownership introduced;
- no card-face or Draft layout redesign;
- no preview display-state authority added yet;
- no input, timeout, Offer, resolution, volley, map, Support, or gameplay behavior changed.

## Mandatory audit fields

```text
Mandatory audit gate touched: P0-07B1 Stable Peek Chrome
Audit status: PASS
Evidence bound to source commit: YES — c76c34cfebe30c7663b54c4862990fd14bc849a6
Highest-priority evidence used: real Godot scene hierarchy and formal runtime lifecycle
PeekButton stable sibling: YES
Runtime reparent used: NO
Chrome remains visible while ChoiceShell moves: YES
Desktop geometry retained: YES
Narrow chrome kept inside viewport: YES
Legacy ChoiceShell movement retired: NO — P0-07B2 only
Preview card input changed: NO — P0-07B3 only
Gameplay changed: NO
Manual/video evidence required before GO: NO for hierarchy-only gate
```
