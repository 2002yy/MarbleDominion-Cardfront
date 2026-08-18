# Architecture / 架构

Date: 2026-05-17
Role: engineering architecture reference / 工程架构参考

## System Layering / 系统分层

```
Main.gd (top-level orchestration)
  ├─ SaveFlowController     — prepare_* / apply_* continue flow
  ├─ RestorePlan            — active restore planning data
  ├─ GameStateCoordinator   — gameplay state transitions
  ├─ SaveGameCodec          — validate & normalize save data
  ├─ SaveStateApplier       — apply cleaned data to runtime objects
  ├─ GameSceneBuilder       — scene construction with owner-callback contract
  └─ EventRouletteController — event dispatch via signals (not Main private helpers)
```

## Ownership Rules / 归属规则

- **`Main.gd`** — top-level lifecycle sequencing only. Keep shrinking away from deep restore mutation, deep event logic, and draw/physics details.
- **`ControlChamber`**, **`Turret`**, **`Bullet`** — each owns `restore_from_state(...)` for their internal restore mutation.
- **`SaveGameCodec`** — validates and normalizes save data only. Does not mutate runtime objects.
- **`SaveStateApplier`** — applies cleaned data to runtime objects and systems.
- **`Bullet` restore** — still needs deferred handling due to pool, trail, and pressure behavior.

## Runtime-Heavy Systems / 运行时重系统

These remain code-driven (editor scenes add little value):

- `Battlefield.gd` — grid management
- `BulletPool.gd` — bullet pooling
- Pooled bullet/trail internals
- Control-chamber internal ball runtime state

## Signal Decoupling / 信号解耦

`EventRouletteController` emits UI requests by signal instead of calling `Main` private helpers directly. The same pattern applies when new runtime-to-UI communication is needed.

## Architecture Guidelines / 架构原则

- New visible UI should be `.tscn`-first; edit in the editor for layout, fonts, spacing, colors.
- Scripts should prefer logic, signals, and lightweight coordination.
- Do not recreate `.tscn` surfaces in code unless there is a clear runtime-only reason.
- Do not move deep restore-field mutation back into `Main.gd`.
- Do not add direct controller-to-`Main` private method calls when a signal seam is sufficient.

## Related Docs / 相关文档

- [SAVE_SYSTEM.md](SAVE_SYSTEM.md) — save slots, backup, version checks, input sanitization
- [TESTING.md](TESTING.md) — test matrix and run guidance
- [TECHNICAL_GUIDE.md](technical/TECHNICAL_GUIDE.md) — editor workflow, validation policy, repo boundaries
