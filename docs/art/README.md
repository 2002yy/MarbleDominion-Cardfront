# Cardfront Art & 3D Production

这里是 Cardfront 正式美术生产入口。供应商素材预览、Blender 单独渲染和实机验收必须分开看：**只有接入正式战场后的确定性截图与性能/可读性验证，才能成为 GO 证据。**

## 1. 当前正式规范

- **当前冻结稿：** [`Cardfront_Art_3D_Production_Spec_v0.3_2026-08-18.docx`](Cardfront_Art_3D_Production_Spec_v0.3_2026-08-18.docx)
- **上一版：** [`Cardfront_Art_3D_Production_Spec_v0.2_2026-08-18.docx`](Cardfront_Art_3D_Production_Spec_v0.2_2026-08-18.docx)
- **早期冻结稿：** [`Cardfront_Art_3D_Production_Spec_v0.1_2026-08-18.docx`](Cardfront_Art_3D_Production_Spec_v0.1_2026-08-18.docx)
- **状态入口：** [`../PROJECT_STATUS.md`](../PROJECT_STATUS.md)
- **V-01 视觉层级参考：** [`../../美术参考_art_reference/cardfront_visual_hierarchy_v01/`](../../美术参考_art_reference/cardfront_visual_hierarchy_v01/)

v0.3 已冻结的决策链：

> **D01 A → D02 A3 → D03 C → D04 B → D05 B2 → D06 MAT-B → D07 SHD-C → D08 TER-C → D09 DIO-B → D10 FAC-C → D11 VFX-C → D12 INF-C → D13 DMG-C → D14 MOT-C → D15 CAM-C → D16 SHP-C → D17 SIL-C**

## 2. 已锁定视觉系统

### 世界、地形与环境
- 70% 玩具战争沙盘 + 30% 微缩世界。
- 连续沙盘 + 弱格纹 + 强状态块。
- 语义低浮雕：**视觉有高度，规则没有高低地形**。
- `Geometry Honesty Rule`：视觉几何不得暗示不存在的碰撞、移动或弹道规则。
- 三带式 Diorama Frame：Z1 Gameplay Core / Z2 Transition Ring / Z3 Outer Diorama。
- 外围遵循 No Decorative Prop、50% Negative Space、Skyline Height Envelope、Viewport-aware Dressing Budget。

### HQ、建筑与持久损伤
- HQ = Common Skeleton + Hero Module + Theme Module + Faction Material + Damage Module。
- 普通塔为 1.0 视觉基准；HQ 主要横向做宽厚，不靠盲目增高。
- `Authored Modular Damage States`：持久损伤由可控模块显隐/替换/轮廓缺口表达，VFX 只强化。
- `Damage Honesty Rule`：视觉损伤不得暗示一个仍有效的 gameplay function 已经失效。
- HQ 允许 D0 Healthy / D1 Worn / D2 Damaged / D3 Critical / Destroy；Tower 更少，Creature 极简。
- Fortification 直接跟随 gameplay defense level 换几何；Stronghold Control State 与 Damage State 分离。

### 材质与光影
- 有材质暗示的玩具化 PBR；大色块、roughness、metallic、bevel、轮廓优先于高频贴图。
- 核心角色：`MAT_Grass / MAT_Stone / MAT_Wood / MAT_Metal / MAT_Faction / MAT_Core / MAT_Water`。
- 第一阶段不做 2K/4K 独立 PBR texture set、完整 Substance Painter 流程、trim-sheet 大工程或污渍 decal 系统。
- `3 米测试`：正式 112% 镜头看不到、看不懂或只增加噪声的几何/阴影/细节应删减。
- 选择性实时 Directional shadow + 少量 contact blob；HQ/Tower/Stronghold 核心/主要工事优先投影，Projectile/VFX/UI 不投实时阴影。

### 阵营与信息生命周期
- `Faction Signal Hierarchy`：F0 中性世界 → F1 弱领土 → F2 中等建筑 → F3 强小型战斗对象 → F4 极短瞬时状态。
- `Faction Color Conservation Rule`：占屏越大、存在越久，阵营色越克制；越小、越快，阵营信号越强。
- Color + Symbol + Orientation + Light 多通道识别。
- **Silhouette = 类型；Faction signal = 所属；Animation/VFX = 状态。**
- D12 `Contextual Hybrid`：**World tells identity, state and change; HUD tells exact value, comparison and history.**
- `Normal state should consume zero UI budget`；世界信息分 Persistent / Contextual / Interaction，精确 HQ HP/全局比较留给 Persistent HUD。
- `Information appears where the decision is made, when the decision is being made.`

### VFX 与运动
- `VFX Importance Hierarchy`：V0 Continuous → V1 Micro Contact → V2 Tactical → V3 Major → V4 Decisive。
- `One Contact = One Primary Effect`；`One Event, One Story`。
- `Readability LOD`、Projectile Density Compensation、Effect Coalescing；正式方向为 Effect Family + Pool + Density Controller。
- D14 `Toy-Mechanical Motion Language`：机械因果优先，采用 `Snap–Settle Grammar`。
- `Motion Honesty Rule`：运动不得让玩家误判 authoritative 位置/朝向/通过状态/时机。
- `Motion Scarcity Rule`：运动本身是注意力预算；Rigid gameplay geometry 不做传统 squash & stretch。
- Gameplay-driven motion 由 Godot 驱动；Blender 负责 Pivot / hierarchy / socket / 可动件拆分。

