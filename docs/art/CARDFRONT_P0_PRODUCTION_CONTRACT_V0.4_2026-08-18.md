# Cardfront P0 Production Contract v0.4

日期：2026-08-18

本文件是 v0.3 完整美术/3D/VFX 规范之后的 **P0 生产合同冻结补充**。它冻结 D18–D22，并明确：**纯 Grill 到此收口，下一阶段进入 `default_duel + Balanced HQ + Castle Theme` Formal Benchmark。**

完整排版 DOCX v0.4 已作为本轮交付生成；仓库内本文件提供可 diff、可审查的文本镜像。

## D18 FPT-C — Layered Perceived Footprint Contract

四层：

- G0 Authoritative Footprint：gameplay truth。
- G1 Grounded Visual Envelope：贴地视觉严格接近 G0。
- G2 Elevated Readability Envelope：允许受控 Camera Bias。
- G3 Ephemeral / Interaction Envelope：VFX、halo、selection、AoE 等临时信息。

冻结规则：Footprint Conservation、Solid Contact Truth、Hit Surface Truth、Directional Overhang、Readability Upward、Precision on Demand。

## D19 OCC-C — Tactical Occlusion Priority Contract

优先级：

O0 Critical Truth → O1 Critical Dynamic → O2 Strategic Anchor → O3 World Structure → O4 Dressing。

冻结规则：Decorative Yield、Protected Readability Corridor、Wide-Not-Tall、Continuity Cue、X-Ray Is a Precision Tool、Shadow Is a Soft Occluder。

## D20 INT-C — Layered Interaction Grammar

五通道：

- Ground = 合法性
- Object = 当前对象
- Target = 对象关系
- Trajectory = 路径
- Area = 范围

冻结规则：Shape Before Color、Reticle Before Outline、Input-Agnostic Focus、Show Permission / Localize Rejection、State-Inside / Interaction-Outside、Certainty Encoding、Prediction ≠ Event、One Primary Spatial Question、Interaction Concurrency Budget、Stable Choice Indicators Become Still。

## D21 MAT-C — Semantic Material Role Contract

正式材质接口：

`CF_<SURFACE>__<CHANNEL>`

Surface Role 第一版：STONE / WOOD / METAL / CERAMIC / CLOTH / FOLIAGE / WATER / ENERGY。

Runtime Channel：STATIC / THEME / FACTION_PRIMARY / FACTION_TRIM / OWNERSHIP / CORE / DAMAGE。

冻结规则：No Whole-Model Faction Tint、Persistent State May Touch Materials; Interaction State Should Not、Contract Not Guessing、Semantic-Safe Fallback、Shared by Default / Instanced by State、Damage Material Follows Damage Geometry。

现有 `EnvironmentBuilder` 与 `_apply_building_material_pass()` 的 whole-model override/tint 继续作为 legacy adapter，不代表正式资产质量。

## D22 EXP-C — Machine-Verifiable Asset Export Contract

### Authoring
- Blender Metric，1 BU = 1m。
- Blender +Z Up，-Y = Model Front；导入 Godot 后 +Y Up，+Z = Model Front。
- Gameplay Core origin = Ground Contact Center；HQ Common/Hero/Theme/Damage 共享 HQ origin。

### Packaging
One GLB = One Runtime Responsibility。

首个 HQ benchmark：
- `hq_common.glb`
- `hq_hero_balanced.glb`
- `hq_theme_castle.glb`
- `hq_damage_common.glb`

### Node Contract
- `CF_` root
- `GEO_` visible geometry
- `PIV_` gameplay-driven pivot
- `SOCKET_` attachment
- `VFX_` presentation anchor
- `DMG_` damage module

方向性 Socket local +Z = outward/forward。

### Export / Authority
- 可见 Mesh 进入导出前 Scale=1,1,1、Rotation applied、无 negative/non-uniform correction scale。
- `00_REFERENCE` 中 Camera/ScaleRef/readability guide 不导出。
- presentation GLB 不携带 gameplay Collision、Camera、Light。
- Gameplay-driven Turret/Gate/Recoil/Capture 由 Godot 驱动 Pivot。
- Formal pipeline 遵守 **Validate, Don't Heal**。

### Done Definition

`Asset Done = Contract PASS + Fixed-Camera Benchmark PASS`

## P0 收口

D18–D22 已全部冻结。不要继续为了理论完整性无限 Grill。

下一阶段只验证生产合同，不一次重做整张地图：

`Reference Kit → HQ Common → Balanced Hero → Castle Theme → D0/D2/D3 → Semantic Material → Export Validator → Godot Import → Shadow C → deterministic screenshots`

GO 之后再扩 Tower / Gate / Stronghold / Rapid / Engineer / Industrial / Lab。

## Benchmark 后再收敛

- D23 Screen-Space Scale & Readability Budget
- D24 Quality Tier Contract
- D25 Draft/Card UI Visual Language
- D26 Damage/VFX/Audio Timing Hooks

Shadow 数值、Vertical Budget 绝对高度、Faction tint、Projectile density threshold、Damage Gap、Camera Bias 强度、G1/G2 外扩比例、Hidden Critical Frame、具体 pixel target 均交由 benchmark 标定。
