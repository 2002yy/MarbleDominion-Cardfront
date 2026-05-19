# Test Matrix / 测试矩阵

Date / 日期: 2026-05-17
Role / 作用: test-only document / 只负责测试

This file answers:

- what tests exist
- which tests are the correctness baseline
- which tests are performance probes
- what to run after a given kind of change

这份文档只回答：

- 现在有哪些测试
- 哪些属于 correctness baseline
- 哪些属于 performance probe
- 不同类型改动后应该跑哪些测试

Development progress belongs in `docs/ROADMAP.md`.  
开发进度请看 `docs/ROADMAP.md`。

Session takeover belongs in `docs/技术_technical/AI_HANDOFF_CURRENT.md`.  
交接卡片请看 `docs/技术_technical/AI_HANDOFF_CURRENT.md`。

## 1. Scene Wiring Tests / 场景接线测试

Purpose / 目的:

- verify `.tscn` scenes load
- verify required node paths stay stable
- verify setup code does not break intended layout/state

- 验证 `.tscn` 场景能正常加载
- 验证关键 node path 没被改坏
- 验证初始化逻辑不会破坏预期布局或状态

Files / 文件:

- `scripts/tests/StartMenuSceneTestRunner.gd`
- `scripts/tests/GameHUDSceneTestRunner.gd`
- `scripts/tests/EventRouletteSceneTestRunner.gd`
- `scripts/tests/SettingsPanelSceneTestRunner.gd`

Run these when / 适用时机:

- editing `.tscn`
- changing scene scripts
- changing node paths or exported scene references

- 修改 `.tscn`
- 修改场景脚本
- 修改 node path 或导出的场景引用

## 2. Coordinator And Restore Helper Tests / 协调器与恢复辅助测试

Purpose / 目的:

- verify extracted helper logic without full runtime boot
- keep `Main.gd` responsibility splits honest
- guard restore planning seams before scene-level restore runs

- 在不启动完整运行时的前提下验证 helper 逻辑
- 约束 `Main.gd` 的职责拆分不要回退
- 在场景级 restore 之前先守住 restore plan 边界

Files / 文件:

- `scripts/tests/GameStateCoordinatorTestRunner.gd`
- `scripts/tests/SaveFlowControllerTestRunner.gd`
- `scripts/tests/RestorePlanTestRunner.gd`

Run these when / 适用时机:

- splitting more logic out of `Main.gd`
- changing save/load orchestration
- changing `RestorePlan.gd`
- changing restore sequencing boundaries

- 继续从 `Main.gd` 往外拆逻辑
- 修改 save/load 编排
- 修改 `RestorePlan.gd`
- 修改 restore sequencing 边界

## 3. Smoke Test / 冒烟测试

Purpose / 目的:

- fast regression guard
- confirms major systems still behave correctly at a high level

- 快速回归守门
- 用较轻成本确认核心系统还在高层面正常工作

Files / 文件:

- `scripts/tests/SmokeTestRunner.gd`

Run this when / 适用时机:

- almost any medium-sized gameplay or system change lands

- 几乎所有中等规模的玩法或系统改动之后都应该跑

## 4. Integration Test / 集成测试

Purpose / 目的:

- medium-weight cross-system correctness
- especially save/load, battlefield rules, and win conditions

- 中等重量的跨系统正确性验证
- 重点覆盖 save/load、battlefield 规则、win condition

Files / 文件:

- `scripts/tests/IntegrationTestRunner.gd`

Run this when / 适用时机:

- touching save/load
- touching battlefield rules
- touching win-condition logic

- 修改 save/load
- 修改 battlefield 规则
- 修改 win-condition 逻辑

## 5. Layout Boundary Test / 布局边界测试

Purpose / 目的:

- verify layout profile boundaries
- catch overflow and placement regressions across supported grid sizes

- 验证 layout profile 边界
- 捕捉不同 grid size 下的越界和摆位回归

Files / 文件:

- `scripts/tests/LayoutSanityTestRunner.gd`

Run this when / 适用时机:

- changing layout profiles
- changing HUD, chamber, or map placement logic

- 修改 layout profile
- 修改 HUD、chamber 或地图摆位逻辑

