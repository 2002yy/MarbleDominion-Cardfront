# Android 导出要点

## 必须设置

Android 导出需要特别注意 Godot 项目设置中的 ETC2/ASTC 纹理压缩。

必须确保 `project.godot` 中存在：

```ini
[rendering]
textures/vram_compression/import_etc2_astc=true
```

如果没有开启，Godot Android Export 面板会提示：

```text
目标平台需要 ETC2/ASTC 纹理压缩。
请在项目设置中启用“导入 ETC2 ASTC”。
```

## 建议导出排错顺序

1. 先导出 Debug APK，不先处理 Release 签名
2. preset 使用英文名，例如 `Android`
3. 输出路径使用英文路径，例如 `C:\Builds\BallWar_debug.apk`
4. `package/signed=false`
5. `script_export_mode=0`
6. `gradle_build/use_gradle_build=false`
7. 确认 `Import ETC2 ASTC` 已写入 `project.godot`
8. 打开 Godot，等待资源重新导入后再导出

## 导出前检查

```powershell
.\tools\check_android_export_config.ps1
```

## 自动修复

```powershell
.\tools\fix_android_export_config.ps1
```

## 命令行导出

```powershell
$godot_console --headless --path "<项目路径>" --export-release "Android" "C:\Builds\BallWar_vX.Y.Z.apk"
```
