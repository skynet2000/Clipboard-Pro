# Clipboard-Pro

<p align="center">
  <strong>macOS 剪贴板历史管理工具</strong><br>
  简洁 · 快速 · 原生
</p>

<p align="center">
  <a href="https://github.com/skynet2000/Clipboard-Pro/actions"><img src="https://github.com/skynet2000/Clipboard-Pro/actions/workflows/build.yml/badge.svg" alt="Build"></a>
  <a href="https://www.apple.com/macos/"><img src="https://img.shields.io/badge/macOS-14.0%2B-blue" alt="macOS"></a>
  <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-6.2-orange" alt="Swift"></a>
  <a href="https://github.com/skynet2000/Clipboard-Pro/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-MIT-green" alt="License"></a>
  <a href="https://github.com/skynet2000/Clipboard-Pro/releases"><img src="https://img.shields.io/github/v/release/skynet2000/Clipboard-Pro" alt="Release"></a>
</p>

---

## 为什么选择 Clipboard-Pro？

市面上的剪贴板工具要么收费昂贵（Paste $14.99/年），要么功能臃肿。Clipboard-Pro 定位是：

- **完全免费开源** — MIT 协议，零成本使用
- **原生 SwiftUI 构建** — 无 Electron，内存占用 < 30MB
- **全局快捷键** — `⌘⇧V` 一键唤起，不需要切换窗口
- **悬浮气泡** — 毛玻璃风格按钮常驻屏幕右侧，不干扰工作

## ✨ 功能特性

- 📋 **剪贴板历史** — 自动记录文本和图片（图片无损 PNG 存储），上限 500 条
- 🔍 **实时搜索** — 输入关键词即时过滤历史记录
- 📌 **置顶功能** — 右键菜单可将多条记录置顶，常驻列表顶部
- 🕐 **时间戳** — 每条记录显示复制时间（刚刚 / 5 分钟前 / 2 天前）
- ⌨️ **全局快捷键** — `⌘ + ⇧ + V` 一键唤起/隐藏面板
- 🫧 **悬浮气泡** — 启动后在屏幕右侧显示毛玻璃风格按钮
- 💾 **数据持久化** — 基于 Core Data 存储，重启后历史不丢失
- 🎨 **原生设计** — 淡蓝色配色 + 毛玻璃效果，遵循 macOS 设计规范
- 🔌 **通用兼容** — 同时支持 Intel 和 Apple Silicon 芯片

## 🚀 快速开始

### 系统要求

- macOS 14.0+
- Intel 或 Apple Silicon 芯片

### 安装

**方式一：下载 DMG（推荐）**

从 [Releases](https://github.com/skynet2000/Clipboard-Pro/releases) 下载最新 `MClipboard-x.x.x.dmg`，打开后将 MClipboard 拖入 `Applications` 文件夹即可。

**方式二：从源码构建**

```bash
git clone https://github.com/skynet2000/Clipboard-Pro.git
cd Clipboard-Pro
bash Scripts/compile_and_run.sh
```

### 首次运行

首次运行时系统会提示授予**辅助功能权限**：

> 系统设置 → 隐私与安全性 → 辅助功能 → 添加 MClipboard

这是为了让全局快捷键 `⌘⇧V` 正常工作。不授权也可使用，仅快捷键无法在外部应用中响应。

## 📖 使用指南

| 操作 | 方式 |
|------|------|
| 打开/隐藏面板 | 点击悬浮气泡 或 按 `⌘⇧V` |
| 选择记录 | 鼠标点击 或 `↑` `↓` 方向键 |
| 复制选中项 | `Enter` 或 鼠标点击 |
| 关闭面板 | `ESC` 或 点击面板外部 |
| 置顶/取消置顶 | 右键记录 → Pin / Unpin |
| 搜索历史 | 面板顶部搜索框输入关键词 |
| 清空历史 | 点击面板顶部 🗑️ 按钮（仅清除非置顶记录）|
| 退出程序 | 右键悬浮气泡 → Quit MClipboard |

## 🛠️ 技术架构

| 组件 | 技术 |
|------|------|
| UI 框架 | SwiftUI + AppKit |
| 数据持久化 | Core Data（程序化模型） |
| 构建系统 | Swift Package Manager |
| 打包方式 | Shell 脚本 → .app → .dmg |
| 最低系统 | macOS 14.0 |

### 项目结构

```
Clipboard-Pro/
├── Package.swift                  # SPM 项目配置
├── version.env                    # 版本号
├── Icon.icns                      # 应用图标
├── .github/workflows/build.yml    # CI
├── Scripts/
│   ├── package_app.sh             # .app 打包脚本
│   └── compile_and_run.sh         # 一键编译运行
└── Sources/MClipboard/
    ├── main.swift                 # 程序入口（accessory 模式）
    ├── MClipboardApp.swift        # AppDelegate + 悬浮气泡 + 全局快捷键
    ├── PersistenceController.swift # Core Data 持久化层
    ├── ClipboardManager.swift     # 剪贴板监控 + 数据管理
    ├── ContentView.swift          # 主面板界面
    └── HistoryRowView.swift       # 历史记录行组件
```

## 🆚 同类对比

| 工具 | 价格 | 技术栈 | 开源 |
|------|------|--------|------|
| **Clipboard-Pro** | 免费 | SwiftUI 原生 | ✅ MIT |
| Paste | $14.99/年 | SwiftUI | ❌ |
| Maccy | 免费 | AppKit | ✅ MIT |
| Clipy | 免费 | AppKit | ✅ MIT |

## 🤝 贡献

欢迎提交 Issue 和 Pull Request。改进建议、bug 反馈、新功能讨论都欢迎。

## 📄 许可证

MIT License — 详见 [LICENSE](LICENSE)

---

<p align="center">
  <sub>Built with ❤️ for macOS</sub>
</p>
