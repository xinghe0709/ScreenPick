# 屏选 ScreenPick

一个原生 macOS 菜单栏截图工具。它会按真实布局展示当前连接的所有屏幕，让你明确选择要截取哪一块屏幕，然后把截图复制到剪贴板、保存到桌面，或同时执行两者。

## 安装

### 从源码构建（推荐）

当前项目提供的是源码和本地构建脚本。安装前请确认：

- macOS 13 Ventura 或更新版本
- 已安装 Apple Command Line Tools
- 已获得本项目源码

如果尚未安装 Command Line Tools，可在终端执行：

```bash
xcode-select --install
```

然后在项目目录执行：

```bash
./Scripts/build-app.sh
open dist/ScreenPick.app
```

构建脚本会使用 Swift Package Manager 编译应用，并生成经过本机临时签名的
`dist/ScreenPick.app`。如果希望像普通 macOS 应用一样安装到“应用程序”目录，可以执行：

```bash
ditto dist/ScreenPick.app /Applications/ScreenPick.app
open /Applications/ScreenPick.app
```

以后更新源码后，重新执行构建脚本，再用新的 App 替换旧版本即可。项目使用固定的
Bundle ID（`com.screenpick.macos`），因此本机重建通常可以保留已授予的系统权限；如果
升级后权限状态异常，请参考[权限排查](#权限排查)。

### 首次启动与系统权限

首次启动时，ScreenPick 需要读取所选屏幕的内容。请打开“系统设置 → 隐私与安全性”，
在“屏幕与系统音频录制”中允许“屏选”（不同 macOS 版本的名称可能略有差异），然后
退出并重新打开应用。

如果要启用“接管系统全屏快捷键”，还需要在同一设置页面中允许“屏选”访问：

- 输入监控
- 辅助功能

不启用快捷键接管时，不需要输入监控或辅助功能权限。应用没有 Dock 图标，启动后请在
菜单栏右侧寻找双屏图标。

### 从源码直接运行

如果只想验证代码而不生成 App 包，可以使用 Swift Package Manager：

```bash
swift run
```

不过，涉及菜单栏常驻、系统权限和全局快捷键的完整功能，建议使用上面的
`build-app.sh` 生成并打开 `.app`。

## 功能

- 菜单栏常驻，不显示 Dock 图标
- 自动识别内建屏幕、外接屏幕、主屏幕与物理像素尺寸
- 按屏幕实际相对位置显示可点击的布局图
- 连接或断开显示器后自动刷新，并尽量保留此前的选择
- 支持复制、保存、复制并保存三种输出方式
- 可接管系统全屏截图快捷键 `Shift-Command-3`，让快捷键也只截取当前所选屏幕
- `Control-Shift-Command-3` 继续表示仅复制到剪贴板
- 默认保存到 `桌面/ScreenPick`
- 使用 ScreenCaptureKit 截取完整 Retina 分辨率画面
- 原生浅色/深色模式、键盘操作与 VoiceOver 标签

## 系统要求

- macOS 13 Ventura 或更新版本
- 首次使用需要在系统设置中授予“屏幕与系统音频录制”权限
- 开启系统快捷键接管时，还需要授予“输入监控”和“辅助功能”权限；关闭该开关后不会监听键盘

## 构建

只需要 Apple Command Line Tools。完整安装流程见[安装](#安装)；重新构建可以直接执行：

```bash
./Scripts/build-app.sh
open dist/ScreenPick.app
```

构建结果位于 `dist/ScreenPick.app`。脚本会进行本机临时签名；正式分发时请在 Xcode 或 CI 中改用 Developer ID 签名并完成公证。

构建脚本为本地签名写入稳定的 Bundle ID 指定要求，使系统录屏和辅助功能授权可以跨本地重建继续生效。第一次从旧构建升级到此版本时，需要在系统设置里关闭再重新开启一次对应权限。

运行测试：

```bash
./Scripts/test.sh
```

需要端到端检查系统快捷键接管时，可在已授权的应用上运行
`open -na dist/ScreenPick.app --args --verify-shortcut`。该诊断会发送一次与物理
`Shift-Command-3` 相同的系统键盘事件。

## 使用

1. 点击菜单栏中的双屏图标。
2. 在屏幕布局图或列表中选择目标屏幕。
3. 选择“复制”“保存”或“两者”。
4. 点击“截取”，或在弹窗聚焦时按 `Command-Return`。

如果开启“接管系统全屏快捷键”，菜单关闭时也可以直接按 `Shift-Command-3` 截取所选屏幕。ScreenPick 会拦截该组合键，避免 macOS 同时对所有屏幕各生成一张截图。

截图触发后菜单弹窗会先关闭，避免把工具自身截进画面。成功时菜单栏图标会短暂变为勾号。

## 权限排查

如果系统设置显示已经授权，但按钮仍不可用：

1. 退出正在运行的旧版屏选。
2. 在“隐私与安全性 → 屏幕与系统音频录制”中关闭再重新开启屏选。
3. 若使用 `Shift-Command-3` 接管，确认“输入监控”和“辅助功能”中的屏选均已开启。
4. 重新打开 `dist/ScreenPick.app`；菜单每次展开都会重新读取最新权限。
