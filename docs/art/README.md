# Cardfront Art & 3D Production

这里是 Cardfront 正式美术生产入口。供应商素材预览、历史参考和最终实机验收必须分开看：**素材“看起来合适”不等于接入实机后通过。**

## 1. 当前正式规范

- **冻结稿：** [`Cardfront_Art_3D_Production_Spec_v0.1_2026-08-18.docx`](Cardfront_Art_3D_Production_Spec_v0.1_2026-08-18.docx)
- **状态入口：** [`../PROJECT_STATUS.md`](../PROJECT_STATUS.md)
- **现有 V-01 视觉规范：** [`../../美术参考_art_reference/cardfront_visual_hierarchy_v01/`](../../美术参考_art_reference/cardfront_visual_hierarchy_v01/)

DOCX 已锁定的决策链：

> **A → A3 → C → B → B2**

- **A** — 70% 玩具战争沙盘 + 30% 微缩世界。
- **A3** — 连续沙盘 + 弱格纹 + 强状态块；格子平时弱化，战略状态时显形。
- **C** — HQ 采用“城堡骨架 + 机械炮座 + 地图主题模块 + 英雄模块”的模块化战争棋子语言。
- **B** — 普通防御塔为 1.0 视觉基准；HQ 宽厚但不过高；据点宽而低；桥宽而更低。
- **B2** — HQ = Common Skeleton + Hero Module + Theme Module + Faction Material + Damage Module。

## 2. 第一生产标杆

只先完成 `default_duel`，不要同时铺开三张地图和三个英雄。

首轮 HQ 范围冻结为：

- HQ Common；
- Balanced Hero；
- Castle Theme；
- Blue / Red faction material；
- 基础 Damage/VFX sockets。

Rapid、Engineer、Industrial、Lab 均在 benchmark 通过后追加。

## 3. 资产边界

- 2D authoritative simulation 不变，3D 仍是 presentation mirror。
- 正式 3D 资产通过集中 Registry 接入；禁止把 raw asset path 散到 `Main.gd` 或效果处理器。
- 新 Blender 正式模型应尽量以 `Scale = 1,1,1`、`Rotation = 0,0,0` 导出；不要继续依赖强非等比运行时缩放修形。
- 蓝/红阵营优先换材质，不复制整套 mesh。
- 实机 deterministic screenshot 才是美术验收证据；单独 Blender render 不算 GO。

## 4. 现有资产位置

- Runtime/environment：`assets/cardfront_environment/`
- 自制 GLB：`assets/cardfront_environment/source/custom/`
- KayKit source：`assets/cardfront_environment/source/kaykit_medieval_hexagon/`
- Runtime registry：`scripts/cardfront/environment/CardfrontEnvironmentAssetRegistry.gd`
- Orthographic arena：`scripts/cardfront/arena/CardfrontOrthographicArenaView.gd`

## 5. 下一项 GrillMe 决策

当前**尚未锁定**统一材质语言：

1. 纯色 low-poly 玩具塑料；
2. 具有石/木/金属材质暗示、但仍保持玩具化的材质语言。

在此决策完成前，可以进行结构 blockout、比例、Socket、Origin 和轮廓验证，不应批量制作最终材质。
