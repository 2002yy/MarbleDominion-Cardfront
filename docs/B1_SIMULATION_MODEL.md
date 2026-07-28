# B1 Simulation Model

## Scope

B1 is a new parity model. It does not replace or mutate the historical A/B0 simulators.

It adds:

- shared pure gate-state and projectile-admission rules used by live runtime and B1;
- map-owned route layouts for all three maps;
- two sorted, non-overlapping bridge lanes per map;
- open, half-open, and closed gate resolution;
- off-bridge river-bank reflection;
- actual side-variant simulation calls;
- a 40-cell virtual starting territory model per faction;
- Engineer contact-front initialization at `2/2` for five virtual front cells;
- ordinary starting cells at `1 / hero cap`;
- capture and recapture at zero defense;
- distinct-cell repair with no automatic refill;
- card appearance, selection, application, and wasted-unit metrics;
- gate passage, reflection, state-crossing, lane-traffic, capture, and recapture metrics.
- per-slot shot, chamber damage, territory pressure, defense absorption, route,
  capture, and recapture metrics;
- a five-round opening-strength audit with upgrades and strongholds disabled;
- a live-versus-B1 contract test for gate thresholds, core upgrade effects, and
  resolved volley sequences;
- diagnostic archetype-growth indicators for Gunner route pressure, Engineer
  defense/bridgehead play, and Balanced draft/Echo behavior.

## Current abstraction boundary

B1 uses a deterministic virtual-cell and route model inside the fast simulator. The live 2D battlefield remains authoritative for actual gameplay. The purpose of this model is to remove the largest known proxy gaps before the next 54,000-match decision gate.

The model is explicitly labeled `b1_spatial_approximation_with_shared_rules`.
It shares discrete rules and effect semantics with live runtime, but it does not
claim to replay every physical collision. Route choice, defended-cell contact,
and capture placement remain seeded spatial approximations. A balance result is
therefore directional until corresponding live telemetry or deterministic
runtime fixtures confirm those distributions.

The virtual territory is intentionally fixed at 40 cells per faction so the full audit remains tractable. It preserves the important semantics rather than reproducing every live grid cell:

- the contact front exists once at initialization;
- losing it removes its free defense;
- recapture begins at zero;
- cap growth does not refill cells;
- one repair card visits each eligible cell at most once.

## Acceptance order

1. Shared-rule and live/simulation contract tests.
2. Five-round opening audit with no upgrades or stronghold bonuses.
3. Small complete full-match matrix probe with archetype diagnostics.
4. Full repository Headless regression.
5. Full 54,000-match B1 audit.
6. Tune opening health/base volley/starting defense only after the opening model
   is stable.
7. Tune deck weights, exclusive effects, and AI marginal values before changing
   hero bases to fix late-game build imbalance.

The intended opening ranges are `48%..52%` hero point rate and `49%..51%`
mirror blue-side rate. They are currently reported as diagnostics, not hard CI
gates. Archetype indicators target a visible `20%..35%` lead while full-match
hero rates remain within `47%..53%`; these are also diagnostic until the model
and sample size are approved.
