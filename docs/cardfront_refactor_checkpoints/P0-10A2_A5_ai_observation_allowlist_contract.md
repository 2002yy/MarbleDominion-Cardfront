# P0-10A2-A5 AI Observation Allowlist Contract

Source commit: `549b995c8789c0f613546084d9563c8ac64c8d36`

Decision: **GO**

Only allowed next step: **P0-10A6 - Own-State Projection, Do Not Pass Full RunState**.

## Implemented contract

`CardfrontAiObservationBuilder` starts from an empty Dictionary and produces exactly three buckets:

```text
public_battle_state
own_private_state
observed_enemy_history
```

Every top-level field is copied from an explicit allowlist. Structured public collections (`support_views`, entities, gates, bridges, revealed cards) also have per-record nested allowlists, so a future pure-value field cannot hitchhike inside an already approved container.

The builder accepts only primitives, Strings/StringNames, Vector2/Vector2i, approved Arrays, and string-keyed approved Dictionaries. It does not retain source references.

## Forbidden input handling

The schema does not expose and tests explicitly challenge:

- Player current Offer or unrevealed choice;
- future Offer;
- RNG object/state or seed;
- hidden route tendency or tactical instruction;
- SceneTree, Node, arbitrary runtime Object, RoundDirector, or full RunState;
- Callable/callback escape hatches;
- unreviewed future top-level or nested fields.

Unknown fields default invisible. Object/callback-contaminated scalar/map fields are rejected; typed record collections retain only their separately approved safe subfields.

## Scope preservation

- Builder is not yet connected to `CardfrontAiCommander` or `CardfrontRoundDirector`.
- Commander still consumes the legacy inputs until A6/A7/B1 migration.
- AI Offer, ranking, scoring formulas, archetype weights, Draft generation, gameplay, and save schema are unchanged.
- This step does not claim the production full-RunState escape hatch is removed; it establishes the tested destination contract first.

## Automated evidence

Godot `4.7.1-stable.official` focused checks against the source commit:

- AI observation allowlist/object boundary - **PASS (30 checks)**
- Shared marginal-value AI - **PASS (43 checks)**
- Round combat/AI choice - **PASS (19 checks)**
- Selectable decks and tactical AI - **PASS (1023 checks)**

Total: **1115 passed**, 0 failed.

The new boundary runner is registered as a dedicated active Headless Tests batch.

## Mandatory audit fields

```text
Mandatory audit gate touched: P0-10 AI observation schema and object escape
Audit status: PASS
Evidence bound to source commit: YES - 549b995c8789c0f613546084d9563c8ac64c8d36
Observation construction mode: empty DTO -> explicit allowlist copy
Information buckets: PublicBattleState / OwnPrivateState / ObservedEnemyHistory
Unknown future fields default visible: NO
Nested unknown fields can hitchhike: NO
Player Offer/choice allowed: NO
Future Offer/RNG/seed allowed: NO
Node/Runtime Object/RunState/RoundDirector/Callable allowed: NO
Returned values detached from source: YES
Production Commander migrated: NO - explicitly deferred to A6/A7/B1
Scoring formulas or archetype weights changed: NO
Gameplay or save schema changed: NO
Manual evidence remaining before GO: NO
P1 route/reroll/deep-card content included: NO
```
