import SwiftUI

extension Color {
    init(hex: String, brightness: Double = 1.0) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        
        let r = min(Double((rgbValue & 0xff0000) >> 16) / 255.0 * brightness, 1.0)
        let g = min(Double((rgbValue & 0x00ff00) >> 8) / 255.0 * brightness, 1.0)
        let b = min(Double(rgbValue & 0x0000ff) / 255.0 * brightness, 1.0)
        
        self.init(red: r, green: g, blue: b)
    }
}

struct Complex {
    let real: Double
    let imaginary: Double
    
    static var zero: Complex {
        return Complex(real: 0, imaginary: 0)
    }
    
    static var one: Complex {
        return Complex(real: 1, imaginary: 0)
    }
    
    var magnitude: Double {
        return sqrt(real * real + imaginary * imaginary)
    }
    
    var angleInRadians: Double {
        return atan2(imaginary, real)
    }
    
    var angleInDegrees: Double {
        angleInRadians * 180 / Double.pi
    }
    
    static func fromPolar(magnitude: Double, angleInRadians: Double) -> Complex {
        return Complex(real: magnitude * cos(angleInRadians), imaginary: magnitude * sin(angleInRadians))
    }
    
    var reciprocal: Complex {
        let denominator = real * real + imaginary * imaginary
        if (denominator == 0) {
            return Complex(real: Double.infinity, imaginary: -Double.infinity)
        }
        if (imaginary == 0) {
            return Complex(real: real / denominator, imaginary: imaginary / denominator)
        } else {
            return Complex(real: real / denominator, imaginary: -imaginary / denominator)
        }
    }
    
    static func + (left: Complex, right: Complex) -> Complex {
        return Complex(real: left.real + right.real, imaginary: left.imaginary + right.imaginary)
    }
    
    static func - (left: Complex, right: Complex) -> Complex {
        return Complex(real: left.real - right.real, imaginary: left.imaginary - right.imaginary)
    }
    
    static func * (left: Complex, right: Complex) -> Complex {
        return Complex(real: left.real * right.real - left.imaginary * right.imaginary,
                       imaginary: left.real * right.imaginary + left.imaginary * right.real)
    }
    
    static func / (left: Complex, right: Complex) -> Complex {
        let denominator = right.real * right.real + right.imaginary * right.imaginary
        return Complex(real: (left.real * right.real + left.imaginary * right.imaginary) / denominator,
                       imaginary: (left.imaginary * right.real - left.real * right.imaginary) / denominator)
    }
}

protocol UnitWithPowerOfTen: CaseIterable, Identifiable, Equatable, Hashable, RawRepresentable where RawValue == String {
    var basePower: Int { get }
    var powerOfTen: Int { get }
    var shouldRender: Bool { get }
}

extension UnitWithPowerOfTen where Self: RawRepresentable, Self.RawValue == String {
    var powerOfTen: Int {
        return basePower + (Self.allCases.firstIndex(of: self) as! Int * 3)
    }
    
    var shouldRender: Bool {
        return true
    }
}

enum FrequencyUnit: String, UnitWithPowerOfTen {
    case mHz, Hz, kHz, MHz, GHz
    var id: Self { self }
    var basePower: Int { -3 }
}

enum ResistanceUnit: String, UnitWithPowerOfTen {
    case mΩ, Ω, kΩ, MΩ, GΩ
    var id: Self { self }
    var basePower: Int { -3 }
}

enum ConductanceUnit: String, UnitWithPowerOfTen {
    case nS, µS, mS, S, kS
    var id: Self { self }
    var basePower: Int { -9 }
}

enum ReflectionCoefficientUnit: String, UnitWithPowerOfTen {
    case µ, m, Γ, k, M
    var id: Self { self }
    var basePower: Int { -6 }
    var shouldRender: Bool {
        return self != .Γ
    }
}

enum CapacitanceUnit: String, UnitWithPowerOfTen {
    case fF, pF, nF, µF, mF, F
    var id: Self { self }
    var basePower: Int { -15 }
}

