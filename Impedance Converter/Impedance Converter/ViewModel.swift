import SwiftUI
import Numerics

enum DisplayMode: Codable {
    case impedance, admittance, reflectionCoefficient
}

enum CircuitMode: Codable {
    case series, parallel
}

enum AngleOrientation: Codable {
    case counterclockwise, clockwise
}

enum ImmittanceType: Codable {
    case impedance, admittance
}

enum Hold {
    case none, inductance, capacitance
}

struct Immittance: Codable, Equatable {
    
    public let type: ImmittanceType
    private let value: Complex<Double>
    
    public init(impedance: Complex<Double>) {
        value = impedance
        type = .impedance
    }
    
    public init(admittance: Complex<Double>) {
        value = admittance
        type = .admittance
    }
    
    public var impedance: Complex<Double> {
        get {
            switch (type) {
            case .impedance:
                return value
            case .admittance:
                return value.reciprocal ?? Complex.infinity
            }
        }
    }
    
    public var admittance: Complex<Double> {
        get {
            switch (type) {
            case .impedance:
                return value.reciprocal ?? Complex.infinity
            case .admittance:
                return value
            }
        }
    }
    
}

extension Double {
    
    func linearlyInterpolated(to endValue: Double, fraction: Double) -> Double {
        return self + (endValue - self) * fraction
    }
    
    func logarithmicallyInterpolated(to endValue: Double, fraction: Double) -> Double {
        // Check if either value is infinite
        let startIsInfinite = self.isInfinite
        let endIsInfinite = endValue.isInfinite
        
        // Handle cases with infinity
        if startIsInfinite || endIsInfinite {
            // Use a proxy for infinity
            let proxyForInfinity = (startIsInfinite ? self : endValue) > 0 ? Double.greatestFiniteMagnitude : -Double.greatestFiniteMagnitude
            
            // If both are infinite (and same sign), return either of them
            if startIsInfinite && endIsInfinite && (self.sign == endValue.sign) {
                return self
            }
            
            // Compute interpolation with the proxy value
            let finiteValue = startIsInfinite ? endValue : self
            let adjustedFraction = startIsInfinite ? 1 - fraction : fraction
            return finiteValue.linearlyInterpolated(to: proxyForInfinity, fraction: adjustedFraction)
        }
        
        // Special case handling for values around zero
        if (self >= 0 && endValue <= 0) || (self <= 0 && endValue >= 0) {
            return linearlyInterpolated(to: endValue, fraction: fraction)
        }

        // Extract signs and magnitudes
        let signStart = self.sign == .minus ? -1.0 : 1.0
        let signEnd = endValue.sign == .minus ? -1.0 : 1.0

        // Use absolute values for logarithmic interpolation
        let magnitudeStart = abs(self)
        let magnitudeEnd = abs(endValue)
        
        // Logarithmic interpolation for magnitudes (guard against zero)
        guard magnitudeStart > 0, magnitudeEnd > 0 else { return (self + endValue) / 2 }
        let logStart = Double.log(magnitudeStart)
        let logEnd = Double.log(magnitudeEnd)
        let logInterpolated = (1 - fraction) * logStart + fraction * logEnd
        let interpolatedMagnitude = Double.exp(logInterpolated)

        // Determine the sign for the interpolated value
        // If signs are different, use the sign of the end value
        let interpolatedSign = (signStart == signEnd) ? signStart : signEnd

        return interpolatedSign * interpolatedMagnitude
    }
}

protocol Interpolatable {
    func interpolated(to endValue: Self, fraction: Double) -> Self
}

extension Double: Interpolatable {
    func interpolated(to endValue: Double, fraction: Double) -> Double {
        return logarithmicallyInterpolated(to: endValue, fraction: fraction)
    }
}

extension Complex<Double> {
    
    func polarInterpolated(to endValue: Complex<Double>, fraction: Double) -> Complex<Double> {
        let interpolatedLength = length.linearlyInterpolated(to: endValue.length, fraction: fraction)
        let shortestDifference = symmetricRemainder(dividend: endValue.phase - phase, divisor: 2 * .pi)
        let interpolatedPhase = phase.linearlyInterpolated(to: phase + shortestDifference, fraction: fraction)
        return Complex<Double>.init(length: interpolatedLength, phase: interpolatedPhase.isNaN ? 0 : interpolatedPhase)
    }
    
