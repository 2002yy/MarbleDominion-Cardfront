# P0-09B1 Resolver Cutover

Source commit: `d43c8d7e33ae5f2cc42956d5a79f2daed12f593b`

Decision: **GO**

Only allowed next step: **P0-09B2 — Save / Restore Contract**.

## Audit result

`CardfrontUpgradeResolver.resolve()` now has the frozen ordering:

```text
validate selected upgrade definition
apply queued Echo effect, if any
 -> effect application history only
apply selected effect
 -> on success, effect application history +1
 -> on success, Selected Level +1
```

The selected definition is validated before queued Echo is consumed. An unknown selection therefore cannot consume/replay a queued Echo, mutate application history, or increment any Selected Level.

Static production search finds exactly one call to `record_selected_upgrade_resolved()`, in `CardfrontUpgradeResolver.resolve()` after `_apply_once()` returns success. Echo replay records only through `record_effect_application()`.

No Resolver effect, Echo timing, card eligibility, numeric value, Draft cadence, save data, view projection, or UI changed in this gate.

## Evidence

- Resolver behavior and failure ordering — **PASS (36 checks)**;
- Echo Level contract — **PASS (16 checks)**;
- Level cap/rarity separation — **PASS (16 checks)**;
- upgrade content regression — **PASS (115 checks)**;
- formal three-choice runtime — **PASS (59 checks)**.

Total assertions: **242 passed** under Godot `4.7.1-stable`.

## Mandatory audit fields

```text
Mandatory audit gate touched: P0-09B1 Resolver Cutover
Audit status: PASS
Evidence bound to source commit: YES — d43c8d7e33ae5f2cc42956d5a79f2daed12f593b
Selected definition validated before Echo consumption: YES
Echo application records application history: YES
Echo application records Selected Level: NO
Successful selected effect records application history: YES
Successful selected effect records Selected Level: YES — once
Failed selection consumes queued Echo: NO
Failed selection mutates application history: NO
Failed selection increments Level: NO
Production Selected Level increment call sites: 1
Save/view/UI migration included: NO
Gameplay expanded: NO
Manual/video evidence required before GO: NO
```
