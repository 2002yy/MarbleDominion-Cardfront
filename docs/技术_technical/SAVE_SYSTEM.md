# Save System / 存档系统

Date: 2026-05-17
Role: save/load architecture reference / 存档架构参考

## Overview / 概览

Slot-based save system with backup recovery, version checks, and centralized input sanitization.

## Architecture / 架构

```
Main.gd (orchestration)
  ├─ SaveFlowController     — prepare_* / apply_* split for continue flow
  │   ├─ SaveGameCodec      — validate & normalize save data (no runtime mutation)
  │   └─ SaveStateApplier   — apply cleaned data to runtime objects
  └─ RestorePlan            — active restore planning data passed through continue path
```

## Components / 组件

### SaveFlowController.gd

Owns the continue/load flow. Split into two phases:
- `prepare_*` — collect save data from runtime objects
- `apply_*` — restore runtime objects from save data

### SaveGameCodec.gd

Validates and normalizes save data. Responsibilities:
- Version checks (reject incompatible saves)
- Size limits (prevent oversized save bloat)
- Path traversal filtering (prevent directory escape attacks)
- Nested data structure validation

Does **not** directly mutate runtime objects.

### SaveStateApplier.gd

Takes cleaned/normalized data from `SaveGameCodec` and applies it to runtime objects and systems.

### RestorePlan.gd

Active restore planning data carried through the continue path. Used by runtime objects that own `restore_from_state(...)`:
- `ControlChamber.gd`
- `Turret.gd`
- `Bullet.gd` (currently needs deferred handling)

### Hardening / 安全加固

- **Size limits**: Save files are checked against size thresholds before loading
- **Path traversal filtering**: Directory escape attempts in save data are rejected
- **Version checks**: Save format version must match current code version
- **Nested validation**: Recursive structure validation prevents malformed data

## Key Design Decisions / 关键设计决策

- `SaveGameCodec` does not mutate runtime objects — single responsibility
- `SaveStateApplier` bridges the gap between validated data and runtime mutation
- Each major system owns its own `restore_from_state(...)` instead of a centralized restore function
- The prepare/apply split allows validation before any mutation occurs

## Related Docs / 相关文档

- [ARCHITECTURE.md](ARCHITECTURE.md) — system layering and ownership rules
- [TESTING.md](TESTING.md) — `SaveFlowControllerTestRunner` and `RestorePlanTestRunner`
