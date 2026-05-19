# BallWar / 领土战争 v1.9.34

本版为 `v1.9.34_event_roulette_v1`，重点接入事件转盘系统第一版代码。

## 本轮完成

1. 新增 `scripts/EventRouletteController.gd`
   - 按模式管理事件倒计时。
   - 基础 / 占领 / 限时 / 狂野 四模式已接入不同触发频率。
   - 先按权重决定阵营与最终效果，再驱动表现层演出。
   - 支持重转逻辑：只重转效果，不重转颜色，最多连续 2 次，超过后强制 `本次 +10`。
   - 六个事件效果全部按 `1/6` 等概率抽取。
   - 正面事件偏向落后阵营，负面事件偏向领先阵营，中性事件四方均等。

2. 新增 `scripts/EventRouletteView.gd`
   - 顶部中轴下拉式临时事件舞台。
   - 左右双轮盘并排：左阵营，右效果。
   - View 只负责演出，不决定结果。
   - 动画加入加速、高速、减速与停格感。
   - 游戏不断开、不暂停，浮层 `mouse_filter = MOUSE_FILTER_IGNORE`。

3. 扩展 `scripts/ControlChamber.gd`
   - 新增事件接口：
     - `apply_pending_bonus(amount)`
     - `apply_pending_multiplier(multiplier)`
     - `add_control_ball_from_event()`
     - `apply_jammed(duration)`
     - `queue_next_round_modifier(modifier)`
     - `cancel_current_burst_with_refund(ratio)`
   - 区分永久 `damaged` 与 5 秒临时 `jammed`。
   - `jammed` 期间门口禁用，控制球到底会被弹回。
   - 下一轮修正在控制仓解锁后应用，不改乱当前 burst。

4. 扩展 `scripts/Turret.gd`
   - 新增 `cancel_burst() -> int`，用于事件干扰时取消剩余发射。

5. 接入 `scripts/Main.gd`
   - 创建并装配 `EventRouletteController` 与 `EventRouletteView`。
   - 保持 Main 只做模块装配，不承载事件核心逻辑。
   - 存档新增事件状态读写。

6. 接入 `scripts/GameHudView.gd`
   - 右下角新增事件信息 HUD：
     - 最近事件
     - 下次事件倒计时

7. 接入 `scripts/SaveGameCodec.gd`
   - 为新存档字段补默认值与兼容清洗逻辑。

## 当前第一版范围

已实现：

- 模式计时
- 双轮盘演出骨架
- 六种事件效果
- 控制仓干扰
- HUD 倒计时
- 事件存档恢复

暂未深入：

- 更复杂的轮盘美术贴图
- 更强的机械指针反馈
- 慢动作演出
- 多事件叠加

## 说明

本版重点是把事件系统骨架真正接进现有工程，同时尽量不破坏原有控制仓发射逻辑。后续如果继续迭代，优先打磨：

1. 双轮盘视觉表现。
2. 控制仓干扰的门口短路特效。
3. HUD 文本排版与中文显示一致性。
