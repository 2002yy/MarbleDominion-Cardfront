# BallWar v2.1.4 - Restore Interfaces And Perf Cleanup

Date / 日期: 2026-05-14
Scope / 范围: restore-chain interface cleanup + targeted runtime performance cleanup  
恢复链接口收口 + 针对性运行时性能优化

## Version Boundary / 版本边界

`v2.1.4` is defined as:  
`v2.1.4` 定义为：

- remove dead restore / pause scaffolding left in `Main.gd`
- finish the `prepare_*` vs `apply_*` boundary for continue flow
- move chamber / turret / bullet restore mutation into runtime objects
- reduce several obvious per-frame full scans
- keep gameplay rules unchanged

- 清理 `Main.gd` 中残留的 restore / pause 死代码骨架
- 完成 continue 流程里 `prepare_*` 与 `apply_*` 的职责分离
- 把 chamber / turret / bullet 的恢复写回收进各自对象
- 收掉几处明显的逐帧全量扫描
- 不改变玩法规则

In short:  
简而言之：

`v2.1.4 = thinner Main.gd + object-owned restore flow + targeted perf cleanup`  
`v2.1.4 = Main.gd 继续瘦身 + restore 链对象自管 + 定点性能收口`

## Goal / 目标

This phase is about making the current architecture safer to extend. It does
not introduce new gameplay, a new save schema, or a new UI flow.  
这一轮的目标是让当前架构更安全、更容易继续扩展，而不是加入新玩法、修改存档
schema，或重做 UI 流程。

It focuses on:  
核心关注点：

- making restore responsibilities explicit
- keeping `Main.gd` as orchestration instead of deep object mutation
- reducing avoidable runtime scanning in hot paths
- tightening tests around the new boundaries

- 让 restore 职责边界更明确
- 让 `Main.gd` 更像总编排层，而不是深度改对象内部状态
- 减少热点路径里可以避免的运行时扫描
- 给新边界补上更明确的测试

## Files Added / 新增文件

- `scripts/BattlefieldDecorLayer.gd`
- `README_v2_1_4_restore_interfaces_and_perf_cleanup.md`

## Files Updated / 修改文件

- `scripts/Main.gd`
- `scripts/SaveFlowController.gd`
- `scripts/SaveStateApplier.gd`
- `scripts/ControlChamber.gd`
- `scripts/Turret.gd`
- `scripts/Bullet.gd`
- `scripts/BulletPool.gd`
- `scripts/Battlefield.gd`
- `scripts/tests/SmokeTestRunner.gd`
- `scripts/tests/SaveFlowControllerTestRunner.gd`

## 1. Continue Flow Boundary / Continue 流程边界

The continue path is now fully split into:  
现在 continue 路径已经明确拆成两段：

- `prepare_*`
  - return pure data only
- `apply_*`
  - perform side effects only

- `prepare_*`
  - 只返回纯数据
- `apply_*`
  - 只负责产生副作用

### What changed / 具体变化

- `SaveFlowController.prepare_continue_start_plan(...)`
  - now returns execution data only
  - no longer mutates `GameConfig` during plan preparation
- `SaveFlowController.apply_continue_start_plan(...)`
  - now owns continue-time config + selection side effects
- `Main.gd`
  - now consumes the prepared plan
  - starts the scene
  - restores runtime state
  - shows the continue banner

- `SaveFlowController.prepare_continue_start_plan(...)`
  - 现在只返回执行计划数据
  - 不再在 prepare 阶段偷偷修改 `GameConfig`
- `SaveFlowController.apply_continue_start_plan(...)`
  - 现在统一负责 continue 时的配置与选择态副作用
- `Main.gd`
  - 现在只负责消费 plan
  - 启动场景
  - 恢复运行时状态
  - 展示 continue banner

### Why this matters / 这样做的意义

This removes the old mixed phase where a function named `prepare_*` was
already writing global runtime state.  
这消除了过去那种“名字叫 `prepare_*`，实际上已经在改全局运行时状态”的混合阶段。

That makes the continue chain easier to reason about, easier to test, and less
likely to leak state across future refactors.  
这样一来 continue 链更容易理解、更容易测试，也更不容易在后续重构里发生状态污染。

## 2. Restore Interfaces / Restore 接口化

The core architectural change in this phase is that restore mutation now lives
with the object that owns the state.  
这一轮最核心的结构变化，是把 restore 的深层写回逻辑放回状态真正的拥有者自身。

### Chamber / 控制仓

`ControlChamber.gd` now owns:  
`ControlChamber.gd` 现在自己提供：

- `restore_from_state(state)`

It restores / 恢复内容：

- pending / locked counts
- jam timer
- queued round modifiers
- reconstructed control-ball state
- release-ball linkage
- final damaged / locked state

- pending / locked 数值
- jam 计时器
- queued round modifiers
- 控制球重建状态
- release-ball 关联
- 最终 damaged / locked 状态

### Turret / 炮塔

`Turret.gd` now owns:  
`Turret.gd` 现在自己提供：

- `restore_from_state(state)`

It restores / 恢复内容：

