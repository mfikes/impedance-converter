import SwiftUI

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
    private let value: Complex
    
    public init(impedance: Complex) {
        value = impedance
        type = .impedance
    }
    
    public init(admittance: Complex) {
        value = admittance
        type = .admittance
    }
    
    public var impedance: Complex {
        get {
            switch (type) {
            case .impedance:
                return value
            case .admittance:
                return value.reciprocal
            }
        }
    }
    
    public var admittance: Complex {
        get {
            switch (type) {
            case .impedance:
                return value.reciprocal
            case .admittance:
                return value
            }
        }
    }
    
}

class ViewModel: ObservableObject, Codable {
    
    @Published var updateTrigger = false
    
    func appDidBecomeActive() {
        updateTrigger.toggle()
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
        isUndoCheckpointEnabled = false
        switch held.type {
        case .none:
            break
        case .inductance:
            inductance = held.value
        case .capacitance:
            capacitance = held.value
        }
        isUndoCheckpointEnabled = true
        hold = held.type
    }


    @Published private var _frequency: Double = 100000
    var frequency: Double {
        get {
            return _frequency
        }
        set {
            if newValue > 0 {
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
        
    @Published private var referenceImmittance: Immittance = Immittance(impedance: Complex(real: 50, imaginary: 0))
    
    @Published private var immittance: Immittance = Immittance(impedance: Complex(real: 50, imaginary: 0))
        
    @Published var refAngle: Angle = Angle(radians: 0)
    
    @Published var angleOrientation: AngleOrientation = .counterclockwise {
        didSet {
            if angleOrientation != oldValue {
                addCheckpoint()
            }
        }
    }
        
    private func ensureNoNaN(value: Complex) -> Complex {
        if (value.real.isNaN && value.imaginary.isNaN) {
            return Complex(real: 0, imaginary: 0)
        } else if (value.real.isNaN) {
            return Complex(real: 0, imaginary: value.imaginary)
        } else if (value.imaginary.isNaN) {
            return Complex(real: value.real, imaginary: 0)
        } else {
            return value
        }
    }
    
    private func ensurePositiveReal(value: Complex) -> Complex {
        if (value.real < 0) {
            return Complex(real: 0, imaginary: value.imaginary)
        } else {
            return value
        }
    }
    
    var referenceImpedance: Complex {
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
    
    var referenceAdmittance: Complex {
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
    
    var impedance: Complex {
        get {
            return immittance.impedance
        }
        set {
            let previousImmittance = immittance
            immittance = Immittance(impedance: newValue)
            if (immittance != previousImmittance) {
                addCheckpoint()
                hold = .none
            }
        }
    }
    
    var admittance: Complex {
        get {
            return immittance.admittance
        }
        set {
            let previousImmittance = immittance
            immittance = Immittance(admittance: newValue)
            if (immittance != previousImmittance) {
                addCheckpoint()
                hold = .none
            }
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
            hold = .capacitance
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
                    resistance =  abs(reactance) * newValue
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
    
    var reflectionCoefficient: Complex {
        get {
            switch (immittance.type) {
            case .impedance:
                if (impedance.magnitude.isInfinite) {
                    return Complex.one
                } else {
                    return (impedance - referenceImpedance) / (impedance + referenceImpedance)
                }
            case .admittance:
                if (admittance.magnitude.isInfinite) {
                    return -Complex.one
                } else {
                    return (referenceAdmittance - admittance) / (referenceAdmittance + admittance)
                }
            }
        }
        set {
            switch (immittance.type) {
            case .impedance:
                impedance = referenceImpedance * (Complex.one + newValue) / (Complex.one - newValue)
            case .admittance:
                admittance = referenceAdmittance * (Complex.one - newValue) / (Complex.one + newValue)
            }
        }
    }
    
    var swr: Double {
        get {
            let reflectionCoefficientMagnitude = reflectionCoefficient.magnitude
            return (1 + reflectionCoefficientMagnitude) / (1 - reflectionCoefficientMagnitude)
        }
        set {
            guard newValue >= 1 else { return }
            let reflectionCoefficientMagnitude = (newValue - 1) / (newValue + 1)
            reflectionCoefficient = Complex.fromPolar(magnitude: reflectionCoefficientMagnitude, angle: reflectionCoefficient.angle)
        }
    }
    
    var returnLoss: Double {
        get {
            let reflectionCoefficientMagnitude = reflectionCoefficient.magnitude
            return -20 * log10(reflectionCoefficientMagnitude)
        }
        set {
            guard newValue >= 0 else { return }
            let reflectionCoefficientMagnitude = pow(10, -newValue / 20)
            reflectionCoefficient = Complex.fromPolar(magnitude: reflectionCoefficientMagnitude, angle: reflectionCoefficient.angle)
        }
    }

    var transmissionCoefficient: Double {
        get {
            let reflectionCoefficientMagnitude = reflectionCoefficient.magnitude
            return 1 - pow(reflectionCoefficientMagnitude, 2)
        }
        set {
            guard newValue >= 0 && newValue <= 1 else { return }
            let reflectionCoefficientMagnitude = sqrt(1 - newValue)
            reflectionCoefficient = Complex.fromPolar(magnitude: reflectionCoefficientMagnitude, angle: reflectionCoefficient.angle)
        }
    }

    var transmissionLoss: Double {
        get {
            let transmissionCoefficientValue = transmissionCoefficient
            return -10 * log10(transmissionCoefficientValue)
        }
        set {
            guard newValue >= 0 else { return }
            let transmissionCoefficientValue = pow(10, -newValue / 10)
            transmissionCoefficient = transmissionCoefficientValue
        }
    }

    var wavelength: Double {
        return 3e8 / frequency
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
            let originalRemainder = symmetricRemainder(dividend: angleSign * (reflectionCoefficient.angle.radians - refAngle.radians), divisor: 2 * Double.pi)
            let adjustedRemainder = (originalRemainder + 2 * Double.pi).truncatingRemainder(dividingBy: 2 * Double.pi)
            return adjustedRemainder / (4 * Double.pi)
        }
        set {
            reflectionCoefficient = Complex.fromPolar(magnitude: reflectionCoefficient.magnitude, angle: Angle(radians:angleSign * (4 * Double.pi) * newValue + refAngle.radians))
        }
    }
    
    var distance: Double {
        get {
            return wavelengths * wavelength
        }
        set {
            wavelengths = newValue / wavelength
        }
    }
    
    func zeroLength() {
        let previous = refAngle
        refAngle = reflectionCoefficient.angle
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
    
    enum CodingKeys: CodingKey {
        case displayMode, circuitMode,
             immittance, immittanceType,
             referenceImmittance, referenceImmittanceType,
             frequency,
             refAngle, measureOrientation
    }
    
    init() {
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        displayMode = try container.decode(DisplayMode.self, forKey: .displayMode)
        circuitMode = try container.decode(CircuitMode.self, forKey: .circuitMode)
        immittance = try container.decode(Immittance.self, forKey: .immittance)
        referenceImmittance = try container.decode(Immittance.self, forKey: .referenceImmittance)
        frequency = try container.decode(Double.self, forKey: .frequency)
        let angleRadians = try container.decode(Double.self, forKey: .refAngle)
        refAngle = Angle(radians:angleRadians)
        angleOrientation = try container.decode(AngleOrientation.self, forKey: .measureOrientation)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(displayMode, forKey: .displayMode)
        try container.encode(circuitMode, forKey: .circuitMode)
        try container.encode(immittance, forKey: .immittance)
        try container.encode(referenceImmittance, forKey: .referenceImmittance)
        try container.encode(frequency, forKey: .frequency)
        try container.encode(refAngle.radians, forKey: .refAngle)
        try container.encode(angleOrientation, forKey: .measureOrientation)
    }
    
    func update(from other: ViewModel) {
        self.displayMode = other.displayMode
        self.circuitMode = other.circuitMode
        self.immittance = other.immittance
        self.referenceImmittance = other.referenceImmittance
        self.frequency = other.frequency
        self.refAngle = other.refAngle
        self.angleOrientation = other.angleOrientation
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
