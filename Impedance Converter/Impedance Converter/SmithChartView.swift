import SwiftUI

enum ConstraintKind {
    case unset, resistance, reactance, conductance, susceptance, none
}

struct SmithChartView: View {
    @ObservedObject var viewModel: ViewModel
    
    @State var constraintKind: ConstraintKind = .unset
    @State var constraintValue: Double = 0
    @State private var modeInterpolator: Double = 1
    
    @State private var animationTimer: Timer?

    func startAnimating(up: Bool) {
        animationTimer?.invalidate()
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [self] _ in
            if (up) {
                self.modeInterpolator = (self.modeInterpolator + 0.15)/1.15
                if self.modeInterpolator >= 0.99 {
                    self.animationTimer?.invalidate()
                    self.modeInterpolator = 1
                }
            } else {
                self.modeInterpolator = (self.modeInterpolator - 0.15)/1.15
                if self.modeInterpolator <= -0.99 {
                    self.animationTimer?.invalidate()
                    self.modeInterpolator = -1
                }
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                let dotRadius:CGFloat = constraintKind == .unset ? 10 : 40
                Canvas { context, size in
                    
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    let radius = min(size.width, size.height) / 2 - 20
                    let dashedLineStyle = StrokeStyle(lineWidth: 1, dash: [5, 5])
                    
                    // Transform and scale coordinates
                    func transform(_ point: CGPoint) -> CGPoint {
                        return CGPoint(
                            x: center.x + point.x * radius,
                            y: center.y - point.y * radius
                        )
                    }
                    
                    // Draw outer circle
                    let outerCircle = Path { path in
                        path.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: 2 * radius, height: 2 * radius))
                    }
                    context.stroke(outerCircle, with: .color(.white), lineWidth: 1)
                    
                    let gridColor: Color = constraintKind == .unset || constraintKind == .none ? .gray : Color(hex:"#FFFFFF").adjusted(brightness:0.4)
                    
                    // Draw circles of constant resistance
                    let resistances: [Double] = [0.2, 0.5, 1, 2, 5]
                    for R in resistances {
                        drawResistanceCircle(context: context, center: center, radius: radius, R: R, color: gridColor, style: dashedLineStyle, modeInterpolator: modeInterpolator)
                    }
                    
                    context.clip(to: outerCircle)
                    
                    // Draw arcs of constant reactance
                    let reactances: [Double] = [0.2, 0.5, 1, 2, 5]
                    for X in reactances {
                        drawReactanceArc(context: context, center: center, radius: radius, X: X, color: gridColor, style: dashedLineStyle, modeInterpolator: modeInterpolator)
                        drawReactanceArc(context: context, center: center, radius: radius, X: -X, color: gridColor, style: dashedLineStyle, modeInterpolator: modeInterpolator)
                    }
                    
                    drawReactanceArc(context: context, center: center, radius: radius, X: 0, color: gridColor, style: dashedLineStyle, modeInterpolator: modeInterpolator)
                    
                    // Plotting the center point
                    let centerPoint = CGPoint(
                        x: 0,
                        y: 0
                    )
                    let transformedCenterPoint = transform(centerPoint)
                    let centerPointPath = Path(ellipseIn: CGRect(x: transformedCenterPoint.x - 5, y: transformedCenterPoint.y - 5, width: 10, height: 10))
                    context.stroke(centerPointPath, with: .color(gridColor))
                    context.fill(centerPointPath, with: .color(gridColor))
                    
                    if (constraintKind == .resistance || constraintKind == .conductance) {
                        drawResistanceCircle(context: context, center: center, radius: radius, R: constraintKind == .resistance ? constraintValue / viewModel.referenceImpedance.real : constraintValue * viewModel.referenceImpedance.real, color: Color.basePrimaryOrange, style: StrokeStyle(lineWidth: 2, dash: [5, 5]), modeInterpolator: modeInterpolator)
                    }
                    
                    if (constraintKind == .reactance || constraintKind == .susceptance) {
                        drawReactanceArc(context: context, center: center, radius: radius, X: constraintKind == .reactance ? constraintValue / viewModel.referenceImpedance.real : -constraintValue * viewModel.referenceImpedance.real, color: Color.basePrimaryOrange, style: StrokeStyle(lineWidth: 2, dash: [5, 5]), modeInterpolator: modeInterpolator)
                    }
                }
                .onChange(of: viewModel.displayMode) { _ in
                    startAnimating(up: viewModel.displayMode != .admittance)
                }
                
                Canvas { context, size in
                    
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    let radius = min(size.width, size.height) / 2 - 20
                    
                    // Transform and scale coordinates
                    func transform(_ point: CGPoint) -> CGPoint {
                        return CGPoint(
                            x: center.x + point.x * radius,
                            y: center.y - point.y * radius
                        )
                    }
                    
                    // Plotting the impedance using the reflection coefficient coordinates
                    let reflectionPoint = CGPoint(
                        x: viewModel.reflectionCoefficient.real,
                        y: viewModel.reflectionCoefficient.imaginary
                    )
                    let transformedPoint = transform(reflectionPoint)
                    let pointPath = Path(ellipseIn: CGRect(x: transformedPoint.x - dotRadius/2, y: transformedPoint.y - dotRadius/2, width: dotRadius, height: dotRadius))
                    context.stroke(pointPath, with: .color(Color.basePrimaryOrange.adjusted(brightness: 1.6)))
                    context.fill(pointPath, with: .color(Color.basePrimaryOrange.adjusted(brightness: 1.6)))
                }
                