- health / destroyed state
- sweep / rotation state
- burst queue state
- burst lock state
- burst progress synchronization

- 血量 / destroyed 状态
- sweep / rotation 状态
- burst 队列状态
- burst lock 状态
- burst progress 同步

### Bullet / 子弹

`Bullet.gd` now owns:  
`Bullet.gd` 现在自己提供：

- `restore_from_state(state, battlefield, target_turrets)`

It restores / 恢复内容：

- faction
- position
- direction
- age
- `last_cell`
- clamped trail points

- 阵营
- 位置
- 方向
- age
- `last_cell`
- 限幅后的拖尾点

### SaveStateApplier / Main.gd changes / SaveStateApplier 与 Main.gd 的变化

`SaveStateApplier.apply_factions(...)` no longer calls back into
`_apply_chamber_state(...)` or `_apply_turret_state(...)`.  
`SaveStateApplier.apply_factions(...)` 不再通过回调去调用
`_apply_chamber_state(...)` 和 `_apply_turret_state(...)`。

It now directly calls:  
现在它直接调用：

- `chamber.restore_from_state(...)`
- `turret.restore_from_state(...)`

`Main.gd` bullet restore also no longer manually writes `bullet.age`,
`bullet.last_cell`, or `bullet.trail_points`.  
`Main.gd` 里的 bullet 恢复也不再手写 `bullet.age`、`bullet.last_cell`、
`bullet.trail_points`。

It now delegates to:  
现在统一委托给：

- `BulletPool.spawn_bullet_from_state(...)`
  or fallback
- `Bullet.restore_from_state(...)`

- `BulletPool.spawn_bullet_from_state(...)`
  或 fallback
- `Bullet.restore_from_state(...)`

## 3. Main.gd Shrinkage / Main.gd 继续瘦身

This phase continues the `Main.gd` reduction started earlier.  
这一轮延续了前面已经开始的 `Main.gd` 瘦身工作。

### Removed from Main.gd / 从 Main.gd 移除的内容

- dead code below early `return` branches in continue / win / game-over helpers
- `_apply_chamber_state(...)`
- `_apply_turret_state(...)`
- manual bullet field restoration

- continue / win / game-over helper 里 `return` 后的死代码
- `_apply_chamber_state(...)`
- `_apply_turret_state(...)`
- 手写 bullet 字段恢复逻辑

### Current status / 当前状态

`Main.gd` is still the top-level scene coordinator, but it is now much closer
to its intended role:

- read prepared plan
- start the game scene
- apply restore sequence
- hand off object-specific restore to runtime objects

`Main.gd` 仍然是顶层场景协调者，但它现在已经更接近理想角色：

- 读取 prepared plan
- 启动游戏场景
- 执行 restore 顺序
- 把对象级 restore 交还给运行时对象自己处理

That is a much healthier boundary than the previous version, where `Main.gd`
knew too many internals of `ControlChamber`, `Turret`, and `Bullet`.  
这比之前的结构健康得多，因为旧版本的 `Main.gd` 知道了太多
`ControlChamber`、`Turret`、`Bullet` 的内部细节。

## 4. Performance Cleanup / 性能收口

This phase intentionally touched only the most obvious low-risk hotspots.  
这轮性能优化是刻意控制范围的，只处理最明显、风险最低的热点。

### 4.1 BulletPool incremental counters / BulletPool 增量统计

`BulletPool.gd` previously recalculated metrics by scanning all tracked turrets
and all active bullets. It now uses incremental caching for:

- total tracked burst queue
- total trail segment estimate

以前 `BulletPool.gd` 会通过扫描所有 tracked turrets 和所有 active bullets
来重新计算指标。现在改成了增量缓存：

- tracked burst queue 总量
- trail segment 估算总量

New behavior / 新行为：

- turret burst progress updates queue totals incrementally
- bullet trail changes update trail-segment totals incrementally

- turret 的 burst progress 会增量更新 queue 总量
- bullet 的 trail 变化会增量更新拖尾段数总量

### 4.2 ControlChamber lighter peg collision path / ControlChamber 更轻的 peg 碰撞路径

`ControlChamber.gd` peg collision now uses:

- cached peg collision radii
- cheap axis-aligned rejection first
- squared-distance comparison before `sqrt`

`ControlChamber.gd` 的 peg 碰撞现在采用：

- 缓存后的 peg collision 半径
- 先做便宜的轴向剔除
- 在进入 `sqrt` 之前先做平方距离比较

This keeps behavior stable while reducing useless work in the common
non-collision path.  
这样可以在不改变行为的前提下，减少大量“其实没撞上”的无效计算。

### 4.3 Battlefield static decor split / Battlefield 静态装饰层拆分

`Battlefield.gd` now separates:

- dynamic ownership texture drawing
- static grid / emblem / border decoration

`Battlefield.gd` 现在把下面两类绘制拆开了：

- 动态 ownership 纹理绘制
- 静态 grid / emblem / border 装饰绘制

The new `BattlefieldDecorLayer.gd` owns the static decorative layer.  
新的 `BattlefieldDecorLayer.gd` 专门负责静态装饰层。

