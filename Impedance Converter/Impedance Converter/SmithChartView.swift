import SwiftUI
import Numerics

enum ConstraintKind {
    case unset, resistance, reactance, conductance, susceptance, magnitude, angle, none
}

extension Double {
    func signum() -> Double {
        if self > 0 {
            return 1.0
        } else if self < 0 {
            return -1.0
        } else {
            return 0.0
        }
    }
}

struct ConstraintValues {
    let resistance: Double
    let reactance: Double
    let conductance: Double
    let susceptance: Double
    let length: Double
    let phase: Double
}

struct SmithChartContentView: View {
    
    @AppStorage("scale") private var scalePreference = "Simple"
    
    @AppStorage("showLength") private var showLength = false
    
    @ObservedObject var viewModel: ViewModel
    
    @State var constraintKind: ConstraintKind = .unset
    
    @State var constraintValue: Double = 0
    
    @State private var modeInterpolator: Double

    let modeAnimationManager: SmoothAnimation
    
    func startAnimatingModeChange(target: Double) {
        modeAnimationManager.startAnimating(target: target) { interpolatorValue in
            modeInterpolator = interpolatorValue
        }
    }
    
    @State private var refAngleInterpolator = Angle(radians: 0)
    @State private var oldRefAngle = Angle(radians: 0)
    
    var refAngleAnimationManager = SmoothAnimation(initialValue: 0)
    
    init(viewModel: ViewModel) {
        self.viewModel = viewModel
        let initialModeInterpolator = SmithChartContentView.animationTarget(for: viewModel.displayMode)
        _modeInterpolator = State(initialValue: initialModeInterpolator)
        modeAnimationManager = SmoothAnimation(initialValue: initialModeInterpolator)
    }
    
