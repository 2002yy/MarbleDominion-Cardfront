# BallWar v2.1.11 — Encoding Recovery & Export Fixes

Date: 2026-05-17
Scope: Chinese encoding recovery, Android export ETC2/ASTC fix, build pipeline stabilization

## Version Boundary

`v2.1.11` is defined as:

- **Encoding**: recover Chinese text in 4 GD scripts corrupted by merge-conflict resolution
- **Android Export**: enable ETC2/ASTC texture compression globally + backport to all older version directories
- **Build Pipeline**: add pre-flight check/fix scripts, document export workflow
- **Foundation**: ChamberBallPhysics extraction, BulletPool swap-remove, EventRouletteController signal decoupling

In short:

`v2.1.11 = 编码恢复 + 安卓导出修复 + 构建流水线`

## Encoding Recovery

Git merge-conflict resolution (`git checkout --theirs`) corrupted UTF-8 Chinese strings in 3 files. Restored from remote.

| File | Issue | Fix |
|---|---|---|
| `Main.gd` | `"领土战争"`, `"开战！"` → garbled | Restored UTF-8 from origin/main |
| `EventRouletteController.gd` | Event description strings → garbled | Restored UTF-8 from origin/main |
| `SaveFlowController.gd` | Save status messages → garbled | Restored UTF-8 from origin/main |
| `StartMenu.gd` | Mode name replacements → garbled | Restored UTF-8 from origin/main |

## Warning Fixes

| File | Change |
|---|---|
| `SettingsPanel.gd` | Renamed conflicting constant |
| `EventRouletteController.gd` | Fixed integer division warning |

## Test Fixes

| File | Change |
|---|---|
| `StartMenuSceneTestRunner.gd` | Updated paths and text assertions |

## Android Export Fix — ETC2/ASTC

Root cause: Android target requires `textures/vram_compression/import_etc2_astc=true` in `project.godot`. Missing in 6 older version directories, causing `configuration errors` on export.

| File | Change |
|---|---|
| `project.godot` (v2.1.8+) | Added `textures/vram_compression/import_etc2_astc=true` under `[rendering]` |
| `BallWar_v1_9_13/.../project.godot` | Backfilled |
| `BallWar_v1_9_19/.../project.godot` | Backfilled |
| `BallWar_v1_9_29/.../project.godot` | Backfilled |
| `BallWar_v1_9_30/.../project.godot` | Backfilled |
| `BallWar_v2_0_1/.../project.godot` | Backfilled |
| `BallWar_v2_0_3/.../project.godot` | Backfilled |
| `BallWar_v2_0_5/.../project.godot` | Backfilled |
| `tools/check_android_export_config.ps1` | Pre-flight script |
| `tools/fix_android_export_config.ps1` | Auto-fix script |
| `docs/技术_technical/README_ANDROID_EXPORT.md` | Export troubleshooting doc |
| `EXPORT_WORKFLOW.md` | Full export workflow doc |

## Build & Release Pipeline

- All 10 releases (v0.1.0-mvp ~ v2.1.8) replanned: each gets `EXE+PCK → ZIP` + `APK`
- Windows: `embed_pck=false`, EXE+PCK bundled in ZIP
- Android: `gradle_build=false`, `package/signed=false`, debug keystore
- MVP (`v0.1.0-mvp`) tagged on first repo commit as founding record
- `archive/MarbleDominion_Godot_MVP/` added to repo

## Infrastructure (v2.1.10 → v2.1.11)

### ChamberBallPhysics Extraction

| File | Change |
|---|---|
| `scripts/ChamberBallPhysics.gd` | New: `class_name ChamberBallPhysics`, extracts ball gravity, wall clamp, peg collision, stuck detection, stay-time relaunch, gate divider, gate floor result |
| `scripts/ControlChamber.gd` | Delegates physics to `ChamberBallPhysics`; retains `pending_count`, `lock`, `jam`, `release_requested` signal |

### BulletPool Swap-Remove

| Location | Before | After |
|---|---|---|
| `BulletPool.gd` `recycle_bullet()` | `active_bullets.remove_at(idx)` (O(n) shift) | swap-remove (O(1)) |

### EventRouletteController Decoupling

| File | Change |
|---|---|
| `EventRouletteController.gd` | Private `Main` method calls replaced with signals |
| `Main.gd` | Connects to EventRouletteController signals instead of exposing private methods |

## Tests

| Test Runner | Expected |
|---|---|
| ChamberBallPhysicsTestRunner | PASS |
| SmokeTestRunner | PASS |
| IntegrationTestRunner | PASS |
| LayoutSanityTestRunner | PASS |
| SaveFlowControllerTestRunner | PASS |
| StartMenuSceneTestRunner | PASS |

---

无玩法变更。
