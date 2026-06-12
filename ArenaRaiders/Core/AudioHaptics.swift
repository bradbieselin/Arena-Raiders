import Foundation
import AVFoundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Game Sounds

enum GameSound: CaseIterable {
    case roll
    case hit
    case crit
    case miss
    case cardPlay
    case coin
    case chestBreak
    case packOpen
    case victory
    case defeat
    case buttonTap

    /// Base name of the bundled audio file in Resources/Audio.
    var fileName: String {
        switch self {
        case .roll: return "sfx_roll"
        case .hit: return "sfx_hit"
        case .crit: return "sfx_crit"
        case .miss: return "sfx_miss"
        case .cardPlay: return "sfx_card"
        case .coin: return "sfx_coin"
        case .chestBreak: return "sfx_chest"
        case .packOpen: return "sfx_pack"
        case .victory: return "sfx_victory"
        case .defeat: return "sfx_defeat"
        case .buttonTap: return "sfx_card"
        }
    }
}

// MARK: - Audio Session

enum AudioSession {
    private static var isConfigured = false

    static func configureIfNeeded() {
        guard !isConfigured else { return }
        isConfigured = true
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
    }
}

// MARK: - Sound Manager
// Plays bundled, AI-produced sound effects from Resources/Audio. If a file is
// missing (or fails to load) it falls back to a short synthesized tone so the
// game always has audible feedback. Gated by GameSettings.

final class SoundManager {
    static let shared = SoundManager()

    private var players: [GameSound: AVAudioPlayer] = [:]
    private var missingFiles: Set<GameSound> = []

    // Synthesized fallback
    private let engine = AVAudioEngine()
    private let synthPlayer = AVAudioPlayerNode()
    private var synthBuffers: [GameSound: AVAudioPCMBuffer] = [:]
    private var synthConfigured = false
    private let sampleRate: Double = 44_100

    private init() {}

    func play(_ sound: GameSound) {
        guard GameSettings.shared.soundEnabled else { return }
        AudioSession.configureIfNeeded()

        if let player = bundledPlayer(for: sound) {
            player.currentTime = 0
            player.play()
        } else {
            playSynthesized(sound)
        }
    }

    // MARK: - Bundled Audio

    private func bundledPlayer(for sound: GameSound) -> AVAudioPlayer? {
        if let cached = players[sound] { return cached }
        guard !missingFiles.contains(sound) else { return nil }

        guard let url = Self.audioURL(named: sound.fileName),
              let player = try? AVAudioPlayer(contentsOf: url) else {
            missingFiles.insert(sound)
            return nil
        }

        player.volume = 0.9
        player.prepareToPlay()
        players[sound] = player
        return player
    }