    func createCenterAndRadius(size: CGSize) -> (CGPoint, CGFloat) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = min(size.width, size.height) / 2 - 20
        return (center, radius)
    }
    
    func createDashedLineStyle() -> StrokeStyle {
        return StrokeStyle(lineWidth: 1)
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
        return constraintKind == .unset || constraintKind == .none ? .gray : .dimGridView
    }
    
    static func animationTarget(for mode: DisplayMode) -> Double {
        switch mode {
        case .impedance:
            return 1
        case .admittance:
            return -1
        case .reflectionCoefficient:
            return 0
        }
    }
    
    func scaleX() -> [Double] {
        if (scalePreference == "1-2-5") {
            return [0.2, 0.5, 1, 2, 5]
        } else if (scalePreference == "Simple") {
            return [0.5, 1, 2]
        } else {
            return [0.2, 0.5, 1, 1.4, 4]
        }
    }
    
    func scaleR() -> [Double] {
        if (scalePreference == "1-2-5") {
            return [0.2, 0.5, 1, 2, 5]
        } else if (scalePreference == "Simple") {
            return [1/3, 1, 3]
        } else {
            return [0.2, 0.5, 1, 1.4, 4]
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                let dotRadius:CGFloat = constraintKind == .unset ? 10 : 40
                
                // Grid canvas, top and parts of bottom
                Canvas { context, size in
                    
                    let (center, radius) = createCenterAndRadius(size: size)
                    let dashedLineStyle = createDashedLineStyle()
                    
                    // Draw outer circle
                    let outerCircle = createOuterCircle(center: center, radius: radius)
                    context.stroke(outerCircle, with: .color(.smithOuterCircle), lineWidth: 1)
                    
                    let gridColor = calculateGridColor()
                    
                    // Draw circles of constant resistance
                    let resistances: [Double] = scaleR()
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
                    
                    if (showLength) {
                        drawReferenceAngleIndicator(context: context, center: center, radius: radius, angle: refAngleInterpolator, color:gridColor)
                    }
                    
                    context.clip(to: outerCircle)
                    
                    let topHalfRect = CGRect(x: 0, y: 0, width: size.width, height: size.height / 2)
                    let topHalfPath = Path { path in
                        path.addRect(topHalfRect)
                    }
                    
                    drawReactanceArc(context: context, center: center, radius: radius, X: 0, color: gridColor, style: dashedLineStyle, modeInterpolator: modeInterpolator)
                    
                    // Apply the top half clipping
                    context.clip(to: topHalfPath)
                    
                    // Draw arcs of constant reactance
                    let reactances: [Double] = scaleX()
                    for X in reactances {
                        drawReactanceArc(context: context, center: center, radius: radius, X: X, color: gridColor, style: dashedLineStyle, modeInterpolator: modeInterpolator)
                    }
                }
                .onChange(of: viewModel.displayMode) { _ in
                    startAnimatingModeChange(target: SmithChartContentView.animationTarget(for: viewModel.displayMode))
                }
                .onChange(of: viewModel.refAngle) { _ in
                    let start = oldRefAngle.radians
                    oldRefAngle = viewModel.refAngle
                    let end = viewModel.refAngle.radians
                    let shortestDifference = symmetricRemainder(dividend: end - start, divisor: 2 * .pi)
                    
                    refAngleAnimationManager.startAnimating(from: 0, target: 1) { interpolatorValue in
                        refAngleInterpolator = Angle(radians: start + shortestDifference * interpolatorValue)
                    }
                }
                .blur(radius: 0.4)
                .brightness(0.1)
                
                // Grid canvas, remaining parts of bottom
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
                    let reactances: [Double] = scaleX()
                    for X in reactances {
                        drawReactanceArc(context: context, center: center, radius: radius, X: -X, color: gridColor, style: dashedLineStyle, modeInterpolator: modeInterpolator)
                    }
                }
                .onChange(of: viewModel.displayMode) { _ in
                    startAnimatingModeChange(target:SmithChartContentView.animationTarget(for: viewModel.displayMode))
                }
                .blur(radius: 0.4)
                .brightness(0.1)
                
                // Constraint indicator canvas
                Canvas { context, size in
                    
                    let (center, radius) = createCenterAndRadius(size: size)
                                        
                    let outerCircle = createOuterCircle(center: center, radius: radius)
                    
                    context.clip(to: outerCircle)
                    
                    if (constraintKind == .resistance || constraintKind == .conductance) {
                        drawResistanceCircle(context: context, center: center, radius: radius, R: constraintKind == .resistance ? constraintValue / viewModel.referenceImpedance.real : constraintValue / viewModel.referenceAdmittance.real, color: Color.basePrimaryOrange, style: StrokeStyle(lineWidth: 2, dash: [5, 5]), modeInterpolator: modeInterpolator)
                    }
                    
                    if (constraintKind == .magnitude) {
                        drawCircle(context: context, center: center, radius: radius, circleRadius: viewModel.reflectionCoefficient.length * radius, circleCenter: center, color: Color.basePrimaryOrange, style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    }
                    
                    if (constraintKind == .reactance || constraintKind == .susceptance) {
                        drawReactanceArc(context: context, center: center, radius: radius, X: constraintKind == .reactance ? constraintValue / viewModel.referenceImpedance.real : -viewModel.referenceAdmittance.real / constraintValue, color: Color.basePrimaryOrange, style: StrokeStyle(lineWidth: 2, dash: [5, 5]), modeInterpolator: modeInterpolator)
                    }
                    
                    if (constraintKind == .angle) {
                        drawRadius(context: context, center: center, radius: radius, angle: Angle(radians: constraintValue), color: Color.basePrimaryOrange, style: StrokeStyle(lineWidth: 2, dash: [5, 5]), modeInterpolator: modeInterpolator)
                    }
                    
                }
                .blur(radius: 0.5)
                .brightness(0.1)
                
                // Trace canvas (blurred bottom)
                Canvas { context, size in
                    
                    let (center, radius) = createCenterAndRadius(size: size)
                    
                    // Creating a path for the trace
                    let trace = viewModel.trace
                    var tracePath = Path()
                    if let firstPoint = trace.first {
                        let firstCGPoint = CGPoint(
                            x: firstPoint.real,
                            y: firstPoint.imaginary
                        )
                        let transformedFirstPoint = transformPoint(center: center, radius: radius, point: firstCGPoint)
                        tracePath.move(to: transformedFirstPoint)
                    }
                    
                    for complexPoint in trace.dropFirst() {
                        let cgPoint = CGPoint(
                            x: complexPoint.real,
                            y: complexPoint.imaginary
                        )
                        let transformedPoint = transformPoint(center: center, radius: radius, point: cgPoint)
                        tracePath.addLine(to: transformedPoint)
                    }
                    
                    context.stroke(tracePath, with: .color(Color.basePrimaryOrange.adjusted(brightness: 0.5)), lineWidth: 4)
                }.blur(radius: 10)
                
                // Trace canvas
                Canvas { context, size in
                    
                    let (center, radius) = createCenterAndRadius(size: size)
                    
                    // Creating a path for the trace
                    let trace = viewModel.trace
                    var tracePath = Path()
                    if let firstPoint = trace.first {
                        let firstCGPoint = CGPoint(
                            x: firstPoint.real,
                            y: firstPoint.imaginary
                        )
                        let transformedFirstPoint = transformPoint(center: center, radius: radius, point: firstCGPoint)
                        tracePath.move(to: transformedFirstPoint)
                    }
                    
                    for complexPoint in trace.dropFirst() {
                        let cgPoint = CGPoint(
                            x: complexPoint.real,
                            y: complexPoint.imaginary
                        )
                        let transformedPoint = transformPoint(center: center, radius: radius, point: cgPoint)
                        tracePath.addLine(to: transformedPoint)
                    }
                    
                    context.stroke(tracePath, with: .color(Color.basePrimaryOrange.adjusted(brightness: 0.5)), lineWidth: 1)
                }.blur(radius: 1)
                  
                // Impedance dot canvas
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
                
                let transformedPoint = transform(reflectionCoefficient: viewModel.reflectionCoefficient, size: geometry.size)
                Circle()
                    .fill(Color.basePrimaryOrange.adjusted(brightness: 1.6))
                    .frame(width: 2*dotRadius, height: 2*dotRadius)
                    .position(transformedPoint)
                    .blur(radius: 1.5*dotRadius)
                
                Color.clear
                    .contentShape(Circle())
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
            .background(Color.smithBackground)
            .cornerRadius(20)
        }
        .aspectRatio(1, contentMode: .fit)
        .padding([.horizontal], 10)
    }
    
    private func drawReferenceAngleIndicator(context: GraphicsContext, center: CGPoint, radius: CGFloat, angle: Angle, color: Color) {
        let angleRadians = angle.radians

        let startPoint = CGPoint(
            x: center.x + 1.05*radius * CGFloat(cos(angleRadians - 0.03)),
            y: center.y - 1.05*radius * CGFloat(sin(angleRadians - 0.03))
        )
        
        let midPoint = CGPoint(
            x: center.x + 1.01*radius * CGFloat(cos(angleRadians)),
            y: center.y - 1.01*radius * CGFloat(sin(angleRadians))
        )
        
        let endPoint = CGPoint(
            x: center.x + 1.05*radius * CGFloat(cos(angleRadians + 0.03)),
            y: center.y - 1.05*radius * CGFloat(sin(angleRadians + 0.03))
        )
        

        let line = Path { path in
            path.move(to: startPoint)
            path.addLine(to: midPoint)
            path.addLine(to: endPoint)
            path.addLine(to: startPoint)
        }

        context.stroke(line, with: .color(color), style: StrokeStyle(lineWidth: 1))
        context.fill(line, with: .color(color))
    }
    
    private func drawResistanceCircle(context: GraphicsContext, center: CGPoint, radius: CGFloat, R: Double, color: Color, style: StrokeStyle, modeInterpolator: Double) {
        let smith = 1 / (1 + R)
        let polar = polarRadiusFor(R: R)
        
        let circleRadius = radius * (abs(modeInterpolator) * smith + (1.0 - abs(modeInterpolator)) * polar)
        let circleCenter = CGPoint(x: center.x + modeInterpolator * radius * R / (R + 1), y: center.y)
        drawCircle(context: context, center: center, radius: radius, circleRadius: circleRadius, circleCenter: circleCenter, color: color, style: style)
    }
    
    private func drawReactanceArc(context: GraphicsContext, center: CGPoint, radius: CGFloat, X: Double, color: Color, style: StrokeStyle, modeInterpolator: Double) {
        if X == 0 {
            drawHorizontalLine(context: context, center: center, radius: radius, color: color, style: style)
        } else {
            let f = modeInterpolator / 2 + 0.5
            let arcRadius = abs((f * (radius / X) + (1 - f) * (X * radius)) / modeInterpolator)
            let anchor = calculateAnchor(X: X, radius: radius, modeInterpolator: modeInterpolator)
            
            if arcRadius > 20 * radius {
                let startPoint = CGPoint(x: center.x + radius * modeInterpolator, y: center.y)
                let endPoint = CGPoint(x: center.x + radius * anchor.real, y: center.y - radius * anchor.imaginary)
                let line = Path { path in
                    path.move(to: startPoint)
                    path.addLine(to: endPoint)
                }
                context.stroke(line, with: .color(color), style: style)
            } else {
                let arcCenter = calculateArcCenter(center: center, anchor: anchor, modeInterpolator: modeInterpolator, radius: radius, arcRadius: arcRadius)
                let rect = CGRect(x: arcCenter.x - arcRadius, y: arcCenter.y - arcRadius, width: 2 * arcRadius, height: 2 * arcRadius)
                let reactanceArc = Path { path in
                    path.addEllipse(in: rect)
                }
                context.stroke(reactanceArc, with: .color(color), style: style)
            }
        }
    }
    
    private func drawCircle(context: GraphicsContext, center: CGPoint, radius: CGFloat, circleRadius: Double, circleCenter:CGPoint, color: Color, style: StrokeStyle) {
        let circle = Path { path in
            path.addEllipse(in: CGRect(x: circleCenter.x - circleRadius, y: circleCenter.y - circleRadius, width: 2 * circleRadius, height: 2 * circleRadius))
        }
        context.stroke(circle, with: .color(color), style: style)
    }
    
    private func drawRadius(context: GraphicsContext, center: CGPoint, radius: CGFloat, angle: Angle, color: Color, style: StrokeStyle, modeInterpolator: Double) {
        let angleRadians = angle.radians
        
        let endPoint = CGPoint(
            x: center.x + radius * CGFloat(cos(angleRadians)),
            y: center.y - radius * CGFloat(sin(angleRadians))
        )

        let line = Path { path in
            path.move(to: center)
            path.addLine(to: endPoint)
        }

        context.stroke(line, with: .color(color), style: style)
    }

    
    private func drawHorizontalLine(context: GraphicsContext, center: CGPoint, radius: CGFloat, color: Color, style: StrokeStyle) {
        let horizontalLine = Path { path in
            path.move(to: CGPoint(x: center.x - radius, y: center.y))
            path.addLine(to: CGPoint(x: center.x + radius, y: center.y))
        }
        context.stroke(horizontalLine, with: .color(color), style: style)
    }
    
    private func polarAngleFor(X: Double) -> Angle {
        switch (abs(X)) {
        case 5.0:
            return Angle(degrees: 30*X.signum())
        case 4.0:
            return Angle(degrees: 30*X.signum())
        case 3.0:
            return Angle(degrees: 45*X.signum())
        case 2.0:
            if scalePreference == "Simple" {
                return Angle(degrees: 45*X.signum())
            } else {
                return Angle(degrees: 60*X.signum())
            }
        case 1.4:
            return Angle(degrees: 60*X.signum())
        case 1.0:
            return Angle(degrees: 90*X.signum())
        case 0.5:
            if scalePreference == "Simple" {
                return Angle(degrees: 135*X.signum())
            } else {
                return Angle(degrees: 120*X.signum())
            }
        case 1.0/3.0:
            return Angle(degrees: 135*X.signum())
        case 0.2:
            return Angle(degrees: 150*X.signum())
        default:
            return Angle(degrees: 45*X.signum())
        }
    }
    
    private func polarRadiusFor(R: Double) -> Double {
        let Rprime = R == 1.4 ? 2 : R
        return 1 / (1 + Rprime);
    }
    
    private func calculateAnchor(X: Double, radius: CGFloat, modeInterpolator: Double) -> Complex<Double> {
        let smith = Complex(-1, X) / Complex(1, X)
        let polar = Complex.init(length: 1, phase: polarAngleFor(X:X).radians)
        return Complex.init(length: 1.0, phase: abs(modeInterpolator) * smith.phase + (1.0 - abs(modeInterpolator)) * polar.phase)
    }
    
    private func calculateArcCenter(center: CGPoint, anchor: Complex<Double>, modeInterpolator: Double, radius: CGFloat, arcRadius: CGFloat) -> CGPoint {
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
    
    
    private func transform(reflectionCoefficient: Complex<Double>, size: CGSize) -> CGPoint {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = min(size.width, size.height) / 2 - 20
        return CGPoint(
            x: center.x + reflectionCoefficient.real * radius,
            y: center.y - reflectionCoefficient.imaginary * radius
        )
    }
    
    @State private var capturedConstraintValues: ConstraintValues?

    private func handleDrag(at location: CGPoint, in size: CGSize) {
        viewModel.isUndoCheckpointEnabled = false
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = min(size.width, size.height) / 2 - 20
        
        let touchOffset = CGFloat(10) // so you can see point tapped
        let tapPoint = CGPoint(
            x: (location.x - center.x) / radius,
            y: (location.y - touchOffset - center.y) / radius
        )
        
        var reflectionCoefficient = Complex(tapPoint.x, -tapPoint.y)
        
        if (viewModel.traceRecordingEnabled) {
            capturedConstraintValues = ConstraintValues(
                resistance: viewModel.resistance,
                reactance: viewModel.reactance,
                conductance: viewModel.conductance,
                susceptance: viewModel.susceptance,
                length: viewModel.reflectionCoefficient.length,
                phase: viewModel.reflectionCoefficient.phase
            )
        }
        
        if (constraintKind != .unset && constraintKind != .none) {
            if (reflectionCoefficient - viewModel.reflectionCoefficient).length > 0.2 {
                constraintKind = .none
                playHapticsFor(constraintEnabled: false);
            }
        }
        
        if (reflectionCoefficient.length > 1) {
            reflectionCoefficient = Complex.init(length: 1, phase: reflectionCoefficient.phase)
        }
        
        switch viewModel.displayMode {
        case .impedance:
            viewModel.impedance = viewModel.referenceImpedance * (Complex.one + reflectionCoefficient) / (Complex.one - reflectionCoefficient)
        case .admittance:
            viewModel.admittance = viewModel.referenceAdmittance * (Complex.one - reflectionCoefficient) / (Complex.one + reflectionCoefficient)
        case .reflectionCoefficient:
            viewModel.setValueRecordingTrace(
                from: viewModel.reflectionCoefficient,
                to: reflectionCoefficient,
                operation: { intermediateValue in
                    viewModel.reflectionCoefficient = intermediateValue
                },
                interpolationMethod: { (oldValue, newValue, fraction) in
                    return oldValue.polarInterpolated(to: newValue , fraction: fraction)
                }
            )
        }
        
        if (viewModel.traceRecordingEnabled) {
            // Now that we have captured first drag transition, turn off trace recording
            viewModel.traceRecordingEnabled = false
            // Only on subsequent drag calls will we allow constraints to kick in return early
            return
        }
        
        // We are now dragging, so clear any trace now
        viewModel.startAnimatingTrace(delay: 0)
        
        let resistance = capturedConstraintValues!.resistance
        let reactance = capturedConstraintValues!.reactance
        let conductance = capturedConstraintValues!.conductance
        let susceptance = capturedConstraintValues!.susceptance
        let length = capturedConstraintValues!.length
        let phase = capturedConstraintValues!.phase
        
        switch constraintKind {
        case .unset:
            switch viewModel.displayMode {
            case .impedance:
                if abs((viewModel.resistance - resistance)/resistance) < 0.2 {
                    constraintKind = .resistance
                    playHapticsFor(constraintEnabled: true);
                    constraintValue = resistance
                    viewModel.resistance = resistance
                } else if abs((viewModel.reactance - reactance)/reactance) < 0.2 ||
                            abs(reactance) < 0.1 * viewModel.referenceImpedance.real &&
                            abs(viewModel.reactance) < 0.1 * viewModel.referenceImpedance.real {
                    constraintKind = .reactance
                    playHapticsFor(constraintEnabled: true);
                    constraintValue = reactance
                    viewModel.reactance = reactance
                } else {
                    constraintKind = .none
                }
            case .admittance:
                if abs((viewModel.conductance - conductance)/conductance) < 0.2 {
                    constraintKind = .conductance
                    playHapticsFor(constraintEnabled: true);
                    constraintValue = conductance
                    viewModel.conductance = conductance
                } else if abs((viewModel.susceptance - susceptance)/susceptance) < 0.2 ||
                            abs(susceptance) < 0.1 * viewModel.referenceAdmittance.real &&
                            abs(viewModel.susceptance) < 0.1 * viewModel.referenceAdmittance.real {
                    constraintKind = .susceptance
                    playHapticsFor(constraintEnabled: true);
                    constraintValue = susceptance
                    viewModel.susceptance = susceptance
                } else {
                    constraintKind = .none
                }
            case .reflectionCoefficient:
                if length < 0.9999999 && abs(viewModel.reflectionCoefficient.length - length)/length < 0.2 {
                    constraintKind = .magnitude
                    playHapticsFor(constraintEnabled: true);
                    constraintValue = length
                    viewModel.reflectionCoefficient = Complex.init(length: length, phase: viewModel.reflectionCoefficient.phase)
                } else if abs(viewModel.reflectionCoefficient.phase - phase) < (5*(2*Double.pi/360)) {
                    constraintKind = .angle
                    playHapticsFor(constraintEnabled: true);
                    constraintValue = phase
                    viewModel.reflectionCoefficient = Complex.init(length: viewModel.reflectionCoefficient.length, phase: phase)
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
        case .magnitude:
            viewModel.reflectionCoefficient = Complex.init(length: constraintValue, phase: viewModel.reflectionCoefficient.phase)
        case .angle:
            viewModel.reflectionCoefficient = Complex.init(length: viewModel.reflectionCoefficient.length, phase: constraintValue)
        case .none:
            break
        }
    }
    
    private func handleDragEnd() {
        constraintKind = .unset
        viewModel.traceRecordingEnabled = true
        viewModel.isUndoCheckpointEnabled = true
        viewModel.addCheckpoint()
    }
    
    private func playHapticsFor(constraintEnabled: Bool) {
        Haptics.shared.playHapticFeedback(for: constraintEnabled)
    }
}

struct ScanLinesEffect: View {
    let lineSpacing: CGFloat = 4

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let height = geometry.size.height
                let lineCount = Int(height / lineSpacing)

                for i in 0..<lineCount {
                    let y = CGFloat(i) * lineSpacing
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                }
            }
            .stroke(Color.black.opacity(0.3), lineWidth: 1)
        }
    }
}

struct SmithChartView: View {
    
    @AppStorage("showSmithChart") private var showSmithChart = true
    
    var viewModel: ViewModel

    var body: some View {
        if (showSmithChart) {
            ZStack {
                SmithChartContentView(viewModel: viewModel)
                
                ScanLinesEffect()
                    .cornerRadius(20)
                    .padding(10)
                    .aspectRatio(1, contentMode: .fit)
                    .allowsHitTesting(false)
                
                // First radial gradient for central brightness
                RadialGradient(gradient: Gradient(colors: [Color.white.opacity(0.8), Color.white.opacity(0.0)]),
                               center: .center, startRadius: 10, endRadius: 250)
                .blendMode(.overlay)
                .allowsHitTesting(false)
                
                // Second radial gradient for specular light reflection
                GeometryReader { geometry in
                    let upperLeft = UnitPoint(x: 0.1, y: 0.1)
                    RadialGradient(gradient: Gradient(colors: [Color.white.opacity(0.1), Color.white.opacity(0)]),
                                   center: upperLeft,
                                   startRadius: 10, endRadius: 80)
                    .blendMode(.normal)
                    .allowsHitTesting(false)
                }
            }
        }
    }
}

