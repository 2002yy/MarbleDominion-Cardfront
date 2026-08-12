# P0-08A1 Current Draw Semantics Baseline

Source commit: `3e6f736`

Decision: **GO**

Only allowed next step: **P0-08A2 — Side RNG State Object**.

## Frozen semantics before RNG isolation

- registered deck IDs: `barrage_control`, `core_tactics`, `fortification_corps`;
- formal default deck: `core_tactics`;
- default deck IDs, in registry order: `volley_plus_5`, `volley_x2`, `attack_level_plus_1`, `defense_cap_plus_1`, `frontline_repair`, `armor_piercing`, `rarity_plus_1`, `echo_next_choice`, `siege_calibration`, `suppression_screen`, `repair_units`, `fire_control_beacon`, `interceptor_tower`, `building_volley`, `heavy_charge`, `armored_guard`, `sapper_unit`, `gate_colossus`;
- base rarity weights: common `100`, uncommon `42`, rare `12`;
- rarity-level adjustment: common `-12` with floor `25`, uncommon `+10`, rare `+8`;
- formal offer size and maximum: `3` / `3`;
- one offer contains unique IDs sampled without replacement;
- timeout fallback uniformly selects one definition from the current non-empty Offer and returns a deep copy;
- empty timeout Offer returns `{}`.

Eligibility remains based only on the selected deck and existing run-state caps/flags: rarity, attack, defense cap, Echo armed state, creature capacity, neutral creature presence, tower levels, and Building Volley's live-tower/level requirements. P0-08A must not add route, profession, behavior, reroll, cross-side exclusion, or new eligibility conditions.

## Pre-isolation trace evidence

Godot `4.7.1.stable.official.a13da4feb`, master seed `8082026`, one shared legacy RNG, eight consecutive default-state draws:

```text
1 armored_guard, defense_cap_plus_1, interceptor_tower
2 repair_units, fire_control_beacon, attack_level_plus_1
3 armor_piercing, defense_cap_plus_1, repair_units
4 frontline_repair, sapper_unit, armor_piercing
5 echo_next_choice, suppression_screen, interceptor_tower
6 siege_calibration, defense_cap_plus_1, volley_plus_5
7 volley_plus_5, volley_x2, suppression_screen
8 siege_calibration, volley_plus_5, defense_cap_plus_1
next offer timeout fallback: armored_guard
```

This trace is migration evidence, not a requirement that the new two-stream implementation reproduce the same concrete sequence. A2-A5 must preserve deck, eligibility, rarity, offer-size, uniqueness, and fallback semantics while deliberately changing cross-side RNG coupling.

## Mandatory audit fields

```text
Deck IDs frozen: YES
Eligibility frozen: YES
Rarity weights frozen: YES
Offer size frozen: YES
Timeout fallback frozen: YES
Eight-round trace captured from real Godot runtime: YES
Gameplay changed: NO
Decision: GO
```
