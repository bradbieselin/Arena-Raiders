import Foundation
import SwiftData

struct DataManager {
    static let shared = DataManager()

    let modelContainer: ModelContainer

    init() {
        let schema = Schema([
            PlayerProfile.self,
            Card.self,
            Deck.self,
            GameSession.self
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
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    @MainActor
    func ensurePlayerProfileExists() {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<PlayerProfile>()

        do {
            let profiles = try context.fetch(descriptor)
            if profiles.isEmpty {
                let newProfile = PlayerProfile()
                context.insert(newProfile)
                try context.save()
            }
        } catch {
            print("Error ensuring player profile: \(error)")
        }
    }
}
