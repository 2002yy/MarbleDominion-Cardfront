# Marble Dominion: Cardfront / 弹珠领土：卡牌前线

Godot 4.7.1 + GDScript strategy prototype built on the Marble Dominion / BallWar foundation.

Cardfront's active loop is:

> Draft three choices -> aim -> simultaneous volley -> contest territory, routes, Supports, and strongholds -> destroy the enemy command chamber.

## Start Here / 开始入口

- [Current project status](docs/PROJECT_STATUS.md) - current commit, latest accepted checkpoint, only allowed next step, and active risks.
- [Documentation map](docs/README.md) - authority order and the full document taxonomy.
- [P0 checkpoint entry](docs/cardfront_refactor_checkpoints/README.md) - frozen execution order and evidence rules.
- [Testing](docs/TESTING.md) - active Godot headless runners and CI batches.

Current implementation status is maintained only in `docs/PROJECT_STATUS.md`. Historical version plans, old handoff notes, and archived screenshots must not override it.

## Runtime Boundaries / 运行时边界

- `scripts/Main.gd` remains top-level orchestration.
- `scripts/cardfront/` owns Cardfront gameplay and presentation systems.
- `scripts/tests/*.gd` and active `.github/workflows/*.yml` are the test authority.
- `tests_legacy_disabled/` and `docs/历史_history/` are historical evidence only.
- Gameplay authority must not be inferred from presentation nodes or generated Godot metadata.

## Local Validation / 本地验证

```powershell
D:\Godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe --headless --audio-driver Dummy --path . --quit
D:\Godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe --headless --audio-driver Dummy --path . --script res://scripts/tests/SmokeTestRunner.gd
```

Use the focused runner list in [docs/TESTING.md](docs/TESTING.md) for the system being changed. Full regression belongs at batch, milestone, PR, or release-candidate boundaries.