    func rectangularInterpolated(to endValue: Complex<Double>, fraction: Double) -> Complex<Double> {
        let interpolatedReal = real.linearlyInterpolated(to: endValue.real, fraction: fraction)
        let interpolatedImaginary = imaginary.linearlyInterpolated(to: endValue.imaginary, fraction: fraction)
        return Complex<Double>(interpolatedReal, interpolatedImaginary)
    }
}

extension Complex<Double>: Interpolatable {
    func interpolated(to endValue: Complex<Double>, fraction: Double) -> Complex<Double> {
        return rectangularInterpolated(to: endValue, fraction: fraction)
    }
}

class ViewModel: ObservableObject, Codable {
    
    @AppStorage("tracePersistence") private var tracePersistence = "Normal"
    
    let traceRecordLength: Int = 100
    
    @Published var traceRecordingEnabled = true
    @Published var trace: [Complex<Double>] = []
    
    var traceAnimator = SmoothAnimation(initialValue: 0)
    
    func startAnimatingTrace(delay: Double) {
        if delay.isFinite {
            traceAnimator.startAnimating(from: 1, target: 0, totalAnimationTime: 0.05, delay: delay) { interpolatorValue in
                let elementsToKeep = Int((Double(self.traceRecordLength) * interpolatorValue).rounded(.down))
                if elementsToKeep < self.trace.count {
                    self.trace.removeFirst(self.trace.count - elementsToKeep)
                }
            }
        }
    }
    
    private func doTracePersistence() {
        let delay = tracePersistence == "Normal" ? 0.00 : tracePersistence == "Long" ? 1.0 : Double.infinity
        startAnimatingTrace(delay: delay)
    }
    
    func setValueRecordingTrace<T: Interpolatable>(from oldValue: T, to newValue: T, operation: (T) -> Void, interpolationMethod: ((T, T, Double) -> T)? = nil) {
        if (!traceRecordingEnabled) {
            operation(newValue)
        } else {
            let traceRecordingEnabledPrev = traceRecordingEnabled
            traceRecordingEnabled = false
            let isUndoCheckpointEnabledPrev = isUndoCheckpointEnabled
            isUndoCheckpointEnabled = false
            
            let steps = traceRecordLength
            
            var trace: [Complex<Double>] = []
            for step in 0...steps {
                let fraction = Double(step) / Double(steps)
                let intermediateValue = interpolationMethod?(oldValue, newValue, fraction) ?? oldValue.interpolated(to: newValue, fraction: fraction)
                operation(intermediateValue)
                trace.append(reflectionCoefficient)
            }
            
            self.trace = trace
            isUndoCheckpointEnabled = isUndoCheckpointEnabledPrev
            operation(newValue)
            traceRecordingEnabled = traceRecordingEnabledPrev
            doTracePersistence()
        }
    }

    @Published var updateTrigger = false
    
    func appDidBecomeActive() {
        updateTrigger.toggle()
        doTracePersistence()
    }
    
    @Published var hold: Hold = .none
    
    func prepareHold() -> (type: Hold, value: Double) {
        switch hold {
        case .none:
            return (.none, 0)
        case .inductance:
            return (.inductance, inductance)
        case .capacitance:
            return (.capacitance, capacitance)
        }
    }

    func performHold(held: (type: Hold, value: Double)) {
        let isUndoCheckpointEnabledPrev = isUndoCheckpointEnabled
        isUndoCheckpointEnabled = false
        switch held.type {
        case .none:
            break
        case .inductance:
            inductance = held.value
        case .capacitance:
            capacitance = held.value
        }
        isUndoCheckpointEnabled = isUndoCheckpointEnabledPrev
        hold = held.type
    }


    @Published private var _frequency: Double = 100000
    var frequency: Double {
        get {
            return _frequency
        }
        set {
            if newValue > 0 && newValue.isFinite {
                if _frequency != newValue {
                    let value = prepareHold()
                    _frequency = newValue
                    performHold(held: value)
                    addCheckpoint()
                }
            }
        }
    }
    
    var omega: Double {
        get {
            return 2 * Double.pi * frequency
        }
    }
        
    @Published private var referenceImmittance: Immittance = Immittance(impedance: Complex(50, 0))
    
    @Published private var immittance: Immittance = Immittance(impedance: Complex(50, 0))
        
    @Published var refAngle: Angle = Angle(radians: 0)
    
    @Published var angleOrientation: AngleOrientation = .clockwise {
        didSet {
            if angleOrientation != oldValue {
                addCheckpoint()
            }
        }
    }

