# Cardfront Visual Hierarchy And Scale Specification / 视觉层级与缩放规范

Version: v1.1
Approved: 2026-07-29
Status: authoritative art-reference package for the current Cardfront presentation pass

本目录是 Cardfront 当前唯一的画面构图、视觉层级和战场缩放参考包。项目进度仍只由
`docs/PROJECT_STATUS.md` 维护；本文件负责可复用的美术和界面判定标准，不建立第二份路线图。

## 1. Approved Direction / 已批准方向

> 明亮玩具沙盘 + 清晰竞技路线 + 粗轮廓占领块

Cardfront 不是皇室战争的复刻。参考作品只用于拆解成熟的信息组织方式，最终画面必须保留：

- 弹珠轨迹是主要动态焦点；
- 玩家蓝方、AI 红方和中立格在移动中仍可区分；
- 两座闸门是路线联通程度的明确开关；
- 控制舱位于战场两端，不侵占核心交战空间；
- 据点控制度可在一眼内读出；
- 三选一阶段完全暂停，并成为唯一视觉焦点。

The approved composition is a deliberate combination:

- **Minion Masters composition:** opposing bases at the two ends, combat pressure in the field, compact identity at the top edges, and card interaction centered at the bottom.
- **Into the Breach information grammar:** routes, danger, selection and outcomes appear directly where they matter, then disappear when no longer relevant.
- **Thronefall material hierarchy:** quiet bright ground, few materials, strong silhouettes, and restrained environment contrast.

## 2. Reference Responsibilities / 参考分工

| Reference | Learn | Do not copy |
| --- | --- | --- |
| Minion Masters | 双端基地对望、中央路线留白、两侧身份信息、底部卡牌焦点 | 角色比例、卡牌内容和完整 HUD 造型 |
| Into the Breach | 格子状态、攻击路径、危险预告和结果反馈的确定性 | 像素风和回合制棋盘比例 |
| Thronefall | 明亮低噪材质、强剪影、少量高价值信息 | 极简到丢失占领格和弹珠物理信息 |
| Bad North | 柔和日光、低多边形地形、外围自然框景 | 岛屿构图和无格线地形 |
| Isle of Arrows | 路径、建筑和占用关系的快速识别 | 塔防密集摆件和固定路径逻辑 |
| Ballionaire | 反例：高密度装饰与数字会争夺弹珠焦点 | 其高噪声画面结构 |

## 3. Official Sources / 官方来源

Official product pages:

- Minion Masters: https://store.steampowered.com/app/489520/Minion_Masters/
- Into the Breach: https://store.steampowered.com/app/590380/Into_the_Breach/
- Thronefall: https://store.steampowered.com/app/2239150/Thronefall/
- Bad North: https://store.steampowered.com/app/688420/Bad_North/
- Isle of Arrows: https://store.steampowered.com/app/1946970/Isle_of_Arrows/
- Ballionaire: https://store.steampowered.com/app/2667120/Ballionaire/

Engine references:

- Godot Camera3D: https://docs.godotengine.org/en/4.4/classes/class_camera3d.html
- Godot CanvasLayer: https://docs.godotengine.org/en/stable/tutorials/2d/canvas_layers.html
- Godot SubViewportContainer: https://docs.godotengine.org/en/4.x/classes/class_subviewportcontainer.html

Open-source implementation references:

- Tanks of Freedom: https://github.com/w84death/Tanks-of-Freedom
- Strongground turn-based hex strategy: https://github.com/Strongground/godot-turnbased-hex-strategy
- Isometric 3D toolkit: https://github.com/marinho/isometric-3d-toolkit

The images under `official_screenshots/` are downloaded from the official Steam CDN on
2026-07-29. They are committed for internal visual study only. They are not Cardfront
shipping assets and must not be bundled into exports.

| Local file | Official image source |
| --- | --- |
| `minion-masters-arena-01.jpg` | https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/489520/ss_ff25c94b1cc1a3731c0f51a2a31d9516d725048a.1920x1080.jpg |
| `minion-masters-arena-02.jpg` | https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/489520/ss_e4ae57dca3a26ce13a01d4ac2871f711679e0934.1920x1080.jpg |
| `into-the-breach-grid-01.jpg` | https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/590380/ss_6113590509c195f98fa64cd738df534762e0c358.1920x1080.jpg |
| `bad-north-lighting-01.jpg` | https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/688420/ss_8c3675db0a388f3717e530c93d0db27f526a5c0a.1920x1080.jpg |
| `thronefall-hierarchy-01.jpg` | https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/2239150/ss_7755da74d905e510998b08d36eb9758869e2f768.1920x1080.jpg |
| `isle-of-arrows-path-01.jpg` | https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/1946970/ss_0b2fadd7fad9b3507bb18cf4a502452fa9d066d0.1920x1080.jpg |
| `ballionaire-anti-reference-01.jpg` | https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/2667120/ss_0b9188304e5f8c80f03281fd71d412ae40296edf.1920x1080.jpg |

## 4. Visual Hierarchy / 视觉层级表

