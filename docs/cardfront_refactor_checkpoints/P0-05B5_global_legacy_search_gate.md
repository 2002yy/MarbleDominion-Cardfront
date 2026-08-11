# P0-05B5 Global Legacy Search Gate

Audited source commit: `b75192484c2543d46a8390918c84a3798f176ace`
Branch: `audit/p0-04e-auto-spawn`
Target step: **P0-05B5 — Global Legacy Search Gate**
Decision: **PENDING CI / NOT GO YET**

## Goal

Close P0-05 by proving that retired Factory / Energy / Lab numeric reward authority is absent from Cardfront production code, while retaining historical migration evidence in checkpoints and golden fixtures.

## Production cleanup completed

The audited source removes these runtime seams:

- Factory / Energy / Lab reward constants from `CardfrontStrongholdRules`;
- `bonuses_sampled`;
- `sample_bonuses()`;
- `get_owner_bonus()`;
- `apply_to_volley_plan()`;
- `current_stronghold_bonuses`;
- `get_stronghold_bonus()`;
- Stronghold reward metadata fields from `CardfrontVolleyPlan` and its snapshot;
- the live Stronghold-specific AI sanitizer;
- UI/runtime callers that used bonus-oriented names.

`CardfrontStrongholdSystem` is now status-only:

```text
sample_status()
get_owner_status()
get_region_activation()
```

Status schema remains:

```text
active_types
active_regions
control_percent
```

No retired numeric gameplay field is produced.

## Repeatable anti-drift gate

`CardfrontStrongholdSystemTestRunner.gd` recursively scans `res://scripts/cardfront/**/*.gd` and fails if any of the following production authority tokens return:

```text
FACTORY_SHOT_BONUS
ENERGY_ATTACK_LEVEL_BONUS
LAB_DRAFT_CHOICE_COUNT
current_stronghold_bonuses
get_stronghold_bonus
sample_bonuses
get_owner_bonus
apply_to_volley_plan
stronghold_shot_bonus
stronghold_attack_level_bonus
bonuses_sampled
```

The scan intentionally excludes `scripts/tests/**` and `docs/**` because historical fixtures and migration assertions may name retired concepts without making them runtime authority.

## Classified residual vocabulary

Some generic AI value-model vocabulary such as `post_multiplier_shot_bonus` or `temporary_attack_level_bonus` may still exist outside the Stronghold system. Those fields are not sourced from Stronghold state in the audited runtime. Their continued existence is therefore classified as generic upgrade-valuation vocabulary, not Stronghold authority.

Historical P0 baseline JSON retains the old numeric values only as migration evidence and explicitly marks their runtime effect as retired. The golden test now verifies that the historical fixture remains identifiable without importing retired Stronghold constants or invoking retired runtime APIs.

## Regression target

The following must remain true on the audited source:

- project parses/imports;
- tactical Stronghold status tests pass;
- three-choice runtime remains exactly three choices;
- AI/shared-upgrade tests remain green;
- battlefield entity/deployment foundation remains green;
- B1 simulation remains green;
- BallWar isolation remains unchanged.

## Mandatory audit fields

```text
Stable IDs introduced/changed? NO
Runtime numeric IDs used as identity? NO new use
Territory capture touched? NO
Creature movement legality touched? NO
Deployment four-consumer authority touched? NO
Derived states persisted as authority? NO
Legacy Stronghold active reward consumers remaining? NONE known
Legacy Stronghold production reward APIs remaining? NONE in production
Save compatibility impact? NONE; see P0-05B4
P1/P2 leakage? NONE
```

## Exit gate

Do not mark GO until CI for audited source `b75192484c2543d46a8390918c84a3798f176ace` confirms the source gate and cross-system regressions.

If green, P0-05 closes and the only allowed next step is **P0-06 — Support Presentation**.
