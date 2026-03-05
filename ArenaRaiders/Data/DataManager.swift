import Foundation
import SwiftData

struct DataManager {
    static let shared = DataManager()

    let modelContainer: ModelContainer

    init() {
        let schema = Schema([
            PlayerProfile.self,
            Champion.self,
            Card.self,
            Deck.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            // Schema migration failed — delete old store and retry
            print("DataManager: Initial container failed (\(error)), recreating store...")
            let storeURL = modelConfiguration.url
            try? FileManager.default.removeItem(at: storeURL)
            try? FileManager.default.removeItem(at: storeURL.deletingPathExtension().appendingPathExtension("store-wal"))
            try? FileManager.default.removeItem(at: storeURL.deletingPathExtension().appendingPathExtension("store-shm"))
            do {
                modelContainer = try ModelContainer(
                    for: schema,
                    configurations: [modelConfiguration]
                )
            } catch {
                fatalError("Could not create ModelContainer after reset: \(error)")
            }
        }
    }

    /// Seeds starter data on first launch and ensures a player profile exists
    @MainActor
    func seedOnFirstLaunch() {
        let context = modelContainer.mainContext
        StarterDataLoader.seedIfNeeded(context: context)
    }
}
