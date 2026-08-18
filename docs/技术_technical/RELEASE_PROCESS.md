# Release Process / 发布流程

Date: 2026-05-17
Role: packaging and release checklist / 打包与发布检查清单

## Prerequisites / 前置

- Godot 4.6 console executable (`<godot_console>`)
- Android export preset configured (see [ANDROID_EXPORT.md](ANDROID_EXPORT.md))
- GitHub CLI (`gh`) for release creation

## 1. Update Version / 更新版本

- Update version reference in `export_presets.cfg` if needed
- Update `README.md` download links and version references
- Update `CHANGELOG.md` and `ROADMAP.md` if needed
- Commit changes to `main`

## 2. Build Windows Package / 打包 Windows

Use Godot editor: Project → Export → Windows → Export PCK/ZIP.
Or headless:

```powershell
<godot_console> --headless --path . --export-release "Windows" "Builds/BallWar_vX.Y.Z.zip"
```

## 3. Build Android APK / 打包 Android

```powershell
# Run pre-flight check first
.\tools\check_android_export_config.ps1

# Export
<godot_console> --headless --path . --export-release "Android" "Builds/BallWar_vX.Y.Z.apk"
```

See [ANDROID_EXPORT.md](ANDROID_EXPORT.md) for troubleshooting.

## 4. Create GitHub Release / 创建 Release

```powershell
# Tag
git tag -a vX.Y.Z -m "vX.Y.Z release description"
git push origin vX.Y.Z

# Release
gh release create vX.Y.Z --title "title" --notes "release notes"
```

## 5. Verification / 验证

- Headless project load: OK
- `SmokeTestRunner.gd`: PASS
- `IntegrationTestRunner.gd`: PASS
- `LayoutSanityTestRunner.gd`: PASS
- Release assets downloadable

Test commands:

```powershell
<godot_console> --headless --path . --script res://scripts/tests/SmokeTestRunner.gd
<godot_console> --headless --path . --script res://scripts/tests/IntegrationTestRunner.gd
<godot_console> --headless --path . --script res://scripts/tests/LayoutSanityTestRunner.gd
```

Full test guide: [TESTING.md](TESTING.md)
