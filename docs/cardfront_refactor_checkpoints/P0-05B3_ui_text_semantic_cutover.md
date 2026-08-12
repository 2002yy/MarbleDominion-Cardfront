# P0-05B3 — UI/Text Semantic Cutover

Status: **PENDING CI / NOT GO YET**

## Goal

Make every live player-facing stronghold surface semantically match P0-05B1/B2:

> Factory / Energy / Lab remain identifiable tactical strongholds, but the retired `+3 shots`, `+1 attack level`, and `four-choice Lab` rewards must not be promised by the UI.

This checkpoint is semantic cleanup only. It does not redesign the HUD and does not invent replacement stronghold abilities.

## Changes

### Three-choice panel

`CardfrontThreeChoicePanel.gd` no longer contains a Lab-driven four-choice presentation branch.

The draft always presents the formal contract:

- title: `选择本轮强化`;
- instruction: click one upgrade, timeout chooses randomly;
- active strongholds are shown separately as control identities, e.g. `据点控制：能源 · 工厂 · 实验室`;
- no `+3`, `+1`, attack-level, extra-shot, or four-choice promise is shown.

The existing layout and peek behavior are unchanged.

### Region information panel

`CardfrontRegionInfoPanel.gd` keeps the real 80% stronghold control threshold, but reframes it as status rather than an ability trigger:

- `据点控制：已达成 / 还差 X%`;
- `据点状态：有效控制 · <owner>`;
- `据点状态：未达控制阈值`;
- `据点状态：待本轮刷新 · <owner>`.

The panel no longer emits `据点能力：...` or old reward descriptions.

### Stronghold text compatibility layer

`CardfrontStrongholdRules.gd` keeps the historical numeric constants for golden-baseline and B5 migration evidence, but its text formatters are neutralized:

- Factory display name changes from the reward-implying `齐射工厂` to `工业据点`;
- `effect_text()` returns status-only wording;
- `compact_effect_text()` returns identity only.

This prevents stale presentation consumers from accidentally resurrecting retired reward text before B5 removes the legacy seams.

## Regression evidence

### `CardfrontThreeChoiceRuntimeTestRunner.gd`

Adds semantic assertions that, with all three strongholds controlled:

- draft remains exactly three choices;
- title is exactly `选择本轮强化`;
- instructions do not mention a Lab bonus;
- HUD begins with `据点控制：`;
- Energy / Factory / Lab identities remain visible;
- `+3`, `+1`, `四选一`, `攻击等级`, and `额外发射` are absent.

### `CardfrontRegionInfoPanelVisibilityTestRunner.gd`

Adds semantic assertions that the region panel:

- uses `据点控制：` for the 80% line;
- uses `据点状态：` for the stronghold line;
- does not contain `据点能力`, `四选一`, `+3`, `+1`, `攻击等级`, or `额外发射`;
- keeps its existing layout/visibility constraints.

## Explicit non-goals

Not touched in P0-05B3:

- replacement Factory/Energy/Lab abilities;
- timeout stronghold scoring based on active identity;
- 80% control threshold itself;
- territory capture semantics;
- Support ownership/connectivity;
- DeploymentRules;
- creature movement legality;
- map geometry;
- save schema;
- global removal of legacy method names/constants (P0-05B5).

## Exit gate

P0-05B3 becomes **GO** only if the final PR head proves:

1. Godot parse/import succeeds;
2. `CardfrontThreeChoiceRuntimeTestRunner.gd` succeeds;
3. `CardfrontRegionInfoPanelVisibilityTestRunner.gd` succeeds;
4. tactical strongholds, three-choice slice, core loop, UI/debug, and live runtime boundary remain green;
5. Shared Upgrade AI and entity/deployment foundations show no regression;
6. no player-visible live UI surface in the touched owner set claims the retired numeric stronghold rewards.

## Batch A checkpoint fields

Test evidence authority: GitHub Actions runners on final P0-05B3 head

Stable IDs introduced/used: none

Runtime numeric IDs used as identity? **NO**

Territory capture touched? **NO**

Creature movement legality touched? **NO**

All spawn paths checked: unchanged from P0-04E/P0-04F

Derived states persisted as authority? **NO**

Legacy numeric stronghold reward UI promises remaining in touched live owners: **NO by contract, pending CI evidence**

Historical constants remaining: **YES — migration/golden evidence only, deferred to P0-05B5 search gate**

Save compatibility impact: **NONE**

## Next checkpoint

After P0-05B3 is green, continue to the next P0-05 legacy-cleanup checkpoint defined by the execution plan. Do not skip directly to new stronghold ability design.
