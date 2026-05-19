# BallWar v2.1.6 - Save Restore Bug Fix & E2E Test

Date: 2026-05-15 (estimated)
Scope: critical save/restore bug fix + end-to-end continue test + minor data fixes

## Version Boundary

`v2.1.6` is defined as:

- bug fix: `SaveStateApplier.apply_factions` incorrectly unlocked chambers
- bug fix: garbled Chinese string in `SaveGameCodec` error messages
- data fix: faction names now use `GameConfig.faction_name()` everywhere
- new test: `EndToEndContinueMainTestRunner.gd` (full Main.gd save→exit→continue cycle)

In short:

`v2.1.6 = 修复存档恢复导致控制仓状态丢失 + 端到端继续游戏测试`

## Critical Bug: SaveStateApplier Chamber Unlock

### Symptom

After save→exit→continue, chambers that were saved as `locked=true` with
`pending_count > 1` would be restored as `locked=false` with `pending_count = 1`.

### Root Cause

`SaveStateApplier.apply_factions()` (`SaveStateApplier.gd:40`) had this logic
after restoring each faction:

```gdscript
if chambers[faction_id].is_locked and turrets[faction_id].burst_remaining <= 0:
    on_chamber_unlock.call(chambers[faction_id])
```

`ControlChamber.restore_from_state()` correctly restored `is_locked = true`
(line 483), but the turret's `burst_remaining` was `0` because no burst was
in progress. Both conditions (`is_locked = true` AND `burst_remaining <= 0`)
were true, so the chamber was **immediately unlocked**.

When `ControlChamber.set_locked(false)` runs (`ControlChamber.gd:565`), it
resets `pending_count = 1` as a side effect (line 572). This destroyed all
saved pending bullet counts.

### Fix

Added `chamber.locked_remaining > 0` as a guard condition:

```gdscript
if chamber.is_locked and chamber.locked_remaining > 0 and turret.burst_remaining <= 0:
    on_chamber_unlock.call(chamber)
```

Now the unlock only fires when:
1. The chamber is locked (`is_locked = true`)
2. A burst WAS in progress (`locked_remaining > 0`)
3. The burst has now completed (`burst_remaining <= 0`)

Chambers saved as locked without an active burst (the common case) are no
longer incorrectly unlocked.

### Impact

This bug affected **every** save→exit→continue cycle. Any chamber that was
locked at save time (regardless of reason) would lose its locked state and
pending count on restore. P2 and P3 tests in the new E2E runner would have
caught this earlier.

## Garbled String Fix

`SaveGameCodec.gd:87` had a corrupted UTF-8 string in the error message:

```
# Before (garbled):
clean["_invalid_reason"] = "瀛樻。鐗堟湰涓嶅吋瀹癸細%s" % version

# After (correct):
clean["_invalid_reason"] = "存档版本不兼容：%s" % version
```

This affected player-facing error messages when loading incompatible save
files. Low risk, high impact fix.

## Faction Name Unification

`EventRouletteController._faction_display_name()` previously hardcoded
faction names as `"蓝方"`, `"红方"`, `"绿方"`, `"黄方"`. Similarly,
the `faction_items` array in event payloads was hardcoded.

Now both use `GameConfig.faction_name(faction_id)`, which respects the
active palette. For example, with the "霓虹" palette, factions display
as `"青方"`, `"粉方"`, `"荧方"`, `"金方"` in event wheels and logs.

| Palette | Faction Names |
|---|---|
| 经典 | 蓝方 / 红方 / 绿方 / 黄方 |
| 霓虹 | 青方 / 粉方 / 荧方 / 金方 |
| 糖果 | 莓方 / 桃方 / 糖方 / 蜜方 |
| 暗夜 | 靛方 / 赤方 / 森方 / 铜方 |
| 薄荷 | 海方 / 莓方 / 荷方 / 杏方 |

Added `_faction_item_names()` helper that builds the wheel display array
from `GameConfig.faction_name()` for all four factions.

## New Test: EndToEndContinueMainTestRunner

`scripts/tests/EndToEndContinueMainTestRunner.gd` — 55 checks

This is the first test that exercises the **full Main.gd** save→exit→continue
cycle, not just individual components.

### P1 — Full save → exit → continue cycle (OCCUPATION / 20×20)

1. Create Main, start game with OCCUPATION mode
2. Modify battlefield ownership (6 cells captured)
3. Reduce turret health (all 4 turrets −5 hp)
4. Lock RED chamber with `pending_count = 12`
5. Damage BLUE chamber
6. Set `game_elapsed_time = 142.0`
7. Save to slot → verify write succeeded
8. Exit to menu → verify cleanup
9. Continue saved game
10. Assert:
    - Grid ownership matches pre-save (all 4 factions)
    - Turret health matches pre-save (all 4 turrets)
    - RED `pending_count = 12`, `is_locked = true`
    - BLUE `is_damaged = true`
    - `GameConfig.get_game_mode_name() == OCCUPATION`

### P2 — Save file structure (WILD / 10×10)

1. Start game in WILD mode
2. Capture first row of cells (BLUE)
3. Save and read back raw data
4. Assert:
    - `save_version = "2.0.0"`
    - `game_mode_name = "狂野模式"` (WILD)
    - `quality_name = "中"` (MEDIUM)
    - `grid_size = 10`
    - `owners`, `factions`, `event_state`, `bullets` all present
    - 4 factions with valid `faction_id`, `chamber_pending_count`, `turret_health`

### P3 — Continue restores gametime + chamber pending + events

1. Start game, modify chamber pending_counts, set `game_elapsed_time = 215.5`
2. Set event countdown to 38.0, last faction to YELLOW, last effect to X2
3. Save → exit → continue
4. Assert:
    - `game_elapsed_time` restored within ±0.5 sec
    - All 4 chamber `pending_count` values match pre-save
    - Event countdown restored
    - `last_event_faction` and `last_event_effect` match
    - Event roulette still enabled

## Files Changed

| File | Change |
|---|---|
| `scripts/SaveStateApplier.gd` | Fixed chamber unlock guard: added `locked_remaining > 0` condition |
| `scripts/SaveGameCodec.gd` | Fixed garbled UTF-8 string `存档版本不兼容` |
| `scripts/EventRouletteController.gd` | `_faction_display_name()` → `GameConfig.faction_name()`; added `_faction_item_names()` |
| `scripts/tests/EndToEndContinueMainTestRunner.gd` | New file: 55 checks, 3 test groups |

## Tests

| Test Runner | Checks | Status |
|---|---|---|
| EndToEndContinueMainTestRunner (NEW) | 55 | PASS |
| SmokeTestRunner | 60 | PASS |
| SaveFlowControllerTestRunner | 84 | PASS |
| IntegrationTestRunner | 133 | PASS |
| LayoutSanityTestRunner | 376 | PASS |
| GameHUDSceneTestRunner | 28 | PASS |
| StartMenuSceneTestRunner | 37 | PASS |

**Total: 773 checks across 7 test suites.**
