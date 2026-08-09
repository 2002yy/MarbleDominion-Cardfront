# P0-00C Frozen Delta Ledger

Status: **COMPLETE**
Decision: **GO**

## Step contract

```text
Step: P0-00C Frozen Delta Ledger
Source commit: a9009e2c8d7e0ef7d1e94f79eee66b45bc100555
Original upstream source commit: fc56e21e0cf7ad8c79eaf9659afbda3e1f89e487
Parent checkpoint: P0-00B_baseline.md
Evidence type: static design/source reconciliation
Allowed mutation surface: docs only
Forbidden changes: gameplay, Support implementation, map mutation, opportunistic refactor, P0-01
Expected checkpoint: docs/cardfront_refactor_checkpoints/P0-00C_delta_ledger.md
```

This ledger applies the Engineering Spec, Guardrails, Batch A, Pre-Implementation Freeze Addendum, P0-00A ownership map, and the manually accepted P0-00B baseline. The commits between the original upstream source and this Source commit contain engine/tooling compatibility, warning cleanup, test determinism/teardown, import metadata, and checkpoints; they do not implement Support gameplay or change the frozen gameplay delta.

## Classification rule

- **MUST CHANGE**: existing behavior or authority that P0 is required to transform.
- **MUST PRESERVE**: existing behavior/authority that the refactor must continue to provide.
- **MUST RETIRE**: old gameplay meaning or bypass that must no longer remain authoritative after its cutover step.
- **OUT OF SCOPE**: work deliberately deferred beyond P0 or prohibited from being pulled into the current refactor.

An implementation can preserve a legacy save-reader or geometry anchor while retiring the legacy gameplay effect. That is compatibility, not two gameplay authorities.

## MUST CHANGE

| ID | Frozen delta | Current authority / problem | Intended P0 destination |
| --- | --- | --- | --- |
| MC-01 | Stable Support identity | Runtime `region_id` is allocation order and is not a stable identity | Authored stable Support IDs mapped to existing anchors; never persist or graph by runtime `region_id` |
| MC-02 | Stronghold meaning | ENERGY / FACTORY / LAB currently produce resource, volley, offer-size and related UI/simulation effects | Deployment Support claim, operational state, connectivity and deployment-source semantics |
| MC-03 | Support capture | Current territory/projectile capture owns cells only; `CardfrontCaptureInterceptor` belongs to that path | Separate Support capture/suppression runtime fed by territory/control facts without taking ownership of projectile territory capture |
| MC-04 | Battle-line topology | Current region/route/gate data does not provide the frozen authored Support graph | `default_duel` authored Core/Support nodes, frozen edges and route-role metadata with deterministic graph resolution |
| MC-05 | Deployment legality | Preview/commit uses `DeploymentRules`, while automatic and upgrade spawn can bypass it | Extend the existing `DeploymentRules` authority and require Player Preview, Player Commit, AI and Auto/Upgrade Spawn parity |
| MC-06 | Automatic placement | Automatic/upgrade paths select cells without the frozen Support-aware resolver | Deterministic source/cell ranking over current legal `DeploymentRules` results, with Core fallback |
| MC-07 | Branch value | The secondary bridge lacks sufficient strategic meaning | Value comes from authored connectivity and deployment reach, not resource/damage/Draft bonuses |
| MC-08 | Draft battlefield preview | Current peek/show-hide ownership can alter layout state | Existing Draft UI owner gains a visibility-only state transition; no second overlay and no Offer regeneration |
| MC-09 | Offer independence | Player and AI calls remain coupled through shared DraftSystem/RNG/weight state | Side-scoped Offer objects, eligible pools and random streams while keeping `CardfrontRoundDirector` as orchestrator |
| MC-10 | Duplicate semantics | Raw applied-upgrade counts are interpreted by consumers | One card level/upgrade API; duplicate choice raises Level rather than adding a separate card instance |
| MC-11 | AI information boundary | AI can be tempted to consume broad runtime objects | Minimal `AIObservationBuilder`/DTO whitelist before `CardfrontAiCommander` decisions |
| MC-12 | Save/snapshot contract | Current save/runtime snapshot has no stable Support identity/state contract | Versioned Support claim/operational/capture/connectivity state plus derived-state rebuild and legacy compatibility handling |

## MUST PRESERVE

| ID | Preserved contract | Boundary |
| --- | --- | --- |
| MP-01 | `Draft -> Aim -> Volley / Execution` phase responsibilities | No phase cancellation or replacement by the Support refactor |
| MP-02 | Command Point system | P0 may integrate with it only where explicitly specified; it is not redesigned here |
| MP-03 | Core objective and 8–12 minute match identity | Core remains the root/fallback objective; no match-format redesign |
| MP-04 | Existing volley, turret, territory and card runtime authorities | Extend at documented seams; do not create parallel game runtimes |
| MP-05 | `CardfrontRoundDirector` as Draft/phase orchestrator | Evolve its dependencies; do not create a second Draft controller |
| MP-06 | `DeploymentRules` as the deployment legality owner | Extend it; do not replace it with UI-, AI- or effect-specific rules |
| MP-07 | `CardfrontAiCommander` as a decision component | Put an observation boundary in front of it; do not replace it with a cheating AI |
| MP-08 | Territory/projectile capture ownership | `CardfrontCaptureInterceptor` remains limited to territory/projectile interception |
| MP-09 | Gate projectile filtering and current bridge geometry | Support graph cannot silently redefine projectile-gate semantics or rebuild the map |
| MP-10 | Creature current own-territory movement constraint | P0 does not grant global movement through neutral/enemy cells |
| MP-11 | Existing units when a Support becomes offline | Units are not deleted or teleported; only future deployment availability changes |
| MP-12 | Core fallback deployment | Losing frontline Supports cannot remove all deployment capability |
| MP-13 | Existing card/effect behavior outside a directly named P0 delta | No opportunistic rebalance or unrelated effect rewrite |
| MP-14 | Current map/region geometry as migration anchors | Existing ENERGY/FACTORY/LAB regions may identify authored anchors, but do not retain gameplay identity |

