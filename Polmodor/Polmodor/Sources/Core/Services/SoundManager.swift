import AVFoundation
import Foundation

#if os(macOS)
    import AppKit
#endif

#if os(iOS)
    class SoundManager {
        static let shared = SoundManager()

        private var audioPlayer: AVAudioPlayer?

        private init() {
            setupAudioSession()
        }

        private func setupAudioSession() {
            do {
                try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print("Failed to set up audio session: \(error.localizedDescription)")
            }
        }

        func playCompletionSound() {
            guard let soundURL = Bundle.main.url(forResource: "timer_complete", withExtension: "mp3")
            else {
                // Use system sound as fallback
                AudioServicesPlaySystemSound(1007) // System sound ID for notification
                return
            }

            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.prepareToPlay()
                audioPlayer?.play()
            } catch {
                print("Failed to play completion sound: \(error.localizedDescription)")
                // Use system sound as fallback
                AudioServicesPlaySystemSound(1007)
            }
        }
    }
#else
    class SoundManager {
        static let shared = SoundManager()

        private init() {}

        func playCompletionSound() {
            // Implement macOS sound playback if needed
            NSSound.beep()
        }
    }
#endif
