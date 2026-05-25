import SwiftUI
import AppKit

// MARK: - AppDelegate

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate?
    private var overlayWindow: OverlayWindow?
    private var bubbleWindow: BubbleWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        // Activate first so windows can display in accessory mode
        NSApp.activate(ignoringOtherApps: true)
        // Brief delay to let activation settle, then show bubble
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.showBubble()
        }
        registerGlobalShortcut()
        showFirstLaunchAlertIfNeeded()
    }

    // MARK: - Floating Bubble

    func showBubble() {
        guard bubbleWindow == nil else { return }
        bubbleWindow = BubbleWindow { [weak self] in
            self?.toggleOverlay()
        }

        // On first run, briefly flash the main window to confirm app is alive
        let key = "MClipboard_firstWindowShown"
        if !UserDefaults.standard.bool(forKey: key) {
            UserDefaults.standard.set(true, forKey: key)
            showOverlay()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
                self?.overlayWindow?.orderOut(nil)
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

        🔑 To use the global shortcut (⌘⇧V), grant Accessibility permission:
        System Settings → Privacy & Security → Accessibility → add MClipboard

        Click the floating blue bubble to open the clipboard panel.
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Open Accessibility Settings")
        alert.addButton(withTitle: "Later")

        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(
                URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
            )
        }
    }

    // MARK: - Global Shortcut (⌘⇧V)

    private func registerGlobalShortcut() {
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains([.command, .shift]),
               event.keyCode == 9
            {
                Task { @MainActor [weak self] in self?.toggleOverlay() }
            }
        }

        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains([.command, .shift]),
               event.keyCode == 9
            {
                Task { @MainActor [weak self] in self?.toggleOverlay() }
                return nil
            }
            return event
        }
    }

    // MARK: - Window Toggle

    func toggleOverlay() {
        if overlayWindow?.isVisible == true {
            overlayWindow?.orderOut(nil)
        } else {
            showOverlay()
        }
    }

    func showOverlay() {
        if let win = overlayWindow {
            win.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        } else {
            let window = OverlayWindow()
            overlayWindow = window
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

// MARK: - Floating Bubble Window

final class BubbleWindow: NSWindow {
    private var initialLocation: NSPoint = .zero

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

        // Force visible regardless of activation state
        orderFrontRegardless()
    }
}

// MARK: - Bubble SwiftUI View

struct BubbleView: View {
    let onTap: () -> Void

    @State private var isHovered = false

    var body: some View {
        ZStack {
            // Frosted glass pill — macOS-native look
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
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .scaleEffect(isHovered ? 1.06 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isHovered)
        .onTapGesture { onTap() }
        .onHover { hovering in
            isHovered = hovering
        }
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
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 560),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        title = "MClipboard"
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
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

        let clipboardManager = ClipboardManager()
        contentViewController = NSHostingController(
            rootView: ContentView().environmentObject(clipboardManager)
        )
    }

    override func close() {
        orderOut(nil)
    }
}
