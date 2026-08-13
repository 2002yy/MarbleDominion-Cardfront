# P0-10B1-B5 AI Commander Observation Adapter

Source commit: `509aea4d5fd8ac95eb23ce87c00c9007c02a559d`

Decision: **GO**

Only allowed next step: **P0-11A - Final Evidence Manifest / Test Classification Freeze**.

## Production cutover

`CardfrontRoundDirector._open_draft()` now calls:

```text
CardfrontAiCommander.choose_from_observation(
    current AI Offer,
    allowlisted AI Observation
)
```

The adapter extracts only the detached `own_private_state` and the approved valuation projection before invoking the unchanged policy chain. Production no longer passes a full `CardfrontFactionRunState` object to Commander.

The legacy `choose(offer, state, context)` method remains as a compatibility/test seam for non-production callers and migration equivalence. The formal RoundDirector path does not use it.

## Decision-strength freeze

For a fixed Engineer state, fixed legal public context, and fixed three-card Offer, the test compares the legacy full-state call with the Observation adapter and proves:

- identical selected upgrade ID;
- identical complete ranking order;
- identical Commander scores.

No score formula, archetype transition, or archetype weight changed.

## Fair-information contracts

- Secret-injection metamorphic test: changing Player Offer, future Offer, RNG seed, and hidden route tendency while keeping public/own legal data identical produces an identical Observation.
- Public-change sensitivity: changing approved enemy defense and public Support state changes Observation; the approved defense change also reaches valuation context.
- No difficulty cheats: damage/HP/resource multipliers, cost discount, hidden extra draw, and same-frame reaction fields are not observation capabilities.
- Live runtime test: a real Draft produces a three-card AI Offer, three ranked evaluations, and a recursively pure Observation.

## Automated evidence

Godot `4.7.1-stable.official` focused and cross-system checks against the source commit:

- AI observation allowlist/object boundary - **PASS (30 checks)**
- Live own-state/context projection - **PASS (12 checks)**
- Commander adapter/freeze/metamorphic/sensitivity/no-cheat - **PASS (15 checks)**
- Shared marginal-value AI - **PASS (43 checks)**
- Round combat/AI choice - **PASS (19 checks)**
- Selectable decks and tactical AI - **PASS (1023 checks)**
- Formal ThreeChoice runtime - **PASS (59 checks)**

Total: **1201 passed**, 0 failed.

## Mandatory audit fields

```text
Mandatory audit gate touched: P0-10 production AI information boundary
Audit status: PASS
Evidence bound to source commit: YES - 509aea4d5fd8ac95eb23ce87c00c9007c02a559d
Production Commander receives full RunState: NO
Production Commander receives allowlisted Observation: YES
Fixed legal decision ranking preserved: YES
Fixed legal Commander scores preserved: YES
Player Offer/future Offer/RNG/hidden route injection changes Observation: NO
Approved public changes can change Observation: YES
Difficulty cheat fields introduced: NO
Scoring formulas or archetype weights changed: NO
Gameplay or save schema changed: NO
Legacy broad choose API reachable outside production: YES - compatibility/test seam only
Second production authority introduced: NO
Manual evidence remaining before GO: NO
P1 route/reroll/deep-card content included: NO
```
