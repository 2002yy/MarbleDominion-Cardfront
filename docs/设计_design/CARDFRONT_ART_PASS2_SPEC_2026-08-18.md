# Cardfront 第二轮 Art Pass 规范（决策锁定版）

日期: 2026-08-18 | 状态: **已锁定**（基于 V-01 验收 + 2026-08-18 五张实机截图评审）
配套: `docs/PROJECT_STATUS.md`（现行状态入口）、`docs/画质档位参数速查表.md`（性能档位）

本轮不推倒重做。方向延续"明亮玩具沙盘 + 清晰竞技路线 + 粗轮廓占领块"，2D 权威模拟不动，3D 只做表现层。

---

## D1 地表范式 = A3 连续沙盘 + 弱格纹 + 强状态块

格子存在，但平时不抢镜。远看是一张地图，不是一张表格。

| 层 | 名称 | 内容 | 关键规则 |
|---|---|---|---|
| L0 | 沙盘底座 | 厚底板 + 木质/石质包边、铆钉、小旗杆、阵营刻印 | 全部装饰只出现在外围 |
| L1 | 普通地面 | 连续草地/泥土，2-3 种缓慢大块明度变化 | 不要每格独立凸起，极浅刻线即可 |
| L2 | 领土状态 | 底色轻 tint + 四边 inset rim | 草还是草，不是整块蓝/红塑料板 |
| L3 | 前线/防御 | 防御值实体化（沙袋/矮墙/拒马/护板） | 玩家不读数字，光看地面知道这条线多硬 |
| L4 | 据点/建筑 | HQ、桥、塔、能源、工厂、实验室 | 唯一明显高于棋盘的层 |

- 同阵营内部领土应视觉融成整块；只有阵营交界出现厚前线实体结构。
- 孤立占领格 = 插在敌后的棋片（SparseClaimMarkers 概念艺术化，不重构玩法）。
- 视觉复杂度随战局增长：开局干净安静 -> 中期前线显现 -> 后期战争痕迹。
- 现有 `TerritoryBoundaries`（深色 BoxMesh 厚 0.36/0.30）改为**双层边界**：底层细暗边制造厚度 + 上层阵营色 rim；仅前线达到最大粗度。

## D2 HQ = 模块化战争棋子（城堡骨架 + 机械炮座 + 地图/英雄模块）

不做 3 英雄 x 3 地图 = 9 套 HQ；做 **1 主骨架 + 3 地图皮肤 + 3 英雄模块**。

```
公共骨架: 厚底盘 / 中央核心 / 旋转炮座 / 两个侧翼体块 / 受击破损接口
地图皮肤: default_duel=石块+木+旗 | cross_resource=铆钉+管道+烟囱 | central_lab=白石+晶体+能量环
英雄模块: 均衡指挥官=标准双肩 | 连射炮手=多管炮/弹仓 | 筑垒工程师=护板/工程支架
```

硬规则：
1. **灰度识别**：转灰度后仍一眼可辨"这是主基地"。HQ 靠宽、低、三段式轮廓取胜，不靠加高。
2. **横向 vs 纵向**：普通塔强调纵向，HQ 强调横向（解决当前 HQ 与塔轮廓接近的问题）。
3. **阵营色只占可见面积 20-30%**：中性主体 + 旗帜 + 炮带 + 核心灯。
4. **禁止运行时非等比缩放塑形**。现债 `CHAMBER_GLB_SCALE = Vector3(1.78, 0.62, 1.05)`（CardfrontOrthographicArenaView.gd:46）待正式 HQ 替换后删除。
5. 破损四档（100-70 / 69-40 / 39-15 / 14-1 / 0 解体），Blender 拆件：Base / Core / Turret / LeftArmor / RightArmor / Banner / DamagePiece_A / DamagePiece_B；Godot 按血量隐藏护板、显示裂痕 Decal、加烟、改 Emission、装甲飞出。
6. 预算 3k-6k triangles。资源投入：大倒角、清晰轮廓、6-8 个大色块、炮口、门/核心、旗帜、破损模块。不雕砖缝/螺丝/窗框。

### B2 装配契约

HQ 不是一个按英雄/地图复制的完整 GLB，而是一个共享根节点上的受控装配体：

