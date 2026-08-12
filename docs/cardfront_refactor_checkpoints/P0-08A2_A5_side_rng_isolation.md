# P0-08A2-A5 Per-Side Draft RNG Isolation

Source commit: `a36c54cf29410c6adcd85433d80d7265f9359095`

Decision: **GO**

Only allowed next step: **P0-08B1 — Side Context Envelope**.

## Result

One `CardfrontUpgradeDraftSystem` remains the single Draft rules implementation, but it now owns deterministic RNG state per duel side:

```text
DraftSystem
  PLAYER_FACTION -> player RNG
  AI_FACTION -> AI RNG
```

The existing `set_seed_for_tests(master_seed)` path remains valid through `DraftSystem.set_seed()`. It deterministically derives Player and AI seeds with fixed integer salts; it does not depend on dictionary iteration, system time, or object identity. `set_side_seed_for_tests(owner_id, seed)` is available for focused invariance tests.

`draw_three`, `draw_offer`, `draw_offer_ids`, weighted selection, and `choose_timeout_fallback` now receive side identity. The RoundDirector explicitly passes the correct owner for both offers and timeout fallback. There is no remaining global `_rng` consumer.

Draw and fallback for the same side deliberately share one side stream. P0 does not introduce separate purpose streams.

## Invariance and isolation evidence

`CardfrontDraftSideRngIsolationTestRunner.gd` proves:

- equal master seeds deterministically reproduce each side's offer;
- Player->AI and AI->Player draw order yields identical per-side offers;
- an extra Player draw does not change the next five AI offers;
- a Player timeout fallback does not change the next five AI offers;
- extra AI draw and fallback consumption do not change the next five Player offers;
- same-side fallback advances that side's same RNG stream.

## Frozen semantics retained

- formal deck remains `core_tactics` with the same 18 IDs;
- eligibility predicates are unchanged;
- base rarity weights remain `100 / 42 / 12` with the same rarity-level adjustment;
- formal default/max Offer remains `3 / 3`;
- IDs remain unique within one Offer;
- timeout fallback still returns a current-Offer deep copy;
- empty timeout Offer remains safe;
- no cross-side exclusivity, reroll, route card, rarity rebalance, or purpose stream was added.

## Evidence

- side RNG isolation — **PASS (20 checks)**;
- upgrade content — **PASS (115 checks)**;
- selectable deck semantics — **PASS (1023 checks)**;
- match phase — **PASS (21 checks)**;
- formal three-choice runtime — **PASS (58 checks)**;
- P0-07 lifecycle regression — **PASS (170 checks)**.

Total assertions: **1,407 passed**.

## Mandatory audit fields

```text
Mandatory audit gate touched: P0-08A Per-side RNG Streams
Audit status: PASS
Evidence bound to source commit: YES — a36c54cf29410c6adcd85433d80d7265f9359095
One DraftSystem rules implementation retained: YES
Player RNG isolated: YES
AI RNG isolated: YES
Master-seed compatibility retained: YES
Fixed stable seed derivation: YES
Draw-order invariance: PASS
Cross-side draw isolation: PASS
Cross-side fallback isolation: PASS
Same-side draw/fallback share one stream: YES
Eligibility changed: NO
Rarity changed: NO
Offer size changed: NO
Reroll/route/P1 behavior added: NO
Gameplay rules changed beyond RNG ownership: NO
Manual/video evidence required before GO: NO
```
