@preconcurrency import CoreData

final class PersistenceController: @unchecked Sendable {
    static let shared = PersistenceController()

    let container: NSPersistentContainer
    var viewContext: NSManagedObjectContext { container.viewContext }

    init() {
        container = NSPersistentContainer(
            name: "MClipboard",
            managedObjectModel: PersistenceController.model
        )

        if let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first {
            let dir = appSupport.appendingPathComponent(
                "MClipboard", isDirectory: true
            )
            try? FileManager.default.createDirectory(
                at: dir, withIntermediateDirectories: true
            )
            container.persistentStoreDescriptions.first?.url =
                dir.appendingPathComponent("MClipboard.sqlite")
        }

        container.loadPersistentStores { _, error in
            if let error = error {
                print("Core Data store error: \(error)")
                // Attempt recovery
                self.destroyAndRebuild()
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    // MARK: - Programmatic Model

    nonisolated(unsafe) private static let model: NSManagedObjectModel = {
        let model = NSManagedObjectModel()

        let entity = NSEntityDescription()
        entity.name = "ClipboardItemEntity"
        entity.managedObjectClassName = "ClipboardItemEntity"

        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .UUIDAttributeType
        idAttr.isOptional = false

        let typeAttr = NSAttributeDescription()
        typeAttr.name = "type"
        typeAttr.attributeType = .stringAttributeType

        let textContentAttr = NSAttributeDescription()
        textContentAttr.name = "textContent"
        textContentAttr.attributeType = .stringAttributeType
        textContentAttr.isOptional = true

        let imageDataAttr = NSAttributeDescription()
        imageDataAttr.name = "imageData"
        imageDataAttr.attributeType = .binaryDataAttributeType
        imageDataAttr.isOptional = true
        imageDataAttr.allowsExternalBinaryDataStorage = true

        let timestampAttr = NSAttributeDescription()
        timestampAttr.name = "timestamp"
        timestampAttr.attributeType = .dateAttributeType

        let isPinnedAttr = NSAttributeDescription()
        isPinnedAttr.name = "isPinned"
        isPinnedAttr.attributeType = .booleanAttributeType
        isPinnedAttr.defaultValue = NSNumber(value: false)

        entity.properties = [
            idAttr, typeAttr, textContentAttr, imageDataAttr,
            timestampAttr, isPinnedAttr,
        ]
        model.entities = [entity]
        return model
    }()

    private func destroyAndRebuild() {
        guard let url = container.persistentStoreDescriptions.first?.url
        else { return }

        for store in container.persistentStoreCoordinator.persistentStores {
            try? container.persistentStoreCoordinator.destroyPersistentStore(
                at: store.url!, ofType: store.type, options: nil
            )
        }

        for suffix in ["", "-shm", "-wal"] {
            try? FileManager.default.removeItem(
                at: URL(fileURLWithPath: url.path + suffix)
            )
        }

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Cannot rebuild Core Data: \(error)")
            }
        }
    }
}

// MARK: - NSManagedObject

@objc(ClipboardItemEntity)
final class ClipboardItemEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var type: String
    @NSManaged var textContent: String?
    @NSManaged var imageData: Data?
    @NSManaged var timestamp: Date
    @NSManaged var isPinned: Bool
}
