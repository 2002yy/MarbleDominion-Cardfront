# v0.1.2.1-cardfront-visibility-polish

本切片是 `v0.1.2-region-morale` 之后的小型可见性修补，不进入部署规则、卡牌、单位、AI 或前线加固。

## Scope / 范围

- 收紧 `CardfrontEconomyDebugPanel.gd`：
  - 面板从 `320x210` 缩到 `260x150`
  - 位置下移到 `Vector2(8, 118)`
  - 背景透明度降到约 `0.58`
  - 默认只显示资源、本 tick 产出摘要和最多 3 个关键区域
- 在 `BulletPool.gd` 增加 Cardfront 专属低压力视觉策略：
  - Cardfront 且压力等级 `<= 1` 时保留完整小球效果
  - Cardfront 低压力拖尾点不少于 `10`
  - 高压和极高压仍沿用自动降级
- 在 `Bullet.gd` 的非降级绘制路径里增加轻微边缘高光和第二层高光。

## Boundaries / 边界

- 不修改 `GameConfig` 全局阈值。
- 不改变旧 BallWar 模式的视觉降级策略。
- 不改小球运动、碰撞、占领或 `Battlefield.apply_bullet()` 逻辑。
- 不做部署规则、卡牌 UI、单位、AI 或前线加固。

## Validation / 验证

- `EconomyDebugPanelSceneTestRunner.gd`
- `CardfrontVisualPolicyTestRunner.gd`
- Existing Cardfront regression runners remain in the validation lane.
