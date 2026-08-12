# P0-09A0-A3 Level Authority Foundation

Source commit: `acd9618ee26f1feff9f6dd69f99b23785eeacf83`

Decision: **GO**

Only allowed next step: **P0-09A4 — Echo Contract**.

## A0 — Corrected assumption

Source audit confirms `applied_upgrade_counts` is incremented for both a side's resolved selection and an automatic Echo replay. It therefore remains effect application/history compatibility data and is not player-facing Level authority.

The compatibility `record_upgrade()` method remains available for existing callers, but delegates only to the explicitly named effect-application recorder. It must not be interpreted as Level.

## A1 — Frozen semantics

```text
Selected Level
= number of successful Draft selections of this upgrade by this side

Effect Application Count
= number of actual effect applications, including Echo/repeat
```

## A2 — Authoritative store

`CardfrontFactionRunState.selected_upgrade_levels` is the sole runtime store for player-facing Level. The public read boundary is `get_selected_upgrade_level()`.

`applied_upgrade_counts` remains the compatibility/history store. The public semantic read boundary is `get_effect_application_count()`.

This stage intentionally does not serialize the new store, project it into Offer/view data, or render UI feedback. Those changes are separately locked to P0-09B2, B3, and B4.

## A3 — Singular increment point

There is exactly one production call to `record_selected_upgrade_resolved()`:

```text
CardfrontUpgradeResolver.resolve()
 -> selected definition applies successfully
 -> effect application history +1
 -> Selected Level +1
```

Echo replay runs before that selected-definition branch and records only an effect application. Draw, failed resolution, direct compatibility/history recording, visual setup, save/restore, and AI evaluation cannot increment Selected Level.

## Evidence

- upgrade resolver/Level authority — **PASS (31 checks)**;
- upgrade content and eligibility regression — **PASS (115 checks)**;
- selectable deck regression — **PASS (1,023 checks)**;
- shared marginal-value policy regression — **PASS (43 checks)**;
- B1 model consistency — **PASS (229 checks)**;
- Draft lifecycle regression — **PASS (170 checks)**;
- formal three-choice runtime — **PASS (59 checks)**.

Total assertions: **1,670 passed** under Godot `4.7.1-stable`.

Godot editor parse/import check exited `0`. The editor also emitted pre-existing missing `.uid` and `core/io/file_access.cpp:967` warnings; they are not claimed as resolved by this checkpoint. Generated import/cache metadata was removed from the scoped diff.

## Mandatory audit fields

```text
Mandatory audit gate touched: P0-09A0-A3 Duplicate -> Level Authority
Audit status: PASS
Evidence bound to source commit: YES — acd9618ee26f1feff9f6dd69f99b23785eeacf83
Selected Level authority: selected_upgrade_levels
Effect application/history authority: applied_upgrade_counts
Production Selected Level increment call sites: 1
Successful direct selection increments Level: YES
Failed resolve increments Level: NO
Direct history recording increments Level: NO
Echo replay increments application count: YES
Echo replay increments Selected Level: NO
Snapshot/restore migration included: NO — locked to P0-09B2
Offer/view projection included: NO — locked to P0-09B3
Player-facing UI included: NO — locked to P0-09B4
Card balance/numeric tracks changed: NO
Gameplay expanded: NO
Manual/video evidence required before GO: NO
```
