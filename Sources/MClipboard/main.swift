import AppKit

// Accessory mode: no Dock icon, runs in background
let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let delegate = AppDelegate()
app.delegate = delegate

app.run()