enum InductanceUnit: String, UnitWithPowerOfTen {
    case fH, pH, nH, µH, mH, H
    var id: Self { self }
    var basePower: Int { -15 }
}

enum DissipationUnit: String, UnitWithPowerOfTen {
    case D
    var id: Self { self }
    var basePower: Int { 0 }
}

enum QualityUnit: String, UnitWithPowerOfTen {
    case Q
    var id: Self { self }
    var basePower: Int { 0 }
}

enum AngleUnit: String, UnitWithPowerOfTen {
    case microDegree = "µ°"
    case milliDegree = "m°"
    case degree = "°"
    
    var id: Self { self }
    
    var basePower: Int { -6 }
    
    var symbol: String {
        switch self {
        case .microDegree:
            return "µ°"
        case .milliDegree:
            return "m°"
        case .degree:
            return "°"
        }
    }
}

class ViewModel: ObservableObject {
    @Published var impedance: Complex = Complex(real: 50, imaginary: 0)
    @Published var referenceImpedance: Complex = Complex(real: 50, imaginary: 0)
    
    @Published var complexDisplayMode: DisplayMode = .impedance {
        didSet {
            if complexDisplayMode != .reflectionCoefficient {
                smithChartDisplayMode = complexDisplayMode
            }
        }
    }
    
    @Published var smithChartDisplayMode: DisplayMode = .impedance
    
    @Published var frequency: Double = 1000
    
    @Published var circuitMode: CircuitMode = .series
    
    var omega: Double {
        get {
            return 2 * Double.pi * frequency
        }
    }
    
    var admittance: Complex {
        get {
            return impedance.reciprocal
        }
        set {
            impedance = newValue.reciprocal
        }
    }
    
    var resistance: Double {
        get {
            return impedance.real
        }
        set {
            impedance = Complex(real: newValue, imaginary: reactance)
        }
    }
    
    var reactance: Double {
        get {
            return impedance.imaginary
        }
        set {
            impedance = Complex(real: resistance, imaginary: newValue)
        }
    }
    
    var conductance: Double {
        get {
            return admittance.real
        }
        set {
            admittance = Complex(real: newValue, imaginary: susceptance)
        }
    }
    
    var susceptance: Double {
        get {
            return admittance.imaginary
        }
        set {
            admittance = Complex(real: conductance, imaginary: newValue)
        }
    }
    
    var capacitance: Double {
        get {
            switch circuitMode {
            case .series:
                return -1 / (omega * reactance)
            case .parallel:
                return susceptance / omega
            }
        }
        set {
            switch circuitMode {
            case .series:
                reactance = -1 / (omega * newValue)
            case .parallel:
                susceptance = omega * newValue
            }
        }
    }
    
    var inductance: Double {
        get {
            switch circuitMode {
            case .series:
                return reactance / omega
            case .parallel:
                return -1 / (susceptance * omega)
            }
        }
        set {
            switch circuitMode {
            case .series:
                reactance = newValue * omega
            case .parallel:
                susceptance = -1 / (newValue * omega)
            }
        }
    }
    
    var dissipationFactor: Double {
        get {
            switch circuitMode {
            case .series:
                return resistance / abs(reactance)
            case .parallel:
                return conductance / abs(susceptance)
            }
        }
        set {
            switch circuitMode {
            case .series:
                resistance =  newValue * abs(reactance)
            case .parallel:
                conductance = newValue * abs(susceptance)
            }
        }
    }
    
    var qualityFactor: Double {
        get {
            return 1 / dissipationFactor
        }
        set {
            dissipationFactor = 1 / newValue
        }
    }
    
    var reflectionCoefficient: Complex {
        get {
            return (impedance - referenceImpedance) / (impedance + referenceImpedance)
        }
        set {
            impedance = (Complex.one + newValue) / (Complex.one - newValue) * referenceImpedance
        }
    }
}



