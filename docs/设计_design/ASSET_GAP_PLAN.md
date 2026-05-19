# Asset Gap Plan / 素材缺口与接入计划

更新时间:
- `2026-05-15`

适用范围:
- `C:\Users\96967\Desktop\Marble Dominion Ricochet War\BallWar_v2_0\BallWar`

目标:
- 把当前项目的素材缺口整理成可交接、可继续执行的清单。
- 明确每个缺口的来源、许可证、优先级、建议接入点。
- 先把稳定、可离线复用、免高风险授权纠纷的候选素材下载到本地，减少下一位接手者的检索成本。

## 1. 结论先看

当前项目的真实缺口不是基础 UI 图像，而是下面四类:

1. `音效 / 音乐`
   - `assets/音效_sfx/` 仍为空。
   - 项目内也没有成型的音频播放层、音频总线配置、统一的 SFX 入口。
2. `字体接入`
   - `Kenney Future.ttf` 已在本地，但仍未替换目前多处 `ThemeDB.fallback_font`。
3. `语义图标`
   - 现有 `Game-Icons` 只够最小候选，不够完整覆盖阵营图腾、事件效果、HUD 状态图标。
4. `少量效果素材`
   - 当前闪烁、拖尾、摧毁、短路、胜利提示几乎全是程序化绘制，没有可复用的装饰层素材。

反过来说，下面这些并不是真缺:

1. `主菜单/面板/按钮/记分条/准星` 的基础图像包
   - 本地已经有 `Kenney + Wenrexa + Game-Icons + 背景图`。
   - 主要问题是“未接入”，不是“没有素材”。
2. `大方向视觉风格`
   - 当前蓝金科幻方向已经成立，后续提升重点是“替换扁平块”和“加反馈”，不是重做风格。

## 2. 本地已确认存在的现成素材

| 类别 | 本地位置 | 状态 | 许可证 |
|---|---|---|---|
| 科幻 UI 框体、按钮、条形框、准星、阴影 | `assets/ui/Kenney科幻UI_kenney_scifi/` | 已导入，未接入代码 | `CC0` |
| 科幻面板、箭头、装饰条、信息块 | `assets/ui/Wenrexa极简科幻_wenrexa_scifi_minimalism_01/` | 已导入，未接入代码 | `CC0` |
| 事件图标、图腾候选 | `assets/ui/游戏图标_科幻_game_icons_scifi/` | 已导入，候选有限 | `CC BY 3.0` |
| 背景图 | `assets/背景_background/wenrexa_scifi/Background.jpg` | 已导入，未正式接入 | `CC0` |
| 科幻字体 | `assets/ui/Kenney科幻UI_kenney_scifi/font/Kenney Future.ttf` | 已导入，未正式接入 | `CC0` |

参考文档:
- `assets/ASSET_SOURCES_AND_LICENSES.md`
- `美术参考_art_reference/free_ui_assets/FREE_UI_INTEGRATION_PLAN.md`

## 3. 这次已下载到本地的候选素材

本次新增下载根目录:
- `美术参考_art_reference/asset_gap_downloads/`

目录用途:
- `audio_cc0/`
  - 原始下载包和单文件音效。
- `audio_cc0_extracted/`
  - 已解包、可直接试听和二次筛选的音效。
- `music_candidates/`
  - 菜单循环 / 环境氛围 / 战斗背景候选。
- `licenses/`
  - 关键来源页和许可证说明的本地备份。

### 3.1 已下载的音效候选

