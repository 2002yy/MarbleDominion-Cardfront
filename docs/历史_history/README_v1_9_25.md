# v1.9.25 HUD 遮挡与警告修复版

本版基于 v1.9.24，主要处理用户实测反馈：

1. 修复右上角“退出”按钮在 30/40/50/60 地图尺寸下被右侧 +球按钮遮挡的问题。
   - GameHudView.gd 中右侧系统按钮改为贴近屏幕右边缘布局。
   - 设置面板位置同步做 clamp，避免移出屏幕。

2. 调试 HUD 文案中文化。
   - `grid` 改为 `地图 N×N`。
   - `active` 改为 `子弹`。
   - `quality` 改为 `画质`。
   - `pressure` 改为 `压力`。
   - 其中“地图 40×40”表示当前战场网格是 40 行 × 40 列。

3. 修复 GameHudView.gd 中 create_runtime_ui() 的未使用参数 warning。
   - `battlefield` 改名为 `_battlefield`。