struct UnitInputView<UnitType>: View where UnitType: RawRepresentable & Hashable & CaseIterable, UnitType.RawValue == String, UnitType: UnitWithPowerOfTen {
    @Binding var value: Double
    @State var unit: UnitType
    @State private var displayedValue: String = ""
    let label: String
    let description: String
    var showNegationDecorator: Bool = false
    @FocusState private var isFocused: Bool
    
    private var unitCases: [UnitType] {
        Array(UnitType.allCases)
    }
    
    private func convertFromEngineeringNotation() -> Double {
        if (displayedValue == "-∞") {
            return -Double.infinity
        } else if (displayedValue == "∞") {
            return Double.infinity
        } else {
            return (Double(displayedValue) ?? 0) * pow(10, Double(unit.powerOfTen))
        }
    }
    
    private func convertToEngineeringNotation(value: Double) {
        // Determine the appropriate unit and value in engineering notation
        let targetUnit = determineAppropriateUnit(for: value)
        let engineeringValue = value / pow(10, Double(targetUnit.powerOfTen))
        unit = targetUnit
        
        if value.isInfinite {
            displayedValue = value < 0 ? "-∞" : "∞"
        } else if value.isNaN {
            displayedValue = ""
        } else {
            if (engineeringValue == 0) {
                displayedValue = "0"
            } else if (abs(engineeringValue) < 0.001) {
                displayedValue = "UFL"
            } else if (abs(engineeringValue) > 9999) {
                displayedValue = "OFL"
            } else {
                if (abs(engineeringValue) >= 1) {
                    let candidate = String(format: "%.4g", engineeringValue)
                    if (abs(Double(candidate)!) >= 1000) {
                        // Rounded up to next unit, so let's try again
                        convertToEngineeringNotation(value: Double(candidate)!/1000);
                    } else {
                        displayedValue = candidate
                    }
                } else {
                    var trimmedValue = String(format: "%.4f", engineeringValue)
                    while trimmedValue.last == "0" {
                        trimmedValue = String(trimmedValue.dropLast())
                    }
                    if (trimmedValue.last == ".") {
                        trimmedValue = String(trimmedValue.dropLast())
                    }
                    displayedValue = trimmedValue
                }
            }
        }
    }
    
    private func determineAppropriateUnit(for value: Double) -> UnitType {
        // Assuming that the units are sorted in the order of their magnitude
        let sortedUnits = unitCases.sorted { $0.powerOfTen < $1.powerOfTen }
        
        for unit in sortedUnits {
            if (value.isInfinite || value == 0 || value.isNaN) {
                if unit.powerOfTen == 0 {
                    return unit;
                }
            } else {
                let unitValue = abs(value) / pow(10, Double(unit.powerOfTen))
                if unitValue >= 1 && unitValue < 1000 {
                    return unit
                }
            }
        }
        
        // Return the original unit if no suitable unit is found
        return unit
    }
    
    private func toggleNegation() {
        if !displayedValue.hasPrefix("-") {
            displayedValue = "-" + displayedValue
        }
        else {
            displayedValue = displayedValue.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        }
    }
    
