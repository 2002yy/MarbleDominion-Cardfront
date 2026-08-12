# P0-04F Four-Consumer Parity Matrix

Audited source commit: `bd30e0cdcf11c10eaf3b5d2e54835a7c0cbd8e91`
Branch: `audit/p0-04e-auto-spawn`
Target step: **P0-04F — Four-Consumer Parity Matrix**
Decision: **GO**
Evidence bound to audited source commit: **YES**

## Goal

Prove that all four production deployment consumers converge on one legality authority and agree on the same deployment facts:

```text
Player Commit ───────────────┐
Player Preview ──────────────┤
AI Placement ────────────────┼─> DeploymentRules.evaluate(SUPPORT_NETWORK)
Automatic / Upgrade Spawn ──> DeploymentPlacementResolver ──┘
```

`DeploymentPlacementResolver` selects among legal cells; it does not replace `DeploymentRules` or infer Support connectivity.

## Static authority convergence

`CardfrontDeploymentAutomaticSpawnTestRunner.gd` recursively scans production `scripts/cardfront/**/*.gd` and locks direct `DeploymentRules.evaluate()` consumers to exactly:

1. `scripts/cardfront/targets/target_rules/FrontlineDeploymentTargetRule.gd` — Player Commit;
2. `scripts/cardfront/ui/CardfrontTargetPreviewLayer.gd` — Preview;
3. `scripts/cardfront/ai/CardfrontAiDeploymentPlanner.gd` — AI;
4. `scripts/cardfront/deployment/DeploymentPlacementResolver.gd` — Automatic placement resolver.

Additional guards prove:

- Entity runtime does not directly import `DeploymentRules`;
- AutomaticSpawnCoordinator does not directly import `DeploymentRules`;
- AutomaticSpawnCoordinator delegates to `DeploymentPlacementResolver`;
- production runtime assembles the authoritative creature coordinator, not the dormant legacy coordinator directly;
- authoritative compatibility spawn helpers call the current automatic placement authority;
- no route-slot or building-slot spawn fallback exists in the authoritative adapter.

Repository GitHub code-search indexing is disabled, so absence of search hits is **not** treated as evidence. The CI source scan is the repeatable anti-drift contract.

## Behavioral four-consumer parity matrix

New runner:

`scripts/tests/CardfrontDeploymentFourConsumerParityTestRunner.gd`

For each scenario it feeds the same battlefield cell and same deployment context to:

- Commit rule;
- Preview layer;
- AI planner;
- Automatic resolver.

For Automatic placement, `availability` is restricted to the exact test cell so the resolver cannot pass by silently choosing another legal Core/Support cell.

| Scenario | Commit | Preview | AI | Auto Spawn |
|---|---:|---:|---:|---:|
| Core legal | legal | legal | legal | legal |
| Online Support rear-zone cell | legal | legal | legal | legal |
| Requested Support disconnected / not Online | illegal | illegal | illegal | illegal |
| Requested Support disabled / not Online | illegal | illegal | illegal | illegal |

Disconnected and disabled are distinct upstream Support states. At the deployment-consumer boundary both are intentionally represented by absence from derived Online Support truth; deployment consumers must not reconstruct the reason or run a second graph traversal.

## Current-click / current-state rule

- Preview is advisory visualization, not permission.
- Commit evaluates current legality when the card is actually played.
- AI evaluates against current supplied deployment context.
- Automatic spawn resolves against current supplied deployment context.
- Stale preview state cannot authorize an otherwise illegal commit.

## Legacy bypass audit

The old base `CardfrontCreatureActionCoordinator.gd` still contains historical route-slot helper implementations. They are isolated behind the authoritative subclass and are not a fifth production authority.

The compatibility regression deliberately makes the battlefield illegal for the player and calls the inherited helper surface through the actual authoritative runtime coordinator. Expected and observed contract:

```text
find_owner_spawn_cell(...) == (-1, -1)
find_adjacent_spawn_cell(...) == (-1, -1)
```

No route origin or arbitrary owned cell is returned.

## Automated evidence — same audited source

All evidence below is from `bd30e0cdcf11c10eaf3b5d2e54835a7c0cbd8e91`.

### Headless Tests — run `31376230274` — SUCCESS

Relevant job:

- `Cardfront P0 deployment pure` — SUCCESS
  - `CardfrontDeploymentContractTestRunner.gd`
  - Core fallback
  - directional zone
  - Player Commit
  - Preview parity
  - AI parity
  - Automatic Spawn
  - **Four-Consumer Parity Matrix**

The job also passed parse/import on the audited source.

### Shared Upgrade AI Tests — run `31376230249` — SUCCESS

AI/shared-upgrade cross-system regression remains green.

### Battlefield Entity Foundation Tests — run `31376230222` — SUCCESS

Entity runtime/live/boundary regressions remain green after automatic-spawn authority migration.

### B1 Simulation Tests — run `31376230232` — SUCCESS

Broader simulation/deck/route-gate regression remains green on the same source.

## Mandatory audit gates

```text
P0-04 four-consumer convergence: PASS
Player Preview authority: PASS / consumer only
Player Commit authority: PASS
AI placement authority: PASS
Automatic placement authority: PASS via resolver
Fifth deployment authority found: NO
Legacy route-slot creature bypass reachable through production runtime: NO
Second graph/BFS authority introduced by deployment consumers: NO
Evidence bound to source commit: YES
Save/restore risk introduced: NONE
Cross-system regression evidence: PASS
Unverified authority assumptions remaining: NONE known
Manual evidence required before GO: NONE for this pure authority/parity gate
P1/P2 leakage: NONE
```

## Decision

**GO** for P0-04F on audited source `bd30e0cdcf11c10eaf3b5d2e54835a7c0cbd8e91`.

P0-04 is closed.

Only allowed next step: **P0-05A1 — Branch Topology Fixture Before Map Behavior Cutover**.
