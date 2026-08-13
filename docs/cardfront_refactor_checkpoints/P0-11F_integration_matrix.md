# P0-11F Full Integration Scenario Matrix

Source commit: `76fdfd31dab4cd69653e9030c08213a324fa766c`

Godot version: `4.7.1-stable.official.a13da4feb`

Decision: **GO**

Only allowed next step: **P0-11G - Metamorphic / Invariance Suite**.

Evidence root: `D:\CardfrontEvidence\P0-11F-14b3ef7-20260813`

Twenty deterministic runners exited 0 with PASS summaries. Their combined runner reports contain **749 checks**, with zero fail markers, parser/runtime errors or warnings.

## F1-F10 matrix

| Scenario | Executable evidence | Result |
|---|---|---|
| F1 Core -> rear -> front, capture/connect/directional deploy, units survive | `CardfrontSupportCaptureTerritoryPrototypeTestRunner`, `CardfrontSupportMapMetadataTestRunner`, `CardfrontDeploymentDirectionalZoneTestRunner` | PASS |
| F2 CapturedOffline, denied deploy, Offline projection, reconnect | `CardfrontSupportStateTestRunner`, `CardfrontSupportPresentationLifecycleTestRunner`, `CardfrontSupportMapMetadataTestRunner`, `CardfrontDeploymentFourConsumerParityTestRunner` | PASS |
| F3 one route severed, branch survives, Gate remains projectile authority | `CardfrontSupportMapMetadataTestRunner`, `CardfrontRouteSemanticsTestRunner`, `CardfrontGateConnectivityTestRunner` | PASS |
| F4 both routes severed, Claims/units survive, Core fallback and rebuild | `CardfrontSupportMapMetadataTestRunner`, `CardfrontDeploymentCoreFallbackTestRunner`, `CardfrontDeploymentAutomaticSpawnTestRunner` | PASS |
| F5 strong unit cannot finish takeover alone | `CardfrontSupportCaptureTerritoryPrototypeTestRunner` uses explicit `SiegePlatform_Test`: 999 fixture suppression pressure, zero capture power; a cheap Scout contributes 2.0 and completes the Claim; the strong entity remains registered | PASS |
| F6 Preview timeout full closure | `CardfrontDraftLifecycleSnapshotTestRunner`: open -> preview -> timeout fallback from visible Offer -> reveal -> volley -> next three-choice Draft | PASS |
| F7 Offer/RNG independence | `CardfrontDraftSideRngIsolationTestRunner`, `CardfrontDraftOfferIndependenceTestRunner` | PASS |
| F8 Echo versus Selected Level | `CardfrontEchoLevelContractTestRunner`, `CardfrontSelectedLevelSnapshotTestRunner` | PASS |
| F9 AI secret isolation | `CardfrontAiObservationBoundaryTestRunner`, `CardfrontAiObservationProjectionTestRunner`, `CardfrontAiCommanderObservationTestRunner` | PASS |
| F10 mid-state snapshot/restore | `CardfrontSupportSnapshotContractTestRunner`, `CardfrontSelectedLevelSnapshotTestRunner`, `CardfrontRuntimeSnapshotTestRunner`: Capturing fields, CapturedOffline inputs, Levels, formal phase/Offer payload and graph rehydration | PASS |

The map has two symmetric authored physical routes rather than a privileged hidden "main" edge. F3 therefore runs the same sever/survive matrix from both faction roots and both physical routes; no undocumented main-route priority was invented for the test.

## Gap closed without gameplay expansion

The frozen `SiegePlatform_Test` fixture did not exist. The prior zero-control check used `gate_colossus` and proved only a generic profile result. The test now carries explicit overwhelming suppression metadata while still entering the real registry and centralized capture adapter. This is test evidence only: no production creature/card, damage value, capture profile or map content was added.

Save evidence was also extended to prove that restored `claim/operational` state is fed back through the real static topology authority. Serialized `network_connected` is not trusted.

## Mandatory audit fields

```text
Mandatory audit gate touched: P0-11F deterministic integration
Evidence bound to source commit: YES
Random long match substituted for deterministic scenarios: NO
F1-F10 unchecked rows: 0
Production gameplay added for fixtures: NO
Focused runners: 20/20 PASS
Errors/warnings: 0/0
Final full-RC rerun still required: YES
```