    var body: some View {
        VStack(alignment: .trailing, spacing: -5) {
            HStack(alignment: .center) {
                Spacer()
                HStack {
                    Text(label)
                        .foregroundColor(Color(hex: "#969F91"))
                    Text(description)
                        .font(.caption)
                        .foregroundColor(Color(hex: "#969F91"))
                }
                .padding(.horizontal, 8)
                .background(Color(hex: "#232521")) // Background for both Text views
                Spacer()
            }
            .zIndex(1)
            ZStack {
                Color(hex:"#400705").edgesIgnoringSafeArea(.all)
                HStack {
                    VStack {
                        Spacer(minLength: 12)
                        TextField("", text: $displayedValue)
                            .multilineTextAlignment(.trailing)
                            .font(.custom("Segment7Standard", size: 30))
                            .kerning(3)
                            .foregroundColor(Color(hex:"#EF8046", brightness: 1.6))
                            .blur(radius: 4)
                            .overlay(
                                ZStack {
                                    TextField("", text: $displayedValue)
                                        .multilineTextAlignment(.trailing)
                                        .font(.custom("Segment7Standard", size: 30))
                                        .kerning(3)
                                        .foregroundColor(Color(hex:"#EF8046", brightness: 1.5))
                                        .tint(Color(hex:"#EF8046", brightness: 1.5))
                                }
                            )
                            .keyboardType(.decimalPad)
                            .focused($isFocused)
                            .onAppear {
                                convertToEngineeringNotation(value:value)
                            }
                            .onChange(of: value) { newValue in
                                convertToEngineeringNotation(value:value)
                            }
                            .onChange(of: isFocused) { focused in
                                if !focused {
                                    value = convertFromEngineeringNotation()
                                }
                            }
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    if isFocused {
                                        if showNegationDecorator {
                                            Spacer()
                                            Button(action: toggleNegation) {
                                                Text("-")
                                                    .font(.custom("Segment7Standard", size: 30))
                                                    .foregroundColor(.black)
                                            }
                                        }
                                        Spacer()
                                        ForEach(unitCases, id: \.self) { unitCase in
                                            Button(action: {
                                                selectUnit(unitCase)
                                            }) {
                                                Text(unitCase.shouldRender ? unitCase.rawValue : "_")
                                                    .foregroundColor(Color(hex: "#D33533", brightness: 1.5))
                                            }
                                            Spacer()
                                        }
                                    }
                                }
                            }
                        Spacer()
                    }
                    Text(unit.shouldRender ? unit.rawValue : "")
                        .foregroundColor(Color(hex:"#D33533", brightness: 1.5))
                        .multilineTextAlignment(.trailing)
                        .frame(width: 36)
                        .overlay(ZStack {
                            Text(unit.shouldRender ? unit.rawValue : "")
                                .foregroundColor(Color(hex:"#D33533", brightness: 1.7))
                                .blur(radius: 4)
                            //.opacity(1)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 36)
                        })
                    Spacer()
                }
            }
            .frame(height: 40)
            .cornerRadius(5)
            .overlay(
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color(hex: "#969F91"), lineWidth: 5)
                        .padding(-8)
                        .offset(y: -1)
                        .mask(RoundedRectangle(cornerRadius: 4)
                            .padding(-7)
                            .padding([.top], -5)
                            .offset(y: -1))
                }
            )
            .padding([.top], 5)
            
        }
        .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
    }
    
    private func selectUnit(_ unitCase: UnitType) {
        unit = unitCase
        value = convertFromEngineeringNotation()
        convertToEngineeringNotation(value:value)
        dismissKeyboard()
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

enum DisplayMode {
    case impedance, admittance, reflectionCoefficient
}

enum CircuitMode {
    case series, parallel
}

struct DisplayView<Content: View>: View {
    var content: Content
    var backgroundColor: Color
    
    init(backgroundColor: Color = Color(hex: "#232521"), @ViewBuilder content: () -> Content) {
        self.backgroundColor = backgroundColor
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(.bottom, 12)
            .background(backgroundColor)
            .edgesIgnoringSafeArea(.bottom)
    }
}

struct ReferenceImpedanceView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        UnitInputView(value: Binding(
            get: { viewModel.referenceImpedance.real },
            set: { viewModel.referenceImpedance = Complex(real: $0, imaginary: 0)}
        ), unit: ResistanceUnit.Ω, label: "Z0", description: "ref. impedance")
    }
}

struct FrequencyView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        UnitInputView(value: Binding(
            get: { viewModel.frequency },
            set: { viewModel.frequency = $0 }
        ), unit: FrequencyUnit.Hz, label: "F", description: "frequency")
    }
}

struct PolarParameterView<UnitType>: View where UnitType: RawRepresentable, UnitType.RawValue == String, UnitType: UnitWithPowerOfTen {
    @Binding var complexValue: Complex
    var magnitudeUnit: UnitType
    var angleUnit: AngleUnit
    var magnitudeLabel: String
    var angleLabel: String
    var magnitudeDescription: String
    var angleDescription: String
    
