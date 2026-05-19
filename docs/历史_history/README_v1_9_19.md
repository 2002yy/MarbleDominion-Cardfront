BallWar v1.9.19

本次更新重点：
1. UI 组件层整理
   - 新增 UIFactory.gd，集中生成 HUD Label、Action Button、Panel/Card、ColorRect 等基础 UI 组件。
   - Main.gd 的顶部 HUD、右侧操作按钮、暂停面板开始接入 UIFactory，后续扩展按钮/面板可以直接复用。
   - 现有 EnergyButton.gd、HudBadge.gd 保留，形成「基础工厂 + 专用组件」的 UI 组件层结构。

2. 控制仓状态精修
   - 顶部增加状态灯，普通 / 锁定 / 损坏 三种状态更直观。
   - 内腔增加扫描线，机械槽质感更强。
   - 锁定状态下，发射口加入更明显的能量高光与输出感。
   - 损坏状态下，故障红光、裂纹与离线表现更明显。
   - 文案微调：锁定显示「能量输出」，正常显示「待命 · x球」，损坏显示「系统离线」。

3. 版本号
   - save_version 更新为 1.9.19
