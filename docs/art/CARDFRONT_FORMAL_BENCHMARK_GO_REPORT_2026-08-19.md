# Cardfront Formal Benchmark GO 报告 — 2026-08-19

范围（v0.4 §17 第一批）：`default_duel + Balanced HQ + Castle Theme`。
代码基线：commit `8cf7bc6`。全部截图为同一确定性 seed/state，capture 工具 `CARDFRONT_CAPTURE_*` 环境变量驱动。

---

## 1. GO 条件逐项证据

### GO-1 结构校验 — PASS（脚本级）

4 个 formal GLB 结构解析（python glTF json dump）：

| GLB | meshes | materials | cameras/lights | 关键节点 |
|---|---|---|---|---|
| hq_common.glb | 20 | 7 (MAT_*) | **0** ✓ | TurretPivot、Socket_Muzzle、Socket_Hit_L/R、Socket_Smoke_L/R、Socket_Destroy_Core 全在 ✓ |
| hq_hero_balanced.glb | 9 | 6 | **0** ✓ | HeroModuleSocket_Top/Shoulder_L/R ✓ |
| hq_theme_castle.glb | 23 | 4 | **0** ✓ | Castle shoulders/merlons/flags/crown ✓ |
| hq_damage_common.glb | 10 | 3 | **0** ✓ | Damage_01/02/03(+Breach/Crack)、Armor_L/R、CoreCover/CoreExposed/CoreHalo ✓ |

合计 62 mesh / ~3.9k tris（3k–6k 预算内）。无 negative scale（Blender 导出前 apply）。
尺寸验证：`tools/blender/verify_hq_exports.py`。

> ⚠️ 口径说明：完整 D22 Asset Admission Gate（自动 validator 工具）尚未建成；本项为脚本级结构验证 + 运行时 166 项 Arena 测试背书。材质命名为 `MAT_*` legacy adapter，非完整 `CF_<SURFACE>__<CHANNEL>`——已在 v0.4 §18 技术债登记，不阻断本批 GO。

### GO-2 材质 role — PASS（代码级）

- `_apply_building_material_pass` named-material 路径识别 9 个 MAT_* 角色通道（FACTION_PRIMARY→tint / FACTION_SECONDARY→dark tint / CORE→暖橙 emissive 3.0 / METAL→metallic 0.72 / DAMAGE / STONE / CREAM / WOOD 各自处理）
- whole-model tint 仅存于 legacy 路径，formal HQ 不经过
- 测试断言：faction rim 跨弹种一致、Blue/Red Tower 材质实例隔离
> ⚠️ 独立 role debug 可视化视图未建；以代码路径+测试替代。列为 benchmark 后补齐项。

### GO-3 Blue/Red × D0/D2/D3 独立状态 — PASS

状态机：D0 >70% 隐藏 / D1 ≤70% Armor+Damage_01 / D2 ≤40% +Damage_02 / D3 ≤15% +Damage_03+Breach+Crack+Core 暴露+runtime glow 脉冲。按 owner_id 字典隔离。
截图：`GO3_blue_D2/D3.png`、`GO3_red_D2/D3.png`（互为镜像血量，另一侧保持 40/40）。
像素验证：D3 vs D0 @112% 暖橙像素 2358 vs 91（26×）。

### GO-4 缩放矩阵 — PASS

`GO4a_scale100/112/120_D0.png` @1600×1000、`GO4b_narrow760x540_D0.png`。
760×540 下阵营区块/河/桥/HQ 仍可辨（另见灰度版 GS_narrow）。

### GO-5 诚实性无阻断 — PASS（附 1 项观察）

- Shadow：`GO5_shadowON/OFF_ref_112.png` 同分辨率同画质 A/B，ON 提供接地感且无黑楔子；dressing 阴影仅 HIGH 开启
- Footprint：HQ uniform scale（Vector3.ONE），无 D18 违规放大
- Interaction：`CONTEXT_draft_112.png` 三选一覆盖时战场仍可见
- Occlusion：macro contour T1 低唇(0.02m)不遮挡；前线 T2 保持语义权重
- 观察（非阻断）：D3 runtime glow 半径较大可再 polish；静态图无法验证脉冲时序（建议后续补 GIF）

---

## 2. 截图清单（截图_screenshots/formal_benchmark/）

| 文件 | 内容 |
|---|---|
| GO4a_scale100/112/120_D0.png | 缩放三档 · 健康态 |
| GO4b_narrow760x540_D0.png | 窄屏 stress |
| GO3_blue_D2.png / GO3_blue_D3.png | 蓝方 28% / 8% |
| GO3_red_D2.png / GO3_red_D3.png | 红方 28% / 8% |
| GO5_shadowOFF_ref_112.png / GO5_shadowON_ref_112.png | 阴影 A/B |
| CONTEXT_draft_112.png | Draft 交互语境 |
| GS_scale112_D0.png / GS_blue_D2.png / GS_blue_D3.png / GS_narrow760x540_D0.png | 灰度诊断（§18 Faction/Damage Grayscale） |

## 3. 结论与建议

**五项 GO 条件全部有据可判，建议人工复检后签发 GO。**
GO 后解锁：Tower/Gate/Stronghold 正式资产批量接入、Rapid/Engineer hero 模块扩展、§18 标定测试矩阵（Shadow 参数细调 / Camera Bias / Silhouette Budget）。
遗留（不阻断）：Admission Gate 自动化工具、role debug 视图、VFX Pool、trail Density Compensation、D25 Draft UI。
