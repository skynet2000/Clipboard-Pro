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
- ⌨️ **全局快捷键** — `⌘ + ⇧ + V` 一键唤起/隐藏面板，基于 Carbon `RegisterEventHotKey`，无需辅助功能权限
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

### ⚠️ 首次运行：解决 macOS 安全限制

由于 Clipboard-Pro 未经过 Apple 官方签名认证，macOS 会阻止其运行。以下提供两种解决方案：

---

### 🔐 方案一：允许单个应用运行（推荐，安全）

当首次打开应用时提示「无法验证开发者」：

1. 打开 **系统设置 → 隐私与安全性**
2. 向下滚动找到安全性部分，看到"App 已被阻止…"的提示
3. 点击 **「仍要打开」** 按钮
4. 再次打开应用，在弹窗中点击 **「打开」**

> 💡 此方法不需要修改系统安全策略，每次新版本只需操作一次。

---

### 🔓 方案二：启用「任何来源」选项

如果你需要频繁安装未签名应用，可以启用「任何来源」。**注意：macOS 10.12 起此选项被默认隐藏。**

#### 步骤一：显示「任何来源」选项

打开 **终端**（在「启动台→其他」中），粘贴以下命令并回车：

```bash
sudo spctl --master-disable
```

输入你的 Mac 登录密码（密码输入时不可见，直接回车即可）。

#### 步骤二：验证设置

1. 打开 **系统设置 → 隐私与安全性**
2. 查看「安全性」部分
3. 此时应出现 **「任何来源」** 选项，选择它

#### 步骤三：恢复默认安全设置（推荐用完即关）

安装完成后建议关闭「任何来源」，保持系统安全：

```bash
sudo spctl --master-enable
```

> ⚠️ 「任何来源」允许所有未签名 app 运行，长期开启存在安全风险。建议用完后执行关闭命令。

---

### 🔧 方案三：移除隔离标记（命令行方式）

```bash
# 拖入 .app 后执行
xattr -cr /Applications/MClipboard.app
```

或者直接：

```bash
xattr -dr com.apple.quarantine /Applications/MClipboard.app
```

> 以上命令会清除 macOS 对应用的「隔离」标记，之后双击即可正常运行。

---

## 📖 使用指南

| 操作 | 方式 |
|------|------|
| 打开/隐藏面板 | 点击悬浮气泡 或 按 `⌘⇧V` |
| 将后台面板翻到最前 | 按 `⌘⇧V`（弹窗开着但被遮挡时） |
| 选择记录 | 鼠标点击 或 `↑` `↓` 方向键 |
| 复制选中项 | `Enter` 或 鼠标点击 |
| 关闭面板 | `ESC` 或 点击面板外部 |
| 置顶/取消置顶 | 右键记录 → Pin / Unpin |
| 搜索历史 | 面板顶部搜索框输入关键词 |
| 清空历史 | 点击面板顶部 🗑️ 按钮（仅清除非置顶记录） |
| 退出程序 | 右键悬浮气泡 → Quit MClipboard |

## 🛠️ 技术架构

| 组件 | 技术 |
|------|------|
| UI 框架 | SwiftUI + AppKit |
| 数据持久化 | Core Data（程序化模型） |
| 全局快捷键 | Carbon `RegisterEventHotKey` |
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

## 📝 更新日志

### v1.0.2 (2026-05-27)

- 🔧 全局快捷键改用 Carbon `RegisterEventHotKey`，无需辅助功能权限，更可靠
- 🐛 修复删除记录后崩溃（NSManagedObject 释放时序问题）
- 🐛 修复弹窗始终浮在其他窗口之上的问题
- ✨ 快捷键增加三态切换：关→开 / 被遮挡→翻到最前 / 最前→关
- 🐛 修复快捷键偶尔失灵问题
- 📖 新增 macOS 未签名应用安装指南

### v1.0.1 (2026-05-25)

- 🐛 修复选中记录后弹窗不消失
- 🐛 修复复制项后跳行（自写入误触发监控）
- ✨ 缩略图放大到 72×72

### v1.0.0 (2026-05-25)

- 🎉 初始发布
- 剪贴板历史管理、搜索、置顶、清空
- 全局快捷键 ⌘⇧V、悬浮气泡、Core Data 持久化

## 🆚 同类对比

| 工具 | 价格 | 技术栈 | 开源 | 快捷键权限 |
|------|------|--------|------|-----------|
| **Clipboard-Pro** | 免费 | SwiftUI 原生 | ✅ MIT | 无需辅助功能 |
| Paste | $14.99/年 | SwiftUI | ❌ | 需要辅助功能 |
| Maccy | 免费 | AppKit | ✅ MIT | 需要辅助功能 |
| Clipy | 免费 | AppKit | ✅ MIT | 需要辅助功能 |

## 🤝 贡献

欢迎提交 Issue 和 Pull Request。改进建议、bug 反馈、新功能讨论都欢迎。

## 📄 许可证

MIT License — 详见 [LICENSE](LICENSE)

---

<p align="center">
  <sub>Built with ❤️ for macOS</sub>
</p>