## 6. Performance Probes / 性能探针

Purpose / 目的:

- measure performance and pressure behavior
- record release evidence when needed
- not a correctness test

- 观察性能与压力退化行为
- 在需要时为版本说明补性能证据
- 不属于 correctness 测试

Files / 文件:

- `scripts/tests/PerfBurstBenchmark.gd`
  - full suite
- `scripts/tests/PerfBurstBenchmarkSingleTurret.gd`
  - split single-turret half
- `scripts/tests/PerfBurstBenchmarkMultiTurret.gd`
  - split multi-turret half

Run these when / 适用时机:

- tuning firing or performance policies
- checking trail-pressure or pool-pressure changes
- collecting benchmark evidence for a version note

- 调整 firing 或 performance 策略
- 检查 trail-pressure 或 pool-pressure 改动
- 需要给版本文档补 benchmark 证据时

## 7. Test Infrastructure / 测试基础设施

Files / 文件:

- `scripts/tests/TestAssert.gd`
- `scripts/tests/TestFixtures.gd`

## 8. Active Correctness Baseline / 当前 Correctness 基线

These ten scripts are the active baseline and should normally stay green:

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

Performance probes are useful, but they are not part of the strict correctness baseline.  
性能探针很有价值，但它们不属于严格的 correctness baseline。

## 9. CI-Verified Baseline / CI 验证基线

The GitHub Actions matrix (`.github/workflows/test.yml`) runs all 10 correctness runners and passed on `2026-05-17`:

| Runner | Expected checks | CI status |
|---|---|---|
| `SmokeTestRunner.gd` | 218 | PASS |
| `SaveFlowControllerTestRunner.gd` | 190 | PASS |
| `IntegrationTestRunner.gd` | 133 | PASS |
| `LayoutSanityTestRunner.gd` | 376 | PASS |
| `StartMenuSceneTestRunner.gd` | 55 | PASS |
| `GameStateCoordinatorTestRunner.gd` | 50 | PASS |
| `GameHUDSceneTestRunner.gd` | 27 | PASS |
| `EventRouletteSceneTestRunner.gd` | 14 | PASS |
| `RestorePlanTestRunner.gd` | 11 | PASS |
| `SettingsPanelSceneTestRunner.gd` | 9 | PASS |

Total: 1083 expected checks across 10 runners.

CI status: [`.github/workflows/test.yml`](/.github/workflows/test.yml) — `Headless Tests` workflow green on `main`.

> These counts reflect the CI workflow's expected values. If a runner's assertion count changes, update the `checks` field in the matrix and this table together.

## 10. What To Run / 改动后跑什么

### If editing `.tscn` or UI wiring / 如果修改 `.tscn` 或 UI 接线

1. scene wiring tests
2. layout boundary test
3. smoke test

### If editing save/load or continue orchestration / 如果修改 save/load 或 continue 编排

1. `SaveFlowControllerTestRunner.gd`
2. `RestorePlanTestRunner.gd`
3. `IntegrationTestRunner.gd`
4. `SmokeTestRunner.gd`

### If editing restore ownership or restore sequencing / 如果修改 restore 归属或 restore 顺序

1. `RestorePlanTestRunner.gd`
2. `SaveFlowControllerTestRunner.gd`
3. `SmokeTestRunner.gd`
4. `IntegrationTestRunner.gd`

### If editing gameplay state flow / 如果修改 gameplay state flow

1. `GameStateCoordinatorTestRunner.gd`
2. `SmokeTestRunner.gd`
3. `IntegrationTestRunner.gd` if save or win flow is involved

### If adding a new gameplay feature / 如果新增玩法功能

1. the most relevant helper/scene tests
2. `SmokeTestRunner.gd`
3. `IntegrationTestRunner.gd` if rules/save/win flow changed
4. a performance probe only if the feature changes runtime pressure or rendering cost

## 11. PASS Labels / 结果标签

- `PASS`
  - assertions passed and the test exits cleanly
- `PASS with cleanup warnings`
  - assertions passed, but resource/object cleanup warnings exist on exit
- `FAIL`
  - assertion failure, script error, parse error, or incomplete run
