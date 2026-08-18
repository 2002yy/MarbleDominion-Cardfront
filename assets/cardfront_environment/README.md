# Cardfront Environment / 3D Presentation Assets

本目录是 Cardfront 3D presentation 资产入口。2D authoritative simulation 不在这里获得 gameplay authority。

## 目录职责

### `source/` — Legacy / Source Compatibility
现有 KayKit 与早期 custom GLB 的兼容区。`CardfrontEnvironmentAssetRegistry.gd` 仍直接引用这里，因此**本轮不移动、不重命名**。

### `formal/` — Formal Runtime 3D
D21/D22 之后新增的正式 runtime GLB 从这里开始。正式资产必须：

- 使用 `cardfront_asset_v1` / `cardfront_v1` 合同；
- Material Role 采用 `CF_<SURFACE>__<CHANNEL>`；
- 遵守 `CF_ / GEO_ / PIV_ / SOCKET_ / VFX_ / DMG_` 节点前缀；
- 不携带 gameplay collision、Camera 或 Light；
- 通过 Asset Admission Gate 与 fixed-camera benchmark。

### 可编辑 Blender 母版
不放在 `assets/` 下，统一使用仓库根目录：

`art_source/cardfront_3d/`

该目录通过 `.gdignore` 避免被 Godot 当 runtime 资产扫描。

## 迁移原则

1. **旧路径稳定优先**：已被 `res://`、Registry 或 `.import` 依赖的资源不因整理而搬家。
2. **新合同从新资产开始**：第一套 `default_duel + Balanced HQ + Castle Theme` HQ 使用 `formal/`。
3. **Legacy adapter 只兼容旧资产**：whole-model tint / material override 不作为正式质量标准。
4. **先验证生产链，再批量迁移**：HQ benchmark GO 之后再决定 Tower/Gate/Stronghold/landmark 的迁移批次。
