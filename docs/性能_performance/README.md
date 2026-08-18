# Performance Docs / 性能文档

这里集中性能基线、性能探针、画质档位与历史性能附录。

## 当前入口

- [`PERFORMANCE.md`](PERFORMANCE.md) — 当前性能说明与优化边界。
- [`画质档位参数速查表.md`](画质档位参数速查表.md) — 画质/性能档位参数速查。
- [`PERFORMANCE_BASELINE_v2_1_9.md`](PERFORMANCE_BASELINE_v2_1_9.md) — 已有性能基线快照。
- `TerritoryWar_V3_v1_9_21_performance_appendix.docx` — 历史性能附录。

## 当前性能门槛状态

`CardfrontPerformanceSmokeTestRunner.gd` 仍是性能 **smoke gate**，不是完整预算门。

美术 v0.2 新增的性能/可读性要求包括：
- Shadow HIGH / MEDIUM / LOW 的 graceful degradation；
- VFX HIGH / MEDIUM / LOW，但 HIGH 也必须启用 Readability LOD；
- Projectile Density Compensation；
- VFX Effect Pool / Coalescing；
- 外围 Diorama 在窄屏/低档位优先裁装饰，不裁 gameplay core 信息；
- `default_duel` 的 Shadow Baseline/C1/C2 与 Quiet/Normal/Stress VFX benchmark。

后续严格预算测试应继续覆盖 active bullet cap、VFX active count、shadow cost、draw-call/object-count stability 与 10 秒持续战斗稳定性。
