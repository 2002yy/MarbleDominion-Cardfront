# Performance Docs / 性能文档

Performance baselines, probes, and historical performance appendices.  
性能基线、性能探针与历史性能附录。

- `PERFORMANCE_BASELINE_v2_1_9.md` — current baseline snapshot / 当前性能基线快照
- `TerritoryWar_V3_v1_9_21_performance_appendix.docx` — historical performance appendix / 历史性能附录

## Current Performance Gate Status / 当前性能预算状态

`CardfrontPerformanceSmokeTestRunner.gd` is the current performance **smoke** gate, not a strict budget gate.
当前 `CardfrontPerformanceSmokeTestRunner.gd` 是性能冒烟关卡，不是严格性能预算关卡。

Current checks (smoke-level):
- Overlay dirty-redraw protection does not crash.
- Shot guide layer is present without debug text.
- 40×40 battlefield launches successfully.
- 50×50 battlefield loads successfully.

These verify that Cardfront runtime is structurally sound under scale, not that it meets specific frame-budget or object-count limits.

A strict budget test (`CardfrontPerformanceBudgetTestRunner.gd`) is planned for a later slice. It should measure:
- FireDirector intent rate per second.
- Active bullet cap under sustained fire.
- VFX active count cap.
- Device instance count cap.
- Overlay redraw triggered only by dirty markers (not per-frame).
- Object-count stability over a 10-second simulation window.
