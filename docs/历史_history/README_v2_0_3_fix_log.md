# v2.0.3 IntegrationTestRunner 修复过程记录

日期: 2026-05-04

## 概述

本轮 v2.0.3 目标是补强测试基础设施，不修改玩法代码。新增 `TestAssert.gd`、`TestFixtures.gd`，重构 `IntegrationTestRunner.gd`，覆盖存档校验、战场规则和胜负条件。

从"临时能跑"升级到"可维护、可解释"。

---

## 修复 1: `true` 方法名与 GDScript 关键字冲突

**现象**: `TestAssert.gd` 中 `_assert.true(...)` 触发解析错误。

**根因**: `true` 是 GDScript 布尔关键字，不可用作方法名。

**修复**: 重命名为 `that(condition, message)`。

**结果**: 解析通过。

---

## 修复 2: Node 不能动态设置属性

**现象**: 测试中用 `Node.new()` 模拟炮塔，`node.is_destroyed = true` 在 Godot 4.6 报错。

**根因**: Godot Node 不支持动态属性添加。

**修复**:
- 初版：改为 `Dictionary {"is_destroyed": bool}` mock
- 终版：`TestFixtures` 内定义 `class MockTurret`，字段 `faction_id: int` + `is_destroyed: bool`，`make_mock_turrets()` 返回 `Array[MockTurret]`。`_basic_winner()` 检查 `turret is MockTurret and not turret.is_destroyed`。

**结果**: Mock 对象行为接近真实 `Turret.gd`，不会在未来 GDScript 版本中因 Node 限制失效。

---

## 修复 3: faction 数组顺序必须按 `faction_id` 排列

**现象**: 存档 faction state 测试中 RED 的字段断言错误（`chamber_jammed_time_left` 预期 2.5 得到 0.0）。

**根因**: `SaveGameCodec` 原样保留 faction 数组顺序。测试最初按 `RED / BLUE / GREEN / YELLOW` 排列（索引 0=RED），但 `GameConfig.Faction` 的顺序是 `BLUE=0, RED=1, GREEN=2, YELLOW=3`。因此 `factions[GameConfig.Faction.RED]`（即 `factions[1]`）实际取到了 BLUE 的数据。

**修复**: 测试数据改为 `BLUE[0], RED[1], GREEN[2], YELLOW[3]` 顺序，与 `GameConfig.Faction` 枚举一致。

**结果**: faction state round-trip 断言恢复正常。

---

## 修复 4: `uniform_paint()` 先清场再精确铺量

**现象**: occupation 测试中，明明 paint 了 300 格给 BLUE，`count_cells_by_team()` 却显示 BLUE 仅 100 格。

**根因**: 有两层问题：
1. `uniform_paint()` 达目标格数后 `return` 跳过了 `rebuild_owner_counts()`
2. 依赖 `reset_quadrants()` 的初始四象限分配，paint 数量与原有归属叠加，测试语义不清

**修复**:
- 将 `uniform_paint()` 拆为两个语义明确的函数：
  - `fill_battlefield(bf, faction_id)` — 全场清空到指定阵营
  - `paint_first_cells(bf, faction_id, target_cells)` — 按顺序铺 N 个格
- 增加底层安全写 `set_owner_cell_raw(bf, x, y, faction_id)`，行级写回 `owners[x]`，匹配 `Battlefield.gd` 的 `owners[cell.x][cell.y]` 访问方向
- occupation 测试改为：`fill(RED)` → `paint_first(BLUE, target)`

**结果**: 测试语义明确：先清场到统一基准 → 再精确铺目标数量 → 判定胜负。不依赖四象限初始分布。

**后续建议**: 若再遇到 owner 计数与预期不符，优先检查 `rebuild_owner_counts()` 是否在修改 `owners` 后确实被调用。

---

## 修复 5: P3 胜负测试 async 污染 static `GameConfig`

**现象**: occupation 测试中 `set_game_mode_by_name(OCCUPATION)` 后立刻读取是 `占领模式`，但 `simulate_check_winner()` 内部读到的是 `基础模式`，导致 `_occupation_winner()` 根本未调用。

