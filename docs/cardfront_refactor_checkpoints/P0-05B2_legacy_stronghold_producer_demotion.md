# P0-05B2 — Legacy Stronghold Producer Demotion

Status: **GO**

Validated code head: `c972bef85257cc6b571344d7e80cfef5ce151e40`

## Goal

Complete the second half of the consumer-first migration:

> P0-05B1 proved the old Factory / Energy / Lab reward values had no gameplay authority. P0-05B2 now stops producing those reward values at the authoritative stronghold boundary.

This checkpoint does not perform the UI/text semantic cutover. That remains P0-05B3.

## Authoritative schema after this checkpoint

`CardfrontStrongholdSystem.sample_status()` produces per-side stronghold status only:

- `active_types`
- `active_regions`
- `control_percent`

It deliberately does **not** produce:

- `shot_count_bonus`
- `temporary_attack_level_bonus`
- `draft_choice_count`
- renamed equivalents of those retired rewards

The 80% activation threshold and strongest-region-per-type selection remain unchanged.

## Compatibility shell

The old method names are retained temporarily because presentation/runtime cleanup is staged:

- `sample_bonuses()` -> delegates to `sample_status()`
- `get_owner_bonus()` -> delegates to `get_owner_status()`
- `bonuses_sampled` -> emits the same status-only snapshot as `status_sampled`

These legacy names are explicitly non-authoritative. They do not recreate, rename, or package the retired reward values.

`apply_to_volley_plan()` also remains as a temporary call seam, but:

- `stronghold_shot_bonus = 0`
- `stronghold_attack_level_bonus = 0`
- only `active_stronghold_types` may be copied as identity/status metadata
- injected legacy numeric fields are ignored

## Golden baseline transition

P0-00E was advanced rather than weakened:

- historical Factory `+3`, Energy `+1`, and Lab `4` values remain recorded as migration history;
- `runtime_effect_expected = false`;
- `retired_at_checkpoint = P0-05B2`;
- the golden runner injects the historical values and proves they cannot revive live volley or attack effects.

## CI evidence

On validated head `c972bef85257cc6b571344d7e80cfef5ce151e40`:

- Cardfront P0 golden baseline: **PASS** — parse, import, and actual runner all passed;
- Cardfront v0.3 tactical strongholds: **PASS**;
- Cardfront v0.3 three-choice slice: **PASS**;
- Cardfront v0.3 core loop: **PASS**;
- Cardfront live runtime boundary: **PASS**;
- Shared Upgrade AI Tests: **PASS**;
- Battlefield Entity Foundation Tests: **PASS**.

This is sufficient evidence for the P0-05B2 owner boundary. Later B3 commits are validated separately and do not retroactively change this code head.

## Regression evidence added/updated

### `CardfrontStrongholdSystemTestRunner.gd`

Proves:

1. 80% activation still works;
2. highest-control region per type is still selected;
3. status snapshots contain no retired reward fields;
4. old API method names return status-only data;
5. malicious/injected old +3/+1/4 data cannot revive volley or attack effects through `apply_to_volley_plan()`;
6. the B1 draft and AI consumer guards remain active.

### `CardfrontThreeChoiceRuntimeTestRunner.gd`

At the B2 validated head it proves:

1. all three stronghold identities can still become active;
2. the runtime snapshot contains no retired numeric reward fields;
3. the player draft remains exactly three choices;
4. Lab no longer drives the `四选一` draft-title branch;
5. Factory/Energy plan metadata is neutral zero.

P0-05B3 subsequently owns the player-visible semantic wording.

## Explicit non-goals

Not touched in P0-05B2:

- P0-05B3 UI/text semantic cutover;
- replacement stronghold abilities;
- timeout scoring from active stronghold identity;
- territory capture semantics;
- Support ownership/connectivity;
- DeploymentRules;
- creature movement legality;
- map geometry or branch topology;
- save schema;
- global deletion of every legacy method/field name (P0-05B5 search gate).

## Batch A checkpoint fields

Test evidence authority: GitHub Actions headless runners on validated code head

Stable IDs introduced/used: none

Runtime numeric IDs used as identity? **NO**

Territory capture touched? **NO**

Creature movement legality touched? **NO**

All spawn paths checked: unchanged from P0-04E/P0-04F

Derived states persisted as authority? **NO**

Legacy stronghold reward producers remaining in authoritative status: **NO**

Legacy compatibility names remaining:

- `sample_bonuses`: **YES — status-only wrapper**
- `get_owner_bonus`: **YES — status-only wrapper**
- `bonuses_sampled`: **YES — status-only compatibility signal**
- `apply_to_volley_plan`: **YES — neutral compatibility seam; no retired rewards**
- UI old effect text/constants: **deferred to P0-05B3/B5 on the B2 code head**

Save compatibility impact: **NONE in P0-05B2**; no save field added, removed, or reinterpreted.

## Next checkpoint

**P0-05B3 — UI/Text Semantic Cutover**.

Do not invent replacement Factory/Energy/Lab abilities during B3. B3 is removal/semantic cleanup only unless a higher-level design document explicitly defines the replacement behavior.
