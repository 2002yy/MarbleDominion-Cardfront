# P0-08B1-B3 Side Context and Offer Independence

Source commit: `07dc91e76587e95384b9c561f0d2a74f04b29689`

Decision: **GO**

Only allowed next step: **P0-08C — Stronghold Cutover Interaction Audit**.

## B1 — Side Context Envelope

`CardfrontDraftOfferContext` is the minimal P0 container:

```text
owner_id
run_state
deck_id
```

It resolves the existing run state's deck through `CardfrontUpgradeDeckRegistry` and exposes a read-only snapshot containing only owner and deck identity. It has no route, profession, behavior, reroll, dominance, or other P1 fields.

Legacy Draft APIs remain compatibility wrappers. They construct a context and delegate to `draw_offer_for_context()` / `draw_offer_ids_for_context()`. The formal `RoundDirector` explicitly creates Player and AI contexts. There is still one DraftSystem and one Manifest authority, not separate Player/AI implementations.

## B2 — Offer Container Independence

Runtime evidence confirms:

- Player and AI Offer arrays are different objects even when contents match;
- each definition and nested `params` dictionary is independently deep copied;
- mutating Player view data does not change AI view data;
- mutating either view does not alter the Manifest authority;
- `RoundDirector.get_player_offer()` and `get_ai_offer()` return deep copies and do not expose authoritative mutable arrays or nested dictionaries.

## B3 — Coincidental Overlap Preserved

With equal explicit side seeds, Player and AI can receive identical three-card Offers. This is expected and tested. No cross-side exclusion, pool subtraction, forced rarity difference, category difference, or “never collide” rule exists.

## Frozen semantics retained

- eligibility and rarity weights unchanged;
- formal Offer size remains three;
- side RNG isolation remains intact;
- timeout fallback semantics unchanged;
- no reroll, route unlock, profession, or new gameplay field introduced.

## Evidence

- Offer context/container/overlap — **PASS (17 checks)**;
- side RNG isolation — **PASS (20 checks)**;
- upgrade content — **PASS (115 checks)**;
- selectable deck semantics — **PASS (1023 checks)**;
- formal three-choice runtime — **PASS (58 checks)**;
- P0-07 lifecycle regression — **PASS (170 checks)**.

Total assertions: **1,403 passed**.

## Mandatory audit fields

```text
Mandatory audit gate touched: P0-08B Per-side Offer Context / Containers
Audit status: PASS
Evidence bound to source commit: YES — 07dc91e76587e95384b9c561f0d2a74f04b29689
RoundDirector remains orchestration owner: YES
Single DraftSystem retained: YES
Minimal side context: YES
P1 fields absent: YES
Player and AI arrays independent: YES
Nested definition dictionaries independent: YES
Getters return deep copies: YES
Manifest remains definition authority: YES
Coincidental overlap allowed: YES
Cross-side exclusion added: NO
Eligibility/rarity/Offer size changed: NO
Gameplay expanded: NO
Manual/video evidence required before GO: NO
```
