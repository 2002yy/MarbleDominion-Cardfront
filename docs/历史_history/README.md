# History Index / 历史阶段索引

本目录只存放**历史证据、旧版本记录、已完成施工批次与仓库迁移记录**。这些文件不是当前真相来源。

当前状态先看 [`../PROJECT_STATUS.md`](../PROJECT_STATUS.md)，精简版本脊柱看 [`../../CHANGELOG.md`](../../CHANGELOG.md)。

## 1. Cardfront 2026-08 重构施工归档

[`cardfront_refactor_2026-08/`](cardfront_refactor_2026-08/) 收纳原先堆在 `docs/` 根目录的：
- P0 execution guardrails；
- P0 Batch A/B/C；
- pre-implementation freeze addendum；
- P1 Batch A/B/C；
- P1 deep-commitment / route-cutover / reroll amendments；
- 2026-08-07 refactor plan。

这些文件用于追溯“当时准备怎样做、分批怎样执行”，**不得覆盖当前 `PROJECT_STATUS.md`、当前工程规范或当前美术冻结稿**。

## 2. 仓库整理记录

[`repository_cleanup/`](repository_cleanup/) 保存文档结构迁移、路径映射与整理审计。需要追旧路径时先看这里。

## 3. 旧版本阶段 README

本目录原有 `README_v*.md` 保持原样，继续作为 BallWar/Cardfront 早期阶段历史。

推荐入口包括：
- `README_v0_1_9_cardfront_engineering_closeout.md` — v0.1.9 engineering closeout；
- `README_v0_1_7d_durable_pioneer_beacon.md` — Durable Pioneer Beacon；
- `README_v0_1_6_2_cardfront_control_chamber_decoupling.md` — control-chamber decoupling；
- `README_v0_1_6_1_cardfront_fire_director.md` — fire director；
- `README_v0_1_5_card_core_lite.md` — early card core；
- `README_v0_1_0_cardfront_prototype.md` — Cardfront prototype entry；
- `README_v2_1_11_1_ui_hotfix.md` — later stable UI hotfix history；
- `README_v2_1_11_public_repo_hardening.md` — public-repo hardening；
- `README_v1_9_37_perf_benchmark.md` — historical performance benchmark。

## 4. 历史文件规则

- 历史文档可以引用当时的版本号、路径、方案与指标，不要求被重写成今天的状态。
- 新的当前决策不要追加到旧历史文件；应进入对应当前专题或 `PROJECT_STATUS.md`。
- 已完成的一次性 batch/审计在退出 active work 后归档到这里。
- 不为了“整理得漂亮”修改历史证据正文；目录迁移优先保持原 blob 内容不变。
