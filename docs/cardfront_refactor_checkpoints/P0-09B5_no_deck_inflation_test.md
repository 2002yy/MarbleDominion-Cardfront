# P0-09B5 No Deck Inflation Test

Source commit: `c769de1439fe9e36d73a6b7a25cc23c11e7218f2`

Decision: **GO**

Only allowed next step: **P0-10A1 - Current AI Read-Set Audit**.

## Actual authority found

- `CardfrontUpgradeManifest` is the single static upgrade-definition authority and returns detached definitions.
- `CardfrontUpgradeDeckRegistry` stores one ordered ID list per formal deck and returns a detached Array.
- `CardfrontUpgradeResolver` resolves one stable upgrade ID; it does not create or append card instances.
- `CardfrontFactionRunState.selected_upgrade_levels[id]` is the one player-facing repeated-selection counter.
- `applied_upgrade_counts[id]` remains a separate effect-history counter and is not a deck/card container.
- Draft eligibility walks the selected deck's stable ID list, and removes a selected ID only from the temporary offer-candidate Array.

There is no live runtime card-instance collection whose size grows when the same upgrade is selected. Offer definitions are detached view Dictionaries, not persistent card identities.

## Frozen proof

`CardfrontNoDeckInflationTestRunner` verifies:

1. every authored Manifest ID is unique;
2. every formal deck contains unique IDs and every ID resolves to the Manifest;
3. resolving the repeatable `volley_plus_5` ID seven times produces Selected Level 7 under one map key;
4. application history records seven applications under one separate map key;
5. Manifest IDs, deck IDs, and eligible occurrences remain unchanged;
6. mutating detached definitions or detached deck arrays cannot add a runtime identity to either registry.

No gameplay, Offer/RNG/rarity, eligibility formula, effect value, deck membership, or save schema changed in this step.

## Automated evidence

Godot `4.7.1-stable.official` focused checks against the source commit:

- No deck inflation contract - **PASS (62 checks)**
- Upgrade resolver - **PASS (36 checks)**
- Selected Level semantic separation - **PASS (16 checks)**
- Selectable decks and tactical cards - **PASS (1023 checks)**

Total: **1137 passed**, 0 failed.

The new runner is registered in the active `Headless Tests / Cardfront v0.3 core loop` workflow batch.

## Mandatory audit fields

```text
Mandatory audit gate touched: P0-09B5 stable upgrade/deck identity
Audit status: PASS
Evidence bound to source commit: YES - c769de1439fe9e36d73a6b7a25cc23c11e7218f2
Repeated selection creates runtime card instances: NO
Selected Level authority: CardfrontFactionRunState.selected_upgrade_levels[id]
Effect history authority: CardfrontFactionRunState.applied_upgrade_counts[id]
Manifest definition count changed: NO
Formal deck ID sets changed: NO
Offer/RNG/rarity/eligibility behavior changed: NO
Gameplay or save schema changed: NO
Second-authority risk introduced: NO
Manual evidence remaining before GO: NO
P1 route/reroll/deep-card content included: NO
```