| Priority | Player must notice | Persistent presentation | Forbidden competition |
| --- | --- | --- | --- |
| P0 | 当前弹珠、命中点、攻城/压制差异 | 高亮实体、清晰轨迹、短促命中反馈 | 大型基地、背景装饰、常驻长文本 |
| P1 | 双方控制舱生命与当前齐射阶段 | 顶部镜像信息、中央计时/回合 | 四阵营旧进度条、重复英雄说明 |
| P1 | 当前阵营占领与接触前线 | 粗轮廓、局部色块、零散格角标 | 整图高饱和铺色 |
| P1 | 据点类型与控制百分比 | 据点上方紧凑徽章 | 覆盖据点平台的两行大字 |
| P2 | 闸门开度和两条路线 | 桥体、闸杆、短状态词 | 长句状态标签 |
| P2 | 生物/塔的受损与特殊状态 | 受损时 HP、状态图标、悬浮短信息 | 所有实体常驻名称和数值 |
| P3 | 英雄身份、瞄准和视野设置 | 边缘紧凑控件 | 压住战场核心的侧栏 |
| P4 | 环境叙事 | 外围低对比树石、地标剪影 | 中央高对比景物和动画 |

## 5. Scale Contract / 缩放规范

### Battlefield presentation scale

The approved readability pass exposes three deliberate presets:

| Display | Camera rule | Purpose |
| --- | --- | --- |
| 100% | `camera.size = base_size` | 看全局路线、闸门和两端控制舱 |
| 112% | `camera.size = base_size / 1.12` | 默认竞技构图，兼顾完整路线和实体可读性 |
| 120% | `camera.size = base_size / 1.20` | 强调弹珠、实体和接触点 |

Rules:

- Only the orthographic `Camera3D.size` changes.
- The authoritative 2D grid, projectile simulation, collision, targeting, gates and AI never scale.
- CanvasLayer HUD never scales with the battlefield.
- The scale is preset-based, not unrestricted mouse-wheel zoom.
- Transition duration is `0.18s`; tests and deterministic captures may request an immediate transition.
- Default is `112%` at match start.
- The three presets must keep both command chambers and both bridges readable.
- Creatures, defense towers and projectiles may receive a presentation-only
  readability multiplier in the `1.20-1.30x` range. Command chambers do not.
- Full-health entities do not show persistent HP bars or role labels. Damage
  and exceptional states may reveal concise local feedback.
- Any future screen-space entity tooltip must use camera projection, not multiply the old 2D position by the scale.

### Independent UI scale

HUD scaling is intentionally deferred. When implemented, it must be a separate accessibility
setting and must not alter battlefield framing. Do not reuse battlefield zoom as a global
`CanvasLayer.scale`.

## 6. HUD Layout Contract / HUD 层级规范

- Top center: timer, round/phase, compact two-faction territory summary.
- Top left/right: one compact hero identity plate per faction.
- Right edge: compact settings/pause/exit controls; never a tall information panel.
- Bottom left: compact direction control only.
- Bottom right: battlefield scale segmented control.
- Center and bridge approaches: no persistent HUD.
- Draft open: battlefield de-emphasized and three equal card columns become P0.
- Success, damage, repair, interception and invalid actions use transient feedback.

## 7. Stronghold Badge Contract / 据点徽章规范

- One line only: `<类型> <百分比>%`, for example `能源 66%`.
- Dark neutral plate with a faction-colored accent/readout.
- The badge floats just above the stronghold platform.
- Maximum label font size: `30`; maximum `pixel_size`: `0.013`.
- Percentage remains numeric and bold; type remains short Chinese.
- Badge must not cover marbles, bridge entrances or the entire stronghold footprint.

## 8. Color And Contrast Contract / 色彩与对比

- Background and neutral ground: bright, low saturation, medium value.
- Player: cyan-blue tint plus bold outline/marker.
- AI: warm red tint plus bold outline/marker.
- Neutral: natural green/warm gray, never dark unlit blue-gray.
- Projectiles and contact VFX have higher local contrast than the ground.
- Environment decoration stays lower contrast than units, towers, gates and ownership edges.
- Do not add purple-blue gradients, neon cyberpunk noise, or full-screen color washes.

## 9. First Slice Acceptance / 第一刀验收

- The runtime exposes `100% / 112% / 120%` battlefield scale presets.
- Changing scale moves only the presentation camera and uses a short smooth transition.
- BallWar does not create the scale control.
- Hero plates are compact and remain outside the arena core.
- The top HUD no longer reads as a four-faction legacy panel.
- Stronghold percentages appear as compact one-line badges with plates.
- Automated tests cover presets, authority isolation, HUD dimensions, badge dimensions and BallWar isolation.
- Desktop screenshots are captured at all three presets and reviewed for clipping, overlap and hierarchy.

## 9.1 Reference Comparison Pass / 参考对比收口

The second presentation pass applies the three references as one system:

- Minion Masters: the arena begins directly below a slim top combat strip;
  hero identity remains at the two corners and live controls no longer form a
  tall right-side stack.
- Into the Breach: gate state and stronghold percentage use short badges;
  persistent labels are removed when shape, color or position already carries
  the information.
- Thronefall: neutral ground uses closer checker values, edge decoration is
  sparse, repeated river stones are reduced, and default-map banners no longer
  compete with units and projectiles.

The live Cardfront HUD keeps only compact settings and pause controls. Exit is
available from the pause surface rather than as a permanent battlefield button.

## 10. Next Visual Slices / 后续画面切片

1. Replace permanent entity role text with hover/damaged/selected-only presentation.
2. Project all screen-space entity feedback from the orthographic camera.
3. Tune ground saturation and ownership edge weight from screenshot evidence.
4. Apply the approved material language to Cross Strongholds and Central Lab.
5. Add an independent accessibility UI-scale option only after battlefield hierarchy is stable.
