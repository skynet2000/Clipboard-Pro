import SwiftUI
import AppKit
import Carbon

// MARK: - AppDelegate

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate?
    private var overlayWindow: OverlayWindow?
    private var bubbleWindow: BubbleWindow?
    private var hotKeyRef: EventHotKeyRef?
    private var isOverlayShowing = false
    private var isHotKeyRegistered = false
    private var shortcutCount: Int = 0
    private(set) var clipboardManager: ClipboardManager!

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        clipboardManager = ClipboardManager()
        NSApp.activate(ignoringOtherApps: true)
        setupMainMenu()
        registerGlobalShortcut()
        registerLocalKeyMonitor()
        // Drop overlay to normal level when MClipboard resigns active
        // (user clicks another app). showOverlay/bringOverlayToFront will
        // re-raise to .floating on next activation via shortcut or bubble tap.
        NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.overlayWindow?.level = .normal
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.showBubble()
        }
        showFirstLaunchAlertIfNeeded()
    }

    // MARK: - Main Menu

    private func setupMainMenu() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        appMenuItem.submenu = NSMenu()
        appMenuItem.submenu?.addItem(
            NSMenuItem(title: "About MClipboard", action: nil, keyEquivalent: "")
        )
        appMenuItem.submenu?.addItem(.separator())
        appMenuItem.submenu?.addItem(
            NSMenuItem(title: "Quit MClipboard",
                       action: #selector(NSApplication.terminate(_:)),
                       keyEquivalent: "q")
        )
        mainMenu.addItem(appMenuItem)

        let windowMenuItem = NSMenuItem()
        windowMenuItem.submenu = NSMenu(title: "Window")
        let toggleItem = NSMenuItem(
            title: "Toggle MClipboard",
            action: #selector(handleMenuShortcut),
            keyEquivalent: "V"
        )
        toggleItem.keyEquivalentModifierMask = [.command, .shift]
        windowMenuItem.submenu?.addItem(toggleItem)
        mainMenu.addItem(windowMenuItem)

        NSApp.mainMenu = mainMenu
    }

    @objc private func handleMenuShortcut() {
        handleShortcut()
    }

    // MARK: - Local Key Monitor (backup)

    private func registerLocalKeyMonitor() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.modifierFlags.intersection([.command, .shift]) == [.command, .shift],
                  event.keyCode == 9
            else { return event }
            self?.handleShortcut()
            return nil
        }
    }

    // MARK: - Global Shortcut (⌘⇧V) — Carbon RegisterEventHotKey

    private static let hotKeyID = EventHotKeyID(signature: 0x4D434C50, id: 1)

    private func registerGlobalShortcut() {
        let status = RegisterEventHotKey(
            UInt32(kVK_ANSI_V),
            UInt32(cmdKey | shiftKey),
            Self.hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        if status == noErr {
            isHotKeyRegistered = true
            fputs("[MClipboard] Carbon hotkey ⌘⇧V registered\n", stderr)
            fflush(stderr)

            var eventType = EventTypeSpec(
                eventClass: OSType(kEventClassKeyboard),
                eventKind: UInt32(kEventHotKeyPressed)
            )

            // Use a static trampoline since Carbon callbacks are C function pointers
            // and inline closures can be fragile with capture semantics
            InstallEventHandler(
                GetApplicationEventTarget(),
                MClipboardHotKeyHandler,
                1,
                &eventType,
                Unmanaged.passRetained(self as AnyObject).toOpaque(),
                nil
            )
        } else {
            fputs("[MClipboard] Carbon hotkey FAILED (status=\(status)), falling back to NSEvent\n", stderr)
            fflush(stderr)
            registerNSEventGlobalMonitor()
        }
    }

    private func registerNSEventGlobalMonitor() {
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.modifierFlags.intersection([.command, .shift]) == [.command, .shift],
                  event.keyCode == 9
            else { return }
            self?.handleShortcut()
        }
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.modifierFlags.intersection([.command, .shift]) == [.command, .shift],
                  event.keyCode == 9
            else { return event }
            self?.handleShortcut()
            return nil
        }
    }

    func handleShortcut() {
        shortcutCount += 1
        fputs("[MClipboard] shortcut #\(shortcutCount) isShowing=\(isOverlayShowing) isKey=\(overlayWindow?.isKeyWindow ?? false)\n", stderr)
        fflush(stderr)

        if !isOverlayShowing {
            fputs("[MClipboard] → showOverlay\n", stderr)
            fflush(stderr)
            showOverlay()
        } else if overlayWindow?.isKeyWindow != true {
            fputs("[MClipboard] → bringToFront\n", stderr)
            fflush(stderr)
            bringOverlayToFront()
        } else {
            fputs("[MClipboard] → hideOverlay\n", stderr)
            fflush(stderr)
            hideOverlay()
        }
    }

    func showOverlay() {
        if overlayWindow == nil {
            overlayWindow = OverlayWindow(clipboardManager: clipboardManager)
        }
        // Raise to .floating so the overlay appears above other apps.
        // didResignActiveNotification will drop it back to .normal when
        // the user clicks away — avoiding permanent floating-top behavior.
        overlayWindow?.level = .floating
        overlayWindow?.orderFrontRegardless()
        overlayWindow?.makeKey()
        NSApp.activate(ignoringOtherApps: true)
        isOverlayShowing = true
    }

    func bringOverlayToFront() {
        guard let window = overlayWindow else { return }
        window.level = .floating
        window.orderFrontRegardless()
        window.makeKey()
        NSApp.activate(ignoringOtherApps: true)
    }

    func hideOverlay() {
        overlayWindow?.orderOut(nil)
        isOverlayShowing = false
    }

    // MARK: - Floating Bubble

    func showBubble() {
        guard bubbleWindow == nil else { return }
        bubbleWindow = BubbleWindow { [weak self] in
            guard let self else { return }
            // Use the three-state shortcut logic for consistent behavior.
            // Prevents the "flash and vanish" bug where a simple binary toggle
            // would hide the overlay when it's showing but behind other windows.
            self.handleShortcut()
        }

        let key = "MClipboard_firstWindowShown"
        if !UserDefaults.standard.bool(forKey: key) {
            UserDefaults.standard.set(true, forKey: key)
            showOverlay()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
                self?.hideOverlay()
            }
        }
    }

    // MARK: - First Launch Guide

    private func showFirstLaunchAlertIfNeeded() {
        let key = "MClipboard_hasLaunchedBefore"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)

        let alert = NSAlert()
        alert.messageText = "Welcome to MClipboard"
        alert.informativeText = """
        MClipboard monitors your clipboard and lets you recall history.

        ⌘⇧V — Toggle clipboard panel from anywhere
        🫧 — Click the floating bubble to show the panel

        No permissions needed. Just copy and paste.
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Got it")
        alert.runModal()
    }
}

// MARK: - Carbon HotKey Callback (C function pointer)

private func MClipboardHotKeyHandler(
    _: OpaquePointer?,
    _: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    let delegate = Unmanaged<AppDelegate>.fromOpaque(userData!).takeUnretainedValue()
    // Carbon handlers may run on main or a Carbon event thread depending on
    // macOS version. dispatch_sync from main would deadlock, so check first.
    if Thread.isMainThread {
        MainActor.assumeIsolated {
            delegate.handleShortcut()
        }
    } else {
        DispatchQueue.main.sync {
            MainActor.assumeIsolated {
                delegate.handleShortcut()
            }
        }
    }
    return noErr
}

// MARK: - Floating Bubble Window

final class BubbleWindow: NSWindow {
    init(onTap: @escaping () -> Void) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 46, height: 46),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isMovableByWindowBackground = true
        ignoresMouseEvents = false
        isReleasedWhenClosed = false

        contentViewController = NSHostingController(
            rootView: BubbleView(onTap: onTap)
        )

        if let screen = NSScreen.main {
            let frame = screen.visibleFrame
            setFrameOrigin(NSPoint(
                x: frame.maxX - 64,
                y: frame.midY - 24
            ))
        }

        orderFrontRegardless()
    }
}

// MARK: - Bubble SwiftUI View

struct BubbleView: View {
    let onTap: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .frame(width: 46, height: 46)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                Color.primary.opacity(isHovered ? 0.15 : 0.08),
                                lineWidth: 0.5
                            )
                    )

                Image(systemName: "clipboard.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(
                        Color(red: 0.3, green: 0.6, blue: 0.95)
                            .opacity(isHovered ? 1.0 : 0.85)
                    )
            }
            .frame(width: 46, height: 46)
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 1.06 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isHovered)
        .onHover { hovering in isHovered = hovering }
        .contextMenu {
            Button("Show Clipboard") { onTap() }
            Divider()
            Button("Quit MClipboard") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}

// MARK: - Main Overlay Window

final class OverlayWindow: NSWindow {
    init(clipboardManager: ClipboardManager) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 560),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        title = "MClipboard"
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = true
        isReleasedWhenClosed = false
        minSize = NSSize(width: 320, height: 320)

        backgroundColor = NSColor(red: 0.91, green: 0.95, blue: 0.99, alpha: 1.0)

        if let screen = NSScreen.main {
            let frame = screen.visibleFrame
            setFrameOrigin(NSPoint(
                x: frame.midX - 210,
                y: frame.midY - 280
            ))
        }

        contentViewController = NSHostingController(
            rootView: ContentView().environmentObject(clipboardManager)
        )
    }

    override func close() {
        AppDelegate.shared?.hideOverlay()
    }
}