    var body: some View {
        VStack {
            HStack {
                UnitInputView(value: Binding(
                    get: { self.complexValue.magnitude },
                    set: {
                        if $0 != 0 {
                            self.complexValue = Complex.fromPolar(magnitude: $0, angleInRadians: self.complexValue.angleInRadians)
                        }
                    }
                ), unit: magnitudeUnit, label: magnitudeLabel, description: magnitudeDescription)
                
                UnitInputView(value: Binding(
                    get: { self.complexValue.angleInDegrees },
                    set: {
                        self.complexValue = Complex.fromPolar(magnitude: self.complexValue.magnitude, angleInRadians: $0 * Double.pi / 180)
                    }
                ), unit: angleUnit, label: angleLabel, description: angleDescription, showNegationDecorator: true)
            }
        }
    }
}

struct PolarImpedanceView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        PolarParameterView<ResistanceUnit>(
            complexValue: $viewModel.impedance,
            magnitudeUnit: .Ω,
            angleUnit: .degree,
            magnitudeLabel: "|Z|",
            angleLabel: "θ",
            magnitudeDescription: "magnitude",
            angleDescription: "phase angle"
        )
    }
}

struct PolarAdmittanceView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        PolarParameterView<ConductanceUnit>(
            complexValue: $viewModel.admittance,
            magnitudeUnit: .S,
            angleUnit: .degree,
            magnitudeLabel: "|Y|",
            angleLabel: "θ",
            magnitudeDescription: "magnitude",
            angleDescription: "phase angle"
        )
    }
}

struct PolarReflectionCoefficientView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        PolarParameterView<ReflectionCoefficientUnit>(
            complexValue: $viewModel.reflectionCoefficient,
            magnitudeUnit: .Γ,
            angleUnit: .degree,
            magnitudeLabel: "|Γ|",
            angleLabel: "θ",
            magnitudeDescription: "magnitude",
            angleDescription: "phase angle"
        )
    }
}

struct RectangularParameterView<UnitType: UnitWithPowerOfTen>: View {
    @Binding var complexValue: Complex
    var realPartUnit: UnitType
    var imaginaryPartUnit: UnitType
    var realPartLabel: String
    var imaginaryPartLabel: String
    var realPartDescription: String
    var imaginaryPartDescription: String
    
    var body: some View {
        VStack {
            HStack {
                UnitInputView(value: Binding(
                    get: { self.complexValue.real },
                    set: { self.complexValue = Complex(real: $0, imaginary: self.complexValue.imaginary) }
                ), unit: realPartUnit, label: realPartLabel, description: realPartDescription)
                UnitInputView(value: Binding(
                    get: { self.complexValue.imaginary },
                    set: { self.complexValue = Complex(real: self.complexValue.real, imaginary: $0) }
                ), unit: imaginaryPartUnit, label: imaginaryPartLabel, description: imaginaryPartDescription, showNegationDecorator: true)
            }
        }
    }
}

struct RectangularImpedanceView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        RectangularParameterView<ResistanceUnit>(
            complexValue: $viewModel.impedance,
            realPartUnit: .Ω,
            imaginaryPartUnit: .Ω,
            realPartLabel: "R",
            imaginaryPartLabel: "X",
            realPartDescription: "resistance",
            imaginaryPartDescription: "reactance"
        )
    }
}

struct RectangularAdmittanceView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        RectangularParameterView<ConductanceUnit>(
            complexValue: $viewModel.admittance,
            realPartUnit: .S,
            imaginaryPartUnit: .S,
            realPartLabel: "G",
            imaginaryPartLabel: "B",
            realPartDescription: "conductance",
            imaginaryPartDescription: "susceptance"
        )
    }
}

struct RectangularReflectionCoefficientView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        RectangularParameterView<ReflectionCoefficientUnit>(
            complexValue: $viewModel.reflectionCoefficient,
            realPartUnit: .Γ,
            imaginaryPartUnit: .Γ,
            realPartLabel: "Re(Γ)",
            imaginaryPartLabel: "Im(Γ)",
            realPartDescription: "real part",
            imaginaryPartDescription: "imaginary part"
        )
    }
}

