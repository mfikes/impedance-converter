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
        do {
            try hapticEngine?.stop()
        } catch {
            print("Error stopping haptic engine: \(error)")
        }
    }
    
    func restartHapticEngine() {
        do {
            try hapticEngine?.start()
        } catch {
            print("Error restarting haptic engine: \(error)")
        }
    }

    func playHapticFeedback(for constraintEnabled: Bool) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        var events = [CHHapticEvent]()
        if constraintEnabled {
            // Create a sharp, strong tap for enabling constraints
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [], relativeTime: 0)
            events.append(event)
        } else {
            // Create a softer, brief tap for disabling constraints
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [], relativeTime: 0)
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
}
