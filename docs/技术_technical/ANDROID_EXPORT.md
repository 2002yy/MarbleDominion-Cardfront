# Android Export / Android 导出

## Required Setting / 必须设置

`project.godot` must have ETC2/ASTC texture compression enabled:

```ini
[rendering]
textures/vram_compression/import_etc2_astc=true
```

Without this, Godot Android Export shows:
> 目标平台需要 ETC2/ASTC 纹理压缩。请在项目设置中启用"导入 ETC2 ASTC"。

## Troubleshooting Order / 排错顺序

1. Export Debug APK first (not Release)
2. Use English preset name (e.g., `Android`)
3. Use English output path (e.g., `C:\Builds\BallWar_debug.apk`)
4. `package/signed=false`
5. `script_export_mode=0`
6. `gradle_build/use_gradle_build=false`
7. Confirm `Import ETC2 ASTC` is in `project.godot`
8. Open Godot, wait for resource reimport, then export

## Pre-Flight Check / 导出前检查

```powershell
.\tools\check_android_export_config.ps1
```

## Auto-Fix / 自动修复

```powershell
.\tools\fix_android_export_config.ps1
```

## Command-Line Export / 命令行导出

```powershell
<godot_console> --headless --path "<project_path>" --export-release "Android" "C:\Builds\BallWar_vX.Y.Z.apk"
```

## Notes / 说明

The current public APK is a **debug build**. Treat it as a trial package, not a signed store/release package.  
当前公开 APK 为 debug 构建，仅作试玩用途。
