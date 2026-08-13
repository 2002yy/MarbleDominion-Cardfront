# P0-10A6-A7 AI State and Context Projection

Source commit: `cad7954885078b28ad1d17f91c8b3436ee2669e1`

Decision: **GO**

Only allowed next step: **P0-10B1 - Commander Adapter First, No Policy Rewrite**.

## Completed migration seam

- `CardfrontAiObservationBuilder.project_own_state()` reads only the A1-approved own-state allowlist and returns detached value data.
- `CardfrontRoundDirector.get_ai_observation(owner_id)` builds the public and own-private buckets without storing the RunState object.
- `get_upgrade_value_context(owner_id)` remains as a compatibility facade, but now returns only `AIObservationBuilder.valuation_context(get_ai_observation(owner_id))`.
- Redundant legacy context keys (`source`, owned creature count, owned tower count) no longer enter valuation context.
- Policy defaults remain authoritative for fields not currently produced by the live runtime (`siege_defense_contact_chance`, `expected_frontline_captures`).

The Commander production call still receives legacy arguments in this checkpoint. B1 is the dedicated adapter cutover; A6/A7 establish and prove its pure input first.

## Scope preservation

- AI scoring formulas, archetype weights, Offer contents/order, Draft RNG, eligibility, gameplay, and save schema are unchanged.
- No Player private state, RNG/seed, runtime object, or callback was added.
- No full RunState is present in the generated Observation.

## Automated evidence

Godot `4.7.1-stable.official` focused checks against the source commit:

- AI observation allowlist/object boundary - **PASS (30 checks)**
- Live own-state/context projection - **PASS (12 checks)**
- Shared marginal-value AI - **PASS (43 checks)**
- Round combat/AI choice - **PASS (19 checks)**
- Formal ThreeChoice runtime - **PASS (59 checks)**

Total: **163 passed**, 0 failed.

## Mandatory audit fields

```text
Mandatory audit gate touched: P0-10 own-state and valuation-context projection
Audit status: PASS
Evidence bound to source commit: YES - cad7954885078b28ad1d17f91c8b3436ee2669e1
Full RunState present in generated Observation: NO
Valuation facade source: AIObservationBuilder.valuation_context(observation)
Unknown context keys retained: NO
Policy scoring/archetype weights changed: NO
Commander production adapter cut over: NO - next step B1
Gameplay or save schema changed: NO
Manual evidence remaining before GO: NO
P1 route/reroll/deep-card content included: NO
```