### 固定镜头与建模语言
- D15 `Controlled Camera-Biased Modeling`：允许为正式正交镜头夸张非 gameplay-critical 的厚度、Core、Damage Gap、Bevel、旗帜与层级间距。
- `Projection-First Rule`：正式镜头投影结果优先于 Blender Turntable。
- `Axis Honesty`：尺寸可以夸张，方向不能伪造；炮管轴线、Projectile 中心/轨迹必须精确。
- `Mirror Fairness Rule`：关键身份/阵营/损伤特征必须通过 0°/180°双方对置测试。
- `Camera Contract`：主玩法长期按固定正交战略视角设计；允许 zoom，不以 360°自由旋转作为资产设计目标。

### Shared Shape Grammar 与复杂度预算
- D16：`Shared Macro Shape Grammar + Theme Accent Vocabulary`，总原则：**同语法，不同词汇。**
- Heavy Base / Three-Stage Silhouette / Chunkiness / Bevel Family / Shape Density Gradient / Detail Replacement。
- `Gameplay Constraint Gradient`：越承担即时 gameplay 判断，主题自由度越低；Outer Diorama/Skyline 最高。
- 第三方资产必须经过 `Cardfrontification`，不能把素材包原貌直接当最终风格。
- D17：`Role-Based Silhouette Complexity Budget`；限制玩家在 112% 要解析的 silhouette events，而不只限制 tris。
- `Contour Purpose Rule`、`Function-First Contour Rule`、`Negative Space Is Geometry`、`Primary Mass Dominance`、`Deletion Pass`。
- 审查优先级：**Silhouette → Projection → Gameplay honesty → Material masses → Bevel/light → Motion/Damage → micro detail**。

## 3. 第一生产标杆

仍只先完成 `default_duel + Balanced HQ`，不要同时铺开三张地图和三个英雄。

首轮正式范围：
- HQ Common + Balanced Hero + Castle Theme；
- Blue/Red faction material；
- Damage D0–D3 / VFX sockets；
- 河床/河岸低浮雕；
- Stronghold pad 与 defense level mockup；
- Shadow Baseline/C1/C2；
- Quiet / Normal / Stress VFX benchmark；
- Information Lifecycle / Camera Bias / Shape Grammar / Silhouette benchmark。

Rapid、Engineer、Industrial、Lab 在 benchmark GO 后追加。

## 4. 资产与运行时边界

- 2D authoritative simulation 不变；3D 仍是 presentation mirror。
- 3D 资产通过集中 Registry 接入；禁止 raw asset path 散入 `Main.gd`、玩法系统和单个 effect handler。
- 世界材质必须升级为 Material Role / slot 调色，不能继续把整个 GLB 用一个 `material_override` 抹平。
- 蓝/红优先换材质/标识，不复制 gameplay-relevant mesh silhouette。
- 新正式 Blender 资产尽量以源文件解决比例，Godot runtime 优先 uniform scale。
- 实机 deterministic screenshot 才是最终美术证据。

现有位置：
- Runtime/environment：`assets/cardfront_environment/`
- 自制 GLB：`assets/cardfront_environment/source/custom/`
- KayKit source：`assets/cardfront_environment/source/kaykit_medieval_hexagon/`
- Registry：`scripts/cardfront/environment/CardfrontEnvironmentAssetRegistry.gd`
- Environment builder：`scripts/cardfront/environment/CardfrontEnvironmentBuilder.gd`
- Orthographic arena：`scripts/cardfront/arena/CardfrontOrthographicArenaView.gd`

## 5. 已知 presentation 技术债

v0.3 继续记录而尚未自动施工：
- `EnvironmentBuilder` 仍整 GLB material override，roughness≈0.84 / metallic=0，冲突 D06。
- Territory 已占领 tile 当前 faction lerp≈0.60，冲突 D10 F1 弱领土。
- Stronghold platform 当前随 owner 约 0.38 混色，冲突“主体中性”。
- Combat impact 当前每事件 new/free 一个发光 SphereMesh，冲突 D11 Pool + Coalescing。
- 所有可见 projectile 当前都有完整 trail；需要 Density Compensation / Readability LOD。
- Directional shadow 当前仍关闭；需先做 default_duel Shadow A/B benchmark。
- HQ/Tower/Creature/Stronghold 的 Contextual visibility、Damage state、Motion grammar 尚未实现。

## 6. 剩余 GrillMe 队列

### P0｜正式批量建模前必须继续锁
1. **D18 Visual Footprint / Perceived Collision Budget**：视觉模型允许超过 gameplay footprint 多少。
2. **D19 Occlusion Budget**：正交镜头下谁有资格遮挡谁，以及 120% stress 的最大遮挡权。
3. **D20 Selection / Hover / Targeting Language**：选中、可部署、目标、危险、AoE、弹道预测的语义与生命周期。
4. **D21 Material Role Runtime Contract**：`MAT_*` / faction / emissive slot 的命名与 Godot override 规则。
5. **D22 Asset Export Contract**：Blender node/socket/pivot 命名、GLB export、uniform scale、import validation、Registry fallback、自动 QA。

**D18–D22 锁定后即可进入第一批正式 Blender/Godot benchmark 施工，不需要无限 Grill 完所有未来内容才开工。**

### P1｜第一套 default_duel benchmark 前最好锁
- D23 Screen-Space Scale & Readability Budget。
- D24 HIGH/MEDIUM/LOW Quality Tier Contract。
- D25 Draft/Card UI Visual Language。
- D26 Damage/VFX/Audio Timing Hooks。

### P2｜benchmark GO 后再定
- Rapid/Engineer Hero Module 细节、地图主题资产扩展比例、更多 Stronghold/landmark、完整 accessibility palette、回放/观战镜头等。

### 应由 prototype/benchmark 标定，而不是继续纯讨论
- Shadow 精确参数、Vertical Budget 绝对高度、Faction tint 百分比、Projectile Density 阈值、Damage Gap 大小、Camera Bias 强度、具体 px/屏幕尺寸。
