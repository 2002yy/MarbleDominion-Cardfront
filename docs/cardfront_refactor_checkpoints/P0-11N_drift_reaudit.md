# P0-11N Drift Re-Audit Against Frozen Spec

P0 RC source commit: `def95b5dd575aee85a132870ba350e51cf51ba27`

Decision: **GO for P0-11N automated drift audit**

## Frozen invariant evidence matrix

| Invariant | Status | Evidence |
|---|---|---|
| Support replaces numeric bonus nodes | PASS | `Main._on_strongholds_sampled()` consumes status/timeout telemetry only; `CardfrontStrongholdSystemTestRunner`, `CardfrontStrongholdTimeoutScoringTestRunner`, source scan, and tactical Stronghold CI batch pass. No `sample_bonuses()` live call remains. |
| SupportGraph and GateConnectivity remain separate | PASS | `CardfrontSupportConnectivity*` runners own Support topology; `CardfrontGateConnectivityTestRunner` and `CardfrontGateRuntimeTestRunner` pass independently. |
| Support capture is not projectile territory capture | PASS | `CardfrontSupportCaptureRuntime` is built as the separate `support_capture` runtime stage. `CardfrontCaptureInterceptor` remains the territory/projectile defense seam. Live capture and fortify/projectile runners pass together. |
| One deployment legality authority | PASS | `DeploymentRules.evaluate()` is consumed by Preview, Commit, AI, and automatic placement. `CardfrontDeploymentFourConsumerParityTestRunner` and stale-preview/current-commit tests pass. |
| Auto/upgrade spawn has no old route-slot fallback | PASS | `CardfrontAutomaticSpawnCoordinator` uses `DeploymentPlacementResolver` and the current Support context; no-legal-cell negative tests and four-consumer parity pass. |
| Offer isolation does not implement P1 deck features | PASS | side RNG/offer independence, exactly-three Draft, and no-deck-inflation runners pass; no reroll or route-unlock feature was added. |
| Selected Level is not polluted by Echo | PASS | Echo Level contract, semantic separation, Selected Level snapshot, Offer projection, and no-deck-inflation runners pass. |
| AI has no hidden Object escape hatch | PASS | AIObservation whitelist/projection/Commander runners and 5400 parity proxy CI pass; Commander receives detached Observation rather than full GameState/RunState/Node. |
| UI remains a projection | PASS | Support visual consumes detached dictionaries and has no collision/runtime authority; Draft Preview remains paused and geometry-stable; visual/non-authority metamorphic tests pass. |
| Draft/Aim/Volley/Command Point survive | PASS | golden baseline, ThreeChoice runtime, RoundCombat, Mode smoke, control-chamber decoupling, and full active regression pass. |
| `runtime region_id` is not stable Support identity | PASS | authored `support_id` keys topology, state, save, and visuals. `DeploymentSupportRegionMapper` is an explicit mapping adapter only; identity/mapper tests pass. |
| Creature movement is not broadened | PASS | movement still validates owned-territory traversal; entity/runtime boundary tests pass. P0 introduced no neutral/enemy traversal rule. |
| Snapshot stores authority, not derived connectivity | PASS | claim/operational/capture fields and Selected Level persist; connectivity, contested, Online and presentation state are rebuilt. Support and runtime snapshot tests pass. |

## Source and evidence review

- `CardfrontCaptureInterceptor` was not expanded into Support capture ownership.
- `GameRuntimeContext.support_capture_runtime` and system-registry mapping expose the new independent runtime without creating another deployment authority.
- Core claims remain immutable roots; non-Core `support_id` state drives capture/graph/deployment.
- Support presenter refreshes existing instances but cannot mutate capture, Claim, graph, territory, or deployment truth.
- 13 source-bound images at `D:\CardfrontEvidence\P0-11L-def95b5-20260813` visually cover all mandatory states.
- Local RC: 155/155, 0 log errors/warnings. CI: 42/42.

## Remaining non-automated gate

The audit cannot prove that a first-time player understands route usefulness, Core counterattack, cheap-control conversion, and CapturedOffline denial without explanation. That is the explicit P0-11K human gate, not an implementation drift finding.

Mandatory audit gates touched: all ten Batch C drift questions plus stable identity, movement, and save authority

Audit status per gate: **PASS for automated/source audit; K remains BLOCKED separately**

Evidence bound to source commit: **YES**

Unverified assumptions remaining: human comprehensibility and live pacing only.

Legacy authority still reachable: no known formal-live gameplay producer/consumer; historical compatibility files and text remain non-authoritative.

Second-authority risk: no duplicate deployment, capture, graph, or UI authority found.

Save/restore risk: no derived-state persistence found.

Cross-system regression evidence: P0-11M local/CI suite and P0-11L visual pack.

Manual evidence required before final GO: **YES**

Only allowed next step: create P0-11O with Final decision NO-GO until P0-11K is independently accepted.
