# P0-09A5-A6 Level Cap And Rarity Separation

Source commit: `eac9739787c5ac77e6cd90a547bac30b12a166bc`

Decision: **GO**

Only allowed next step: **P0-09B1 — Resolver Cutover audit**.

## A5 — Eligibility is not a Level cap

Current eligibility remains based on existing effect state:

- `attack_level` against its current cap;
- `rarity_level` against its current cap;
- tower/entity state against its existing rules;
- Echo armed state and other existing predicates.

It does not read `selected_upgrade_levels`.

Focused evidence proves both directions:

- a fixture with Selected Level 5 and uncapped attack effect state remains eligible;
- attack effect state at its existing cap is ineligible even with Selected Level 0;
- a repeatable +5 volley card remains eligible at Selected Level 7;
- therefore P0 introduces no implicit global card max Level.

Existing effect-state caps remain unchanged. They are not promoted into per-card Level-track design.

## A6 — Rarity is not card Level

The three values remain separate authorities:

```text
run_state.rarity_level
definition.rarity
run_state.selected_upgrade_levels[upgrade_id]
```

Selecting the rarity upgrade independently increases run rarity and that card's Selected Level once. It does not rewrite the authored rarity label. Directly changing run rarity does not rewrite Selected Level or definition rarity.

No rarity curve, card rarity, eligibility predicate, effect cap, Draft weight, or upgrade numeric value changed.

## Evidence

- focused Level cap/rarity separation — **PASS (16 checks)**;
- Echo Level contract — **PASS (16 checks)**;
- upgrade resolver regression — **PASS (31 checks)**;
- upgrade content regression — **PASS (115 checks)**;
- selectable deck regression — **PASS (1,023 checks)**;
- shared AI value policy regression — **PASS (43 checks)**;
- formal three-choice runtime — **PASS (59 checks)**.

Total assertions: **1,303 passed** under Godot `4.7.1-stable`.

## Mandatory audit fields

```text
Mandatory audit gate touched: P0-09A5-A6 Eligibility/Rarity separation
Audit status: PASS
Evidence bound to source commit: YES — eac9739787c5ac77e6cd90a547bac30b12a166bc
Eligibility reads Selected Level: NO
High Selected Level creates implicit cap: NO
Existing effect-state caps retained: YES
Effect-state cap equals card max Level: NO
run rarity equals Selected Level: NO
definition rarity equals Selected Level: NO
Selecting a card rewrites definition rarity: NO
Changing run rarity rewrites Selected Level: NO
Eligibility/rarity weights changed: NO
Gameplay expanded: NO
Manual/video evidence required before GO: NO
```
