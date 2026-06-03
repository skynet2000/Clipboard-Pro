# Clipboard-Pro

<p align="center">
  <strong>macOS Clipboard History Manager</strong><br>
  Simple · Fast · Native
</p>

<p align="center">
  <a href="README.md">中文</a> | <strong>English</strong>
</p>

<p align="center">
  <a href="https://github.com/skynet2000/Clipboard-Pro/actions"><img src="https://github.com/skynet2000/Clipboard-Pro/actions/workflows/build.yml/badge.svg" alt="Build"></a>
  <a href="https://www.apple.com/macos/"><img src="https://img.shields.io/badge/macOS-14.0%2B-blue" alt="macOS"></a>
  <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-6.2-orange" alt="Swift"></a>
  <a href="https://github.com/skynet2000/Clipboard-Pro/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-MIT-green" alt="License"></a>
  <a href="https://github.com/skynet2000/Clipboard-Pro/releases"><img src="https://img.shields.io/github/v/release/skynet2000/Clipboard-Pro" alt="Release"></a>
</p>

---

## Why Clipboard-Pro?

Most clipboard tools are either expensive (Paste at $14.99/yr) or bloated. Clipboard-Pro is:

- **Free & Open Source** — MIT licensed, zero cost forever
- **Native SwiftUI** — No Electron, < 30MB memory footprint
- **Global Shortcut** — `⌘⇧V` to summon instantly, no window switching needed
- **Floating Bubble** — Subtle frosted-glass button pinned to screen edge

## ✨ Features

- 📋 **Clipboard History** — Auto-captures text and images (lossless PNG), 500-item limit
- 🔍 **Live Search** — Instant filtering as you type
- 📌 **Pin Items** — Right-click to pin/unpin, pinned items stay at top
- 🕐 **Timestamps** — Relative time display (Just now / 5 min ago / 2 days ago)
- ⌨️ **Global Shortcut** — `⌘⇧V` anywhere, powered by Carbon `RegisterEventHotKey` — no Accessibility permission required
- 🫧 **Floating Bubble** — Frosted-glass button on screen right side at launch
- 💾 **Persistent** — Core Data storage, history survives restarts
- 🌐 **Translation** — Right-click text item → Translate, powered by Apple Translation (macOS 26+)
- 🎨 **Native Design** — Light blue palette + frosted glass, macOS design language
- 🔌 **Universal** — Intel and Apple Silicon

## 🚀 Getting Started

### Requirements

- macOS 14.0+
- Intel or Apple Silicon

### Installation

**Option 1: Download DMG (Recommended)**

