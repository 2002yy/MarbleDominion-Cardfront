# Cardfront 3D Blender Source Masters

这里承接 D22 之后的可编辑 Blender 母版。Godot 通过本目录的 `.gdignore` 忽略这些源文件。

## 第一生产标杆

建议第一份母版：

`Cardfront_HQ_Master.blend`

集合/职责：

- `00_REFERENCE`：Camera_Cardfront、GroundPlane、Cell/Tower/HQ ScaleRef、readability guide；永不导出。
- `01_COMMON`：HQ Common Skeleton。
- `02_HERO`：Balanced 等 Hero Module。
- `03_THEME`：Castle / Industrial / Lab Theme Module。
- `04_DAMAGE`：D1/D2/D3 authored damage modules。
- `05_SOCKETS`：PIV_ / SOCKET_ / VFX_ 语义节点。
- `99_EXPORT`：明确的导出集合/入口。

## D22 基线

- Blender Metric；1 BU = 1m。
- Blender +Z Up，-Y Model Front。
- Root/Gameplay asset origin = Ground Contact Center。
- HQ Common/Hero/Theme/Damage 模块共享同一 HQ 原点。
- Render geometry export 前 Scale=1,1,1，Rotation applied；无 negative scale。
- 方向性 `SOCKET_` / `VFX_` local +Z 指向 outward/forward。
- Material 使用 `CF_<SURFACE>__<CHANNEL>`。
- Gameplay-driven Turret/Gate/Recoil/Capture 运动不烘死为 Blender Action，由 Godot 驱动 Pivot。

## 首轮导出目标

- `assets/cardfront_environment/formal/hq/hq_common.glb`
- `assets/cardfront_environment/formal/hq/hq_hero_balanced.glb`
- `assets/cardfront_environment/formal/hq/hq_theme_castle.glb`
- `assets/cardfront_environment/formal/hq/hq_damage_common.glb`

## P0-FT1 Tower 跨资产目标

- `assets/cardfront_environment/formal/tower/tower_common.glb`
- `assets/cardfront_environment/formal/tower/tower_interceptor.glb`
- `assets/cardfront_environment/formal/tower/tower_theme_castle.glb`
- `assets/cardfront_environment/formal/tower/tower_damage_common.glb`

Tower 母版在建模前必须先通过可执行的 D22 validator fixture contract。
必需节点至少包含 `PIV_Turret`、`SOCKET_Muzzle`、`VFX_Intercept`。

只有通过 validator 和 fixed-camera benchmark 后才能登记为正式 GO 资产。
