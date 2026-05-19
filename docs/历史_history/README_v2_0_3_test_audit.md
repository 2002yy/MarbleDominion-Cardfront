# README v2.0.3 — Test Audit

日期: 2026-05-04 (final, verified 107/107 PASS)

## 修复记录

详见 `README_v2_0_3_fix_log.md`。六项修复：`true`→`that`；Node动态属性→MockTurret类；faction数组索引；fill/paint清场语义；P3 async污染static GameConfig；GDScript %%格式转义。

核心原则：只改测试代码，不改 Battlefield.gd / Main.gd / GameConfig.gd / SaveGameCodec.gd。

## 范围

本版本只做测试补强和重构准备，不加新玩法。不改事件规则、子弹数、中文编码、存档版本号。

## 新增文件

| 文件 | 角色 |
|---|---|
| `scripts/tests/TestAssert.gd` | 通用断言工具 (RefCounted)，提供 `true`/`eq`/`neq`/`gt`/`gte`/`between`/`report` 七个方法 |
| `scripts/tests/TestFixtures.gd` | 测试对象工厂 (RefCounted)，提供 save payload 构建、turret mock、battlefield 辅助、胜负模拟、节点清理等静态方法 |
| `scripts/tests/IntegrationTestRunner.gd` | 重构版集成测试，使用 TestAssert + TestFixtures，覆盖 P1/P2/P3 |

## 重构文件

| 文件 | 变更 |
|---|---|
| `scripts/tests/IntegrationTestRunner.gd` | 从 775 行内联测试重写为 ~290 行，使用 TestAssert + TestFixtures；测试覆盖无缩减 |

## 测试覆盖范围

### P1 — 存档/读档回环 (~22 断言)

- save payload 构造后的 ownership mutation 持久性
- SaveGameCodec 全字段校验：grid_size、game_mode、time_limit、owners、bullets、event_state、faction 基础字段
- save schema 版本兼容：1.9.34/1.9.0 通过，2.0.0/空字符串 被拒
- game mode set/get 回环 (basic/occupation/timed/wild)
- gate multiplier：basic x2、wild x3、basic reset
- max pending：basic BASE_MAX、wild WILD_MAX
- battlefield 初始归属 (4 象限等分)
- faction state round-trip：pending、locked remaining、jammed time、turret health、burst remaining、queued modifiers
- event state import/export：countdown、last faction、last effect、reroll count、interval、enabled

### P2 — 战场规则 (~21 断言)

- 40x40 / 20x20 初始领土象限分配
- 同阵营子弹 no-op (SAME_CELL，count 不变)
- 敌方占领 (HIT_ENEMY_CELL，count ±1)
- 界外子弹 (OUTSIDE，无副作用)
- owner_counts 与 owners 数组同步 (手动扫描 vs count_cells_by_team)
- world_to_cell 坐标转换 + is_inside 边界
- rebuild_owner_counts 重算后同步

### P3 — 胜负条件 (~14 断言)

- basic：最后存活 turret 胜利、全部摧毁平局
- occupation：75% 触发胜利、70% 不触发
- timed：计分领先者胜利、均分平局
- wild：gate x3、max pending WILD_MAX，basic 恢复验证
- save 版本兼容：1.9.34 通过、2.0.0 被拒

## 未覆盖范围

| 缺口 | 原因 |
|---|---|
| Main.gd 完整场景启动 | 涉及 UI/TSCN，不在此次 scope |
| 存档文件 I/O (写磁盘/读回) | 测试在 SceneTree 环境，存储 I/O 需物理文件验证，留给桌面验证 |
| 子弹物理/碰撞/拖尾 | 由 PerfBurstBenchmark 和 SmokeTestRunner 部分覆盖，本次不扩展 |
| 控制仓物理 (peg/floor/gate divider) | 部分由 SmokeTestRunner 覆盖，本次不扩展 |
| 事件轮盘 UI 展示 | 纯展示层，不做逻辑测试 |
| 完整对局流程 (new game -> play -> save -> load -> resume) | 需场景启动 + 物理文件，留给桌面人工验证 |
| 所有四种炮塔同时存活的基本模式 (2/3 alive) | 非胜负触发点，省略 |

## 测试分工

| 测试 | 类型 | 运行时间 | 角色 |
|---|---|---|---|
| `SmokeTestRunner.gd` | 快速冒烟 | <1s | codec 边界、event 间隔/权重、chamber 事件规则、turret cancel |
| `IntegrationTestRunner.gd` | 中量集成 | <5s | 存档回环、战场规则、胜负条件 |
| `PerfBurstBenchmark.gd` | 性能探针 | ~60s | FPS/queue/trail/draw_calls 压力测试 |

三者互补：smoke 快但窄、integration 中等但覆盖核心逻辑、perf 慢但保障性能不退化。

## 运行命令 (桌面)

```cmd
"E:\Godot\Godot_\Godot_console.exe" --path "C:\Users\96967\Desktop\Marble Dominion Ricochet War\BallWar_v2_0\BallWar" --script "res://scripts/tests/SmokeTestRunner.gd"

"E:\Godot\Godot_\Godot_console.exe" --path "C:\Users\96967\Desktop\Marble Dominion Ricochet War\BallWar_v2_0\BallWar" --script "res://scripts/tests/IntegrationTestRunner.gd"

"E:\Godot\Godot_\Godot_console.exe" --path "C:\Users\96967\Desktop\Marble Dominion Ricochet War\BallWar_v2_0\BallWar" --script "res://scripts/tests/PerfBurstBenchmark.gd"
```

## 桌面人工验证清单

- [ ] SmokeTestRunner.gd — 确认 PASS
- [ ] IntegrationTestRunner.gd — 确认 PASS
- [ ] PerfBurstBenchmark.gd — 确认 FPS 不退化
- [ ] 完整 save/load 流程 — 新游戏 → 改归属/血量/球数 → 保存 → 读取 → 验证
- [ ] 四种模式胜负条件 — 在 Godot 编辑器中实际触发
- [ ] Chinese text in-game rendering — 确认中文 UI 正常

## 本次未改动文件

以下文件完全未动，保持 v2.0.2 状态：
- `scripts/Main.gd`
- `scripts/GameConfig.gd`
- `scripts/SaveGameCodec.gd`
- `scripts/ControlChamber.gd`
- `scripts/EventRouletteController.gd`
- `scripts/EventRouletteView.gd`
- `scripts/RuntimeHudController.gd`
- `scripts/GameHudView.gd`
- `scripts/Battlefield.gd`
- `scripts/Turret.gd`
- `scripts/Bullet.gd`
- `scripts/BulletPool.gd`
- `scripts/BulletTrailLayer.gd`
- `scripts/ControlBall.gd`
- `scripts/EnergyButton.gd`
- `scripts/Gate.gd`
- `scripts/HudBadge.gd`
- `scripts/LayoutProfiles.gd`
- `scripts/MenuDecor.gd`
- `scripts/StartMenuView.gd`
- `scripts/BannerController.gd`
- `scripts/GameSceneBuilder.gd`
- `scripts/SaveGameCodec.gd`
- `scripts/UIAnimationController.gd`
- `scripts/UIFactory.gd`
- `scripts/tests/SmokeTestRunner.gd`
- `scripts/tests/PerfBurstBenchmark.gd`
