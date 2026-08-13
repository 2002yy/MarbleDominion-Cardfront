# P0-10A1 Current AI Read-Set Audit

Source commit: `758351d33e19fa8846fb880c566246de432950ff`

Decision: **GO**

Only allowed next step: **P0-10A2 through P0-10A5 - explicit allowlist buckets, forbidden fields, and no-object-escape contract**.

## Live call chain

```text
CardfrontRoundDirector._open_draft()
 -> get_ai_offer()
 -> get_run_state(AI_FACTION)                  # full RefCounted object
 -> get_upgrade_value_context(AI_FACTION)      # free-form Dictionary
 -> CardfrontAiCommander.choose()
 -> CardfrontAiUpgradePolicy.rank_ids()
 -> CardfrontTacticalUpgradeValuePolicy.evaluate()
 -> CardfrontDeckUpgradeValuePolicy.evaluate()
 -> CardfrontUpgradeValuePolicy.evaluate()
```

The AI receives only its own current Offer, but it also receives its entire mutable `CardfrontFactionRunState` object. The current policies happen to project fixed keys into internal Dictionaries; the caller boundary itself does not prevent future or accidental reads.

## AI currently reads

### Explicit Offer input

- current AI Offer definitions: `id` only for selection/ranking; the selected detached definition is returned;
- Offer order for deterministic tie breaking.

The current Player Offer is not passed to the commander.

### Commander-owned configuration

- configured AI hero identity, converted to an archetype;
- frozen archetype weights;
- `own_health_ratio` and `round_number` from valuation context for archetype transition.

### Own RunState fields

Union of the live Base, Deck, and Tactical policy projections:

```text
deck_id
base_volley_count
base_projectile_mix
frontline_repair_bonus
captured_frontline_defense
next_volley_bonus
next_volley_multiplier
next_volley_armor_pierce_contacts
next_volley_conversions
attack_level
territory_defense_cap
rarity_level
echo_next_choice_armed
queued_echo_upgrade_id
pending_repair_points
owned_creature_count
owned_defense_tower_count
tower_levels
building_volley_level
neutral_creature_summoned
applied_upgrade_counts
```

`selected_upgrade_levels` is not currently read by AI scoring. The build diversity/synergy logic still reads the separate Echo-inclusive `applied_upgrade_counts` history by design.

### Valuation context fields

Union of fields read by Commander/Base/Deck/Tactical policy:

```text
round_number
rounds_remaining
pre_multiplier_shot_bonus
post_multiplier_shot_bonus
temporary_attack_level_bonus
estimated_chamber_hit_chance
enemy_defense_contact_chance
siege_defense_contact_chance
enemy_defense_points
repairable_frontline_cells
owned_cell_count
defended_cell_count
own_health_ratio
enemy_health_ratio
route_pressure
future_offer_size
expected_frontline_captures
enemy_defense_tower_count
```

Current live `RoundDirector.get_upgrade_value_context()` supplies all except `siege_defense_contact_chance` and `expected_frontline_captures`, for which policy defaults are used. The three temporary/shot bonus fields are currently supplied as public constants (`0`), and hit chance as `0.17`.

`source`, `owned_creature_count`, and `owned_defense_tower_count` are currently emitted by the live context but are not read from context by the active policy chain. The two owned entity counts are already read from own RunState instead.

## AI currently could read because broad inputs are passed

- every current and future property/method on the full AI `CardfrontFactionRunState` object;
- any arbitrary future key added to the free-form context Dictionary;
- mutable nested Dictionaries/Arrays reachable from that RunState;
- any runtime object, callback, Node, SceneTree, RNG, offer, or hidden-state reference if a caller later inserts one into context;
- derived or opponent-private state exposed by any future expansion of `get_upgrade_value_context()`.

The current policy helpers enumerate known keys, so there is no confirmed present read of those secrets. This is nevertheless a real boundary defect: adding a field to Game/RunState or context does not default to invisible.

## AI does not need

The audited current decision algorithm does not read or require:

- Player current Offer or unrevealed Player selection;
- future Offers, Draft RNG state, seed, or side RNG object;
- full Player RunState or full AI RunState object identity;
- `RoundDirector`, SceneTree, Node, runtime entity objects, callbacks, or query functions;
- hidden route-tendency score or hidden tactical instruction;
- Support/capture/deployment authority objects;
- save manager, snapshot authority, UI state, Aim/Volley input, or projectile runtime objects;
- `selected_upgrade_levels` for current score/ranking parity.

## Findings

1. **Full-object escape hatch:** `CardfrontAiCommander.choose(..., run_state, ...)` is the primary boundary risk.
2. **Free-form context escape hatch:** `get_upgrade_value_context()` returns a plain extensible Dictionary and the commander deep-duplicates it without an allowlist.
3. **Redundant context keys:** `source`, `owned_creature_count`, and `owned_defense_tower_count` are not part of the current read set.
4. **No confirmed current secret read:** Player Offer/RNG/unrevealed choice are not in the current production call chain.
5. **Migration must preserve ranking:** P0-10 must project exactly the audited union before adapting the commander; scoring formulas and archetype weights remain read-only.

## Mandatory audit fields

```text
Mandatory audit gate touched: P0-10 AI information boundary
Audit status: PASS - current reads and broad-input risks enumerated
Evidence bound to source commit: YES - 758351d33e19fa8846fb880c566246de432950ff
Current Player Offer passed to AI: NO
Current Player unrevealed choice passed to AI: NO
Current RNG/seed passed to AI: NO
Full AI RunState object passed to AI: YES - migration required
Free-form valuation context passed to AI: YES - migration required
Node/SceneTree/runtime object currently read by policy: NO
Scoring formulas or archetype weights changed: NO
Unverified assumptions remaining: none for the audited production call chain
Second-authority risk introduced: NO - documentation only
Manual evidence required before GO: NO
P1 route/reroll/deep-card content included: NO
```
