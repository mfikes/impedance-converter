import SwiftUI

import SwiftUI

struct BaseButtonView<Content: View>: View {
    @Binding var isPressed: Bool
    var rectColor: Color
    var pressedRectColor: Color { rectColor.adjusted(brightness: 0.95) }
    var panelGapColor: Color
    let content: Content

    init(isPressed: Binding<Bool>, rectColor: Color, panelGapColor: Color, @ViewBuilder content: () -> Content) {
        self._isPressed = isPressed
        self.rectColor = rectColor
        self.panelGapColor = panelGapColor
        self.content = content()
    }

    var body: some View {
        ZStack {
            let padding: CGFloat = 5
            let offset: CGFloat = padding / 2

            GeometryReader { geometry in
                RadialGradient(gradient: Gradient(colors: [Color.gray.opacity(0.95), Color.gray.opacity(0)]),
                               center: .center,
                               startRadius: 1,
                               endRadius: 20)
                .scaleEffect(x: 1.5, y: 0.5, anchor: .bottom) // Scale in y-direction to create an ellipse
                .frame(width: geometry.size.width, height: geometry.size.height + (isPressed ? offset : padding))
            }
            .blendMode(.normal)
            .allowsHitTesting(false)

            Canvas { context, size in
                let panelGapWidth: CGFloat = min(size.width, size.height) * 0.11
                let cornerRadius: CGFloat = 10
                let buttonSize = size.width - padding
                
                // Drawing the panel gap
                let outerRect = CGRect(x: panelGapWidth / 2 + offset,
                                       y: panelGapWidth / 2 + offset,
                                       width: buttonSize - panelGapWidth,
                                       height: buttonSize - panelGapWidth)
                context.fill(Path(roundedRect: outerRect, cornerRadius: cornerRadius*1.2), with: .color(panelGapColor))
                
                // Drawing the inner rectangle (button)
                let innerRectSize: CGFloat = buttonSize - 2 * panelGapWidth
                let innerRect = CGRect(x: panelGapWidth + offset,
                                       y: panelGapWidth + offset,
                                       width: innerRectSize,
                                       height: innerRectSize)
                context.fill(Path(roundedRect: innerRect, cornerRadius: cornerRadius), with: .color(isPressed ? pressedRectColor : rectColor))
                // Shiny edge
                context.stroke(Path(roundedRect: innerRect, cornerRadius: cornerRadius), with: .color(isPressed ? pressedRectColor : rectColor.adjusted(brightness: 1.2)), lineWidth: 0.5)
            }
            .frame(width: 50, height: 50)
            .aspectRatio(contentMode: .fit)
            // Phong in button
            GeometryReader { geometry in
                RadialGradient(gradient: Gradient(colors: [Color.white.opacity(0.2), Color.white.opacity(0)]),
                               center: .center,
                               startRadius: 1,
                               endRadius: 20)
                .scaleEffect(x: 1, y: 0.5, anchor: .bottom) // Scale in y-direction to create an ellipse
                .frame(width: geometry.size.width - padding , height: geometry.size.height - padding)
            }
            .blendMode(.normal)
            .allowsHitTesting(false)

            content
        }
    }
}


struct ButtonView: View {
    @State private var isPressed = false
    var rectColor: Color = .gray
    var panelGapColor: Color = .black
    var action: () -> Void

    var body: some View {
        BaseButtonView(isPressed: $isPressed, rectColor: rectColor, panelGapColor: panelGapColor) {
            // Empty for now as no specific UI elements are needed
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged({ _ in
                    if (!self.isPressed) {
                        self.isPressed = true
                        Haptics.shared.playHapticFeedback(for: self.isPressed)
                        action()
                    }
                })
                .onEnded({ _ in
                    self.isPressed = false
                    Haptics.shared.playHapticFeedback(for: self.isPressed)
                })
        )
    }
}

struct ToggleButtonView: View {
    @Binding var isOn: Bool
    @State private var isPressed = false

    var rectColor: Color = .gray
    var offCircleColor: Color = .black
    var onCircleColor: Color = .green
    var panelGapColor: Color = .black

    var body: some View {
        BaseButtonView(isPressed: $isPressed, rectColor: rectColor, panelGapColor: panelGapColor) {
            let circleDiameter: CGFloat = 10
            let circleColor = isOn ? onCircleColor : offCircleColor

            ZStack {
                Circle()
                    .fill(circleColor)
                    .frame(width: circleDiameter, height: circleDiameter)
                if isOn {
                    Circle()
                        .fill(circleColor)
                        .frame(width: circleDiameter, height: circleDiameter)
                        .blur(radius: 4)
                }
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged({ _ in
                    if (!self.isPressed) {
                        self.isPressed = true
                        Haptics.shared.playHapticFeedback(for: self.isPressed)
                        self.isOn.toggle()
                    }
                })
                .onEnded({ _ in
                    self.isPressed = false
                    Haptics.shared.playHapticFeedback(for: self.isPressed)
                })
        )
    }
}
