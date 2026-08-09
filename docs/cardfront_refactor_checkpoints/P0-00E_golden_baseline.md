# P0-00E Golden Baseline Contract

Source commit: `9323c9f3c9f2bf7d2d9d222731a74ca05b089290`
Target step: P0-00E Golden Baseline Contract
Evidence type: automated + prior manual baseline
Evidence source: `P0-00E_golden_baseline.json`, `CardfrontP0GoldenBaselineTestRunner.gd`, P0-00B
Decision: PASS

## Frozen structural baseline

The machine-comparable source is `P0-00E_golden_baseline.json`. It freezes only:

- Cardfront mode ID, configured main scene, and duel-side ownership;
- the four current match phases covering battle/aim, paused Draft, choice resolution/execution, and Volley launch;
- Command Point defaults;
- Player and AI default three-choice offers plus the legacy Lab four-choice override;
- two-lane count, center ratios, and `two_equal_routes` strategy identity;
- the current legacy Stronghold ruleset, activation threshold, and Factory/Energy/Lab effects;
- Draft peek target semantics and its still-unverified runtime evidence status.

The focused runner parses the JSON, compares it with current code/configuration, verifies the main scene resource exists, and applies a legacy Factory + Energy snapshot through `CardfrontStrongholdSystem.apply_to_volley_plan()` to prove that old Stronghold data still changes a resolved plan.

## Deliberate exclusions

Random Offer IDs, visual pixels, and instantaneous FPS are explicitly excluded. They cannot become accidental compatibility requirements by being present in an incidental run.

## Evidence qualification

P0-00B supplies prior real boot and headless evidence under the manual-acceptance process. This checkpoint adds a repeatable structural contract; it does not claim a fresh complete playthrough.

The current Draft peek defect was not captured as reproducible runtime evidence. The JSON therefore records `FOLLOW-UP / AUDIT REQUIRED`, not PASS. Its P0 target is frozen as visibility-only behavior with no Offer regeneration, while pixel geometry remains unfrozen. Under the approved manual-acceptance cadence, this explicit follow-up does not create a parse, authority, corruption, or focused-test blocker.

## Mandatory audit fields

```text
Mandatory audit gates touched: P0-00E Golden Baseline Contract
Audit status per gate: PASS, with Draft peek runtime evidence explicitly FOLLOW-UP / AUDIT REQUIRED
Evidence bound to source commit: YES
Unverified assumptions remaining: Exact current Draft peek reproduction remains a declared manual follow-up; no gameplay authority depends on assuming it passed.
Legacy authority still reachable: YES; focused runtime application proves Factory and Energy still alter the Volley plan, and Lab remains the four-choice constant.
Second-authority risk: LOW; JSON is a regression contract, while production constants remain current runtime authority.
Save/restore risk: No new save state; legacy Stronghold retirement remains governed by P0-05.
Cross-system regression evidence: Prior P0-00B baseline only; focused golden runner is required for this checkpoint.
Manual evidence required before GO: NO under the approved manual-acceptance cadence; Draft peek remains named follow-up.
```

## Gate result

Decision: **GO**

Only allowed next step: **P0-00F Pre-Implementation Battle-line Freeze Verification**.
