import Foundation

class SmoothAnimation {
    static var isAnimationDisabled: Bool = false
    
    private var animationTimer: Timer?
    private var currentInterpolator: Double
    private var updateAction: ((Double) -> Void)?

    init(initialValue: Double = 0) {
        self.currentInterpolator = initialValue
    }
    
    
    func startAnimating(target: Double, updateAction: @escaping (Double) -> Void) {
        
        if SmoothAnimation.isAnimationDisabled {
            self.currentInterpolator = target
            updateAction(target)
            return
        }
        
        self.updateAction = updateAction
        animationTimer?.invalidate()
        let startValue = currentInterpolator

        let totalDistance = abs(target - startValue)
        let totalAnimationTime = 0.25
        let timerInterval = 0.016
        let numberOfSteps = totalAnimationTime / timerInterval
        let step = totalDistance / numberOfSteps

        animationTimer = Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: true) { [weak self] _ in
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
    
    func startAnimating(from: Double, target: Double, updateAction: @escaping (Double) -> Void) {
        animationTimer?.invalidate()
        self.currentInterpolator = from
        startAnimating(target: target, updateAction: updateAction)
    }

    func stopAnimating() {
        animationTimer?.invalidate()
    }
}
