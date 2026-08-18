# Legacy / Source Compatibility Zone

`source/` 是现有 3D 资产兼容区，不是 D22 之后的正式资产目标结构。

当前内容：

- `custom/`：早期 Cardfront 自制 GLB；
- `kaykit_medieval_hexagon/`：第三方 KayKit 原始/导入资产。

## 为什么暂时不搬

`CardfrontEnvironmentAssetRegistry.gd` 仍直接引用这些 `res://assets/cardfront_environment/source/...` 路径，Godot 还存在对应 `.import` 关系。仅为了目录整洁迁移会制造无收益的路径风险。

## Legacy 规则

- 可继续被当前 presentation 层读取；
- 允许现有 legacy material adapter 维持兼容；
- 不把 whole-model tint / whole-model material override 当作 D21 正式质量；
- 若某个旧资产需要大改，优先在 `art_source/` 建正式母版，并将新 runtime 导出到 `../formal/`，而不是原地继续堆叠补丁。

旧资产保留用于回滚、对照和逐步 Cardfrontification。