```
ChamberTower / HQ_Root
├─ hq_common.glb
├─ hq_hero_balanced.glb
├─ hq_theme_castle.glb
└─ hq_damage.glb（默认隐藏，按 HP 状态启用）
```

- Common、Hero、Theme 模块都以 HQ 根原点导出，socket 坐标在模块之间保持一致；这样 Godot 只需统一缩放和挂接，不需要为每个组合重新校正位置。
- Common 必须包含 `TurretPivot`、`Socket_Muzzle`、`Socket_Hit_L/R`、`Socket_Smoke_L/R`、`Socket_Destroy_Core`；Hero 模块内部保留自己的 socket parent，避免 GLB 分离导出丢失父变换。
- Godot 运行时按模块名挂接 `HQHeroBalanced`、`HQThemeCastle`、`HQDamageModule`，并只让 `TurretPivot` 跟随瞄准旋转；HQ 根和 Core 不旋转。
- `MAT_FACTION_PRIMARY` / `MAT_FACTION_SECONDARY` 是唯一阵营换色入口；蓝红共享 mesh，其他材质只做 darken，不被全体 tint 成阵营色。
- 第一 benchmark 只交付 `Common + Balanced + Castle + Blue/Red`；Rapid、Engineer、Industrial、Lab 等模块等 default_duel 112% 验收通过后再扩展。

## D3 尺寸层级 = 三级战术轮廓体系（塔 = 1.0 基准）

| 资产 | 视觉高度 (x塔) | 占地 | 备注 |
|---|---|---|---|
| HQ | **1.35-1.55** | 宽 5-6 格 x 深 3-4 格（Presentation Footprint，非逻辑格子） | 宽 2.2-2.6 x 塔；Base=100%宽 / Core=55-70% / Turret=25-40%，金字塔式轮廓 |
| 桥/闸 | 桥栏 0.30-0.45 / 闸门机械 0.60-0.80 | 横向很宽 | **桥负责横向引导，不纵向抢镜**；曾发生高桥遮挡桥区战斗被剔除的事故，此约束永久生效 |
| 据点核心 | 0.6-1.1 | 2.0-3.0 格 | 面积可大、高度不能大；能源=地面装置（环形），实验室=宽而扁（穹顶），都不是塔 |
| 普通防御塔 | **1.0（基准）** | 约 1.3x1.3 格，底座可 1.6x1.6 | 组成: Base/TowerBody/Turret/Weapon/FactionPiece/Core；800-2k tris |
| 小型单位 | 0.4-0.6 | 0.6-0.9 格 | 轮廓极简，职责是"动"，不是地标 |

- 视觉优先级目标：**HQ -> 活跃战斗 -> 塔 -> 据点 -> 桥 -> 环境装饰**（当前病灶：据点方块 -> HUD -> HQ -> 战斗）。
- **英雄模块不改变 HQ bounding box**：只改上部轮廓/武器/护甲/装饰/VFX，不改占地与总高，否则构图随英雄漂移。
- 正交相机下高模型无透视缩小，遮挡是实打实的——一切"更高"的提议默认可疑。

## Blender 坐标与导出标准（全模型强制）

```
1 Blender Unit = 1 Godot meter
Origin = 底座中心 | +Y 向上 | Forward = -Z
导出 GLB: scale (1,1,1), rotation (0,0,0)
Godot 内只允许 scale = Vector3.ONE * uniform_scale
```

## 共享材质体系（KayKit 与自制件统一换装）

`stone / wood / metal-dark / neutral-cream / faction-primary / faction-highlight / emissive`
统一 bevel 宽度、统一 low-poly 法线语言、统一粗糙度、阵营可换色部件。禁止每个 GLB 自带一套独立 PBR。

## 第一批模型族（先做 6+1，不撒胡椒面）

1. 基准防御塔（1.0 参照物，本批一切尺寸的标尺）
2. 沙盘边框模块（L0）
3. 前线边界模块（L3 双层边界）
4. 1-4 级防御工事模块（L3）
5. 正式 HQ 主骨架 + default_duel 皮肤（L4）
6. 正式桥 + 闸门（L4）
7. 正式据点底座（L4，形状即图标，去 UI 化）

