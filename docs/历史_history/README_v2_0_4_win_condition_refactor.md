# BallWar v2.0.4 — Win Condition Refactor

日期: 2026-05-04

## 目标

纯逻辑解耦，不加新玩法。不改事件规则、子弹数、中文编码、存档版本号。

## 新增文件

- `scripts/WinConditionEvaluator.gd` — 胜负判断纯逻辑，零依赖 UI/渲染/物理

## 修改文件

- `scripts/Main.gd` — `_check_winner()` 改为调用 `WinConditionEvaluator.evaluate()`
- `scripts/tests/IntegrationTestRunner.gd` — 新增 5 项 WCE 专项测试
- `AI_HANDOFF_CURRENT.md` — 更新 v2.0.4 状态

## 未修改文件

- `scripts/Battlefield.gd`
- `scripts/BulletPool.gd`
- `scripts/BulletTrailLayer.gd`
- `scripts/ControlChamber.gd`
- `scripts/ControlBall.gd`
- `scripts/EnergyButton.gd`
- `scripts/EventRouletteController.gd`
- `scripts/EventRouletteView.gd`
- `scripts/SaveGameCodec.gd`
- `scripts/GameConfig.gd`
- `scripts/Gate.gd`
- `scripts/Turret.gd`
- `scripts/Bullet.gd`
- `scripts/LayoutProfiles.gd`
- `scripts/GameHudView.gd`
- `scripts/StartMenuView.gd`
- `scripts/BannerController.gd`
- `scripts/GameSceneBuilder.gd`
- `scripts/UIAnimationController.gd`
- `scripts/UIFactory.gd`
- `scripts/MenuDecor.gd`
- `scripts/HudBadge.gd`
- `scripts/RuntimeHudController.gd`
- `scripts/tests/SmokeTestRunner.gd`
- `scripts/tests/PerfBurstBenchmark.gd`
- `scripts/tests/TestAssert.gd`
- `scripts/tests/TestFixtures.gd`

## 重构内容

`Main.gd._check_winner()` 保留为编排层，胜负判断抽到 `WinConditionEvaluator.gd`。

Main.gd 继续负责：
- `is_game_over` 状态管理
- banner 展示 (`_finish_with_winner` / `_finish_as_draw`)
- 所有 UI/场景编排

WinConditionEvaluator 负责（纯函数）：
- `evaluate_basic(turrets)` — 最后存活/全灭
- `evaluate_occupation(counts, total_cells, target_percent)` — 75% 占领
- `evaluate_timed(counts, time_expired)` — 时间结束计分
- `evaluate(mode, turrets, counts, cells, time_expired)` — 四个模式分派

返回结构（5 字段固定）：
```gdscript
{ended: bool, winner: int, draw: bool, sub_text: String, reason: String}
```

旧 helper `_get_occupation_winner` / `_get_score_winner` 保留在 Main.gd，加 `# Deprecated after v2.0.4` 注释，待 v2.0.5+ 确认稳定后清理。

## 验证结果

```
SmokeTestRunner       PASS 33 checks
IntegrationTestRunner PASS 128 checks
PerfBurstBenchmark    not run (logic-only refactor, not required)
```

## 注意事项

- 本轮没有修改 save version，沿用 1.9 主版本兼容策略
- 本轮没有修改中文编码
- 本轮没有删除 Gate.gd
- 本轮没有修改 BulletPool / TrailPressure / Layout 任何代码
