# P0-11D Existing Class A/B Regression Suite

P0 RC source commit: `34ca4b518ec846b3f50e2988d288a83da74dd498`

Godot version: `4.7.1-stable.official.a13da4feb`

Decision: **GO**

Only allowed next step: **P0-11E - Intentional Semantic Replacement Audit**.

## Full active-suite result

Evidence root: `D:\CardfrontEvidence\P0-11BCD-34ca4b5-20260813`

| Authority | Cases run | Result |
|---|---:|---|
| `headless-tests.yml` (150 listed entries, 142 unique runners) | 142 | PASS |
| `b1-simulation-tests.yml` | 8 | PASS, including 20-seed deck candidates and 5,400-match audit |
| `battlefield-entity-foundation-tests.yml` | 4 | PASS |
| `shared-upgrade-ai-tests.yml` | 2 | PASS, including 5,400-match parity proxy |
| Total | 156 | PASS |

The four workflows reference **153 unique active runners**. All 156 workflow-equivalent cases exited 0 with standard PASS summaries, zero fail markers, zero script/engine errors and zero warnings. Measured runner time was 798.63 seconds, excluding fresh import and boot.

Class A/B coverage includes baseline scenes and old-mode isolation, save/continue, existing DeploymentRules, Round/Draft/Aim/Volley, Command Point and lane allocation, Gate connectivity/runtime, entity runtime boundary, target/UI interaction, map/economy and performance smoke.

## Regression-inventory gaps closed

- `EndToEndContinueMainTestRunner.gd`: clean PASS (55 checks); added to Baseline runtime so the existing full save/exit/continue path cannot silently fall out of CI.
- `CardfrontLaneAllocationTestRunner.gd`: PASS (43 checks); two test-created `CardfrontDirectionController` nodes are now explicitly freed, eliminating 4 leaked ObjectDB instances and one retained script resource. Added to the arena batch because it owns lane split and Command Point regression.
- `CardfrontCardHoverMotionTestRunner.gd`: added as recorded in P0-11C.

These are test/CI corrections only; production gameplay was not changed.

## Complete source inventory classification

The source directory contains 158 `*TestRunner.gd` files. Five are intentionally not active workflow authority:

1. `CardfrontB1HeroCandidateAuditTestRunner.gd` - historical candidate search; the current B1 finalist/product matrices are authoritative. A one-seed inventory audit passed.
2. `CardfrontB1HeroFinalistAuditTestRunner.gd` - historical finalist search; a one-seed inventory audit passed, but it is not a release gate.
3. `CardfrontHandPanelGuidanceTestRunner.gd` - targets the retired fixed-card hand and currently reaches null live `card_system`; it is not evidence for the formal three-choice loop.
4. `CardfrontTargetPreviewGuidanceTestRunner.gd` - same retired fixed-card targeting path; active three-choice/Draft Preview runners own the current contract.
5. `SettingsAndResultTestRunner.gd` - stale v2.1.9 combined runner with a removed `Main.player_settings` assumption; active SettingsPanel, result/game-flow and baseline scene runners replace its authority.

The last three are not counted as passes and were not weakened or force-fitted to the current product. Their behavior is recorded so future cleanup can archive them without mistaking inventory for active evidence.

## Mandatory audit fields

```text
Mandatory audit gate touched: P0-11D existing Class A/B regression
Audit status: PASS
Evidence bound to source commit: YES - 34ca4b518ec846b3f50e2988d288a83da74dd498
Source runner inventory: 158
Active workflow runners: 153 unique
Workflow-equivalent cases executed: 156
Cases passed: 156
Fail markers: 0
Script/engine errors: 0
Warnings: 0
Inactive inventory classified: 5/5
Existing DeploymentRules: PASS
Round/Draft/Aim/Volley: PASS
Command Point/lane allocation: PASS
Gate/entity/non-target UI/other-mode isolation: PASS
```
