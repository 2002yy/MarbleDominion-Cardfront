# Documentation Map / 文档地图

This page is the navigation and authority map for repository documentation. It does not replace frozen specifications or checkpoint evidence.

## Authority Order / 权威顺序

When documents disagree, use this order:

1. `docs/PROJECT_STATUS.md` for current branch, latest accepted checkpoint, and the only allowed next step.
2. Frozen Engineering Spec, execution guardrails, freeze addenda, and batch detail for intended behavior and phase boundaries.
3. The latest applicable checkpoint under `docs/cardfront_refactor_checkpoints/` for source-bound implementation evidence.
4. Active source code, `scripts/tests/*.gd`, and `.github/workflows/` for current repository facts.
5. General architecture, testing, save, performance, release, design, and asset references.
6. `docs/历史_history/`, `docs/ROADMAP.md`, archived handoffs, and `archive/` for historical context only.

If a frozen specification and current source conflict, record the conflict in the active checkpoint. Do not silently let either a historical document or presentation behavior become gameplay authority.

## Current Status / 当前状态

- [PROJECT_STATUS.md](PROJECT_STATUS.md) - the only current status page.
- [P0 checkpoint entry](cardfront_refactor_checkpoints/README.md) - mandatory reading order and evidence format.
- [P0 mandatory audit gates](cardfront_refactor_checkpoints/P0_MANDATORY_AUDIT_GATES.md) - authority, save, AI, regression, and legacy cutover gates.
- [P1 future entry](cardfront_refactor_checkpoints/P1_README.md) - locked until P0 final GO explicitly permits P1.

## Frozen Cardfront Specifications / 冻结规范

Read in this order for P0 work:

1. [Engineering Spec](CARDFRONT_ENGINEERING_SPEC_2026-08-07.md)
2. [P0 Execution Guardrails](CARDFRONT_P0_EXECUTION_GUARDRAILS_2026-08-07.md)
3. [P0 Batch A](CARDFRONT_P0_EXECUTION_DETAIL_BATCH_A_2026-08-08.md)
4. [Pre-Implementation Freeze Addendum](CARDFRONT_P0_PRE_IMPLEMENTATION_FREEZE_ADDENDUM_2026-08-08.md)
5. [P0 Batch B](CARDFRONT_P0_EXECUTION_DETAIL_BATCH_B_2026-08-08.md)
6. [P0 Batch C](CARDFRONT_P0_EXECUTION_DETAIL_BATCH_C_2026-08-08.md)
7. [Refactor Plan](CARDFRONT_REFACTOR_PLAN_2026-08-07.md)

P1 detail and amendments remain frozen future material until P0 final GO:

- `CARDFRONT_P1_EXECUTION_DETAIL_BATCH_A/B/C_2026-08-08.md`
- `CARDFRONT_P1_BATCH_A_DEEP_COMMITMENT_AMENDMENT_2026-08-08.md`
- `CARDFRONT_P1_BATCH_A_ROUTE_CUTOVER_AMENDMENT_2026-08-08.md`
- `CARDFRONT_P1_BATCH_B_REROLL_DECISION_AMENDMENT_2026-08-08.md`

## Engineering References / 工程参考

- [Architecture](ARCHITECTURE.md)
- [Testing](TESTING.md)
- [Save system](SAVE_SYSTEM.md)
- [Performance](PERFORMANCE.md)
- [Android export](ANDROID_EXPORT.md)
- [Release process](RELEASE_PROCESS.md)
- [Technical index](技术_technical/README.md)
- [Performance index](性能_performance/README.md)

## Product, Design, and Assets / 产品、设计与素材

- [Strategic map design](CARDFRONT_STRATEGIC_MAP_DESIGN.md)
- [Battlefield entities and defense towers plan](BATTLEFIELD_ENTITIES_AND_DEFENSE_TOWERS_PLAN.md)
- [Asset gap plan](设计_design/ASSET_GAP_PLAN.md)
- [Design index](设计_design/README.md)
- `docs/设计_design/*.docx` - visual/UI and audio-tool research attachments.
- `docs/技术_technical/Godot素材导入与格式速查手册.docx` - asset-import reference.

These files provide intent or reference material. They do not grant permission to expand the active phase.

## Historical Material / 历史材料

- [History index](历史_history/README.md) - detailed `README_v*.md` stage records.
- [Archived roadmap](ROADMAP.md) - completed v0.1.x-v0.2.x plan.
- [Changelog](../CHANGELOG.md) - short milestone spine.
- `archive/` - old MVP source and README material.
- `PROJECT_STATUS_pre_consolidation_2026-08-13.md` and `README_cardfront_pre_p0_consolidation_2026-08-13.md` preserve the pre-cleanup mixed status/reference documents.

## Maintenance Rules / 维护规则

- Update current state in `PROJECT_STATUS.md`, not in README, ROADMAP, handoff notes, or historical files.
- Put source-bound implementation evidence in a checkpoint, not in the status page.
- Keep frozen specifications immutable unless an explicit amendment is approved.
- Move obsolete narratives to `docs/历史_history/`; do not delete evidence needed to explain old behavior.
- Do not commit generated screenshots, reports, `.uid`, `.godot/`, or random `.import` churn with documentation changes.
