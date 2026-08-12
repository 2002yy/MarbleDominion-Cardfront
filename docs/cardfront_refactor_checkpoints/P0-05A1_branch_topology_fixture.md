# P0-05A1 Branch Topology Fixture Before Map Behavior Cutover

Audited source commit: `f27a74b06938dc408531cc70b0d6fca7689b91e8`
Branch: `audit/p0-04e-auto-spawn`
Target step: **P0-05A1 — Branch Topology Fixture Before Map Behavior Cutover**
Decision: **GO**
Evidence bound to audited source commit: **YES**

## Goal

Freeze branch/route semantics in a pure, repeatable fixture before retiring legacy Stronghold gameplay behavior. This step is intentionally structural: it proves the authored route graph and branch semantics independently of legacy Factory / Energy / Lab bonuses.

## What is frozen

- Support / route identity remains stable.
- Branch semantics are tested independently from legacy Stronghold reward behavior.
- Route semantics do not require Factory / Energy / Lab passive gameplay bonuses to remain active.
- No map behavior cutover is claimed by this step.
- No Stronghold gameplay consumer is removed by this step.

## Automated evidence — same audited source

All evidence below is from `f27a74b06938dc408531cc70b0d6fca7689b91e8`.

### Headless Tests — run `31377066121` — SUCCESS

Relevant jobs:

- `Cardfront P0 route semantics pure` — SUCCESS
  - parse succeeds;
  - import succeeds;
  - `CardfrontRouteSemanticsTestRunner.gd` succeeds.
- `Cardfront P0 support graph pure` — SUCCESS.
- `Cardfront P0 deployment pure` — SUCCESS.
- `Cardfront v0.3 core loop` — SUCCESS.
- `Cardfront live runtime boundary` — SUCCESS.
- `Cardfront v0.3 tactical strongholds` — SUCCESS.

The full Headless workflow completed successfully on the same source commit.

### Other same-source workflows

- `Battlefield Entity Foundation Tests` — SUCCESS.
- `Shared Upgrade AI Tests` — SUCCESS.
- `B1 Simulation Tests` — SUCCESS.

## Mandatory audit gates

```text
Pure branch/route semantics fixture: PASS
Evidence bound to source commit: YES
Map behavior changed by this step: NO
Legacy Stronghold gameplay retired by this step: NO
P0-04 deployment authority disturbed: NO
Cross-system regression evidence: PASS
Manual/video evidence required: NO
```

## Decision

**GO** for P0-05A1 on audited source `f27a74b06938dc408531cc70b0d6fca7689b91e8`.

Only allowed next step: **P0-05A2 — Bind Existing Default Map to Authored Graph**.