| 文件 / 包 | 本地路径 | 已解包数量 | 推荐用途 | 来源 | 许可证 |
|---|---|---:|---|---|---|
| `opengameart_50_cc0_scifi_sfx.zip` | `美术参考_art_reference/asset_gap_downloads/audio_cc0/` | 50 | 子弹发射、爆炸、传送、终端、环境循环 | OpenGameArt `50 CC0 Sci-Fi SFX` | `CC0` |
| `opengameart_interface_sounds_kenney.zip` | `美术参考_art_reference/asset_gap_downloads/audio_cc0/` | 103 | 菜单点击、开关、滑动、界面确认 | OpenGameArt `Interface Sounds` | `CC0` |
| `opengameart_ui_sounds.zip` | `美术参考_art_reference/asset_gap_downloads/audio_cc0/` | 11 | 提示音、通知音、状态切换 | OpenGameArt `UI sounds` | `CC0` |
| `opengameart_beeps.zip` | `美术参考_art_reference/asset_gap_downloads/audio_cc0/` | 16 | 轮盘 tick、科技 beep、菜单 hover | OpenGameArt `Interface Beeps` | `CC0` |
| `opengameart_10_clicks_and_switches.zip` | `美术参考_art_reference/asset_gap_downloads/audio_cc0/` | 11 | 按钮点击、切换、轻确认 | OpenGameArt `10 Clicks and Switches` | `CC0` |
| `opengameart_gui_sound_effects.7z` | `美术参考_art_reference/asset_gap_downloads/audio_cc0/` | 13 | GUI confirm / cancel / error | OpenGameArt `GUI Sound Effects` | `CC0` |
| `opengameart_win_jingle.zip` | `美术参考_art_reference/asset_gap_downloads/audio_cc0/` | 34 | 胜利、结算、成功提示 | OpenGameArt `Win Jingle` | `CC0` |
| `opengameart_victory_sting.ogg` | `美术参考_art_reference/asset_gap_downloads/audio_cc0/` | 1 | 短促胜利提示 / 事件结果 | OpenGameArt `Victory Sting` | `CC0` |

当前统计:
- 音效原始包 / 单文件: `8`
- 已解包文件数: `238`
- 直接单文件音效: `1`
- 可立即筛选的音效候选总数: `239`

### 3.2 已下载的音乐 / 环境氛围候选

| 文件 | 本地路径 | 推荐用途 | 来源 | 许可证 |
|---|---|---|---|---|
| `opengameart_space_echo.ogg` | `美术参考_art_reference/asset_gap_downloads/music_candidates/` | 菜单循环 / 低存在感外层氛围 | OpenGameArt `Space Echo` | `CC0` |
| `opengameart_scifi_background_noise.ogg` | `美术参考_art_reference/asset_gap_downloads/music_candidates/` | 战斗环境底噪 / 低音量 ambience | OpenGameArt `Sci-Fi Background noise` | `CC0` |
| `opengameart_space_dungeon_bpm100.mp3` | `美术参考_art_reference/asset_gap_downloads/music_candidates/` | 菜单 / 战斗前中段循环候选 | OpenGameArt `Space Dungeon` | `CC0` |

### 3.3 本地许可页备份

本地备份位置:
- `美术参考_art_reference/asset_gap_downloads/licenses/`

已保存页面:
- `oga_50_cc0_scifi_sfx.html`
- `oga_gui_sound_effects.html`
- `oga_interface_sounds.html`
- `oga_ui_sounds.html`
- `oga_interface_beeps.html`
- `oga_10_clicks_and_switches.html`
- `oga_win_jingle.html`
- `oga_victory_sting.html`
- `oga_space_echo.html`
- `oga_scifi_background_noise.html`
- `oga_space_dungeon.html`
- `mixkit_license.html`
- `game_icons_faq.html`
- `kenney_ui_pack_scifi.html`
- `kenney_rpg_audio.html`

说明:
- `Pixabay` 的许可证页面本次抓取被 Cloudflare 拦截，所以只保留在线来源建议，不把它作为当前离线证据链的一部分。

## 4. 缺口总表

