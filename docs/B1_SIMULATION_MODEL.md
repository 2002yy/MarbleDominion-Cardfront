# B1 Simulation Model

## Scope

B1 is a new parity model. It does not replace or mutate the historical A/B0 simulators.

It adds:

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

## Current abstraction boundary

B1 uses a deterministic virtual-cell and route model inside the fast simulator. The live 2D battlefield remains authoritative for actual gameplay. The purpose of this model is to remove the largest known proxy gaps before the next 54,000-match decision gate.

The virtual territory is intentionally fixed at 40 cells per faction so the full audit remains tractable. It preserves the important semantics rather than reproducing every live grid cell:

- the contact front exists once at initialization;
- losing it removes its free defense;
- recapture begins at zero;
- cap growth does not refill cells;
- one repair card visits each eligible cell at most once.

## Acceptance order

1. Route schema and deterministic unit tests.
2. Small complete matrix probe.
3. Full repository Headless regression.
4. Full 54,000-match B1 audit.
5. Only then consider Engineer health `42 -> 44` if aggregate Engineer rate remains below `47%`.
