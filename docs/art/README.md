# Cardfront Art & 3D Production

这里是 Cardfront 正式美术生产入口。供应商素材预览、Blender 单独渲染和实机验收必须分开看：**只有接入正式战场后的确定性截图与性能/可读性验证，才能成为 GO 证据。**

## 1. 当前正式规范

- **当前冻结稿：** [`Cardfront_Art_3D_Production_Spec_v0.2_2026-08-18.docx`](Cardfront_Art_3D_Production_Spec_v0.2_2026-08-18.docx)
- **上一版：** [`Cardfront_Art_3D_Production_Spec_v0.1_2026-08-18.docx`](Cardfront_Art_3D_Production_Spec_v0.1_2026-08-18.docx)
- **状态入口：** [`../PROJECT_STATUS.md`](../PROJECT_STATUS.md)
- **V-01 视觉层级参考：** [`../../美术参考_art_reference/cardfront_visual_hierarchy_v01/`](../../美术参考_art_reference/cardfront_visual_hierarchy_v01/)

v0.2 已冻结的决策链：

> **D01 A → D02 A3 → D03 C → D04 B → D05 B2 → D06 MAT-B → D07 SHD-C → D08 TER-C → D09 DIO-B → D10 FAC-C → D11 VFX-C**

## 2. 已锁定视觉系统

### 世界与地面
- 70% 玩具战争沙盘 + 30% 微缩世界。
- 连续沙盘 + 弱格纹 + 强状态块。
- 语义低浮雕：**视觉有高度，规则没有高低地形**。
- `Geometry Honesty Rule`：视觉几何不得暗示不存在的碰撞、移动或弹道规则。

### HQ 与建筑
- HQ = Common Skeleton + Hero Module + Theme Module + Faction Material + Damage Module。
- 普通塔为 1.0 视觉基准；HQ 主要横向做宽厚，不靠盲目增高。
- 英雄模块不改变 HQ 核心 bounding box。
- 新正式 Blender 资产以源文件比例解决造型，尽量 `Scale=1,1,1` 导入 Godot，避免强非等比运行时修形。

### 材质
- 有材质暗示的玩具化 PBR；大色块、roughness、metallic、bevel、轮廓优先于高频贴图。
- 核心角色：`MAT_Grass / MAT_Stone / MAT_Wood / MAT_Metal / MAT_Faction / MAT_Core / MAT_Water`。
- 第一阶段不做 2K/4K 独立 PBR texture set、完整 Substance Painter 流程、trim-sheet 大工程或污渍 decal 系统。
- `3 米测试`：正式 112% 镜头看不到、看不懂或只增加噪声的几何/阴影/细节应删减。

### 阴影
- 选择性实时 Directional shadow + 少量 contact blob。
- HQ、普通塔、Stronghold 核心、主要工事优先投影；Projectile/VFX/UI 不投实时阴影。
- 从 Orthogonal shadow 起步，PCSS 关闭；4-split 暂不进入首轮。
- HIGH/MEDIUM/LOW 从第一天拥有可降级路径，但 gameplay 信息不得随画质档消失。

### 环境
- 三带式 Diorama Frame：
  - Z1 Gameplay Core：`No Decorative Prop Rule`
  - Z2 Transition Ring：低矮、贴地、弱对比
  - Z3 Outer Diorama：地图主题与世界感
- 外围遵循 50% Negative Space Rule、Skyline Height Envelope 与 Viewport-aware Dressing Budget。
- 战术可读性高于阴影/布景的物理正确性。

### 阵营
- `Faction Signal Hierarchy`：F0 中性世界 → F1 弱领土 → F2 中等建筑 → F3 强小型战斗对象 → F4 极短瞬时状态。
- `Faction Color Conservation Rule`：占屏越大、存在越久，阵营色越克制；越小、越快，阵营信号越强。
- Color + Symbol + Orientation + Light 多通道识别。
- **Silhouette = 类型；Faction signal = 所属；Animation/VFX = 状态。**
- Stronghold 主体保持中性，归属主要由 ring / lamp / flag 表达。

### VFX
- `VFX Importance Hierarchy`：V0 Continuous → V1 Micro Contact → V2 Tactical → V3 Major → V4 Decisive。
- `One Contact = One Primary Effect`。
- `One Event, One Story`：特效优先解释状态变化，而不是泛化为“爆炸”。
- `Readability LOD`：信息越密，普通事件单体 VFX 预算越低，即使 GPU 仍有余量。
- `Effect Coalescing`：同格/同 family/短时间窗内的低级事件允许合并；重大状态事件不被吞掉。
- 正式方向为 Effect Family + Pool + Density Controller。

## 3. 第一生产标杆

仍只先完成 `default_duel + Balanced HQ`，不要同时铺开三张地图和三个英雄。

首轮正式范围：
- HQ Common；
- Balanced Hero；
- Castle Theme；
- Blue/Red faction material；
- Damage/VFX sockets；
- 河床/河岸低浮雕；
- Stronghold pad 与防御工事高度 mockup；
- Shadow Baseline/C1/C2；
- Quiet / Normal / Stress VFX benchmark。

Rapid、Engineer、Industrial、Lab 在 benchmark GO 后追加。

## 4. 资产与运行时边界

- 2D authoritative simulation 不变；3D 仍是 presentation mirror。
- 3D 资产通过集中 Registry 接入；禁止 raw asset path 散入 `Main.gd`、玩法系统和单个 effect handler。
- 世界材质必须升级为 Material Role / slot 调色，不能继续把整个 GLB 用一个 `material_override` 抹平。
- 蓝/红优先换材质/标识，不复制 gameplay-relevant mesh silhouette。
- 实机 deterministic screenshot 才是最终美术证据。

现有位置：
- Runtime/environment：`assets/cardfront_environment/`
- 自制 GLB：`assets/cardfront_environment/source/custom/`
- KayKit source：`assets/cardfront_environment/source/kaykit_medieval_hexagon/`
- Registry：`scripts/cardfront/environment/CardfrontEnvironmentAssetRegistry.gd`
- Environment builder：`scripts/cardfront/environment/CardfrontEnvironmentBuilder.gd`
- Orthographic arena：`scripts/cardfront/arena/CardfrontOrthographicArenaView.gd`

## 5. 已知 presentation 技术债

v0.2 已明确记录而尚未自动施工：
- `EnvironmentBuilder` 仍整 GLB material override，roughness≈0.84 / metallic=0，冲突 D06。
- Territory 已占领 tile 当前 faction lerp≈0.60，冲突 D10 F1 弱领土。
- Stronghold platform 当前随 owner 约 0.38 混色，冲突“主体中性”。
- Combat impact 当前每事件 new/free 一个发光 SphereMesh，冲突 D11 Pool + Coalescing。
- 所有可见 projectile 当前都有完整 trail；需要 Density Compensation / Readability LOD。
- Directional shadow 当前仍关闭；需先做 default_duel Shadow A/B benchmark。

## 6. 下一项 GrillMe

**尚未锁定：世界空间动态信息 vs HUD 的职责边界。**

需要决定 HQ HP、单位 HP/状态文字、Stronghold 百分比、Gate 状态、目标/部署提示中，哪些：
- 常驻世界空间；
- 受伤/变化/悬停时出现；
- 仅在 HUD 表达。

在这项决策完成前，不应继续增加新的常驻 Label3D / HP bar / badge。