| 缺口 | 当前状态 | 推荐来源 | 许可证 | 优先级 | 建议落地位置 | 接入点 |
|---|---|---|---|---|---|---|
| 全局字体 | `Kenney Future.ttf` 已有但未用 | 本地 `assets/ui/Kenney科幻UI_kenney_scifi/font/` | `CC0` | `P0` | 建议后续镜像到 `assets/theme/fonts/` 或直接保留原路径 | `StartMenu.gd`, `StartMenuView.gd`, `RuntimeHudController.gd`, `EventRouletteView.tscn`, 所有仍依赖 `ThemeDB.fallback_font` 的界面 |
| 子弹发射音 | 完全缺失 | 本地已下 `50 CC0 Sci-Fi SFX` | `CC0` | `P0` | 后续筛选后导入 `assets/音效_sfx/bullets/` | `scripts/Turret.gd:_spawn_bullet()` |
| 格子占领音 | 完全缺失 | 本地已下 `UI sounds`、`Interface Beeps`、`50 CC0 Sci-Fi SFX` | `CC0` | `P0` | `assets/音效_sfx/capture/` | `scripts/Battlefield.gd` 的分数/归属变化路径，重点看 `scores_changed` 触发链 |
| 按钮点击 / hover | 完全缺失 | 本地已下 `10 Clicks and Switches`、`Interface Sounds`、`GUI Sound Effects` | `CC0` | `P1` | `assets/音效_sfx/ui/` | `scripts/StartMenu.gd`, `scripts/StartMenuView.gd`, 以及暂停/设置菜单按钮连接处 |
| 事件转盘 tick | 完全缺失 | 本地已下 `Interface Beeps`、`UI sounds` | `CC0` | `P1` | `assets/音效_sfx/event_roulette/` | `scripts/EventRouletteController.gd`, `scenes/ui/EventRouletteView.tscn` |
| 事件结果音 | 完全缺失 | 本地已下 `Victory Sting`、`Win Jingle`、`GUI Sound Effects` | `CC0` | `P1` | `assets/音效_sfx/event_result/` | `scripts/EventRouletteController.gd:_finish_event_round()` 附近 |
| 控制舱过门音 | 完全缺失 | 本地已下 `Interface Sounds`、`UI sounds` | `CC0` | `P2` | `assets/音效_sfx/chamber/` | `scripts/ControlChamber.gd` 的放球 / 过门 / 回弹路径 |
| 炮塔摧毁音 | 完全缺失 | 本地已下 `50 CC0 Sci-Fi SFX` 中爆炸类 | `CC0` | `P2` | `assets/音效_sfx/turret/` | `scripts/Turret.gd` 的摧毁逻辑 |
| 限时模式警告音 | 完全缺失 | 本地已下 `Interface Beeps`、`UI sounds` | `CC0` | `P2` | `assets/音效_sfx/timer/` | `scripts/RuntimeHudController.gd` 或 `Main.gd` 的倒计时逻辑 |
| 胜利 / 平局短乐句 | 完全缺失 | 本地已下 `Win Jingle`、`Victory Sting` | `CC0` | `P2` | `assets/音效_sfx/results/` | `scripts/Main.gd:_finish_with_winner()`, `scripts/Main.gd:_finish_as_draw()` |
| 背景音乐 / 环境氛围 | 完全缺失 | 本地已下 `Space Echo`, `Sci-Fi Background noise`, `Space Dungeon` | `CC0` | `P3` | `assets/音效_sfx/music/` 或 `assets/music/` | `Main.gd` 的菜单与局内状态切换链；建议未来新增统一音频控制器 |
| 阵营图腾正式版 | 仅有少量候选 SVG | 本地 `assets/ui/游戏图标_科幻_game_icons_scifi/totem_candidates/`，必要时去 Game-icons 增补 | `CC BY 3.0` | `P2` | `assets/ui/游戏图标_科幻_game_icons_scifi/faction_totems/` | `GameHUD.tscn`, `StartMenu.tscn`, 结算横幅 |
| 事件效果图标扩充 | 现有仅够最小集 | 本地 `assets/ui/游戏图标_科幻_game_icons_scifi/event_icons/`，必要时增补 Game-icons | `CC BY 3.0` | `P2` | `assets/ui/游戏图标_科幻_game_icons_scifi/event_icons/` | `EventRouletteView.tscn`, `EventRouletteController.gd` 关联显示 |
| 主菜单背景升级 | 已有 `Background.jpg` 但未正式替换 | 本地现成 | `CC0` | `P1` | 现有 `assets/背景_background/wenrexa_scifi/` | `scenes/ui/StartMenu.tscn` |
| 主题资源 `.tres` | 完全缺失 | 本地现有 UI 图像足够生成主题 | 继承原素材许可证 | `P1` | 建议新增 `assets/theme/` | `StartMenu`, `GameHUD`, `EventRouletteView`, `SettingsPanel` |

## 5. 我建议的接入顺序

### 第一轮: 立刻见效

1. 接入 `Kenney Future.ttf`
2. 把 `Background.jpg` 用到主菜单
3. 做一个最小 `AudioRouter` 或 `SfxController`
4. 先挂 4 个基础音:
   - 子弹发射
   - 按钮点击
   - 格子占领
   - 胜利提示

### 第二轮: 交互层完整

