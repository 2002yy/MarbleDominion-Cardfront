# P0-09B2 Selected Level Save / Restore Contract

Source commit: `20fd895b0f6825f2578030c8f18d8329303b305d`

Decision: **GO**

Only allowed next step: **P0-09B3 — Offer / View Data Level Projection**.

## New-save contract

`CardfrontFactionRunState.snapshot()` now persists both distinct authorities:

```text
selected_upgrade_levels   # player-facing successful selection Level
applied_upgrade_counts    # effect application/history, including Echo
```

`restore()` reads both dictionaries independently. A live Echo fixture round-trips copied-card Level `1` and copied effect applications `2`, proving the saved fields do not collapse into each other.

Snapshot and restored dictionaries are detached copies. Mutating the payload cannot mutate live state, and mutating the payload after restore cannot mutate restored state.

## Legacy-save contract

When `selected_upgrade_levels` is absent, restore uses an explicit empty dictionary. It does **not** reconstruct Level from `applied_upgrade_counts`, because the old history includes Echo and cannot identify exact real selection count.

Legacy application history remains readable. The safe Level default is zero/unknown authority rather than a false precision claim.

No outer `CardfrontRuntimeSnapshot` key or schema version changes: the additive field is inside each existing `faction_run_states` payload.

## Evidence

- focused Selected Level save contract — **PASS (13 checks)**;
- resolver and failure ordering — **PASS (36 checks)**;
- Echo Level contract — **PASS (16 checks)**;
- runtime snapshot schema regression — **PASS (39 checks)**;
- upgrade content regression — **PASS (115 checks)**;
- Draft lifecycle regression — **PASS (170 checks)**;
- formal three-choice runtime — **PASS (59 checks)**.

Total assertions: **448 passed** under Godot `4.7.1-stable`.

## Mandatory audit fields

```text
Mandatory audit gate touched: P0-09B2 Save / Restore Contract
Audit status: PASS
Evidence bound to source commit: YES — 20fd895b0f6825f2578030c8f18d8329303b305d
New save persists Selected Level: YES
New save persists application history separately: YES
Echo-distinct values round-trip: YES
Legacy application history remains readable: YES
Legacy missing Level inferred from applications: NO
Legacy missing Level safe default: empty / zero
Snapshot dictionaries detached from live state: YES
Restored dictionaries detached from payload: YES
Outer runtime schema key/version changed: NO
Offer/view/UI migration included: NO
Gameplay expanded: NO
Manual/video evidence required before GO: NO
```
