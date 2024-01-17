import Foundation

class SmoothAnimation {
    static var isAnimationDisabled: Bool = false

    private var animationTimer: Timer?
    private var currentInterpolator: Double
    private var updateAction: ((Double) -> Void)?

    init(initialValue: Double = 0) {
        self.currentInterpolator = initialValue
    }

    func startAnimating(target: Double, totalAnimationTime: Double = 0.25, delay: TimeInterval = 0, updateAction: @escaping (Double) -> Void) {
        
        // Invalidate existing timer before starting a new animation
        animationTimer?.invalidate()

        if SmoothAnimation.isAnimationDisabled {
            self.currentInterpolator = target
            updateAction(target)
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.updateAction = updateAction
            self.animationTimer?.invalidate()
            let startValue = self.currentInterpolator

            let totalDistance = abs(target - startValue)
            let timerInterval = 1.0 / 60.0
            let numberOfSteps = totalAnimationTime / timerInterval
            let step = totalDistance / numberOfSteps

            self.animationTimer = Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: true) { [weak self] _ in
                guard let self = self else { return }

                if abs(self.currentInterpolator - target) <= step {
                    self.animationTimer?.invalidate()
                    self.currentInterpolator = target
                } else {
                    self.currentInterpolator += (self.currentInterpolator < target) ? step : -step
                }

                let angle = self.currentInterpolator * Double.pi / 2
                let interpolatorValue = target == 0 ? (startValue < 0 ? -(1 - cos(angle)) : (1 - cos(angle))) : sin(angle)
                self.updateAction?(interpolatorValue)
            }
        }
    }

    func startAnimating(from: Double, target: Double, totalAnimationTime: Double = 0.25, delay: TimeInterval = 0, updateAction: @escaping (Double) -> Void) {
        // Invalidate existing timer before starting a new animation
        animationTimer?.invalidate()
        self.currentInterpolator = from

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.startAnimating(target: target, totalAnimationTime: totalAnimationTime, updateAction: updateAction)
        }
    }

    func stopAnimating() {
        animationTimer?.invalidate()
    }
}