1. 菜单 hover / confirm / cancel / disabled
2. 事件轮盘 tick / result
3. 限时模式警告
4. 控制舱过门 / 炮塔摧毁

### 第三轮: 氛围和装饰

1. 菜单循环音乐
2. 战斗环境底噪
3. 阵营图腾正式版
4. 事件图标扩充
5. 胜利横幅和短路装饰层

## 6. 已下载素材如何映射到游戏需求

| 需求 | 第一选择 | 第二选择 | 备注 |
|---|---|---|---|
| 子弹发射 | `oga_50_cc0_scifi_sfx/shoot_01.ogg` | `shoot_02.ogg`, `retro_laser_01.ogg` | 高频触发，优先短、干、不过亮 |
| 格子占领 | `oga_ui_sounds/` 里的 notification 类 | `oga_interface_beeps/` | 需要短促且可叠加 |
| 按钮 click | `oga_10_clicks_and_switches/` | `oga_interface_sounds_kenney/` | hover 和 click 需要分离 |
| 按钮 hover | `oga_interface_beeps/` | `oga_ui_sounds/` | 建议比 click 更轻 |
| 轮盘 tick | `oga_interface_beeps/` | `oga_gui_sound_effects/` | 连续触发，要避免过刺耳 |
| 轮盘结果 | `opengameart_victory_sting.ogg` | `oga_win_jingle/` | 成功类和负面类建议后续拆色 |
| 炮塔摧毁 | `oga_50_cc0_scifi_sfx/explosion_01.ogg` | `explosion_02.ogg`, `retro_explosion.ogg` | 可配合现有程序化闪烁 |
| 控制舱过门 | `oga_interface_sounds_kenney/` 里的轻提示音 | `oga_ui_sounds/` | 以“叮/铛”型为主 |
| 倒计时警告 | `oga_interface_beeps/` | `oga_ui_sounds/` | 建议最后 30 秒才启用 |
| 菜单背景音乐 | `opengameart_space_echo.ogg` | `opengameart_space_dungeon_bpm100.mp3` | 前者更保守 |
| 战斗 ambience | `opengameart_scifi_background_noise.ogg` | `space_echo.ogg` 低音量铺底 | 不建议压过战斗反馈 |

## 7. 暂未下载但值得保留的在线来源

| 来源 | 适合补什么 | 当前处理意见 |
|---|---|---|
| `Mixkit` | 免费 UI / sci-fi 提示音 | 已保存 `mixkit_license.html`；可作为补充池，不建议先当主来源 |
| `Pixabay` | 菜单音乐、环境氛围 | 本次许可证页抓取被 Cloudflare 拦截；建议后续人工挑 1 到 2 条时再补 |
| `Kenney RPG Audio` | 更统一的 UI / RPG 风格通用 SFX | 已保存来源页 `kenney_rpg_audio.html`；后续如果要统一音色，可以再抓 |
| `Game-icons.net` | 新增阵营图腾、事件语义图标 | 当前本地候选已够第一轮；扩图标时记得保留 `CC BY 3.0` 署名 |

## 8. 下一位接手者的最短路径

1. 先看这份文件。
2. 再看:
   - `assets/ASSET_SOURCES_AND_LICENSES.md`
   - `美术参考_art_reference/free_ui_assets/FREE_UI_INTEGRATION_PLAN.md`
3. 如果先做音效:
   - 从 `美术参考_art_reference/asset_gap_downloads/audio_cc0_extracted/` 里筛选
   - 复制最小集合到 `assets/音效_sfx/`
   - 新增一个统一音频入口，不要把 `AudioStreamPlayer` 散着塞进每个脚本
4. 如果先做 UI:
   - 从 `Kenney Future.ttf` 和 `Background.jpg` 开始
   - 再做 `.tres` 主题资源
5. 如果先做图标:
   - 先用本地 `game_icons_scifi/`
   - 真缺再去 `Game-icons.net` 定点补

## 9. 本次工作边界

这次完成的是:
- 素材缺口审计收口
- 交接文档整理
- 一批稳定 `CC0` 音效 / 音乐候选的本地下载
- 关键许可证 / 来源页面的本地备份

这次没有做的是:
- 代码接入
- `.tres` 主题资源生产
- 最终素材筛选和统一命名
- `assets/音效_sfx/` 正式导入