                if let reflectionCoefficient = viewModel.reflectionCoefficient {
                    let transformedPoint = transform(reflectionCoefficient: reflectionCoefficient, size: geometry.size)
                    Circle()
                        .fill(Color.basePrimaryOrange.adjusted(brightness: 1.6))
                        .frame(width: 2*dotRadius, height: 2*dotRadius)
                        .position(transformedPoint)
                        .blur(radius: 1.5*dotRadius)
                }
                
            }
            .background(Color(hex: "#3A0C08").adjusted(brightness: 0.6))
            .cornerRadius(8)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let tapLocation = value.location
                        handleDrag(at: tapLocation, in: geometry.size)
                    }
                    .onEnded { _ in
                        handleDragEnd()
                    }
            )
        }
        .aspectRatio(1, contentMode: .fit)
        .padding([.horizontal], 10)
        .padding([.bottom], 10)
    }
    
    private func drawResistanceCircle(context: GraphicsContext, center: CGPoint, radius: CGFloat, R: Double, color: Color, style: StrokeStyle, modeInterpolator: Double) {
        let circleRadius = radius / (R + 1)
        let circleCenter = CGPoint(x: center.x + modeInterpolator * radius * R / (R + 1), y: center.y)
        let resistanceCircle = Path { path in
            path.addEllipse(in: CGRect(x: circleCenter.x - circleRadius, y: circleCenter.y - circleRadius, width: 2 * circleRadius, height: 2 * circleRadius))
        }
        context.stroke(resistanceCircle, with: .color(color), style: style)
    }
    
    private func drawReactanceArc(context: GraphicsContext, center: CGPoint, radius: CGFloat, X: Double, color: Color, style: StrokeStyle, modeInterpolator: Double) {
        if (X == 0) {
            let horizontalLine = Path { path in
                path.move(to: CGPoint(x: center.x - radius, y: center.y))
                path.addLine(to: CGPoint(x: center.x + radius, y: center.y))
            }
            context.stroke(horizontalLine, with: .color(color), style: style)
        } else {
            let arcRadius = radius / X
            let arcCenter = CGPoint(x: center.x + modeInterpolator*radius, y: center.y - arcRadius)
            let reactanceArc = Path { path in
                path.addEllipse(in: CGRect(x: arcCenter.x - arcRadius, y: arcCenter.y - arcRadius, width: 2 * arcRadius, height: 2 * arcRadius))
            }
            context.stroke(reactanceArc, with: .color(color), style: style)
        }
    }
    
    private func transform(reflectionCoefficient: Complex, size: CGSize) -> CGPoint {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = min(size.width, size.height) / 2 - 20
        return CGPoint(
            x: center.x + reflectionCoefficient.real * radius,
            y: center.y - reflectionCoefficient.imaginary * radius
        )
    }
    
    private func handleDrag(at location: CGPoint, in size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = min(size.width, size.height) / 2 - 20
        
        let touchOffset = CGFloat(10) // so you can see point tapped
        let tapPoint = CGPoint(
            x: (location.x - center.x) / radius,
            y: (location.y - touchOffset - center.y) / radius
        )
        
        var reflectionCoefficient = Complex(real: tapPoint.x, imaginary: -tapPoint.y)
        
        let resistance = viewModel.resistance
        let reactance = viewModel.reactance
        let conductance = viewModel.conductance
        let susceptance = viewModel.susceptance
        
        if (reflectionCoefficient.magnitude > 1) {
            reflectionCoefficient = Complex.fromPolar(magnitude: 1, angle: reflectionCoefficient.angle)
            viewModel.reflectionCoefficient = reflectionCoefficient
            viewModel.resistance = 0
        } else {
            viewModel.reflectionCoefficient = reflectionCoefficient
        }
        
        switch constraintKind {
        case .unset:
            if (viewModel.displayMode == .admittance) {
                if abs((viewModel.conductance - conductance)/conductance) < 0.2 {
                    constraintKind = .conductance
                    constraintValue = conductance
                    viewModel.conductance = conductance
                } else if abs((viewModel.susceptance - susceptance)/susceptance) < 0.2 ||
                            abs(susceptance) < 0.1 * viewModel.referenceAdmittance.real &&
                            abs(viewModel.susceptance) < 0.1 * viewModel.referenceAdmittance.real {
                    constraintKind = .susceptance
                    constraintValue = susceptance
                    viewModel.susceptance = susceptance
                } else {
                    constraintKind = .none
                }
            } else {
                if abs((viewModel.resistance - resistance)/resistance) < 0.2 {
                    constraintKind = .resistance
                    constraintValue = resistance
                    viewModel.resistance = resistance
                } else if abs((viewModel.reactance - reactance)/reactance) < 0.2 ||
                            abs(reactance) < 0.1 * viewModel.referenceImpedance.real &&
                            abs(viewModel.reactance) < 0.1 * viewModel.referenceImpedance.real {
                    constraintKind = .reactance
                    constraintValue = reactance
                    viewModel.reactance = reactance
                } else {
                    constraintKind = .none
                }
            }
        case .resistance:
            viewModel.resistance = constraintValue
        case .reactance:
            viewModel.reactance = constraintValue
        case .conductance:
            viewModel.conductance = constraintValue
        case .susceptance:
            viewModel.susceptance = constraintValue
        case .none:
            break
        }
    }
    
    private func handleDragEnd() {
        constraintKind = .unset
    }
}
