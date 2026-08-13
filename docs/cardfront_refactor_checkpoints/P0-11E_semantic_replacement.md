# P0-11E Intentional Semantic Replacement Audit

Source commit: `6e4b287da4c95c9f382402a51ef45b7661dabbe7`

Godot version: `4.7.1-stable.official.a13da4feb`

Decision: **GO**

Only allowed next step: **P0-11F - Full Integration Scenario Matrix**.

## Stronghold retirement result

The production/source audit confirms:

- Factory no longer adds volley shots;
- Energy no longer adds temporary attack levels;
- Lab no longer expands Draft to four choices;
- the formal runtime remains three-choice;
- UI does not advertise the retired bonuses;
- save compatibility accepts old fields only to discard them, never to restore gameplay authority;
- Stronghold observation remains status-only (`active_types`, `active_regions`, `control_percent`) for map/status and timeout telemetry.

### RED consumer found and repaired

`Main._check_winner()` still called the removed `runtime.stronghold_system.sample_bonuses()` when a live Cardfront match timed out. Normal runner execution had not advanced the real Main loop to timeout, so the stale outer consumer survived the earlier recursive scan of `scripts/cardfront/**`.

The call is now `sample_status()`. This preserves the already-established 50/35/15 timeout composition (chamber/territory/active Stronghold status) without reviving Factory/Energy/Lab numeric rewards. The source gate now explicitly scans `scripts/Main.gd` in addition to the Cardfront subtree, so the removed API token cannot silently return at that boundary.

This is a correctness fix to an existing reachable timeout path, not a new rule or balance change.

## Snapshot and semantic evidence

Focused evidence root: `D:\CardfrontEvidence\P0-11E-timeout-fix-20260813`

| Runner | Result |
|---|---|
| Stronghold source/status reverse gate | PASS (now also scans `Main.gd`) |
| Stronghold timeout scoring | PASS |
| Cardfront mode and round combat | PASS |
| formal three-choice runtime | PASS |
| runtime and Support snapshot compatibility | PASS |
| Selected Level snapshot | PASS |
| upgrade content/resolver | PASS |
| Support-region UI language | PASS |
| P0 golden baseline reverse gate | PASS |

Twelve focused runners exited 0 with standard PASS summaries and zero fail markers, errors or warnings.

Snapshot assertions prove:

- new Support/Selected Level state round-trips;
- legacy payloads remain readable with safe defaults;
- `current_stronghold_bonuses` is ignored and not re-emitted;
- legacy Stronghold data does not infer Support state;
- `network_connected`, Online and contested truth are not trusted from serialized cache and require authoritative rebuild;
- Selected Level is independent from effect-application history.

## Mandatory audit fields

```text
Mandatory audit gate touched: P0-11E intentional semantic replacement
Audit status: PASS after repair
Evidence bound to source commit: YES - 6e4b287da4c95c9f382402a51ef45b7661dabbe7
Reachable retired consumer found: YES - Main timeout path
Consumer repaired: YES - status telemetry replaces removed reward API
Stronghold numeric reward authority reachable: NO
Formal Draft choice count: 3
Legacy save reward field re-emitted: NO
Legacy reward data inferred into Support: NO
Derived connectivity trusted from save: NO
Selected Level/effect history conflated: NO
Focused runners: 12/12 PASS
Full final-RC rerun required after all P0-11 repairs: YES
```
