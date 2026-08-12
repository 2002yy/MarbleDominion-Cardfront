# P0-07B2 Single Draft Display-State Authority

Source commit: `e39e75e96a1951f1305ac2294ba633a94b8a4b37`

Decision: **GO**

Only allowed next step: **P0-07B3 — Preview Input Contract**.

## Result

Draft presentation now has exactly two explicit display states:

```text
DRAFT_VISIBLE
BATTLEFIELD_PREVIEW
```

All PeekButton and Space toggles pass through `_set_draft_display_mode()`. That function is the single owner of preview dimmer alpha and PeekButton text.

The legacy `_peeking` boolean and `_saved_shell_position` storage are removed. Preview no longer writes `ChoiceShell.position`; the only remaining production assignment initializes the A1-frozen geometry during `setup()`.

## Geometry and lifecycle evidence

Godot: `4.7.1.stable.official.a13da4feb`

- 20 desktop toggles retain `ChoiceShell Rect2(88, 116, 944, 488)` on every transition.
- 20 narrow toggles retain `ChoiceShell Rect2(-92, 116, 944, 488)` on every transition.
- resizing desktop -> narrow -> desktop returns to both A1 golden geometries.
- Offer IDs remain unchanged through toggles and resize.
- repeated same-director setup retains exactly one panel connection for every audited director signal.
- source search finds no `_peeking`, `_saved_shell_position`, runtime `reparent()`, or preview-time `ChoiceShell.position` write.

## Deliberately deferred behavior

P0-07B2 centralizes state and removes geometry mutation only. It does not claim the complete preview contract:

- `ChoiceShell` is not hidden yet in `BATTLEFIELD_PREVIEW`;
- cards therefore remain visible/clickable until P0-07B3;
- reveal/volley/stop reset points remain unchanged until P0-07B4.

This preserves the locked sequencing and avoids mixing input/lifecycle changes into the state-authority cutover.

## Evidence

- `CardfrontDraftLifecycleSnapshotTestRunner.gd` — **PASS (154 checks)**.
- `CardfrontDraftGeometrySnapshotTestRunner.gd` — **PASS (84 checks)**.
- `CardfrontThreeChoiceRuntimeTestRunner.gd` — **PASS (58 checks)**.
- `CardfrontRoundCombatTestRunner.gd` — **PASS (19 checks)**.
- `CardfrontModeSmokeTestRunner.gd` — **PASS (38 checks)**.

Total focused assertions: **353 passed**.

## Scope and non-goals

- no Draft offer, timeout, choice, resolution, or volley change;
- no card-face or responsive-layout redesign;
- no Aim, CardSelection, battle simulation, map, Support, or gameplay change;
- no speculative director replacement architecture.

## Mandatory audit fields

```text
Mandatory audit gate touched: P0-07B2 Single Display-State Authority
Audit status: PASS
Evidence bound to source commit: YES — e39e75e96a1951f1305ac2294ba633a94b8a4b37
Highest-priority evidence used: real Godot formal runtime plus forbidden-source search
Single display-state authority: YES
Display modes limited to Draft and battlefield preview: YES
Legacy _peeking retired: YES
Legacy _saved_shell_position retired: YES
Preview-time ChoiceShell movement retired: YES
20 desktop toggles without drift: YES
20 narrow toggles without drift: YES
Resize returns to A1 geometry: YES
Offer identity unchanged: YES
Preview card input fixed: NO — P0-07B3 only
Lifecycle reset fixed: NO — P0-07B4 only
Gameplay changed: NO
Manual/video evidence required before GO: NO for state-authority gate
```
