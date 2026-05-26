import AppKit
import CoreData

@MainActor
final class ClipboardManager: ObservableObject {
    @Published var items: [ClipboardItemEntity] = []
    @Published var searchText: String = ""

    private let pasteboard = NSPasteboard.general
    private let context: NSManagedObjectContext
    private var lastChangeCount: Int
    private var timer: Timer?
    private var lastTextContent: String?
    private var lastImageData: Data?

    static let maxItems = 500

    init() {
        context = PersistenceController.shared.viewContext
        lastChangeCount = pasteboard.changeCount
        loadItems()
        startMonitoring()
    }

    // MARK: - Persistence

    func loadItems() {
        let request = NSFetchRequest<ClipboardItemEntity>(
            entityName: "ClipboardItemEntity"
        )
        request.sortDescriptors = [
            NSSortDescriptor(key: "isPinned", ascending: false),
            NSSortDescriptor(key: "timestamp", ascending: false),
        ]
        items = (try? context.fetch(request)) ?? []
    }

    private func saveContext() {
        guard context.hasChanges else { return }
        try? context.save()
    }

    // MARK: - Clipboard Monitoring

    private func startMonitoring() {
        timer = Timer.scheduledTimer(
            withTimeInterval: 0.5, repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.checkPasteboard() }
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func checkPasteboard() {
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        // Image first (takes priority)
        if let image = pasteboard.readObjects(
            forClasses: [NSImage.self], options: nil
        )?.first as? NSImage,
            let tiff = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiff),
            let png = bitmap.representation(using: .png, properties: [:])
        {
            if png == lastImageData { return }
            lastImageData = png
            lastTextContent = nil
            addItem(type: "image", text: nil, imageData: png)
            return
        }

        // Text
        if let text = pasteboard.string(forType: .string)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !text.isEmpty
        {
            if text == lastTextContent { return }
            lastTextContent = text
            lastImageData = nil
            addItem(type: "text", text: text, imageData: nil)
        }
    }

    // MARK: - CRUD

    private func addItem(type: String, text: String?, imageData: Data?) {
        // Dedup: skip if same content appears in last 5 items
        if type == "text", let t = text,
           items.prefix(5).contains(where: { $0.textContent == t })
        {
            return
        }

        let entity = ClipboardItemEntity(context: context)
        entity.id = UUID()
        entity.type = type
        entity.textContent = text
        entity.imageData = imageData
        entity.timestamp = Date()
        entity.isPinned = false

        saveContext()

        // Refresh in-memory array, then enforce limit
        loadItems()
        enforceLimit()
    }

    private func enforceLimit() {
        let unpinned = items.filter { !$0.isPinned }
        let excess = items.count - Self.maxItems

        guard excess > 0, unpinned.count >= excess else { return }

        for item in unpinned.suffix(excess) {
            context.delete(item)
        }
        saveContext()
        loadItems()
    }

    func deleteItem(_ item: ClipboardItemEntity) {
        context.delete(item)
        saveContext()
        loadItems()
    }

    func togglePin(_ item: ClipboardItemEntity) {
        item.isPinned.toggle()
        saveContext()
        loadItems()
    }

    func clearUnpinned() {
        // Keep only pinned items in the array FIRST.
        // This guarantees SwiftUI renders empty/pinned-only state
        // before any ManagedObject deletion, avoiding the crash where
        // HistoryRowView tries to bridge a dead object's nil Date→Date.
        let toDelete = items.filter { !$0.isPinned }
        items = items.filter(\.isPinned)

        for item in toDelete {
            context.delete(item)
        }
        saveContext()
        loadItems()
    }

    func copyItem(_ item: ClipboardItemEntity) {
        pasteboard.clearContents()
        if item.type == "image", let data = item.imageData {
            pasteboard.setData(data, forType: .png)
            lastImageData = data
            lastTextContent = nil
        } else if let text = item.textContent {
            pasteboard.setString(text, forType: .string)
            lastTextContent = text
            lastImageData = nil
        }
        // Suppress monitor from re-adding the item we just copied
        lastChangeCount = pasteboard.changeCount
    }

    // MARK: - Queries

    var filteredItems: [ClipboardItemEntity] {
        guard !searchText.isEmpty else { return items }
        return items.filter {
            $0.type == "text"
                && ($0.textContent?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var pinnedItems: [ClipboardItemEntity] {
        items.filter(\.isPinned)
    }
}
