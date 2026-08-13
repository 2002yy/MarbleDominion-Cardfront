# P0-09B3 Offer / View Data Level Projection

Source commit: `32ce9af20cd213993acdee1fd9cc0f422a2201c7`

Decision: **GO**

Only allowed next step: **P0-09B4 - Minimal Player-Facing Level Feedback**.

## Projection contract

`CardfrontUpgradeOfferView.project()` builds detached Offer/View data from:

```text
static manifest definition
+ side run-state get_selected_upgrade_level(upgrade_id)
```

Each projected definition contains:

```text
current_level
next_level
```

`current_level` is the side's successful-selection Level. `next_level` is the Level after one successful selection. A missing run state safely projects `0 -> 1`.

The projection never reads `applied_upgrade_counts`. Echo-inclusive application history therefore cannot appear as player-facing Level.

## Offer and runtime behavior

`CardfrontUpgradeDraftSystem.draw_offer_for_context()` retains the existing ID draw, eligibility, rarity weight, RNG, three-choice, and Player/AI isolation behavior. It only replaces raw definition copies with detached projected definitions after IDs are selected.

Player and AI can receive the same upgrade ID while seeing Levels from their own run states. Timeout fallback retains the projected fields and remains detached from the current Offer array.

The live ThreeChoice panel receives the projected dictionaries through the existing `draft_opened` signal and choice-card `setup()` call. P0-09B3 does not add player-facing Level text; that is locked to P0-09B4.

## Static authority

`CardfrontUpgradeManifest.DEFINITIONS` remains static. Neither `current_level` nor `next_level` is written to Manifest data. Top-level and nested mutations to projected definitions cannot mutate Manifest or the opposite side's Offer.

## Evidence

- Offer/View Level projection - **PASS (35 checks)**;
- Offer isolation and deep-copy contract - **PASS (22 checks)**;
- upgrade content / eligibility / deterministic offers - **PASS (115 checks)**;
- formal ThreeChoice runtime - **PASS (59 checks)**;
- Draft lifecycle snapshot - **PASS (170 checks)**;
- Selected Level save contract - **PASS (13 checks)**.

Total assertions: **414 passed** under Godot `4.7.1-stable`.

## Mandatory audit fields

```text
Mandatory audit gate touched: P0-09B3 Offer / View Data Level Projection
Audit status: PASS
Evidence bound to source commit: YES - 32ce9af20cd213993acdee1fd9cc0f422a2201c7
Level projection authority: selected_upgrade_levels through get_selected_upgrade_level()
Effect application/history read by projection: NO
Manifest definition mutated: NO
Player and AI Level reads isolated: YES
Offer ID/RNG/eligibility behavior changed: NO
Timeout fallback retains projected data: YES
Live choice cards receive projected data: YES
Player-facing Level text added: NO - locked to P0-09B4
Save/restore changed: NO
Gameplay effects changed: NO
P1 route/reroll/deep-card content included: NO
Manual/video evidence required before GO: NO
```
