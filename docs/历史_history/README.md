# History Index / 历史阶段索引

本目录存放曾经散落在根目录的详细阶段记录 `README_v*.md`。  
This folder keeps the detailed stage-by-stage BallWar history that used to live in root `README_v*.md` files.

## 使用方法 / How to use this folder

- 先看 [../../CHANGELOG.md](../../CHANGELOG.md) 获取精简版本脊柱
- 需要详细阶段说明时再打开对应的 `README_v*.md`
- 这些文件是历史记录，不是当前真相来源

- Read [../../CHANGELOG.md](../../CHANGELOG.md) first for the short milestone spine.
- Open the matching `README_v*.md` file here when you need detailed stage notes.
- Treat these files as historical records, not as the current source of truth.

## 推荐入口 / Suggested entry points

- `README_v0_1_9_cardfront_engineering_closeout.md`
  - v0.1.9 engineering closeout / version sync, CI batch, snapshot audit, effect resolver split, doc alignment, performance smoke gate
- `README_v0_1_7d_durable_pioneer_beacon.md`
  - Durable Pioneer Beacon / persistent beacon device that periodically converts nearby neutral cells; device tetralogy complete
- `README_v0_1_7c_engineer_bot_lite.md`
  - Engineer Bot Lite / reinforces nearby owned-border cells with fortify stacks per tick
- `README_v0_1_7b_absorber_core_lite.md`
  - Absorber Core Lite / absorbs enemy bullets within radius, grants energy on kill
- `README_v0_1_7a_device_core.md`
  - Device core layer / placement, lifetime tick, snapshot; 3 types registered, no effects
- `README_v0_1_6_2_cardfront_control_chamber_decoupling.md`
  - Cardfront control-chamber decoupling / hides legacy control chambers and +ball buttons, adds automatic/card-directed fire HUD status, global + per-owner shot budgets
- `README_v0_1_6_1_cardfront_fire_director.md`
  - Cardfront fire director / automatic low-frequency firing, FireIntent, target scorer, Calibrated Shot target-bias steering
- `README_v0_1_6_1_pioneer_beacon_lite.md`
  - Pioneer Beacon Lite / logic-only owned-border pulse converting up to 3 nearby neutral cells
- `README_v0_1_6_first_card_effects.md`
  - Cardfront first card effects / Morale Fluctuation real morale effect, Calibrated Shot target bias, rollback tests
- `README_v0_1_5_card_core_lite.md`
  - Cardfront card core lite / fixed 3-card hand, resource costs, target validation, Fortify effect
- `README_v0_1_3_deployment_rules.md`
  - Cardfront deployment-rules slice / owned cell, owned border, and controlled-region permission checks
- `README_v0_1_2_1_cardfront_visibility_polish.md`
  - Cardfront visibility polish / compact economy debug panel and Cardfront-only low-pressure bullet visuals
- `README_v0_1_2_region_morale.md`
  - Cardfront region-morale slice / region-local morale ownership shifts with deterministic RNG
- `README_v0_1_1_region_yield.md`
  - Cardfront region-yield slice / resource state, yield rules, yield calculator, economy tick, and debug panel
- `README_v0_1_1_region_instances.md`
  - Cardfront region-instance slice / region_id, explicit region instances, and per-region control statistics
- `README_v0_1_1_region_map.md`
  - Cardfront region-map slice / 卡牌前线区域层：RegionMap、区域覆盖层、无经济 tick
- `README_v0_1_0_cardfront_prototype.md`
  - Cardfront prototype branch entry / 卡牌前线原型分支入口：新模式、双阵营基线、8 分钟结算
- `README_v2_1_11_1_ui_hotfix.md`
  - Latest Stable / 当前稳定版：控制仓门文字裁切热修复
- `README_v2_1_11.md`
  - encoding recovery, Android export fix, public repo hardening / 编码恢复、Android 导出修复、公开仓库收口
- `README_v2_1_11_public_repo_hardening.md`
  - public repository hardening / 公开仓库收口：文档分层、CI 接入、导出脚本清理
- `README_v2_1_10.md`
  - security & performance hardening / 安全加固与性能优化
- `README_v2_1_9_settings_and_result_panel.md`
  - settings system, result panel / 设置系统与结算面板
- `README_v2_1_8_decor_and_chamber_state.md`
  - decor-layer event model, chamber-state extraction / 装饰层事件化与状态外提
- `README_v2_1_4_restore_interfaces_and_perf_cleanup.md`
  - stable structural baseline / 恢复接口与结构基线
- `README_v2_0_7_start_menu_scene.md`
  - start-menu scene migration / 开始菜单场景迁移
- `README_v1_9_37_perf_benchmark.md`
  - performance benchmark milestone / 性能基准测试里程碑

## 命名规则 / Naming rule

- `README_v*.md` — 每个文件对应一个历史阶段或里程碑 / one file per historical stage or milestone