    private func ensurePositiveReal(value: Complex<Double>) -> Complex<Double> {
        if (value.real < 0) {
            return Complex(0, value.imaginary)
        } else {
            return value
        }
    }
    
    private func zeroCorrect(value: Double) -> Double {
        let epsilon = 1e-10
        if abs(value) < epsilon {
            return 0
        } else {
            return value
        }
    }
    
    private func zeroCorrect(value: Complex<Double>) -> Complex<Double> {
        return Complex(zeroCorrect(value: value.real), zeroCorrect(value: value.imaginary))
    }
    
    var referenceImpedance: Complex<Double> {
        get {
            return referenceImmittance.impedance
        }
        set {
            // Guard against negative real part
            guard newValue.real > 0 && newValue.imaginary == 0 else {
                print("Attempted to set reference impedance that is not positive real")
                return
            }
            
            let previousReferenceImmittance = referenceImmittance
            referenceImmittance = Immittance(impedance: newValue)
            if (referenceImmittance != previousReferenceImmittance) {
                addCheckpoint()
            }
        }
    }
    
    var referenceAdmittance: Complex<Double> {
        get {
            return referenceImmittance.admittance
        }
        set {
            // Guard to ensure the real part of the admittance is positive
            guard newValue.real > 0 && newValue.imaginary == 0 else {
                print("Attempted to set reference admittance that is not positive real")
                return
            }
            
            let previousReferenceImmittance = referenceImmittance
            referenceImmittance = Immittance(admittance: newValue)
            if (referenceImmittance != previousReferenceImmittance) {
                addCheckpoint()
            }
        }
    }
    
    var impedance: Complex<Double> {
        get {
            return zeroCorrect(value: immittance.impedance)
        }
        set {
            let previousImmittance = immittance
            setValueRecordingTrace(from: impedance, to: ensurePositiveReal(value: newValue)) { intermediateValue in
                immittance = Immittance(impedance: intermediateValue)
            }
            if (immittance != previousImmittance) {
                addCheckpoint()
                hold = .none
            }
        }
    }
    
    var admittance: Complex<Double> {
        get {
            return zeroCorrect(value: immittance.admittance)
        }
        set {
            let previousImmittance = immittance
            setValueRecordingTrace(from: admittance, to: ensurePositiveReal(value: newValue)) { intermediateValue in
                immittance = Immittance(admittance: intermediateValue)
            }
            if (immittance != previousImmittance) {
                addCheckpoint()
                hold = .none
            }
        }
    }
    
    var resistance: Double {
        get {
            return impedance.canonicalizedReal
        }
        set {
            setValueRecordingTrace(from: resistance, to: newValue) { intermediateValue in
                impedance = Complex(intermediateValue, reactance)
            }
        }
    }
    
    var reactance: Double {
        get {
            return impedance.canonicalizedImaginary
        }
        set {
            setValueRecordingTrace(from: reactance, to: newValue) { intermediateValue in
                impedance = Complex(resistance, intermediateValue)
            }
        }
    }
    
    var conductance: Double {
        get {
            return admittance.canonicalizedReal
        }
        set {
            setValueRecordingTrace(from: conductance, to: newValue) { intermediateValue in
                admittance = Complex(intermediateValue, susceptance)
            }
        }
    }
    
    var susceptance: Double {
        get {
            return admittance.canonicalizedImaginary
        }
        set {
            setValueRecordingTrace(from: susceptance, to: newValue) { intermediateValue in
                admittance = Complex(conductance, intermediateValue)
            }
        }
    }
    