    /// Looks up an audio file in the bundled Audio folder, trying common extensions.
    static func audioURL(named name: String) -> URL? {
        for ext in ["mp3", "m4a", "wav"] {
            if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Audio") {
                return url
            }
            if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                return url
            }
        }
        return nil
    }

    // MARK: - Synthesized Fallback

    private func playSynthesized(_ sound: GameSound) {
        configureSynthIfNeeded()
        if !engine.isRunning {
            try? engine.start()
        }
        guard engine.isRunning, let buffer = synthBuffers[sound] else { return }

        synthPlayer.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
        if !synthPlayer.isPlaying {
            synthPlayer.play()
        }
    }

    private func configureSynthIfNeeded() {
        guard !synthConfigured else { return }
        synthConfigured = true

        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }
        engine.attach(synthPlayer)
        engine.connect(synthPlayer, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 0.8

        // Each sound is a sequence of (frequency Hz, duration seconds) tones.
        let definitions: [GameSound: [(Double, Double)]] = [
            .roll: [(320, 0.05), (420, 0.05), (540, 0.06)],
            .hit: [(660, 0.12)],
            .crit: [(523, 0.08), (659, 0.08), (784, 0.18)],
            .miss: [(190, 0.16)],
            .cardPlay: [(440, 0.06), (494, 0.05)],
            .coin: [(988, 0.05), (1319, 0.12)],
            .packOpen: [(440, 0.07), (554, 0.07), (659, 0.14)],
            .victory: [(523, 0.12), (659, 0.12), (784, 0.12), (1047, 0.3)],
            .defeat: [(392, 0.16), (330, 0.16), (262, 0.32)],
            .buttonTap: [(700, 0.035)]
        ]

        for (sound, segments) in definitions {
            synthBuffers[sound] = makeBuffer(segments: segments, format: format)
        }
    }

    /// Renders a series of sine tones with a soft attack/decay envelope into a PCM buffer.
    private func makeBuffer(
        segments: [(Double, Double)],
        format: AVAudioFormat,
        volume: Float = 0.45
    ) -> AVAudioPCMBuffer? {
        let totalDuration = segments.reduce(0) { $0 + $1.1 }
        let totalFrames = AVAudioFrameCount(totalDuration * sampleRate)
        guard totalFrames > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: totalFrames),
              let channel = buffer.floatChannelData?.pointee else { return nil }

        buffer.frameLength = totalFrames

        var frame = 0
        for (frequency, duration) in segments {
            let segmentFrames = Int(duration * sampleRate)
            for i in 0..<segmentFrames {
                guard frame < Int(totalFrames) else { break }
                let t = Double(i) / sampleRate
                let attack = min(1.0, t / 0.005)
                let decay = exp(-4.0 * t / duration)
                let sample = sin(2.0 * .pi * frequency * t) * attack * decay
                channel[frame] = Float(sample) * volume
                frame += 1
            }
        }
        return buffer
    }
}

// MARK: - Music Manager
// Loops the bundled, AI-composed background tracks and reacts to the music
// setting and screen changes. Silently does nothing if tracks are missing.

final class MusicManager {
    static let shared = MusicManager()

    enum Track: String {
        case menu = "music_menu"
        case battle = "music_battle"
    }

    private var player: AVAudioPlayer?
    private var currentTrack: Track?
    /// The track that should be playing, even while music is toggled off.
    private var desiredTrack: Track?

    private init() {}

    func play(_ track: Track) {
        desiredTrack = track
        guard GameSettings.shared.musicEnabled else { return }
        guard track != currentTrack || player?.isPlaying != true else { return }

        AudioSession.configureIfNeeded()
        guard let url = SoundManager.audioURL(named: track.rawValue),
              let newPlayer = try? AVAudioPlayer(contentsOf: url) else { return }

        player?.stop()
        newPlayer.numberOfLoops = -1
        newPlayer.volume = 0.35
        newPlayer.prepareToPlay()
        newPlayer.play()
        player = newPlayer
        currentTrack = track
    }

    func stop() {
        desiredTrack = nil
        player?.stop()
        player = nil
        currentTrack = nil
    }

    /// Called when the music setting toggles: pause or resume the desired track.
    func musicSettingChanged() {
        if GameSettings.shared.musicEnabled {
            if let desiredTrack {
                currentTrack = nil // force restart
                play(desiredTrack)
            }
        } else {
            player?.stop()
            player = nil
            currentTrack = nil
        }
    }
}

// MARK: - Haptics Manager
// Wraps UIKit feedback generators; no-ops on platforms without haptics
// and when disabled in settings.

final class HapticsManager {
    static let shared = HapticsManager()

    enum Feedback {
        case light
        case medium
        case heavy
        case success
        case warning
        case error
        case selection
    }

    private init() {}

    func trigger(_ feedback: Feedback) {
        guard GameSettings.shared.hapticsEnabled else { return }

        #if canImport(UIKit) && !os(tvOS)
        switch feedback {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .selection:
            UISelectionFeedbackGenerator().selectionChanged()
        }
        #endif
    }
}
