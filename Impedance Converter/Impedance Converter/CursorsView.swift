import SwiftUI

struct SmithChartIcon: View {
    enum IconType {
        case constantResistance, constantReactance, constantMagnitude, constantAngle
    }

    var type: IconType

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 * 0.9
            let path = Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: 2 * radius, height: 2 * radius))
            context.stroke(path, with: .color(.black), lineWidth: 1.5)
            context.clip(to: path)
            
            let dashStyle = StrokeStyle(lineWidth: 1.5, dash: [2, 2])

            switch type {
            case .constantResistance:
                let innerRadius = radius / 2
                let innerCircle = Path(ellipseIn: CGRect(x: center.x, y: center.y - innerRadius, width: 2 * innerRadius, height: 2 * innerRadius))
                context.stroke(innerCircle, with: .color(.black), style: dashStyle)

            case .constantReactance:
                let innerRadius = radius * 2
                let innerCircle = Path(ellipseIn: CGRect(x: center.x - radius, y: center.y, width: 2 * innerRadius, height: -2 * innerRadius))
                context.stroke(innerCircle, with: .color(.black), style: dashStyle)
                
            case .constantMagnitude:
                let innerRadius = radius / 2
                let innerCircle = Path(ellipseIn: CGRect(x: center.x - innerRadius, y: center.y - innerRadius, width: 2 * innerRadius, height: 2 * innerRadius))
                context.stroke(innerCircle, with: .color(.black), style: dashStyle)

            case .constantAngle:
                context.stroke(Path { p in
                    p.move(to: CGPoint(x: center.x + radius * cos(.pi / 3), y: center.y - radius * sin(.pi / 3)))
                    p.addLine(to: CGPoint(x: center.x - radius * cos(.pi / 3), y: center.y + radius * sin(.pi / 3)))
                }, with: .color(.black), style: dashStyle)
            }
        }
        .frame(width: 25, height: 25)
    }
}

struct ToggleButton: View {
    @Binding var isOn: Bool
    @State private var isPressed = false // State to track if the button is being pressed

    var rectColor: Color = .gray // The constant color of the rectangle
    var pressedRectColor: Color { rectColor.adjusted(brightness: 0.8) } // Darker color for pressed state
    var offCircleColor: Color = .black // Color of the circle when off
    var onCircleColor: Color = .green // Color of the circle when on
    var panelGapColor: Color = .black // Color of the gap between button and front panel

    func playHapticFeedback() {
        Haptics.shared.playHapticFeedback(for: self.isPressed)
    }
    
    var body: some View {
        ZStack {
            // Use a custom gesture instead of Button
            Canvas { context, size in
                let panelGapWidth: CGFloat = min(size.width, size.height) * 0.11
                let cornerRadius: CGFloat = 10
                
                // Drawing the panel gap
                let outerRect = CGRect(x: panelGapWidth / 2,
                                       y: panelGapWidth / 2,
                                       width: size.width - panelGapWidth,
                                       height: size.height - panelGapWidth)
                context.fill(Path(roundedRect: outerRect, cornerRadius: cornerRadius*1.1), with: .color(panelGapColor))
                
                // Drawing the inner rectangle (button)
                let innerRectSize: CGFloat = min(size.width, size.height) - 2 * panelGapWidth
                let innerRect = CGRect(x: panelGapWidth,
                                       y: panelGapWidth,
                                       width: innerRectSize,
                                       height: innerRectSize)
                context.fill(Path(roundedRect: innerRect, cornerRadius: cornerRadius), with: .color(isPressed ? pressedRectColor : rectColor))
                
                // Drawing the circle
                let circleDiameter: CGFloat = innerRectSize / 4
                let circleRect = CGRect(x: (size.width - circleDiameter) / 2,
                                        y: (size.height - circleDiameter) / 2,
                                        width: circleDiameter,
                                        height: circleDiameter)
                let circlePath = Path(ellipseIn: circleRect)
                
                // Shiny edge
                context.stroke(Path(roundedRect: innerRect, cornerRadius: cornerRadius), with: .color(isPressed ? pressedRectColor : rectColor.adjusted(brightness: 1.2)))
                
                if isOn {
                    // Draw a blurred green circle and shiny edge blur
                    context.fill(circlePath, with: .color(onCircleColor))
                    context.addFilter(.blur(radius: 1))
                    context.stroke(Path(roundedRect: innerRect, cornerRadius: cornerRadius), with: .color(isPressed ? pressedRectColor : rectColor.adjusted(brightness: 1.2)))
                    context.addFilter(.blur(radius: 4))
                    context.fill(circlePath, with: .color(onCircleColor.adjusted(brightness: 1.1)))
                    
                } else {
                    // Draw a black circle
                    context.fill(circlePath, with: .color(offCircleColor))
                    // And shiny edge blur
                    context.addFilter(.blur(radius: 1))
                    context.stroke(Path(roundedRect: innerRect, cornerRadius: cornerRadius), with: .color(isPressed ? pressedRectColor : rectColor.adjusted(brightness: 1.2)))
                }
            }
            .frame(width: 50, height: 50)
            .aspectRatio(contentMode: .fit)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged({ _ in
                        if (!self.isPressed) {
                            self.isPressed = true
                            playHapticFeedback()
                        }
                    })
                    .onEnded({ _ in
                        self.isPressed = false
                        playHapticFeedback()
                        self.isOn.toggle()  // Toggle the state when the gesture ends
                    })
            )
            GeometryReader { geometry in
                RadialGradient(gradient: Gradient(colors: [Color.white.opacity(0.2), Color.white.opacity(0)]),
                               center: .center,
                               startRadius: 1,
                               endRadius: 20)
                .scaleEffect(x: 1, y: 0.5, anchor: .bottom) // Scale in y-direction to create an ellipse
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipShape(Rectangle()) // Clip to the frame's bounds
            }
            .blendMode(.normal)
            .allowsHitTesting(false)
        }
    }
}

struct CursorsView: View {
    
    @AppStorage("showCursorControls") private var showCursorControls = false
    
    @ObservedObject var viewModel: ViewModel

    var body: some View {
        if (showCursorControls) {
            HStack() {
                Spacer()
                HStack {
                    SmithChartIcon(type: .constantResistance)
                    ToggleButton(isOn: $viewModel.constantCircleCursor)
                }
                Spacer()
                HStack {
                    SmithChartIcon(type: .constantReactance)
                    ToggleButton(isOn: $viewModel.constantArcCursor)
                }
                Spacer()
                HStack {
                    SmithChartIcon(type: .constantMagnitude)
                    ToggleButton(isOn: $viewModel.constantMagnitudeCursor)
                }
                Spacer()
                HStack {
                    SmithChartIcon(type: .constantAngle)
                    ToggleButton(isOn: $viewModel.constantAngleCursor)
                }
                Spacer()
            }
        }
    }
}