struct ComplexView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        VStack {
            Picker("Mode", selection: $viewModel.complexDisplayMode) {
                Text("Impedance Z").tag(DisplayMode.impedance)
                Text("Admittance Y").tag(DisplayMode.admittance)
                Text("Refl. Coeff. Γ").tag(DisplayMode.reflectionCoefficient)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding([.horizontal], 10)
            .padding([.top], 10)
            
            DisplayView {
                switch viewModel.complexDisplayMode {
                case .impedance:
                    PolarImpedanceView(viewModel: viewModel)
                case .admittance:
                    PolarAdmittanceView(viewModel: viewModel)
                case .reflectionCoefficient:
                    PolarReflectionCoefficientView(viewModel: viewModel)
                }
            }
            DisplayView {
                switch viewModel.complexDisplayMode {
                case .impedance:
                    RectangularImpedanceView(viewModel: viewModel)
                case .admittance:
                    RectangularAdmittanceView(viewModel: viewModel)
                case .reflectionCoefficient:
                    RectangularReflectionCoefficientView(viewModel: viewModel)
                }
            }
        }
    }
}


struct CapacitanceView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        DisplayView {
            VStack {
                HStack {
                    UnitInputView(value: $viewModel.capacitance, unit: CapacitanceUnit.F, label: "C", description: "capacitance")
                    UnitInputView(value: $viewModel.dissipationFactor, unit: DissipationUnit.D, label: "D", description: "dissipation factor")
                }
            }
        }
    }
}

struct InductanceView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        DisplayView {
            VStack {
                HStack {
                    UnitInputView(value: $viewModel.inductance, unit: InductanceUnit.H, label: "L", description: "inductance")
                    UnitInputView(value: $viewModel.qualityFactor, unit: QualityUnit.Q, label: "Q", description: "quality factor")
                }
            }
        }
    }
}

struct ParametersView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        DisplayView {
            HStack {
                FrequencyView(viewModel: viewModel)
                ReferenceImpedanceView(viewModel: viewModel)
            }
        }
    }
}


struct CircuitView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        InductanceView(viewModel: viewModel)
        CapacitanceView(viewModel: viewModel)
        Picker("Mode", selection: $viewModel.circuitMode) {
            Image("Series").tag(CircuitMode.series)
            Image("Parallel").tag(CircuitMode.parallel)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding([.horizontal], 10)
        .frame(maxWidth: 200)
    }
}

enum ConstraintKind {
    case unset, resistance, reactance, conductance, susceptance, none
}

struct SmithChartView: View {
    @ObservedObject var viewModel: ViewModel
    
    @State var constraintKind: ConstraintKind = .unset
    @State var constraintValue: Double = 0
    
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
                    
                    let gridColor: Color = constraintKind == .unset || constraintKind == .none ? .gray : Color(hex:"#FFFFFF", brightness: 0.4)
                    
                    // Draw circles of constant resistance
                    let resistances: [Double] = [0.2, 0.5, 1, 2, 5]
                    for R in resistances {
                        drawResistanceCircle(context: context, center: center, radius: radius, R: R, color: gridColor, style: dashedLineStyle)
                    }
                    
                    context.clip(to: outerCircle)
                    
                    // Draw arcs of constant reactance
                    let reactances: [Double] = [0.2, 0.5, 1, 2, 5]
                    for X in reactances {
                        drawReactanceArc(context: context, center: center, radius: radius, X: X, color: gridColor, style: dashedLineStyle)
                        drawReactanceArc(context: context, center: center, radius: radius, X: -X, color: gridColor, style: dashedLineStyle)
                    }
                    
                    // Draw horizontal line
                    let horizontalLine = Path { path in
                        path.move(to: CGPoint(x: center.x - radius, y: center.y))
                        path.addLine(to: CGPoint(x: center.x + radius, y: center.y))
                    }
                    context.stroke(horizontalLine, with: .color(gridColor), style: dashedLineStyle)
                    
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
                        drawResistanceCircle(context: context, center: center, radius: radius, R: constraintKind == .resistance ? constraintValue / viewModel.referenceImpedance.real : constraintValue * viewModel.referenceImpedance.real, color: Color(hex:"#EF8046", brightness: 1), style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    }
                    
