# P0-11H Save / Restore Migration Gate

Source commit: `76fdfd31dab4cd69653e9030c08213a324fa766c`

Godot version: `4.7.1-stable.official.a13da4feb`

Decision: **GO**

Only allowed next step: **P0-11I - Performance & Recompute Evidence**.

Evidence root: `D:\CardfrontEvidence\P0-11GHIJ-76fdfd3-20260813`

## Results

- H1: Support authoritative fields and Selected Level/effect history round-trip independently. Capturing side/progress and CapturedOffline-producing claim/operational inputs persist.
- H2: partial/legacy payloads load with safe defaults; removed `current_stronghold_bonuses` is ignored and never re-emitted or inferred into Support authority.
- H3: derived `network_connected`, contested, Online and visual state are discarded. Restored claim/operational fields are applied to `CardfrontSupportDeploymentAuthority`, which rebuilds connectivity from the real default-map topology. An isolated front Claim remains offline.
- H4: the current runtime snapshot schema formally stores `match_phase` and `current_offers`; round-trip assertions cover both. It does not define an independently persisted UI Preview display mode, so restoring Preview chrome is N/A and no new save feature was added.
- Baseline save/continue regression remains green through `RestorePlanTestRunner` and `EndToEndContinueMainTestRunner` (55 checks in the real Main save/exit/continue path).

Evidence runners:

| Runner | Result |
|---|---|
| `CardfrontSupportSnapshotContractTestRunner` | PASS (26) |
| `CardfrontSelectedLevelSnapshotTestRunner` | PASS (13) |
| `CardfrontRuntimeSnapshotTestRunner` | PASS (41) |
| `RestorePlanTestRunner` | PASS (11) |
| `EndToEndContinueMainTestRunner` | PASS (55) |

```text
Mandatory audit gate touched: P0-11H save/restore migration
Evidence bound to source commit: YES
New Support/Level round-trip: PASS
Legacy payload acceptance: PASS
Retired Stronghold reward resurrected: NO
Serialized connectivity trusted: NO
Formal phase/Offer round-trip: PASS
Unsupported Preview-chrome persistence added: NO
Errors/warnings: 0/0
```
