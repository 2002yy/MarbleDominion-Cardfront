# BallWar / 领土战争 v1.9.23

本版是 **Main.gd 模块化收口版**。目标不是改玩法，而是降低 Main.gd 的职责密度，先把高复用、低风险、非核心玩法逻辑拆出去。

## 主要变化

### 1. 新增 `LayoutProfiles.gd`
负责地图尺寸与布局档位：

- `sanitize_grid_size()`
- `get_profile()`

Main.gd 不再直接维护 10/20/30/40/50/60 多套布局表。

### 2. 新增 `RuntimeHudController.gd`
负责运行时 HUD 文本和顶部占领条刷新：

- FPS / active bullets / quality / grid / pressure 调试文本
- 计时器
- 阶段名
- 领先阵营
- 顶部电竞占领条 segment 宽度与文字适配

Main.gd 只保留调用入口。

### 3. 新增 `UIAnimationController.gd`
负责轻量 UI 动效：

- 菜单标题轻微摆动
- 开始/继续按钮呼吸
- 游戏标题呼吸
- 胜利文字脉冲
- +球按钮悬浮与 hover 缩放

Main.gd 不再直接写这些每帧动画细节。

### 4. 新增 `SaveGameCodec.gd`
负责存档编解码和校验中的通用逻辑：

- Vector2 / Vector2i 与数组互转
- 控制球状态收集
- 子弹状态收集
- release_ball 索引记录
- 存档基础结构校验

Main.gd 仍保留“什么时候保存 / 什么时候读取 / 如何应用到当前场景”的流程控制。

## Main.gd 变化

- 从约 1564 行降到约 1174 行。
- Main.gd 目前主要负责：
  - 游戏入口
  - 菜单与场景创建
  - 战场 / 炮台 / 控制仓装配
  - 信号连接
  - 胜负流程
  - 存档应用流程
- 没有改动核心玩法规则。

## 保留自 v1.9.22 的性能改动

- 子弹绘制降频。
- 老子弹随压力统一降级。
- 战场占格变化批处理刷新。
- HUD 元信息降频更新。
- 控制仓 `queue_redraw()` 降频。

## 建议下一步

v1.9.24 可以继续拆：

1. `StartMenuView.gd`：开始菜单独立成视图组件。
2. `GameSceneBuilder.gd`：战场、炮台、控制仓、UI 的创建装配独立出来。
3. `SaveGameManager.gd`：把保存/读取/应用流程进一步从 Main.gd 中拆走。
4. `BannerController.gd`：中央开局/胜利横幅独立管理。

当前版先选择低风险拆分，避免一次性大重构破坏现有可玩版本。
