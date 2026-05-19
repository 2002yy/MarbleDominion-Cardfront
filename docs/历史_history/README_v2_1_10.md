# BallWar v2.1.10 — Security & Performance Hardening

Date: 2026-05-16
Scope: save-system security hardening, performance-path optimization, start-menu UI clarity

## Version Boundary

`v2.1.10` is defined as:

- **Security**: save file size limit (1MB), path traversal filter, nested array field validation
- **Performance**: Turret O(n²) queue total → O(1), `has_method()` cache, `_cached_map_size`, `keys()` → direct iteration, `find()+remove_at()` → `erase()`, `priority` Dictionary → `const`
- **UI**: StartButton prominence, text contrast, ModeTipLabel brightness
- **Export**: all Windows releases switched from `embed_pck=true` (unstable) to `.exe+.pck` zip bundle
- **Packaging**: `export_presets.cfg` `embed_pck=false` for all version directories

In short:

`v2.1.10 = 安全加固 + 性能优化 + 开始菜单UI改进`

## Security Fixes

### Save File Size Limit

| File | Change |
|---|---|
| `SaveFlowController.gd` | Added `MAX_SAVE_FILE_BYTES: int = 1 * 1024 * 1024`. `_read_save_dictionary()` checks `file.get_length()` before reading, rejects files > 1MB or empty. |

### Path Traversal Prevention

| File | Change |
|---|---|
| `SaveFlowController.gd` | `get_save_path()` filters `..` and `~` from slot template to prevent directory escape. |

### Save Data Validation

| File | Change |
|---|---|
| `SaveGameCodec.gd` | `validate_save_data()` now validates `queued_round_modifiers` entries are Dictionary with `effect`/`duration` fields, type-safe conversion. `control_balls` validates each has `position`/`velocity`/`radius`/`stay_time` with type-safe conversion. |

## Performance Fixes

### Turret.gd — O(n²) → O(1)

| Location | Before | After |
|---|---|---|
| `_current_total_queue()` | Iterated `all_turrets` values every call (O(n) per turret × n turrets = O(n²)) | Uses `bullet_container.get_tracked_queue_total()` (O(1) from BulletPool's signal-tracked `tracked_queue_total`) |
| `_spawn_bullet()` | Called `bullet_container.has_method("spawn_bullet")` every bullet | Uses cached `_bullet_container_can_spawn` bool set once in `setup()` |

`BulletPool.gd` already maintains `tracked_queue_total` via `_on_tracked_turret_burst_progress` signal, updated incrementally.

### Bullet.gd — Cached Map Size

| Location | Before | After |
|---|---|---|
| `_physics_process()` | `float(battlefield.grid_size) * float(battlefield.cell_size)` every frame | Uses `_cached_map_size: float` set in `setup()`, with zero-value fallback |

### Bullet.gd — Avoid Array Allocation

| Location | Before | After |
|---|---|---|
| `_try_hit_enemy_turret()` | `for target_faction_id in target_turrets.keys()` (allocates new Array) | `for target_faction_id in target_turrets` (direct Dictionary iteration) |

### BulletPool.gd — Single-Pass Erase

| Location | Before | After |
|---|---|---|
| `recycle_bullet()` | `active_bullets.find(bullet)` + `active_bullets.remove_at(idx)` (two O(n) passes) | `active_bullets.erase(bullet)` (single O(n) pass) |

### BulletPool.gd — Const Dictionary

| Location | Before | After |
|---|---|---|
| `_prefer_reason()` | `var priority: Dictionary = {...}` allocated per call | Class-level `const PRIORITY: Dictionary` allocated once |

## UI Fixes

### StartMenu.tscn / StartMenu.gd

| Change | Detail |
|---|---|
| StartButton layout | Moved from ConfigRow2 to its own full-width row as direct child of ConfigVBox |
| StartButton size | 0×42 (was 140×32), font size 20 (was 15), brighter blue `Color(0.22, 0.65, 1, 1)` |
| StartButton text | "开始新游戏（槽%d）" (was "新局覆盖槽%d") |
| ModeTipLabel | Brighter color `Color(0.9, 0.94, 1, 1)`, font size 14 |
| MobileHint | Brighter color `Color(0.82, 0.9, 1, 1)` |
| SaveTitle | Brighter color `Color(0.88, 0.94, 1, 1)` |

## Export Packaging

All Windows Desktop releases for past versions re-packaged from single-file `embed_pck=true` (unstable with "Couldn't load project data" errors) to `.exe+.pck` zip bundle:

- `BallWar_v<version>.exe` + `BallWar_v<version>.pck` bundled in `BallWar_v<version>.zip`
- `export_presets.cfg` set to `application/binary_format/embed_pck=false` consistently
- Uploaded to GitHub Releases as asset replacement for all 10 affected versions

## Tests

| Test Runner | Expected |
|---|---|
| StartMenuSceneTestRunner | PASS |
| GameHUDSceneTestRunner | PASS |
| EventRouletteSceneTestRunner | PASS |
| SettingsPanelSceneTestRunner | PASS |
| GameStateCoordinatorTestRunner | PASS |
| SaveFlowControllerTestRunner | PASS |
| RestorePlanTestRunner | PASS |
| SmokeTestRunner | PASS |
| IntegrationTestRunner | PASS |
| LayoutSanityTestRunner | PASS |
