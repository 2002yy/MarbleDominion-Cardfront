# P0-08C Stronghold Cutover Interaction

Source commit: `735f2e24bb3300d54604ae9ed40b4ed9696c9322`

Decision: **GO**

Only allowed next step: **P0-09A0-A3 — Level Authority semantics, storage, and singular increment point**.

## Audit result

The formal Draft remains fixed at three choices after the P0-05B Stronghold cutover:

- `CardfrontDraftOfferContext` contains owner, run-state reference, and deck identity only;
- Stronghold status, active Stronghold types, and retired `draft_choice_count` are absent from the Offer context;
- both Player and AI stale four-choice requests are capped to three by the Draft consumer;
- with Factory, Energy, and Lab all active for Player, the live Player Offer, live AI Offer, and visible Player panel all remain three-choice;
- Lab remains an observable Stronghold identity/status only;
- no route, profession, reroll, rarity, eligibility, or Draft cadence behavior changed.

The Draft constant comment was corrected to describe the current compatibility boundary. It no longer implies that a live Stronghold producer still emits `draft_choice_count = 4`.

## Runtime evidence

- Offer context and cutover boundary — **PASS (22 checks)**;
- side RNG isolation — **PASS (20 checks)**;
- Stronghold status system — **PASS (2,388 checks)**;
- formal three-choice runtime — **PASS (59 checks)**;
- P0 golden baseline — **PASS (39 checks)**.

Total assertions: **2,528 passed** under Godot `4.7.1-stable`.

## Mandatory audit fields

```text
Mandatory audit gate touched: P0-08C Stronghold Cutover Interaction
Audit status: PASS
Evidence bound to source commit: YES — 735f2e24bb3300d54604ae9ed40b4ed9696c9322
Formal Offer size: 3
Player runtime Offer with all Strongholds active: 3
AI runtime Offer with Player Strongholds active: 3
Visible Player choice cards: 3
Stale four-choice request accepted: NO
Stronghold fields present in Offer context: NO
Lab identity remains observable: YES
Lab gameplay bonus restored: NO
Eligibility/rarity/cadence changed: NO
Gameplay expanded: NO
Manual/video evidence required before GO: NO
```