**根因**: P3 测试中存在不必要的 `await process_frame` / `await _flush()`，外层没有完整 `await` 链，测试间异步交错。`GameConfig._game_mode_name` 是 `static var`，被前后测试互相污染。

**修复**:
- P3 胜负测试全部同步化，删除所有 `await` / `_flush()` 调用
- `TestFixtures.simulate_check_winner(mode_name: String, battlefield, mock_turrets)` 改为接收**显式** `mode_name` 参数
- 内部用 `match mode_name` 分派到四种模式，不再调用 `GameConfig.get_game_mode_name()`
- 各测试显式传入：`GameConfig.GAME_MODE_BASIC` / `OCCUPATION` / `TIMED` / `WILD`

**结果**: 胜负测试零依赖全局 `GameConfig` 当前模式，不会被其他测试污染。

**后续建议**: 未来在 SceneTree 测试中尽量避免依赖 `static var` 全局可变状态。如果必须依赖，确保测试间显式重置且不使用 `await` 跨越测试边界。

---

## 修复 6: GDScript `%` 格式字符串转义

**现象**: `"BLUE cells >= 75% (%d)" % target` 触发 `String formatting error: unsupported format character`。

**根因**: GDScript 的 `%` 格式化解析器将 `%(` 误识别为格式说明符。

**修复**: `75%` 改为 `75%%`（`%%` 是 GDScript 中 literal `%` 的转义写法）。无占位符的字符串不要使用 `% value` 后缀。

**结果**: 格式化警告消失。

---

## 修复 7: 测试结束后不自动退出

**现象**: IntegrationTestRunner 运行完成后进程挂起，需手动 `Ctrl+C` 关闭。

**根因**: `_run()` 末尾调用 `_assert.report()` 后就结束了，没有调用 `quit()`。SceneTree 脚本模式下，不主动 `quit()` 则进程不退出。

**修复**: `_assert.report()` 后根据 `_assert.failures.is_empty()` 调用 `quit(0)` 或 `quit(1)`，与 `SmokeTestRunner` 行为一致。

**结果**: 测试 PASS 后自动退出，不需要手动干预。

---

## 附: 黑屏/空白窗口说明

**现象**: 运行 IntegrationTestRunner 或 PerfBurstBenchmark 时，中间出现黑屏或空白窗口。

**判断**: `--script` 模式不会启动 `Main.tscn`、菜单、HUD 等完整游戏界面，仅运行测试脚本。测试创建少量逻辑节点后图形窗口可能空白。这不是错误。

**判断标准**:
- 控制台持续输出，最终显示 PASS → 正常
- 控制台长期无输出、进程不退出 → 应怀疑协程挂起或 `await` 未完成

**建议**: 优先看控制台结果，必要时使用 `--headless` 避免图形窗口干扰。

---

## 最终验证

```
SmokeTestRunner.gd         33 PASS
IntegrationTestRunner.gd  107 PASS
```

PerfBurstBenchmark 为性能探针，不作为 correctness 判断。

---

## 未覆盖 & 后续建议

| 缺口 | 原因 / 建议 |
|---|---|
| 完整场景启动 (Main.tscn) | 需 UI/TSCN 环境，当前测试无场景加载 |
| 存档文件 I/O (写磁盘/读回) | 需物理文件验证，留给桌面人工测试 |
| 真正 `load → resume` 流程 | 需要 `Main.gd._load_game()` 全链路，当前仅测试 codec 层 |
| 控制仓物理 (peg/gate/floor) | 部分由 SmokeTestRunner 覆盖 |
| 子弹碰撞/弹射/trail | 部分由 SmokeTest 和 PerfBurst 覆盖 |

推荐后续接入方向顺序：
1. 加一个 `ResumeTestRunner.gd` 覆盖完整 `save → load → verify` 流程
2. 将 `Main.gd` 的 `_check_winner()` 抽为可单独测试的纯函数，测试与生产逻辑不脱节
3. PerfBurstBenchmark 定期对比基线，做回退检测
