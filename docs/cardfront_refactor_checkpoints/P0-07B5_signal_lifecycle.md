# P0-07B5 Setup and Signal Lifecycle

Source commit: `02beda3c515243340f41c7c559655fea5e726c95`

Decision: **GO**

Only allowed next step: **P0-08A1 — Freeze Current Draw Semantics**.

## Production lifecycle finding

The formal path is singular:

```text
Main._create_ui()
 -> CardfrontMode.create_three_choice_panel()
 -> instantiate panel
 -> add to UI layer
 -> panel.setup(round_director, view_size)
```

No production caller reuses a panel with a different director. Therefore the frozen instruction says to keep the implementation simple and not add speculative disconnect-old/connect-new signal architecture.

The existing `is_connected()` guard remains. Real runtime evidence confirms exactly one `CardfrontThreeChoicePanel` connection for each of its eight director signals, including after repeated same-director setup and desktop/narrow/desktop resizing. Other runtime systems legitimately consume `draft_opened`, `volley_launched`, and `director_stopped`; total director connection count is not incorrectly treated as panel connection count.

## Evidence

P0-07 and adjacent cross-system regression on Godot `4.7.1.stable.official.a13da4feb`:

- Draft lifecycle — PASS (170)
- Draft geometry — PASS (84)
- three-choice runtime — PASS (58)
- round combat — PASS (19)
- mode smoke — PASS (38)
- live runtime boundary — PASS (34)
- Stronghold system — PASS (2377)
- gate connectivity — PASS (22)
- orthographic arena — PASS (61)

Total assertions: **2,863 passed**.

Local compatibility audio import-cache errors were printed by runtime construction, but all affected assertions passed. CI performs its normal import step; no audio/gameplay change belongs to P0-07.

## P0-07 completion audit

```text
Stable Peek chrome: PASS
Single display-state authority: PASS
ChoiceShell movement/save/restore retired: PASS
Read-only preview input contract: PASS
Timeout/reveal/volley/next-Draft regression: PASS
20 desktop + 20 narrow toggles without drift: PASS
Offer identity unchanged: PASS
Exactly one panel connection per director signal: PASS
Speculative director replacement refactor added: NO
Map/Support/gameplay changed: NO
Decision: GO
```
