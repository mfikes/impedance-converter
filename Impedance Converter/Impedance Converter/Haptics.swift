import UIKit
import CoreHaptics

class Haptics {
    static let shared = Haptics()
    private var hapticEngine: CHHapticEngine?
    
    init() {
        setupHapticEngine()
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil) { [weak self] _ in
            self?.restartHapticEngine()
        }
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { [weak self] _ in
            self?.stopHapticEngine()
        }
    }

    private func setupHapticEngine() {
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
            hapticEngine?.resetHandler = { [weak self] in
                do {
                    try self?.hapticEngine?.start()
                } catch {
                    print("Failed to restart the haptic engine: \(error)")
                }
            }
        } catch {
            print("There was an error creating the haptic engine: \(error.localizedDescription)")
        }
    }
    
    func stopHapticEngine() {
        hapticEngine?.stop()
    }
    
    func restartHapticEngine() {
        do {
            try hapticEngine?.start()
        } catch {
            print("Error restarting haptic engine: \(error)")
        }
    }

    private func playHapticFeedback(for on: Bool, sharpnessOn: Float, sharpnessOff: Float) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        var events = [CHHapticEvent]()
        if on {
            // Create a sharp, strong tap
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0) // Strong intensity
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpnessOn) // Sharp feel
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
            events.append(event)
        } else {
            // Create a softer, less sharp tap
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8) // Softer intensity
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpnessOff) // Less sharp feel
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
            events.append(event)
        }

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try hapticEngine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play haptic feedback: \(error)")
        }
    }
    
    func playConstraintHapticFeedback(for on: Bool) {
        playHapticFeedback(for: on, sharpnessOn: 1.0, sharpnessOff: 0.6)
    }
    
    func playButtonHapticFeedback(for on: Bool) {
        playHapticFeedback(for: on, sharpnessOn: 0.4, sharpnessOff: 0.4)
    }
}
