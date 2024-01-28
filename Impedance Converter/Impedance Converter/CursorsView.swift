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

struct CursorsView: View {
    
    @AppStorage("showCursorControls") private var showCursorControls = false
    
    @ObservedObject var viewModel: ViewModel

    var body: some View {
        if (showCursorControls) {
            HStack() {
                Spacer(minLength: 15)
                HStack(spacing: -3) {
                    SmithChartIcon(type: .constantResistance)
                    ToggleButtonView(isOn: $viewModel.constantCircleCursor)
                }
                Spacer()
                HStack(spacing: -3) {
                    SmithChartIcon(type: .constantReactance)
                    ToggleButtonView(isOn: $viewModel.constantArcCursor)
                }
                Spacer()
                HStack(spacing: -3) {
                    SmithChartIcon(type: .constantMagnitude)
                    ToggleButtonView(isOn: $viewModel.constantMagnitudeCursor)
                }
                Spacer()
                HStack(spacing: -3) {
                    SmithChartIcon(type: .constantAngle)
                    ToggleButtonView(isOn: $viewModel.constantAngleCursor)
                }
            }
            .padding(.vertical, -2)
            .frame(maxWidth: 400, maxHeight: 50)
        }
    }
}