Download the latest `MClipboard-x.x.x.dmg` from [Releases](https://github.com/skynet2000/Clipboard-Pro/releases), open and drag MClipboard into your `Applications` folder.

**Option 2: Build from Source**

```bash
git clone https://github.com/skynet2000/Clipboard-Pro.git
cd Clipboard-Pro
bash Scripts/compile_and_run.sh
```

### ⚠️ First Launch: macOS Security Gatekeeper

Since Clipboard-Pro is not signed with an Apple Developer certificate, macOS will block it on first launch. Here are three ways to solve this:

---

### 🔐 Option 1: Allow Single App (Recommended)

When the "unverified developer" dialog appears:

1. Open **System Settings → Privacy & Security**
2. Scroll to the Security section — look for "App was blocked…" message
3. Click **"Open Anyway"**
4. Launch the app again, click **"Open"** in the dialog

> 💡 No system policy changes needed. Repeat once for each new version.

---

### 🔓 Option 2: Enable "Allow Applications From Anywhere"

Use this if you frequently install unsigned apps. **Note: macOS 10.12+ hides this option by default.**

#### Step 1: Unhide the Option

Open **Terminal** (Launchpad → Other), paste and run:

```bash
sudo spctl --master-disable
```

Enter your Mac login password (invisible while typing, press Enter when done).

#### Step 2: Select the Option

1. Open **System Settings → Privacy & Security**
2. Under "Allow applications downloaded from," select **"Anywhere"**

#### Step 3: Revert After Use (Recommended)

Once installed, restore the default security setting:

```bash
sudo spctl --master-enable
```

> ⚠️ Keeping "Anywhere" enabled indefinitely allows all unsigned apps to run, which is a security risk.

---

### 🔧 Option 3: Remove Quarantine Flag (Terminal)

```bash
xattr -cr /Applications/MClipboard.app
```

Or equivalently:

```bash
xattr -dr com.apple.quarantine /Applications/MClipboard.app
```

> This clears macOS's quarantine attribute. Double-click to run normally afterward.

---

## 📖 Usage

| Action | How |
|--------|-----|
| Show/Hide panel | Click floating bubble or press `⌘⇧V` |
| Bring background panel to front | Press `⌘⇧V` when panel is open but obscured |
| Select item | Click or `↑` `↓` arrow keys |
| Copy selected item | `Enter` or click |
| Close panel | `ESC` or click outside |
| Pin/Unpin | Right-click item → Pin / Unpin |
| Search | Type in the search bar at top |
| Translate | Right-click text item → Translate (inline result) |
| Clear history | Click 🗑️ button (keeps pinned items) |
| Quit | Right-click floating bubble → Quit MClipboard |

## 🛠️ Tech Stack

| Component | Technology |
|-----------|-----------|
| UI Framework | SwiftUI + AppKit |
| Persistence | Core Data (programmatic model) |
| Global Hotkey | Carbon `RegisterEventHotKey` |
| Build System | Swift Package Manager |
| Packaging | Shell script → .app → .dmg |
| Minimum OS | macOS 14.0 |

### Project Structure

```
Clipboard-Pro/
├── Package.swift                  # SPM project config
├── version.env                    # Version number
├── Icon.icns                      # App icon
├── .github/workflows/build.yml    # CI
├── Scripts/
│   ├── package_app.sh             # .app packaging script
│   └── compile_and_run.sh         # One-click build & run
└── Sources/MClipboard/
    ├── main.swift                 # App entry (accessory mode)
    ├── MClipboardApp.swift        # AppDelegate + bubble + global shortcut
    ├── PersistenceController.swift # Core Data layer
    ├── ClipboardManager.swift     # Clipboard monitor + data management
    ├── ContentView.swift          # Main panel UI
    ├── HistoryRowView.swift       # History row component
    └── Translator.swift           # Translation service
```

## 📝 Changelog

### v1.0.2 (2026-06-04)

- 🌐 New: Translation feature — right-click text → Translate, powered by Apple Translation
- 🔧 Switched to Carbon `RegisterEventHotKey` for global shortcut — no Accessibility permission needed, more reliable
- 🐛 Fixed crash when clearing history (Core Data entity release timing)
- 🐛 Fixed panel always floating on top of other windows
- ✨ Three-state shortcut toggle: hidden→show / obscured→bring-to-front / frontmost→hide
- 🐛 Fixed intermittent shortcut unresponsiveness
- 🐛 Fixed translation LanguageAvailability false-negative check
- 📖 Added installation guide for unsigned macOS apps

### v1.0.1 (2026-05-25)

- 🐛 Fixed panel not dismissing after selecting an item
- 🐛 Fixed item jumping after copy (self-write re-triggering monitor)
- ✨ Enlarged thumbnails to 72×72

### v1.0.0 (2026-05-25)

- 🎉 Initial release
- Clipboard history, search, pin, clear
- Global shortcut ⌘⇧V, floating bubble, Core Data persistence

## 🆚 Comparison

| Tool | Price | Stack | Open Source | Hotkey Permission |
|------|-------|-------|-------------|-------------------|
| **Clipboard-Pro** | Free | SwiftUI native | ✅ MIT | None needed |
| Paste | $14.99/yr | SwiftUI | ❌ | Accessibility |
| Maccy | Free | AppKit | ✅ MIT | Accessibility |
| Clipy | Free | AppKit | ✅ MIT | Accessibility |

## 🤝 Contributing

Issues and Pull Requests welcome. Bug reports, feature suggestions, and code contributions are all appreciated.

## 📄 License

MIT License — see [LICENSE](LICENSE)

---

<p align="center">
  <sub>Built with ❤️ for macOS</sub>
</p>