## MUST RETIRE

| ID | Legacy authority to retire | Cutover meaning |
| --- | --- | --- |
| MR-01 | ENERGY resource bonus, FACTORY volley bonus and LAB extra-choice bonus as active Stronghold gameplay | Removed from producers, consumers, UI and new saves when Support cutover occurs |
| MR-02 | Legacy Stronghold type as Support identity | Type may remain readable for migration/geometry lookup only; it cannot drive new Support behavior |
| MR-03 | Runtime `region_id` as any persisted, graph or Support key | Replaced by authored stable Support ID |
| MR-04 | Automatic/upgrade spawn bypasses around `DeploymentRules` | All ordinary consumers use the same legality authority |
| MR-05 | Shared mutable Player/AI Offer, RNG or private candidate state | Immutable definitions may remain shared; mutable offer state may not |
| MR-06 | Duplicate-card pile growth and scattered raw-count interpretation | Replaced by the level API |
| MR-07 | AI access to opponent private Offer, future RNG, hidden precise route values or arbitrary runtime objects | Replaced by the observation whitelist |
| MR-08 | Draft peek implemented by moving/rebuilding the root layout or regenerating the Offer | Replaced by visibility-only state transitions |
| MR-09 | `GateConnectivitySystem` or geometric proximity acting as the future Support graph | Authored topology is the only Support graph authority |
| MR-10 | New writes of obsolete Stronghold bonus save fields | A bounded legacy reader may remain until migration compatibility is intentionally removed |

## OUT OF SCOPE

| ID | Deferred/prohibited work | Destination |
| --- | --- | --- |
| OS-01 | Full faction/route/card content and complete route loop | P1/P2 |
| OS-02 | Complete Hard AI, long-horizon planning and hidden difficulty bonuses | P2; hidden bonuses remain prohibited |
| OS-03 | PvP network synchronization | Later networking phase |
| OS-04 | Large-scale map or bridge geometry redesign | Separate map amendment |
| OS-05 | Airborne, Infiltration, Forward Engineer and other special cross-line deployment cards | P2 extension points only |
| OS-06 | Final numerical balance, exact capture timing, exact deployment dimensions and final performance thresholds | Central tuning after functional authority exists |
| OS-07 | Kill/capture/suppression rewards that grant extra Draft opportunities | Not part of the frozen design |
| OS-08 | Global UI/art redesign | Later presentation work; P0 only fixes directly owned Support/Draft surfaces |
| OS-09 | Independent Support HP/building-combat system | P0 suppression uses territory ownership input |
| OS-10 | Rewriting projectile territory capture as Support capture | The two authorities remain separate |
| OS-11 | Global Creature movement across neutral/enemy territory | Explicitly forbidden by the freeze addendum |
| OS-12 | New gameplay, map changes or Support implementation during P0-00C | Earliest implementation remains after the remaining P0-00 gates |

## Legacy Stronghold resolution

The old Stronghold bonus is classified once:

```text
Legacy ENERGY / FACTORY / LAB gameplay bonuses: MUST RETIRE
Existing region geometry/anchor facts: MUST PRESERVE for migration
Legacy serialized fields: compatibility reader only, then retire by explicit migration decision
New Support gameplay identity: MUST CHANGE to stable authored Support definitions/state
```

No P0 implementation may keep the resource/volley/extra-choice bonus active as a hidden fallback after Support cutover. Conversely, removing the bonus does not authorize deleting its legacy save-reader or anchor mapping before the migration contract is implemented.

## Audit fields

```text
Mandatory audit gates touched: P0-00C Frozen Delta Ledger
Audit status per gate: PASS
Evidence bound to source commit: YES
Unverified assumptions remaining: exact tuning constants remain intentionally unfrozen; no unverified item is labeled PASS
Legacy authority still reachable: YES, as current pre-cutover baseline and future bounded compatibility input
Second-authority risk: CONTROLLED BY LEDGER; legacy gameplay and new Support gameplay may not remain simultaneously authoritative after cutover
Save/restore risk: EXPLICIT; preserve legacy read compatibility, stop obsolete new writes at the owning migration step
Cross-system regression evidence: NOT RERUN; documentation-only step, using accepted P0-00B evidence
Manual evidence required before GO: NO; product owner authorized entry and this step changes no runtime behavior
```

## Decision

The four classifications are mutually consistent, the Stronghold gameplay/compatibility distinction is explicit, and no gameplay or map file changed.

```text
Decision: GO
```

The **only allowed next step** is **P0-00D Test Harness Truth**. P0-01 remains gated by P0-00D, P0-00E, and P0-00F.
