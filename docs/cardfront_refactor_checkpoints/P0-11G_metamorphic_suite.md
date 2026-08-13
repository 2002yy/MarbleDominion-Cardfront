# P0-11G Metamorphic / Invariance Suite

Source commit: `76fdfd31dab4cd69653e9030c08213a324fa766c`

Godot version: `4.7.1-stable.official.a13da4feb`

Decision: **GO**

Only allowed next step: **P0-11H - Save / Restore Migration Gate**.

Evidence root: `D:\CardfrontEvidence\P0-11GHIJ-76fdfd3-20260813`

| Invariant | Executable evidence | Result |
|---|---|---|
| G1 draw-order invariance | `CardfrontDraftSideRngIsolationTestRunner`: swapped order, extra opposing draw and fallback consumption leave the other trace unchanged | PASS |
| G2 hidden-data invariance | `CardfrontAiCommanderObservationTestRunner`: changed Player Offer/future Offer/seed/hidden route values produce equal AI Observation | PASS |
| G3 public-data sensitivity | same runner: approved defense and Support public fields change Observation and valuation context | PASS |
| G4 four-consumer deployment parity | `CardfrontDeploymentFourConsumerParityTestRunner`: Commit/Preview/AI/Automatic agree for Core legal, Online legal, disconnected denied and disabled denied | PASS |
| G5 visual non-authority | `CardfrontSupportPresentationLifecycleTestRunner`: scale/visibility changes leave complete authority debug snapshot unchanged | PASS |
| G6 graph non-visual invariance | `CardfrontSupportConnectivityCacheTestRunner` plus Draft lifecycle: idle/hover and 40 Preview toggles with two resizes leave graph cache/revision unchanged | PASS |
| G7 Preview geometry invariance | `CardfrontDraftLifecycleSnapshotTestRunner`: desktop/narrow anchors, offsets, Offer IDs and one connection per signal remain stable | PASS |

The visual-lifecycle audit found a projection defect: existing Support visual instances were not receiving later snapshots. It was repaired at `c99ad6819974036279ede57e82e210ce0778f057`; the same node now refreshes from Active to CapturedOffline without gaining gameplay authority.

```text
Mandatory audit gate touched: P0-11G metamorphic invariance
Evidence bound to source commit: YES
Invariance rows exercised: 7/7
Visual mutation changes authority: NO
Preview/resize changes graph revision: NO
Errors/warnings: 0/0
```
