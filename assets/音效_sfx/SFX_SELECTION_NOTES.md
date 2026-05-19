# SFX Selection Notes / 音效筛选说明

更新时间:
- `2026-05-15`

说明:
- 这里不是原始下载包镜像，而是第一轮“可直接接线”的筛选结果。
- 命名目标是让后续代码接入时不需要重新猜素材用途。
- 原始下载包、完整解包和许可证页都保留在:
  - `美术参考_art_reference/asset_gap_downloads/`

## 当前目录结构

- `assets/音效_sfx/bullets/`
  - 子弹发射候选
- `assets/音效_sfx/capture/`
  - 格子占领 / 归属变化候选
- `assets/音效_sfx/ui_click/`
  - 按钮点击 / 菜单确认候选
- `assets/音效_sfx/ui_hover/`
  - 按钮悬停 / 轻选择候选
- `assets/音效_sfx/event_roulette/`
  - 事件轮盘 tick 候选
- `assets/音效_sfx/event_result/`
  - 事件结果正负反馈候选
- `assets/音效_sfx/chamber/`
  - 控制舱过门 / 落点类候选
- `assets/音效_sfx/turret_destroy/`
  - 炮塔摧毁候选
- `assets/音效_sfx/timer_warning/`
  - 限时模式警告候选
- `assets/音效_sfx/results/`
  - 胜利 / 结算候选
- `assets/音效_sfx/music/`
  - 菜单循环 / 战斗循环候选
- `assets/音效_sfx/ambient/`
  - 环境底噪 / 低存在感氛围候选

## 第一轮推荐优先试音

1. 子弹发射
   - `bullets/bullet_fire_light_01.ogg`
   - `bullets/bullet_fire_light_02.ogg`
2. 格子占领
   - `capture/cell_capture_confirm_01.ogg`
   - `capture/cell_capture_positive_01.wav`
3. 按钮点击
   - `ui_click/button_click_kenney_01.ogg`
   - `ui_click/button_click_soft_01.ogg`
4. 按钮悬停
   - `ui_hover/button_hover_tick_01.ogg`
   - `ui_hover/button_hover_beep_01.wav`
5. 事件轮盘
   - `event_roulette/roulette_tick_01.ogg`
   - `event_roulette/roulette_tick_beep_02.ogg`
6. 事件结果
   - `event_result/event_result_positive_01.wav`
   - `event_result/event_result_negative_01.wav`
7. 炮塔摧毁
   - `turret_destroy/turret_destroy_explosion_01.ogg`
8. 胜利结算
   - `results/result_victory_brass_01.ogg`
   - `results/result_victory_sting_01.ogg`
9. 菜单音乐
   - `music/menu_loop_space_echo.ogg`
10. 战斗环境
   - `ambient/battle_ambient_scifi_noise.ogg`

## 备注

- 当前筛选是“先覆盖功能面”，不是“最终混音定稿”。
- 后续如果要缩小包体，可以在每个子目录里保留 1 到 2 个最终版，其余回退到 `美术参考_art_reference/asset_gap_downloads/`。
- 如果要统一音色风格，优先在 `Kenney Interface Sounds` 与 `50 CC0 Sci-Fi SFX` 内部做二次收敛。
