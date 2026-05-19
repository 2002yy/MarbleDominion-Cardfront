# AI_HANDOFF_CURRENT

Last updated: 2026-05-19
Role / 作用: handoff card only / 仅作快速接管卡片

## 1. Current Version / 当前版本

- Current line: `v2.1.x`
- Latest documented milestone: `v2.1.9`
- Last stable structural baseline: `v2.1.4`
- Current theme:
  - settings system + result panel + statistics
  - decor-layer event-driven cleanup
  - chamber-state extraction
  - repo entrance and history-doc cleanup

## 2. Current Status / 当前状态

- `SaveFlowController` owns the `prepare_*` vs `apply_*` split for continue flow.
- `RestorePlan.gd` is in the active restore path.
- `ControlChamber.gd`, `Turret.gd`, and `Bullet.gd` own `restore_from_state(...)`.
- `Main.gd` stays at top-level sequencing and should keep shrinking away from deep restore mutation, deep event logic, and draw/physics details.
- `BattlefieldDecorLayer.gd` is event/dirty-flag driven instead of per-frame polled.
- `ChamberState.gd` is extracted as a pure state container.
- `EventRouletteController.gd` now emits UI requests by signal instead of calling `Main` private helpers directly.
- `GameSceneBuilder.gd` has an explicit owner callback contract comment; treat it as the current runtime interface seam.
- `PlayerSettingsStore.gd`, `SettingsPanel`, and `ResultPanel` are wired into the active product flow.

## 3. Just Completed / 刚完成的内容

- refreshed root `README.md` so it describes the current `v2.1.x` line instead of treating `v2.1.4` as the latest version
- moved all stage reports from root `README_v*.md` into `docs/history/`
- compressed `CHANGELOG.md` into a true milestone spine
- aligned live docs so the repo root keeps only current-truth documents

## 4. Next Steps / 下一步

1. Keep Release naming, README wording, and milestone docs aligned as `v2.1.x` continues.
2. When performance evidence is needed, run and archive:
   - `scripts/tests/PerfBurstBenchmark.gd`
   - `scripts/tests/PerfBurstBenchmarkSingleTurret.gd`
   - `scripts/tests/PerfBurstBenchmarkMultiTurret.gd`
3. Continue shrinking `ControlChamber` and `Main.gd` without pushing deep restore mutation, event-effect details, or draw/physics logic back into `Main.gd`.
4. If more history notes are added, place them under `docs/history/` instead of the repo root.

## 5. Do Not Do / 不要做什么

- do not turn this file into a roadmap or architecture diary
- do not put roadmap content into `docs/technical/README_TEST_MATRIX.md`
- do not claim performance validation is complete unless there is either:
  - a recorded probe result, or
  - a clearly labeled manual observation
- do not move deep restore-field mutation back into `Main.gd`
- do not add new direct controller-to-`Main` private method calls when a signal seam is sufficient
- do not treat `docs/history/README_v*.md` as the current source of truth; they are stage records

## 6. Required Tests / 当前必跑测试

Current active correctness baseline:

- `StartMenuSceneTestRunner.gd`
- `GameHUDSceneTestRunner.gd`
- `EventRouletteSceneTestRunner.gd`
- `SettingsPanelSceneTestRunner.gd`
- `GameStateCoordinatorTestRunner.gd`
- `SaveFlowControllerTestRunner.gd`
- `RestorePlanTestRunner.gd`
- `SmokeTestRunner.gd`
- `IntegrationTestRunner.gd`
- `LayoutSanityTestRunner.gd`

Cardfront baseline:
- `FortifyLayerTestRunner.gd`
- `CardCoreLiteTestRunner.gd`
- `DeploymentRulesTestRunner.gd`
- `EconomyTickTestRunner.gd`
- `RegionMapTestRunner.gd`
- `CardfrontModeSmokeTestRunner.gd`
- `NeutralOwnerCompatibilityTestRunner.gd`

Latest documented broader baseline:

- `SettingsAndResultTestRunner.gd`
- `EndToEndContinueMainTestRunner.gd`
- plus the correctness baseline above when the touched area warrants it

Performance probes are separate from correctness:

- `PerfBurstBenchmark.gd`
- `PerfBurstBenchmarkSingleTurret.gd`
- `PerfBurstBenchmarkMultiTurret.gd`

## 7. Canonical Docs / 主文档分工

- `docs/technical/AI_HANDOFF_CURRENT.md`
  - quick takeover card for the next AI / Codex session / 下一次 AI/Codex 快速接管卡
- `README.md`
  - current project entrypoint / 项目入口
- `docs/ROADMAP.md`
  - main progress board and development direction / 进度板与开发方向
- `docs/TESTING.md`
  - test ownership, baseline, and run guidance / 测试职责、基线和运行建议
- `docs/technical/TECHNICAL_GUIDE.md`
  - current architecture, editor, validation, and repo-boundary rules / 架构、编辑器协作、验证规则
- `CHANGELOG.md`
  - condensed version spine / 精简版本脊柱
- `docs/history/README.md`
  - historical stage index / 历史阶段索引
