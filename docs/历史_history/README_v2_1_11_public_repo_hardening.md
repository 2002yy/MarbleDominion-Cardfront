# BallWar v2.1.11 — Public Repository Hardening

Date: 2026-05-17
Scope: repository documentation split, CI/test visibility, Android export workflow cleanup, release narrative alignment

## 1. Version Positioning

本版本不是玩法大改，而是**公开仓库产品化收口**。所有变更集中于：

- 公开仓库可读性（README 从工程交接转向玩家/招聘官友好）
- Release 版本叙事对齐（Latest Stable / Milestone / Historical 三层明确）
- CI 和测试可见性（GitHub Actions 接入，10 个 test runner matrix）
- 文档分层清理（根目录只留入口，历史归档到 `docs/历史_history/`）
- Android 导出脚本去本机路径依赖（别人 clone 下来直接能用）

## 2. Completed Work

### README restructuring / README 入口强化
- 顶部新增 Intro + Download + Screenshots + Tech Highlights 区块，面向玩家和招聘方
- 技术亮点拆为 Engineering & test discipline 和 Gameplay systems 两组
- 快速事实栏（Engine / Language / Tests / Platforms / CI）可在 10 秒内判断项目含金量
- 原有工程内容（状态、Release 分层、核心玩法、运行方式、项目结构、文档入口）完整保留在后

### Release narrative alignment / Release 版本叙事对齐
- Latest Stable: `v2.1.11` → Windows zip、Android debug APK、source archives
- Milestone: `v2.1.10`, `v2.1.9`, `v2.1.8`, `v2.1.4`, `v2.0.3`
- Historical: `v1.9.x`, `v0.1.0-mvp`
- 每层在 README、CHANGELOG、Releases 页面三处一致

### Documentation split / 根目录文档分层
- 所有 `README_v*.md` 历史阶段记录已移入 `docs/历史_history/`，根目录不再堆叠
- `docs/` 下设 `history/`、`technical/`、`design/`、`performance/` 四个子目录
- 每个子目录有独立的 `README.md` 作为索引

### Android export workflow cleanup / Android 导出脚本修复
- `tools/check_android_export_config.ps1`: `$ProjPath` 默认值从硬编码本机路径改为相对路径 `(Resolve-Path "$PSScriptRoot\..").Path`
- `tools/fix_android_export_config.ps1`: 同上
- `export_presets.cfg` Android preset 对齐：
  - `name="领土战争"` → `name="Android"`
  - `export_path` 从中文改为英文
  - `script_export_mode=2` → `0`
  - `version/name=""` → `"2.1.11"`
- `docs/技术_technical/README_ANDROID_EXPORT.md` 命令行示例中的 preset 名同步更新

### GitHub Actions CI / CI 接入
- `.github/workflows/test.yml`: 两个 job
  - `validate`: 验证 `project.godot` 能被 Godot 4.6 headless 加载
  - `test`: matrix 并行跑 10 个 correctness baseline 的 test runner
- Godot 4.6 headless 二进制通过 GitHub Releases 官方 URL 下载，`actions/cache` 缓存
- 所有日志通过 `actions/upload-artifact` 上传，即使失败也有记录

### History doc for public-repo-hardening
- 本文档：`docs/历史_history/README_v2_1_11_public_repo_hardening.md`

## 3. Repository Structure After Cleanup

```text
BallWar/
├─ .github/workflows/          # GitHub Actions CI
├─ assets/                     # 素材资源与授权记录
├─ docs/
│  ├─ history/                 # 历史阶段记录 README_v*.md
│  │  ├─ README.md             #   历史阶段索引
│  │  ├─ README_v2_1_11*.md    #   v2.1.11 版本说明
│  │  ├─ README_v2_1_10.md     #   v2.1.10
│  │  └─ ...
│  ├─ technical/               # 工程协作、测试矩阵、导出说明、AI 交接
│  │  ├── TECHNICAL_GUIDE.md
│  │  ├── README_TEST_MATRIX.md
│  │  ├── AI_HANDOFF_CURRENT.md
│  │  └── README_ANDROID_EXPORT.md
│  ├─ design/                  # 美术/UI/音效/素材规划文档
│  └─ performance/             # 性能基线与附录
├─ scenes/                     # Godot 场景
├─ 截图_screenshots/                # 仓库展示截图
├─ scripts/                    # 核心 GDScript 与测试脚本
├─ tools/                      # 导出/检查辅助脚本
├─ CHANGELOG.md                # 精简版本主线
├─ LICENSE
├─ README.md                   # 项目入口
├─ ROADMAP.md                  # 当前方向
├─ export_presets.cfg
└─ project.godot
```

## 4. Verification

版本收口后应检查以下项目：

| 检查项 | 方法 |
|---|---|
| README 链接检查 | 逐一点击 `docs/历史_history/`、`docs/技术_technical/`、`assets/` 下的链接，确保不 404 |
| Godot headless SmokeTest | `<godot> --headless --path . --script res://scripts/tests/SmokeTestRunner.gd` |
| Godot headless IntegrationTest | `<godot> --headless --path . --script res://scripts/tests/IntegrationTestRunner.gd` |
| Android export config check | `.\tools\check_android_export_config.ps1`（从 `tools/` 目录运行） |
| CI 状态检查 | GitHub Actions `Headless Tests` workflow — validate + 10 matrix job 全绿 ✅ |
| Release 下载入口检查 | 确认 GitHub Releases 页面 Latest Stable 标签指向 v2.1.11 |
| 版本号一致性 | README / CHANGELOG / ROADMAP 三处 v2.1.11 统一 |

## 5. Known Limitations / 已知限制

- **美术资源还未完全接入** — 菜单背景、按钮皮肤、顶部占领条等仍使用占位素材
- **音效系统仍在早期阶段** — 基本试听已集成但未覆盖发射、占领、事件、胜负全链路
- **移动端布局未经过真机验证** — Godot editor 模拟器通过但不代表真机可用
- **性能基线可继续补充** — 高压弹幕和大网格场景的性能基线归档暂缺
- **Android 发布仍为 debug APK** — 签名包和商店交付流程待后续建立

## 6. Next Version Recommendation

建议下一版本方向：

```
v2.1.12-visual-audio-polish
```

优先级建议：

1. **素材实际接入**：菜单背景、按钮皮肤、顶部占领条视觉增强（参考 `docs/设计_design/ASSET_GAP_PLAN.md`）
2. **音效系统第一版**：按钮点击、子弹发射、格子占领、事件触发、胜负判定全链路音效
3. **移动端真机布局验证**：确保所有 UI 在真实 Android 设备上可用
4. **性能基线归档**：覆盖常规模式、高压弹幕（满配四阵营同时发射）、较大网格场景
5. **ControlChamber 第二阶段拆分**：继续拆出 `ChamberBallPhysics.gd` 的几何和绘制边界

---

无玩法变更。
