import Foundation
import Observation

/// App-wide user preferences, persisted to UserDefaults and observable by SwiftUI.
@Observable
final class GameSettings {
    static let shared = GameSettings()

    private enum Keys {
        static let soundEnabled = "settings.soundEnabled"
        static let musicEnabled = "settings.musicEnabled"
        static let hapticsEnabled = "settings.hapticsEnabled"
        static let hasSeenTutorial = "settings.hasSeenTutorial"
    }

    var soundEnabled: Bool {
        didSet { defaults.set(soundEnabled, forKey: Keys.soundEnabled) }
    }

    var musicEnabled: Bool {
        didSet {
            defaults.set(musicEnabled, forKey: Keys.musicEnabled)
            MusicManager.shared.musicSettingChanged()
        }
    }

    var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: Keys.hapticsEnabled) }
    }

    var hasSeenTutorial: Bool {
        didSet { defaults.set(hasSeenTutorial, forKey: Keys.hasSeenTutorial) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.soundEnabled = defaults.object(forKey: Keys.soundEnabled) as? Bool ?? true
        self.musicEnabled = defaults.object(forKey: Keys.musicEnabled) as? Bool ?? true
        self.hapticsEnabled = defaults.object(forKey: Keys.hapticsEnabled) as? Bool ?? true
        self.hasSeenTutorial = defaults.object(forKey: Keys.hasSeenTutorial) as? Bool ?? false
    }

    /// App marketing version, shown in Settings.
    static var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        if let build { return "\(version) (\(build))" }
        return version
    }
}
