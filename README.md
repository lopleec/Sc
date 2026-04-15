<div align="center">

# Sc

Lightweight macOS overlay chat for windowed and borderless-fullscreen games.

<p>
  <img alt="Platform" src="https://img.shields.io/badge/platform-macOS%2015%2B-black?logo=apple">
  <img alt="Swift" src="https://img.shields.io/badge/Swift-6-orange?logo=swift">
  <img alt="UI" src="https://img.shields.io/badge/UI-SwiftUI-0A84FF">
  <img alt="Language" src="https://img.shields.io/badge/language-English%20%7C%20%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87-34C759">
  <img alt="License" src="https://img.shields.io/github/license/lopleec/Sc">
</p>

<p>
  <a href="#english">English</a> · <a href="#简体中文">简体中文</a>
</p>

</div>

## Screenshots

![Control Center](docs/images/control-center.png)

*Control Center*

![Overlay Chat](docs/images/overlay-chat.png)

*Overlay Chat*

---

## English

Sc is a lightweight macOS overlay chat app for windowed and borderless-fullscreen games. It uses private IRC-backed sessions with shareable invite codes and a lower-left in-game-style chat bar that can be toggled with `Command + /`.

### Features

- Lower-left overlay chat bar designed for game-style communication
- Global `Command + /` hotkey to show or hide the chat window
- Private single-session rooms with randomized channel names and passwords
- `SC1:` invite codes for sharing and joining conversations
- Automatic pop-up previews when new messages arrive while the overlay is hidden
- Scrollable chat history inside the overlay window
- Standard SwiftUI control center for creating, joining, stopping, and managing sessions
- Configurable nickname, server, opacity, font size, width, and spacing
- Built-in IRC server presets and custom server support
- English and Simplified Chinese interface support with manual in-app switching
- Nicknames restricted to English letters and numbers for IRC compatibility
- Full-screen hotkey fallback with macOS Input Monitoring support

### Download

- Prebuilt app: [GitHub Releases](https://github.com/lopleec/Sc/releases)

### Run From Source

1. Open `Sc.xcodeproj` in Xcode
2. Select the `Sc` scheme
3. Run it on your Mac

Or build from the command line:

```bash
xcodebuild -project Sc.xcodeproj -scheme Sc -configuration Debug CODE_SIGNING_ALLOWED=NO build
```

### Workflow

1. Launch the app and open the control center
2. Create a session or paste an invite code to join one
3. Use `Command + /` to open the overlay chat once connected
4. Stop the current session from the control center when done

### Permissions

- Standard global hotkeys usually work in normal windowed apps
- Some full-screen apps require `Input Monitoring`
- `Accessibility` permission is usually not required

### Project Structure

- `Sc/`: application source
- `ScTests/`: unit tests
- `docs/images/`: README screenshots
- `project.yml`: XcodeGen configuration

### License

This project is licensed under the `MIT License`. See `LICENSE` for details.

---

## 简体中文

Sc 是一个面向窗口化和无边框全屏游戏场景的 macOS 悬浮聊天工具。它基于私密 IRC 会话工作，通过可分享的邀请码加入，并提供一个固定在左下角、可用 `Command + /` 呼出或隐藏的游戏风格聊天栏。

### 功能

- 左下角游戏风格悬浮聊天栏
- 全局 `Command + /` 快捷键呼出或隐藏聊天窗口
- 单会话私密房间，自动生成随机频道名和密码
- `SC1:` 邀请码分享和加入流程
- 聊天栏隐藏时，新消息自动弹出预览
- 悬浮窗内支持滚动查看聊天历史
- 标准 SwiftUI 控制中心，可创建、加入、停止和管理会话
- 可配置昵称、服务器、透明度、字号、宽度和边距
- 内置 IRC 预设服务器，并支持自定义服务器
- 支持 English / 简体中文，并可在应用内手动切换
- 昵称只允许英文和数字，以兼容 IRC 服务器
- 对全屏应用提供基于 macOS `Input Monitoring` 的热键兜底

### 下载

- 已编译版本：[GitHub Releases](https://github.com/lopleec/Sc/releases)

### 从源码运行

1. 用 Xcode 打开 `Sc.xcodeproj`
2. 选择 `Sc` scheme
3. 直接运行到本机

也可以使用命令行构建：

```bash
xcodebuild -project Sc.xcodeproj -scheme Sc -configuration Debug CODE_SIGNING_ALLOWED=NO build
```

### 使用流程

1. 打开应用，进入控制中心
2. 创建会话，或粘贴邀请码加入
3. 连接成功后，用 `Command + /` 呼出聊天栏
4. 使用结束后，在控制中心停止当前会话

### 权限说明

- 普通窗口应用下，全局热键通常可直接使用
- 某些全屏应用需要开启 `Input Monitoring`
- 一般不需要 `Accessibility` 权限

### 项目结构

- `Sc/`：应用源码
- `ScTests/`：单元测试
- `docs/images/`：README 截图资源
- `project.yml`：XcodeGen 配置

### License

本项目使用 `MIT License`。详见 `LICENSE` 文件。
