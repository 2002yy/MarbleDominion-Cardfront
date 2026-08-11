# P0-05B1 — Legacy Stronghold Consumer Cut

Status: **PENDING CI / NOT GO YET**

## Goal

Prove the consumer-first cut required by the P0 plan:

> The legacy Factory / Energy / Lab producer may still publish `+3 shots`, `+1 attack level`, and `4 choices`, but those values no longer have gameplay authority.

This checkpoint deliberately does **not** demote or delete the producer. Producer cleanup belongs to P0-05B2.

## Frozen legacy producer evidence

`CardfrontStrongholdSystem.sample_bonuses()` still publishes the existing fields and values when the corresponding stronghold is active:

- Factory: `shot_count_bonus = 3`
- Energy: `temporary_attack_level_bonus = 1`
- Lab: `draft_choice_count = 4`
- `active_types`, `active_regions`, and `control_percent` remain unchanged.

The 80% activation threshold and strongest-region-per-type selection are unchanged.

## Consumer cut implemented

### 1. Factory -> volley consumer

`CardfrontStrongholdSystem.apply_to_volley_plan()` no longer appends projectiles or changes `shot_count`.

The old Factory value may still be copied to `plan.stronghold_shot_bonus` as compatibility/debug metadata, but it does not mutate the projectile sequence or live volley size.

### 2. Energy -> attack consumer

`CardfrontStrongholdSystem.apply_to_volley_plan()` no longer increments `plan.attack_level` and no longer raises `chamber_damage_quarters` from the legacy Energy value.

The old Energy value may still be copied to `plan.stronghold_attack_level_bonus` as compatibility/debug metadata only.

### 3. Lab -> draft consumer

`CardfrontUpgradeDraftSystem` now enforces the formal three-choice contract:

- `DEFAULT_OFFER_SIZE = 3`
- `MAX_OFFER_SIZE = 3`

Therefore a legacy Lab request for four choices is clamped to three even though `sample_bonuses()` still reports `draft_choice_count = 4`.

### 4. Indirect AI valuation consumer

A hidden gameplay consumer was found during the cut: live AI valuation received legacy stronghold values through the upgrade value context.

`CardfrontAiCommander` now sanitizes the live legacy fields before ranking upgrades:

- `post_multiplier_shot_bonus -> 0`
- `temporary_attack_level_bonus -> 0`
- `future_offer_size -> 3`

This prevents retired stronghold rewards from changing AI card selection after the direct combat consumers have been detached.

## Regression evidence

Updated runners:

- `CardfrontStrongholdSystemTestRunner.gd`
  - producer still publishes Factory +3 / Energy +1 / Lab 4;
  - Factory does not change shot count or projectile sequence;
  - Energy does not change attack level or chamber damage;
  - Lab four-choice request resolves to three;
  - AI live valuation receives neutralized legacy stronghold values.
- `CardfrontUpgradeContentTestRunner.gd`
  - explicit legacy four-choice request is capped to three and remains unique.
- `CardfrontThreeChoiceRuntimeTestRunner.gd`
  - full runtime still observes legacy producer values;
  - formal player offer and panel remain exactly three choices;
  - legacy Factory/Energy values remain metadata-only on the plan.

## Explicit non-goals

Not touched in P0-05B1:

- P0-05B2 producer demotion/removal;
- P0-05B3 UI/text semantic cutover;
- replacement stronghold abilities;
- timeout stronghold scoring based on `active_types`;
- territory capture semantics;
- Support ownership/connectivity;
- DeploymentRules;
- creature movement legality;
- map geometry or branch topology;
- save schema.

The current stronghold UI may therefore still describe the old effects until P0-05B3. That semantic mismatch is known and must not be mistaken for retained gameplay authority.

## Exit gate

P0-05B1 can become **GO** only if the PR head proves:

1. Godot headless parse/import passes;
2. `CardfrontStrongholdSystemTestRunner.gd` passes;
3. `CardfrontUpgradeContentTestRunner.gd` passes;
4. `CardfrontThreeChoiceRuntimeTestRunner.gd` passes;
5. the broader v0.3 stronghold / three-choice / shared-upgrade-AI batches remain green;
6. no unrelated deployment, capture, movement, map, or save regression appears.

## Batch A checkpoint fields

Test evidence authority: GitHub Actions headless test runners on PR head

Stable IDs introduced/used: none

Runtime numeric IDs used as identity? **NO**

Territory capture touched? **NO** — stronghold reward consumers only

Creature movement legality touched? **NO** — no movement or spawn-legality code changed

All spawn paths checked:
- preview: unchanged; inherited from P0-04F
- commit: unchanged; inherited from P0-04F
- AI: deployment unchanged; only upgrade valuation legacy reward fields sanitized
- automatic/upgrade spawn: unchanged; inherited from P0-04E/P0-04F

Derived states persisted as authority? **NO**

Legacy stronghold active consumers remaining:
- old producer fields: **YES, intentionally, compatibility evidence for P0-05B1**
- gameplay draft/volley/attack consumers: **NO by contract under this checkpoint**
- UI/text descriptions: **YES, intentionally deferred to P0-05B3**
- timeout scoring from `active_types`: **YES, unchanged and outside the three retired numeric reward consumers**

Save compatibility impact: **NONE in P0-05B1**; no save field added, removed, or reinterpreted.

## Next checkpoint

After this checkpoint is green, proceed to **P0-05B2 — Legacy Stronghold Producer Demotion**. Do not start UI wording cleanup or replacement ability design before the consumer-first evidence is green.