This means ownership redraws no longer need to rebuild every decorative element
inside the same `_draw()` path.  
这样 ownership 变化引发的 redraw 就不需要每次都把所有装饰元素一起重画。

## 5. Tests Added Or Strengthened / 测试补强

### SaveFlowController tests / SaveFlowController 测试

`scripts/tests/SaveFlowControllerTestRunner.gd` now verifies that:

- `prepare_continue_start_plan(...)` stays pure
- `apply_continue_start_plan(...)` is where side effects happen

`scripts/tests/SaveFlowControllerTestRunner.gd` 现在会验证：

- `prepare_continue_start_plan(...)` 保持纯数据行为
- `apply_continue_start_plan(...)` 才是副作用真正发生的位置

### Smoke tests / SmokeTest 补口

`scripts/tests/SmokeTestRunner.gd` now covers:

- `ControlChamber.restore_from_state(...)`
- `Turret.restore_from_state(...)`
- `Bullet.restore_from_state(...)`
- `BulletPool` incremental queue tracking
- `BulletPool` incremental trail-segment tracking
- `BulletPool.spawn_bullet_from_state(...)`

`scripts/tests/SmokeTestRunner.gd` 现在补到了：

- `ControlChamber.restore_from_state(...)`
- `Turret.restore_from_state(...)`
- `Bullet.restore_from_state(...)`
- `BulletPool` 的增量 queue 统计
- `BulletPool` 的增量拖尾段数统计
- `BulletPool.spawn_bullet_from_state(...)`

## 6. Validation Result / 验证结果

Headless validation after the refactor:  
本轮重构后进行的 headless 验证结果：

```text
SmokeTestRunner.gd               PASS 60 checks
SaveFlowControllerTestRunner.gd  PASS 75 checks
IntegrationTestRunner.gd         PASS 133 checks
GameStateCoordinatorTestRunner   PASS 50 checks
```

## 7. What This Phase Did Not Change / 本轮没有改什么

This phase did **not** change:

- save major-version compatibility policy
- gameplay rules
- event roulette behavior
- win-condition rules
- start menu structure
- scene creation topology

本轮 **没有** 改动：

- 存档大版本兼容策略
- 玩法规则
- event roulette 行为
- 胜负判定规则
- 开始菜单结构
- 场景创建拓扑

It also did not introduce a separate dedicated bullet restore coordinator,
because the clearer intermediate step was to let `Bullet` own its own restore
logic first.  
同时，这一轮也没有单独引入 bullet restore coordinator，因为更清晰、更稳妥的中间
步骤，是先让 `Bullet` 自己接管 restore 逻辑。

## 8. Known Good Boundary After v2.1.4 / v2.1.4 之后较清晰的边界

### SaveFlowController

- continue pre-start planning
- continue side-effect application
- save/load orchestration

- continue 启动前规划
- continue 副作用应用
- save/load 编排

### SaveStateApplier

- high-level restore sequencing
- battlefield / faction / event / game-over phase dispatch

- 高层 restore 顺序编排
- battlefield / faction / event / game-over 阶段分发

### Runtime objects / 运行时对象

- `ControlChamber.restore_from_state(...)`
- `Turret.restore_from_state(...)`
- `Bullet.restore_from_state(...)`

### Main.gd

- top-level coordination only

- 只保留顶层协调职责

This is the most important architectural outcome of the phase.  
这是本轮最重要的结构性成果。

## 9. Recommended Next Step / 下一步建议

The next safe direction is no longer "split more save logic". A better next
step is one of:  
下一步更安全的方向，已经不是“继续拆更多 save 逻辑”，而是下面几种之一：

1. add an end-to-end continue-game runtime test that enters from the real
   `Main.gd` continue path
2. audit whether `SaveStateApplier` should absorb more sequencing structure
   without hurting readability
3. decide whether the remaining `Main.gd` restore orchestration should be
   formalized into a dedicated restore coordinator

1. 增加一个真正从 `Main.gd` continue 入口走进去的端到端恢复测试
2. 评估 `SaveStateApplier` 是否应该继续吸收一部分顺序结构，同时不伤可读性
3. 决定剩余的 `Main.gd` restore 编排，是否值得进一步收口成专门 coordinator

If correctness confidence is the top priority, option 1 should come first.  
如果当前最优先的是正确性信心，建议先做第 1 项。

## Final Summary / 最终总结

`v2.1.4` completes the first real restore-interface cleanup:

- continue flow is now cleanly `prepare` vs `apply`
- chamber / turret / bullet restore now belongs to the owning object
- `Main.gd` stopped reaching into several private runtime fields
- three concrete performance hotspots were reduced without changing rules

`v2.1.4` 完成了第一次比较完整的 restore 接口化收口：

- continue 流程已经清晰分成 `prepare` 和 `apply`
- chamber / turret / bullet 的 restore 现在回到对象自身负责
- `Main.gd` 不再直接去捅多处运行时私有字段
- 三个明确的性能热点已经在不改规则的前提下被收掉

This is a structural stability release, not a feature release.  
这是一次“结构稳定性版本”，不是“玩法功能版本”。
