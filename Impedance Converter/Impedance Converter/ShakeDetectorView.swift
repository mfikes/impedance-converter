import SwiftUI
import UIKit

class ShakeResponderView: UIView {
    var onShake: () -> Void

    init(onShake: @escaping () -> Void) {
        self.onShake = onShake
        super.init(frame: .zero)
        self.backgroundColor = .clear
        self.isUserInteractionEnabled = true
        setupNotificationObservers()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(becomeFirstResponder), name: UIResponder.keyboardDidHideNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            onShake()
        }
    }
}


struct ShakeDetectorView: UIViewRepresentable {
    var onShake: () -> Void

    func makeUIView(context: Context) -> UIView {
        let view = ShakeResponderView(onShake: onShake)
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Reinforce first responder status when the view updates
        DispatchQueue.main.async {
            uiView.becomeFirstResponder()
        }
    }
}

