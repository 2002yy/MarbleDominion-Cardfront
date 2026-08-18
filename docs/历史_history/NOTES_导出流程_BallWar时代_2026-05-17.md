> **历史笔记归档** | 归档日期: 2026-08-18 | 原位置: 项目顶层目录（仓库外散落笔记）
>
> 现行导出/发布流程见 `docs/RELEASE_PROCESS.md` 与 `docs/ANDROID_EXPORT.md`。本文件不再维护。

# Godot 导出流程 / Export Workflow

> 最后更新: 2026-05-17 | 版本: v2.1.10+

## 关键错误与教训

| 错误 | 原因 | 解决 |
|:---|:---|:---|
| `configuration errors` 红字 | `package/signed=true` 但无 release keystore | 设 `false`，要发布再配 keystore |
| `configuration errors` 红字 | `script_export_mode=2` 加密模式 | 排错阶段用 `=0` |
| 中文 preset 名日志乱码 | PowerShell 编码吞掉中文 stderr | 用编辑器 GUI 看红字报错 |
| Godot GUI 覆盖 export_presets.cfg | 编辑器打开项目会自动重写 preset 名字 | 先 GUI 验证通过，再命令行导出 |
| EXE + PCK 两个文件不直观 | 默认分开发布 | `embed_pck=true` 合为单文件 |
| `--install-android-build-template` 无效 | 只对 `gradle_build=true` 有用 | `gradle_build=false` 不需要 |
| android/ 目录干扰扫描 | 模板含多余 project.godot | 用 `gradle_build=false` 直接删掉 |
| .godot 缓存导致崩溃 | 改名前需先关编辑器 | 排错时 `rename .godot` 安全 |

## 正确流程

### 1. export_presets.cfg 最小可用配置

```ini
[preset.0]
name="领土战争"          # GUI 会改回中文，保持不动
platform="Android"
export_filter="all_resources"
script_export_mode=0

[preset.0.options]
gradle_build/use_gradle_build=false
package/signed=false
package/name="BallWar"
architectures/arm64-v8a=true

[preset.1]
name="Windows Desktop"
platform="Windows Desktop"
export_filter="all_resources"
script_export_mode=0

[preset.1.options]
application/binary_format/embed_pck=false  # embed_pck 不稳定，改用 exe+pck zip 发布
```

### 2. Godot 编辑器验证

用 Godot 打开项目 → Project → Export → 确认无红字报错。
这一步会修正 preset 里被 GUI 改动的字段。

### 3. 命令行导出

```powershell
$godot = "E:\Godot\Godot_\Godot_console.exe"
$proj = "<项目目录>"
$tag  = "v2.1.10"   # 对应版本号

# Windows (exe + pck，需要打包为 zip)
& $godot --headless --path "$proj" --export-release "Windows Desktop" "C:\Builds\BallWar_$tag.exe"
Compress-Archive -Path "C:\Builds\BallWar_$tag.exe", "C:\Builds\BallWar_$tag.pck" -DestinationPath "C:\Builds\BallWar_${tag}_Windows.zip" -Force

# Android Release
& $godot --headless --path "$proj" --export-release "领土战争" "C:\Builds\BallWar_$tag.apk"
```

### 4. 上传 GitHub Release

```powershell
gh release upload $tag --repo 2002yy/BallWar `
  "C:\Builds\BallWar_${tag}_Windows.zip" `
  "C:\Builds\BallWar_$tag.apk" --clobber
```

## 发布标准

每个 GitHub Release 只放 **2 个文件**：

| 文件 | 说明 |
|:---|:---|
| `BallWar_vX.Y.Z_Windows.zip` | Windows 压缩包（内含 .exe + .pck，需同时解压到同一目录） |
| `BallWar_vX.Y.Z.apk` | Android Release APK |
