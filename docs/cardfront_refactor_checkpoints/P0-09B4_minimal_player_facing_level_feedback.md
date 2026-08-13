# P0-09B4 Minimal Player-Facing Level Feedback

Source commit: `6826c8310eef6a8f2fe68dcf1f2d450980700c16`

Decision: **GO**

Only allowed next step: **P0-09B5 - No Deck Inflation Test**.

## Display contract

`CardfrontUpgradeChoiceCard` reads only the detached Offer/View fields introduced by P0-09B3:

```text
current_level
next_level
```

The player-facing rarity line now distinguishes:

```text
first selection: <rarity> · 获得 Lv.1
repeat selection: <rarity> · Lv.N → Lv.N+1
```

The card does not read RunState, application history, Echo state, rarity progression, or static Manifest internals. Missing Level fields safely render as a first selection.

## Scope preservation

- Manifest descriptions and `display_stats` are unchanged.
- No Lv2/Lv3 numeric effect track was invented.
- No scene node or Draft geometry changed.
- Offer IDs, eligibility, rarity weights, side RNG, timeout selection, and gameplay effects are unchanged.
- Echo-inclusive application counts remain separate from Selected Level.

## Automated evidence

Godot `4.7.1-stable.official` focused checks against the source commit:

- Offer/View Level projection and player-facing feedback - **PASS (44 checks)**
- Formal ThreeChoice runtime - **PASS (59 checks)**
- Draft lifecycle snapshot - **PASS (170 checks)**
- Draft geometry snapshot - **PASS (84 checks)**

Total: **357 passed**, 0 failed.

## Real-render evidence

The existing non-headless capture tool was run from a detached worktree bound to the source commit after a clean Godot 4.7.1 import.

- `40x50`, `1120x720`, `default_duel`: Level text readable; no overlap or clipping.
- `40x50`, `760x540`, `default_duel`: three-card layout and Level text remain readable; no overlap or clipping.
- Both capture runs exited 0 with no visible engine error/warning lines.

Evidence directory outside the repository:

```text
D:\CardfrontEvidence\P0-09B4-6826c83-20260813-190253
```

## Mandatory audit fields

```text
Mandatory audit gate touched: P0-09B4 player-facing Selected Level feedback
Audit status: PASS
Evidence bound to source commit: YES - 6826c8310eef6a8f2fe68dcf1f2d450980700c16
Level source: detached Offer/View current_level and next_level only
RunState or gameplay authority read by ChoiceCard: NO
Application/Echo history read by ChoiceCard: NO
Manifest mutated: NO
Effect descriptions or numeric tracks changed: NO
Offer/RNG/eligibility/rarity behavior changed: NO
Scene geometry changed: NO
Desktop real-render evidence: PASS
Narrow real-render evidence: PASS
P1 route/reroll/deep-card content included: NO
Manual evidence remaining before GO: NO
```

