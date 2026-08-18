# Cardfront Art & 3D Production

这里是 Cardfront 正式美术生产入口。供应商素材预览、Blender 单独渲染和实机验收必须分开看：**只有接入正式战场后的确定性截图与性能/可读性验证，才能成为 GO 证据。**

## 1. 当前生产权威

- **完整基础冻结稿（D01–D17）：** [`Cardfront_Art_3D_Production_Spec_v0.3_2026-08-18.docx`](Cardfront_Art_3D_Production_Spec_v0.3_2026-08-18.docx)
- **P0 生产合同 v0.4（D18–D22）：** [`CARDFRONT_P0_PRODUCTION_CONTRACT_V0.4_2026-08-18.md`](CARDFRONT_P0_PRODUCTION_CONTRACT_V0.4_2026-08-18.md)
- **资产仓库整理 v1：** [`ASSET_REPOSITORY_ORGANIZATION_V1_2026-08-18.md`](ASSET_REPOSITORY_ORGANIZATION_V1_2026-08-18.md)
- **上一版 DOCX：** [`Cardfront_Art_3D_Production_Spec_v0.2_2026-08-18.docx`](Cardfront_Art_3D_Production_Spec_v0.2_2026-08-18.docx)
- **早期冻结稿：** [`Cardfront_Art_3D_Production_Spec_v0.1_2026-08-18.docx`](Cardfront_Art_3D_Production_Spec_v0.1_2026-08-18.docx)
- **项目状态入口：** [`../PROJECT_STATUS.md`](../PROJECT_STATUS.md)

本轮完整排版 DOCX v0.4 已生成并交付，SHA-256：

`1ac0c0f033088eaea132e72452f992cff95b55aa63d052858284f8c22c50a6d2`

仓库连接器当前只写 UTF-8 文本，因此仓库内以 v0.4 Markdown 合同镜像承接 D18–D22；v0.3 DOCX 与旧版本继续保留，避免伪造/损坏二进制文件。

当前冻结链：

> **D01 A → D02 A3 → D03 C → D04 B → D05 B2 → D06 MAT-B → D07 SHD-C → D08 TER-C → D09 DIO-B → D10 FAC-C → D11 VFX-C → D12 INF-C → D13 DMG-C → D14 MOT-C → D15 CAM-C → D16 SHP-C → D17 SIL-C → D18 FPT-C → D19 OCC-C → D20 INT-C → D21 MAT-C → D22 EXP-C**

## 2. 已锁定核心语言

- 70% 玩具战争沙盘 + 30% 微缩世界；连续沙盘 + 弱格纹 + 强状态块。
- 2D authoritative simulation 不变；3D 是 presentation mirror。
- `Geometry Honesty / Damage Honesty / Motion Honesty`：视觉不得暗示不存在的规则、失效或时机。
- `Faction Signal Hierarchy`：形状=类型，阵营信号=所属，Animation/VFX=状态。
- `Contextual Hybrid`：World tells identity, state and change; HUD tells exact value, comparison and history。
- `Toy-Mechanical Motion + Snap–Settle`；运动和 VFX 都是注意力预算。
- `Controlled Camera-Biased Modeling`：允许为固定正交镜头强化读取，但 Axis/Footprint/Hit truth 不得伪造。
- `Shared Macro Shape Grammar + Theme Accent Vocabulary`：同语法，不同词汇。
- `Role-Based Silhouette Complexity Budget`：先管 silhouette events，再管 material slots / tris。

## 3. D18–D22 P0 生产合同

### D18｜Layered Perceived Footprint
G0 gameplay truth → G1 grounded visual → G2 elevated readability → G3 ephemeral interaction。贴地最诚实；提高读取优先向上、向 Crown/厚度/Bevel 花预算。

### D19｜Tactical Occlusion Priority
O0 Critical Truth → O1 Critical Dynamic → O2 Strategic Anchor → O3 World Structure → O4 Dressing。装饰必须给玩法让路；Bridge/Gate/Frontline/HQ 出口是 Protected Readability Corridor。

### D20｜Layered Interaction Grammar
Ground=合法性，Object=当前对象，Target=对象关系，Trajectory=路径，Area=范围。默认最多 **1 Primary Spatial Overlay + 1 Secondary Precision Cue**。

### D21｜Semantic Material Role
正式接口：`CF_<SURFACE>__<CHANNEL>`。禁止正式 gameplay asset 整模 faction tint；unknown role Formal validation FAIL，runtime neutral-safe fallback。

### D22｜Machine-Verifiable Asset Export
1 BU=1m；Blender +Z Up / -Y Model Front；Ground Contact Center origin；`CF_/GEO_/PIV_/SOCKET_/VFX_/DMG_`；presentation GLB 无 gameplay collision/Camera/Light；`Validate, Don't Heal`。

**Asset Done = Contract PASS + Fixed-Camera Benchmark PASS。**

## 4. 资产目录边界

### 现有兼容区 — 不搬
- `assets/cardfront_environment/source/custom/`
- `assets/cardfront_environment/source/kaykit_medieval_hexagon/`

Registry 仍直接引用这些路径，因此本轮保留原位；whole-model material override/tint 仅视为 legacy adapter。

### 新 Formal runtime
- `assets/cardfront_environment/formal/`

第一批目标：
- `hq/hq_common.glb`
- `hq/hq_hero_balanced.glb`
- `hq/hq_theme_castle.glb`
- `hq/hq_damage_common.glb`

### 可编辑 Blender 母版
- `art_source/cardfront_3d/`

通过 `.gdignore` 与 Godot import scan 隔离。`.blend` 不当 runtime 资源使用。

## 5. 第一 Formal Benchmark

停止继续纯 Grill。第一轮只验证：

`default_duel + Balanced HQ + Castle Theme`

生产链：

`Reference Kit → HQ Common → Balanced Hero → Castle Theme → D0/D2/D3 → Semantic Material → Export Validator → Godot Import → Shadow C → deterministic screenshots`

Bridge/Gate/Tower/Stronghold 暂可使用现有 primitive/legacy，避免合同未验证前批量返工。

GO 条件至少覆盖：
- Structural/Material contract PASS；
- Blue/Red 与 D0/D2/D3 instance isolation PASS；
- 100/112/120% + 760×540；
- Shadow / Occlusion / Footprint / Interaction honesty；
- fixed-camera screenshot review。

## 6. 已知 presentation 技术债

- `EnvironmentBuilder` 仍整 GLB material override（roughness≈0.84 / metallic=0）。
- `_apply_building_material_pass()` 仍 whole-model darken/faction tint。
- Occupied tile faction lerp≈0.60，冲突 F1 弱领土。
- Stronghold platform owner 混色约 0.38，冲突主体中性。
- Combat impact 每事件 new/free SphereMesh；应演进为 Pool + Coalescing。
- 所有可见 projectile 仍完整 trail；需 Density Compensation / Readability LOD。
- Directional shadow 当前仍关闭；需 Shadow A/B benchmark。

## 7. Benchmark 后再 Grill

不阻挡首个 Formal Benchmark：

- D23 Screen-Space Scale & Readability Budget
- D24 Quality Tier Contract
- D25 Draft/Card UI Visual Language
- D26 Damage/VFX/Audio Timing Hooks

Shadow 精确参数、Vertical Budget 绝对高度、Faction tint、Projectile Density 阈值、Damage Gap、Camera Bias、G1/G2 外扩、Hidden Critical Frame、具体 pixel target 均由 prototype/benchmark 标定，不继续纸面硬写死。