    var capacitance: Double {
        get {
            switch circuitMode {
            case .series:
                return reactance.isZero ? Double.infinity : -1 / (omega * reactance)
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
            hold = .capacitance
        }
    }
    
    var inductance: Double {
        get {
            switch circuitMode {
            case .series:
                return reactance / omega
            case .parallel:
                return susceptance.isZero ? Double.infinity : -1 / (susceptance * omega)
            }
        }
        set {
            switch circuitMode {
            case .series:
                reactance = newValue * omega
            case .parallel:
                susceptance = -1 / (newValue * omega)
            }
            hold = .inductance
        }
    }
    
    private func factorTransform() -> ImmittanceType {
        if hold == .capacitance || hold == .inductance {
            switch circuitMode {
            case .series:
                return .impedance
            case .parallel:
                return .admittance
            }
        } else {
            switch displayMode {
            case .impedance:
                return .impedance
            case .admittance:
                return .admittance
            default:
                return .impedance
            }
        }
    }
    
    var dissipationFactor: Double {
        get {
            switch immittance.type {
            case .impedance:
                return resistance / abs(reactance)
            case .admittance:
                return conductance / abs(susceptance)
            }
        }
        set {
            let value = prepareHold()
            switch factorTransform() {
            case .impedance:
                if reactance == 0 || abs(reactance).isInfinite {
                    if resistance != 0 {
                        reactance = resistance / newValue
                    }
                } else {
                    resistance = abs(reactance) * newValue
                }
            case .admittance:
                if susceptance == 0 || abs(susceptance).isInfinite {
                    if conductance != 0 {
                        susceptance = conductance / newValue
                    }
                } else {
                    conductance = abs(susceptance) * newValue
                }
            }
            performHold(held: value)
        }
    }
    
    var qualityFactor: Double {
        get {
            switch immittance.type {
            case .impedance:
                return abs(reactance) / resistance
            case .admittance:
                return abs(susceptance) / conductance
            }
        }
        set {
            let value = prepareHold()
            switch factorTransform() {
            case .impedance:
                if reactance == 0 || abs(reactance).isInfinite {
                    if resistance != 0 {
                        reactance = resistance * newValue
                    }
                } else {
                    if newValue == 0 {
                        reactance = 0
                    } else {
                        resistance = abs(reactance) / newValue
                    }
                }
            case .admittance:
                if susceptance == 0 || abs(susceptance).isInfinite {
                    if conductance != 0 {
                        susceptance = conductance * newValue
                    }
                } else {
                    if newValue == 0 {
                        susceptance = 0
                    } else {
                        conductance = abs(susceptance) / newValue
                    }
                }
            }
            performHold(held: value)
        }
    }
    
    var reflectionCoefficient: Complex<Double> {
        get {
            switch (immittance.type) {
            case .impedance:
                if (impedance.length.isInfinite) {
                    return Complex.one
                } else {
                    return zeroCorrect(value: (impedance - referenceImpedance) / (impedance + referenceImpedance))
                }
            case .admittance:
                if (admittance.length.isInfinite) {
                    return -Complex.one
                } else {
                    return zeroCorrect(value: (referenceAdmittance - admittance) / (referenceAdmittance + admittance))
                }
            }
        }
        set {
            setValueRecordingTrace(from: reflectionCoefficient, to: newValue) { intermediateValue in
                switch (immittance.type) {
                case .impedance:
                    impedance = referenceImpedance * (Complex.one + intermediateValue) / (Complex.one - intermediateValue)
                case .admittance:
                    admittance = referenceAdmittance * (Complex.one - intermediateValue) / (Complex.one + intermediateValue)
                }
            }
        }
    }
    
    private func unityReflectionCoefficient() -> Bool {
        let epsilon = 1e-15
        return abs(reflectionCoefficient.length - 1.0) < epsilon
    }
    
    var swr: Double {
        get {
            if unityReflectionCoefficient() {
                return Double.infinity
            } else {
                let reflectionCoefficientLength = reflectionCoefficient.length
                return (1 + reflectionCoefficientLength) / (1 - reflectionCoefficientLength)
            }
        }
        set {
            guard newValue >= 1 else { return }
            guard !reflectionCoefficient.phase.isNaN else { return }
            setValueRecordingTrace(from: swr, to: newValue) { intermediateValue in
                let reflectionCoefficientLength = (intermediateValue - 1) / (intermediateValue + 1)
                reflectionCoefficient = Complex.init(length: reflectionCoefficientLength, phase: reflectionCoefficient.phase)
            }
        }
    }
    
    var swr_dB: Double {
        get {
            return 20 * log10(swr)
        }
        set {
            swr = pow(10, newValue / 20)
        }
    }
    
    var reflectionCoefficientRho: Double {
        get {
            return reflectionCoefficient.length
        }
        set {
            guard !reflectionCoefficient.phase.isNaN else { return }
            setValueRecordingTrace(from: reflectionCoefficientRho, to: newValue) { intermediateValue in
                reflectionCoefficient = Complex.init(length: intermediateValue, phase: reflectionCoefficient.phase)
            }
        }
    }
    
    var reflectionCoefficientPower: Double {
        get {
            if (unityReflectionCoefficient()) {
                return 1
            } else {
                return reflectionCoefficient.lengthSquared
            }
        }
        set {
            guard !reflectionCoefficient.phase.isNaN else { return }
            setValueRecordingTrace(from: reflectionCoefficientPower, to: newValue) { intermediateValue in
                reflectionCoefficient = Complex.init(length: sqrt(intermediateValue), phase: reflectionCoefficient.phase)
            }
        }
    }
    
    var returnLoss: Double {
        get {
            if (unityReflectionCoefficient()) {
                return 0
            } else {
                return -20 * log10(reflectionCoefficient.length)
            }
        }
        set {
            guard newValue >= 0 else { return }
            setValueRecordingTrace(from: returnLoss, to: newValue) { intermediateValue in
                let reflectionCoefficientLength = pow(10, -intermediateValue / 20)
                reflectionCoefficient = Complex.init(length: reflectionCoefficientLength, phase: reflectionCoefficient.phase)
            }
        }
    }

    var transmissionCoefficient: Complex<Double> {
        get {
            1 + reflectionCoefficient
        }
        set {
            reflectionCoefficient = newValue - 1
        }
    }
    
    var transmissionCoefficientTau: Double {
        get {
            return transmissionCoefficient.length
        }
        set {
            guard !transmissionCoefficient.phase.isNaN else { return }
            transmissionCoefficient = Complex.init(length: newValue, phase: transmissionCoefficient.phase)
        }
    }
    
    var transmissionCoefficientPower: Double {
        get {
            1 - reflectionCoefficientPower
        }
        set {
            reflectionCoefficientPower = 1 - newValue
        }
    }

    var reflectionLoss: Double {
        get {
            return -10 * log10(transmissionCoefficientPower)
        }
        set {
            guard newValue >= 0 else { return }
            transmissionCoefficientPower = pow(10, -newValue / 10)
        }
    }

    @Published var _velocityFactor: Double = 1

    var velocityFactor: Double {
        get {
            return _velocityFactor
        }
        set {
            if 0 < newValue && newValue <= 1 {
                if _velocityFactor != newValue {
                    _velocityFactor = newValue
                    addCheckpoint()
                }
            }
        }
    }
    
    private var propagationVelocity: Double {
        get {
            return velocityFactor * 3e8
        }
    }
    var wavelength: Double {
        get {
            return propagationVelocity / frequency
        }
        set {
            frequency = propagationVelocity / newValue
        }
    }
    
    var angleSign: Double {
        switch angleOrientation {
        case .counterclockwise:
            return 1
        case .clockwise:
            return -1
        }
    }
    
    var wavelengths: Double {
        get {
            let originalRemainder = symmetricRemainder(dividend: angleSign * (reflectionCoefficient.phase - refAngle.radians), divisor: 2 * Double.pi)
            let adjustedRemainder = (originalRemainder + 2 * Double.pi).truncatingRemainder(dividingBy: 2 * Double.pi)
            return adjustedRemainder / (4 * Double.pi)
        }
        set {
            setValueRecordingTrace(from: wavelengths, to: newValue) { intermediateValue in
                reflectionCoefficient = Complex.init(length: reflectionCoefficient.length, phase: angleSign * (4 * Double.pi) * intermediateValue + refAngle.radians)
            }
        }
    }
    
    var length: Double {
        get {
            return wavelengths * wavelength
        }
        set {
            wavelengths = newValue / wavelength
        }
    }
    
    func zeroLength() {
        let previous = refAngle
        refAngle = Angle(radians: reflectionCoefficient.phase)
        if (refAngle != previous) {
            addCheckpoint()
        }
    }
    
    @Published var complexDisplayMode: DisplayMode = .impedance {
        didSet {
            if complexDisplayMode != .reflectionCoefficient {
                displayMode = complexDisplayMode
            }
        }
    }
    
    @Published var circuitMode: CircuitMode = .series
    
    @Published var displayMode: DisplayMode = .impedance
    
    @Published var constantCircleCursor = false
    
    @Published var constantArcCursor = false
    
    @Published var constantMagnitudeCursor = false
    
    @Published var constantAngleCursor = false
    
    enum CodingKeys: CodingKey {
        case displayMode, circuitMode,
             immittance, immittanceType,
             referenceImmittance, referenceImmittanceType,
             frequency, velocityFactor,
             refAngle, measureOrientation,
             trace,
             constantCircleCursor, constantArcCursor,
             constantMagnitudeCursor, constantAngleCursor
    }
    
    init() {
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let isUndoCheckpointEnabledPrev = isUndoCheckpointEnabled
        isUndoCheckpointEnabled = false
        displayMode = try container.decode(DisplayMode.self, forKey: .displayMode)
        circuitMode = try container.decode(CircuitMode.self, forKey: .circuitMode)
        immittance = try container.decode(Immittance.self, forKey: .immittance)
        referenceImmittance = try container.decode(Immittance.self, forKey: .referenceImmittance)
        frequency = try container.decode(Double.self, forKey: .frequency)
        velocityFactor = try container.decode(Double.self, forKey: .velocityFactor)
        let angleRadians = try container.decode(Double.self, forKey: .refAngle)
        refAngle = Angle(radians:angleRadians)
        angleOrientation = try container.decode(AngleOrientation.self, forKey: .measureOrientation)
        trace = try container.decode([Complex<Double>].self, forKey: .trace)
        if tracePersistence != "Infinite" {
            trace = []
        }
        constantCircleCursor = try container.decode(Bool.self, forKey: .constantCircleCursor)
        constantArcCursor = try container.decode(Bool.self, forKey: .constantArcCursor)
        constantMagnitudeCursor = try container.decode(Bool.self, forKey: .constantMagnitudeCursor)
        constantAngleCursor = try container.decode(Bool.self, forKey: .constantAngleCursor)
        isUndoCheckpointEnabled = isUndoCheckpointEnabledPrev
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(displayMode, forKey: .displayMode)
        try container.encode(circuitMode, forKey: .circuitMode)
        try container.encode(immittance, forKey: .immittance)
        try container.encode(referenceImmittance, forKey: .referenceImmittance)
        try container.encode(frequency, forKey: .frequency)
        try container.encode(velocityFactor, forKey: .velocityFactor)
        try container.encode(refAngle.radians, forKey: .refAngle)
        try container.encode(angleOrientation, forKey: .measureOrientation)
        try container.encode(trace, forKey: .trace)
        try container.encode(constantCircleCursor, forKey: .constantCircleCursor)
        try container.encode(constantArcCursor, forKey: .constantArcCursor)
        try container.encode(constantMagnitudeCursor, forKey: .constantMagnitudeCursor)
        try container.encode(constantAngleCursor, forKey: .constantAngleCursor)
    }
    
    func update(from other: ViewModel) {
        let isUndoCheckpointEnabledPrev = isUndoCheckpointEnabled
        isUndoCheckpointEnabled = false
        self.displayMode = other.displayMode
        self.circuitMode = other.circuitMode
        self.immittance = other.immittance
        self.referenceImmittance = other.referenceImmittance
        self.frequency = other.frequency
        self.velocityFactor = other.velocityFactor
        self.refAngle = other.refAngle
        self.angleOrientation = other.angleOrientation
        self.trace = other.trace
        self.constantCircleCursor = other.constantCircleCursor
        self.constantArcCursor = other.constantArcCursor
        self.constantMagnitudeCursor = other.constantMagnitudeCursor
        self.constantAngleCursor = other.constantAngleCursor
        isUndoCheckpointEnabled = isUndoCheckpointEnabledPrev
    }
    
    func encodeToJSON() -> String? {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(self)
            return String(data: data, encoding: .utf8)
        } catch {
            print("Error encoding ViewModel: \(error)")
            return nil
        }
    }
    
    static func decodeFromJSON(_ jsonString: String) -> ViewModel? {
        let decoder = JSONDecoder()
        if let data = jsonString.data(using: .utf8) {
            do {
                let viewModel = try decoder.decode(ViewModel.self, from: data)
                return viewModel
            } catch {
                print("Error decoding ViewModel: \(error)")
                return nil
            }
        }
        return nil
    }
    
    @Published var isUndoCheckpointEnabled = true
    
    private var checkpoints: [String] = []
    
    func addCheckpoint() {
        if isUndoCheckpointEnabled, let json = encodeToJSON() {
            if checkpoints.count >= 32 {
                checkpoints.removeFirst()
            }
            checkpoints.append(json)
        }
    }

    var canUndo: Bool {
        get {
            checkpoints.count > 1
        }
    }
    
    func undo() {
        // Ensure there's more than one checkpoint
        guard checkpoints.count > 1 else { return }

        // Remove the last checkpoint (current state)
        checkpoints.removeLast()

        // Now, use the new last checkpoint for undo
        if let previousCheckpoint = checkpoints.last,
           let restoredViewModel = ViewModel.decodeFromJSON(previousCheckpoint) {
            update(from: restoredViewModel)
        }
    }
}
