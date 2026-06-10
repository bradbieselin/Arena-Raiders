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
    case packOpen
    case victory
    case defeat
    case buttonTap
}

// MARK: - Sound Manager
// Synthesizes short UI tones at runtime (no bundled audio assets) and plays
// them through a single AVAudioEngine. All playback is gated by GameSettings.

final class SoundManager {
    static let shared = SoundManager()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let sampleRate: Double = 44_100
    private var buffers: [GameSound: AVAudioPCMBuffer] = [:]
    private var isConfigured = false

    private init() {}

    func play(_ sound: GameSound) {
        guard GameSettings.shared.soundEnabled else { return }

        configureIfNeeded()
        if !engine.isRunning {
            try? engine.start()
        }
        guard engine.isRunning, let buffer = buffers[sound] else { return }

        player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
        if !player.isPlaying {
            player.play()
        }
    }

    // MARK: - Setup

    private func configureIfNeeded() {
        guard !isConfigured else { return }
        isConfigured = true

        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif

        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 0.8

        buildBuffers(format: format)
    }

    private func buildBuffers(format: AVAudioFormat) {
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
            buffers[sound] = makeBuffer(segments: segments, format: format)
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