                    if (constraintKind == .reactance || constraintKind == .susceptance) {
                        drawReactanceArc(context: context, center: center, radius: radius, X: constraintKind == .reactance ? viewModel.referenceImpedance.real / constraintValue : -1 / (constraintValue * viewModel.referenceImpedance.real), color: Color(hex:"#EF8046", brightness: 1), style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    }
                }
                .scaleEffect(x: viewModel.smithChartDisplayMode == .admittance ? -1 : 1, y: 1, anchor: .center)
                
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
                    context.stroke(pointPath, with: .color(Color(hex:"#EF8046", brightness: 1.6)))
                    context.fill(pointPath, with: .color(Color(hex:"#EF8046", brightness: 1.6)))
                }
                
                if let reflectionCoefficient = viewModel.reflectionCoefficient {
                    let transformedPoint = transform(reflectionCoefficient: reflectionCoefficient, size: geometry.size)
                    Circle()
                        .fill(Color(hex: "#EF8046", brightness: 1.6))
                        .frame(width: 2*dotRadius, height: 2*dotRadius)
                        .position(transformedPoint)
                        .blur(radius: 1.5*dotRadius)
                }
                
            }
            .background(.black)
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
    
    private func drawResistanceCircle(context: GraphicsContext, center: CGPoint, radius: CGFloat, R: Double, color: Color, style: StrokeStyle) {
        let circleRadius = radius / (R + 1)
        let circleCenter = CGPoint(x: center.x + radius * R / (R + 1), y: center.y)
        let resistanceCircle = Path { path in
            path.addEllipse(in: CGRect(x: circleCenter.x - circleRadius, y: circleCenter.y - circleRadius, width: 2 * circleRadius, height: 2 * circleRadius))
        }
        context.stroke(resistanceCircle, with: .color(color), style: style)
    }
    
    private func drawReactanceArc(context: GraphicsContext, center: CGPoint, radius: CGFloat, X: Double, color: Color, style: StrokeStyle) {
        let arcRadius = radius * X
        let arcCenter = CGPoint(x: center.x + radius, y: center.y - arcRadius)
        let reactanceArc = Path { path in
            path.addEllipse(in: CGRect(x: arcCenter.x - arcRadius, y: arcCenter.y - arcRadius, width: 2 * arcRadius, height: 2 * arcRadius))
        }
        context.stroke(reactanceArc, with: .color(color), style: style)
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
            reflectionCoefficient = Complex.fromPolar(magnitude: 1, angleInRadians: reflectionCoefficient.angleInRadians)
            viewModel.reflectionCoefficient = reflectionCoefficient
            viewModel.resistance = 0
        } else {
            viewModel.reflectionCoefficient = reflectionCoefficient
        }
        
        switch constraintKind {
        case .unset:
            if (viewModel.smithChartDisplayMode == .admittance) {
                if abs((viewModel.conductance - conductance)/conductance) < 0.2 {
                    constraintKind = .conductance
                    constraintValue = conductance
                    viewModel.conductance = conductance
                } else if abs((viewModel.susceptance - susceptance)/susceptance) < 0.2 ||
                            abs(susceptance) < 0.001 && abs(viewModel.susceptance) < 0.001 {
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
                            abs(reactance) < 4 && abs(viewModel.reactance) < 4 {
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

struct ContentView: View {
    
    @StateObject var viewModel = ViewModel()
    
    var body: some View {
        ZStack {
            Color(hex:"#A1BB9B").edgesIgnoringSafeArea(.all)
            ScrollView {
                VStack {
                    VStack {
                        ComplexView(viewModel: viewModel)
                        ParametersView(viewModel: viewModel)
                        CircuitView(viewModel: viewModel)
                    }
                    .frame(maxWidth: 600)
                    SmithChartView(viewModel: viewModel)
                }
            }
            .padding(.top, 1)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
