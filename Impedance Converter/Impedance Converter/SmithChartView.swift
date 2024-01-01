import SwiftUI

enum ConstraintKind {
    case unset, resistance, reactance, conductance, susceptance, none
}

struct SmithChartView: View {
    @ObservedObject var viewModel: ViewModel
    
    @State var constraintKind: ConstraintKind = .unset
    @State var constraintValue: Double = 0
    @State private var modeInterpolatorKernel: Double = 1
    @State private var modeInterpolator: Double = 1
    
    @State private var animationTimer: Timer?
    
    func startAnimating(up: Bool) {
        animationTimer?.invalidate()
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            modeInterpolatorKernel += up ? 0.13 : -0.13
            if abs(modeInterpolatorKernel) >= 0.999 {
                animationTimer?.invalidate()
                modeInterpolatorKernel = up ? 1 : -1
            }
            modeInterpolator = sin(modeInterpolatorKernel * Double.pi/2.0)
        }
    }
    
    func createCenterAndRadius(size: CGSize) -> (CGPoint, CGFloat) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = min(size.width, size.height) / 2 - 20
        return (center, radius)
    }
    
    func createDashedLineStyle() -> StrokeStyle {
        return StrokeStyle(lineWidth: 1, dash: [1, 1])
    }
    
    func transformPoint(center: CGPoint, radius: CGFloat, point: CGPoint) -> CGPoint {
        return CGPoint(
            x: center.x + point.x * radius,
            y: center.y - point.y * radius
        )
    }
    
    func createOuterCircle(center: CGPoint, radius: CGFloat) -> Path {
        return Path { path in
            path.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: 2 * radius, height: 2 * radius))
        }
    }
    
    func calculateGridColor() -> Color {
        return constraintKind == .unset || constraintKind == .none ? .gray : Color(hex:"#FFFFFF").adjusted(brightness:0.4)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                let dotRadius:CGFloat = constraintKind == .unset ? 10 : 40
                
                Canvas { context, size in
                    
                    let (center, radius) = createCenterAndRadius(size: size)
                    let dashedLineStyle = createDashedLineStyle()
                    
                    // Draw outer circle
                    let outerCircle = createOuterCircle(center: center, radius: radius)
                    context.stroke(outerCircle, with: .color(Color(hex: "#CCCCCC")), lineWidth: 1)
                    
                    let gridColor = calculateGridColor()
                    
                    // Draw circles of constant resistance
                    let resistances: [Double] = [0.2, 0.5, 1, 2, 5]
                    for R in resistances {
                        drawResistanceCircle(context: context, center: center, radius: radius, R: R, color: gridColor, style: dashedLineStyle, modeInterpolator: modeInterpolator)
                    }
                    
                    // Plotting the center point
                    let centerPoint = CGPoint(
                        x: 0,
                        y: 0
                    )
                    let transformedCenterPoint = transformPoint(center: center, radius: radius, point: centerPoint)
                    let centerPointPath = Path(ellipseIn: CGRect(x: transformedCenterPoint.x - 5, y: transformedCenterPoint.y - 5, width: 10, height: 10))
                    context.stroke(centerPointPath, with: .color(gridColor))
                    context.fill(centerPointPath, with: .color(gridColor))
                    
                    context.clip(to: outerCircle)
                    
                    let topHalfRect = CGRect(x: 0, y: 0, width: size.width, height: size.height / 2)
                    let topHalfPath = Path { path in
                        path.addRect(topHalfRect)
                    }
                    
                    drawReactanceArc(context: context, center: center, radius: radius, X: 0, color: gridColor, style: dashedLineStyle, modeInterpolator: modeInterpolator)
                    
                    // Apply the top half clipping
                    context.clip(to: topHalfPath)
                    
                    // Draw arcs of constant reactance
                    let reactances: [Double] = [0.2, 0.5, 1, 2, 5]
                    for X in reactances {
                        drawReactanceArc(context: context, center: center, radius: radius, X: X, color: gridColor, style: dashedLineStyle, modeInterpolator: modeInterpolator)
                    }
                }
                .onChange(of: viewModel.displayMode) { _ in
                    startAnimating(up: viewModel.displayMode != .admittance)
                }
                
                Canvas { context, size in
                    
                    let (center, radius) = createCenterAndRadius(size: size)
                    let dashedLineStyle = createDashedLineStyle()
                    
                    let outerCircle = createOuterCircle(center: center, radius: radius)
                    
                    let gridColor = calculateGridColor()
                    
                    context.clip(to: outerCircle)
                    
                    let bottomHalfRect = CGRect(x: 0, y: size.height / 2, width: size.width, height: size.height / 2)
                    
                    let bottomHalfPath = Path { path in
                        path.addRect(bottomHalfRect)
                    }
                    
                    // Apply the bottom half clipping
                    context.clip(to: bottomHalfPath)
                    
                    // Draw arcs of constant reactance
                    let reactances: [Double] = [0.2, 0.5, 1, 2, 5]
                    for X in reactances {
                        drawReactanceArc(context: context, center: center, radius: radius, X: -X, color: gridColor, style: dashedLineStyle, modeInterpolator: modeInterpolator)
                    }
                }
                .onChange(of: viewModel.displayMode) { _ in
                    startAnimating(up: viewModel.displayMode != .admittance)
                }
                
                Canvas { context, size in
                    
                    let (center, radius) = createCenterAndRadius(size: size)
                                        
                    let outerCircle = createOuterCircle(center: center, radius: radius)
                    
                    context.clip(to: outerCircle)
                    
                    if (constraintKind == .resistance || constraintKind == .conductance) {
                        drawResistanceCircle(context: context, center: center, radius: radius, R: constraintKind == .resistance ? constraintValue / viewModel.referenceImpedance.real : constraintValue / viewModel.referenceAdmittance.real, color: Color.basePrimaryOrange, style: StrokeStyle(lineWidth: 2, dash: [5, 5]), modeInterpolator: modeInterpolator)
                    }
                    
                    if (constraintKind == .reactance || constraintKind == .susceptance) {
                        drawReactanceArc(context: context, center: center, radius: radius, X: constraintKind == .reactance ? constraintValue / viewModel.referenceImpedance.real : -viewModel.referenceAdmittance.real / constraintValue, color: Color.basePrimaryOrange, style: StrokeStyle(lineWidth: 2, dash: [5, 5]), modeInterpolator: modeInterpolator)
                    }
                    
                }
                
                Canvas { context, size in
                    
                    let (center, radius) = createCenterAndRadius(size: size)
                    
                    // Plotting the impedance using the reflection coefficient coordinates
                    let reflectionPoint = CGPoint(
                        x: viewModel.reflectionCoefficient.real,
                        y: viewModel.reflectionCoefficient.imaginary
                    )
                    let transformedPoint = transformPoint(center: center, radius: radius, point: reflectionPoint)
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
        if X == 0 {
            drawHorizontalLine(context: context, center: center, radius: radius, color: color, style: style)
        } else {
            let f = modeInterpolator / 2 + 0.5
            let arcRadius = min((f * (radius / X) + (1 - f) * (X * radius)) / modeInterpolator, 5000)
            let anchor = calculateAnchor(X: X, radius: radius)
            let arcCenter = calculateArcCenter(center: center, anchor: anchor, modeInterpolator: modeInterpolator, radius: radius, arcRadius: arcRadius)
            
            let reactanceArc = Path { path in
                let rect = CGRect(x: arcCenter.x - arcRadius, y: arcCenter.y - arcRadius, width: 2 * arcRadius, height: 2 * arcRadius)
                path.addEllipse(in: rect)
            }
            context.stroke(reactanceArc, with: .color(color), style: style)
        }
    }
    
    private func drawHorizontalLine(context: GraphicsContext, center: CGPoint, radius: CGFloat, color: Color, style: StrokeStyle) {
        let horizontalLine = Path { path in
            path.move(to: CGPoint(x: center.x - radius, y: center.y))
            path.addLine(to: CGPoint(x: center.x + radius, y: center.y))
        }
        context.stroke(horizontalLine, with: .color(color), style: style)
    }
    
    private func calculateAnchor(X: Double, radius: CGFloat) -> Complex {
        return Complex(real: -1, imaginary: X) / Complex(real: 1, imaginary: X)
    }
    
    private func calculateArcCenter(center: CGPoint, anchor: Complex, modeInterpolator: Double, radius: CGFloat, arcRadius: CGFloat) -> CGPoint {
        let anchorX = radius * anchor.real
        let anchorY = radius * anchor.imaginary
        let p = modeInterpolator >= 0 ? 1.0 : -1.0
        let scaledModeInterpolator = radius * modeInterpolator
        let frontX = (anchorX + scaledModeInterpolator) / 2.0
        let frontY = anchorY / 2.0
        let atanArg = (frontX - anchorX) / (anchorY - frontY)
        let centerX = frontX + p * (sqrt(arcRadius * arcRadius - (scaledModeInterpolator - frontX) * (scaledModeInterpolator - frontX) - frontY * frontY) * cos(atan(atanArg)))
        let centerY = frontY + p * (sqrt(arcRadius * arcRadius - (scaledModeInterpolator - frontX) * (scaledModeInterpolator - frontX) - frontY * frontY) * sin(atan(atanArg)))
        
        return CGPoint(x: center.x + centerX, y: center.y - centerY)
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
