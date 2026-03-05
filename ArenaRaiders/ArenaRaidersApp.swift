import SwiftUI
import SwiftData

@main
struct ArenaRaidersApp: App {
    @State private var appState = AppState()
    private let dataManager = DataManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .modelContainer(dataManager.modelContainer)
                .task {
                    dataManager.ensurePlayerProfileExists()
                }
        }
    }
}