树/石头/房子/旗子全部排后。现有 GLB 保留/重做判定清单另行评审后补入本文件附录。

## 建模原则（固定正交远景，屏幕上只有几十像素）

**轮廓 > 大色块 > 倒角受光 > 动画反馈 > 小纹理细节**
LOD 暂不做（固定镜头距离变化小）；优先控材质数、透明材质、阴影、draw call、VFX。重复件（树石栏杆）继续 MultiMesh，数量增大后按左/右/上/下拆分以便视锥剔除。

## 阴影方案（P0 执行项）

单太阳主光 + 很柔的环境填充 + 克制接触阴影（Bad North 式玩具阴影，非军事重阴影）。开启 `shadow_enabled` 但限制 Shadow Max Distance 只覆盖竞技场主体；低端档降 shadow map 分辨率；树木/石头等外围件改廉价 blob shadow。

---

### 决策记录

| 决策点 | 选项 | 结论 | 日期 |
|---|---|---|---|
| 地表范式 | A1 积木格 / A2 隐藏格子 / **A3 连续沙盘+弱格纹+强状态块** | A3 | 2026-08-18 |
| HQ 形态 | A 纯城堡 / B 纯战争机械 / **C 模块化战争棋子** | C | 2026-08-18 |
| 尺寸体系 | A 同尺度 / **B 三级战术轮廓** / C Boss 建筑 | B | 2026-08-18 |
| 默认视野 | 100 / **112** / 120 | 112（已修 DEFAULT_PRESENTATION_SCALE，commit 30996ea） | 2026-08-18 |
| 阴影方案 | **D07 SHD-C** 选择性实时阴影 | shadow_enabled=true, MEDIUM/HIGH on, LOW off; dressing cast_shadow only on HIGH | 2026-08-18 |
| 地形低浮雕 | **D08 TER-C** 语义低浮雕 | PlaneMesh top full footprint (no physical gap); occupied +0.05m elevation; boundary skirt at ownership edges | 2026-08-18 |
| Grid 工程规则 | **Grid Is Presentation, Not Geometry** | Terrain Top Surface 不得通过真实 cell 间隙表达网格；TILE_GAP 仅供 skirt/其他几何使用 | 2026-08-18 |
| 领土边界 | **B1 Macro Territory Contour** | run-merged segments; T1 low rim (0.02×0.08); T2 frontline keeps thick (0.24×0.36); B2 connected-region perimeter 暂停 | 2026-08-18 |
| 河流可读性 | 水面增宽 + 河岸外移 | z-extent 2.0→3.2×z_scale; banks ±1.18→±1.62×z_scale | 2026-08-18 |
| 据点白环 | 削弱视觉竞争 | ring scale 0.42→0.32; brightness/opacity/emission 降低 | 2026-08-18 |

---

## P0 验收状态

| 项目 | 结果 | 关键 commit |
|---|---|---|
| P0-1 阴影 | PASS | `d622300` shadow_enabled + ambient retune + selective caster |
| P0-2 低浮雕地形 | PASS | `ff9ba1e` low-relief + `fc7e651` skirt system + `115d874` no physical tile gap |
| P0-3 HQ 轮廓 | PASS | `6bafcdb` thicker base + 4-side faction panels + thicker cannon + larger flags |

**下一步：Formal Benchmark** — Material Role (D21) / Faction Signal (D10) / HQ State (D13) / 首套正式资产集成。

### 2026-08-20 Formal Benchmark 退出门补充

HQ D21/D13 实现后，Formal Benchmark 仍未 GO。为验证生产合同可跨资产
复用，退出门增加一条模块化 Interceptor Tower 垂直切片；先实现可复用
D22 validator，再建模。

Tower 保持 `1.0` 高度基准，使用 Common + Interceptor + Castle Theme +
Damage 模块，覆盖 L1–L3、HP 4–0、供电/压制/额度耗尽/三级反击，且所有
建造、升级、摧毁动画不得改变 gameplay authority。

执行 checkpoint：
[`../cardfront_refactor_checkpoints/P0-FT1_formal_interceptor_tower_benchmark.md`](../cardfront_refactor_checkpoints/P0-FT1_formal_interceptor_tower_benchmark.md)
