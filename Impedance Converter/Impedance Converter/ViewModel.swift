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

enum ActiveRepresentation: Codable {
    case impedance, admittance
}

class ViewModel: ObservableObject, Codable {
        
    @Published var frequency: Double = 100000 {
        didSet {
            if frequency <= 0 {
                frequency = oldValue
            }
        }
    }
    
    var omega: Double {
        get {
            return 2 * Double.pi * frequency
        }
    }
    
    @Published var activeRefRep: ActiveRepresentation = .impedance
    
    @Published var refRep: Complex = Complex(real: 50, imaginary: 0)
    
    @Published var rep: Complex = Complex(real: 50, imaginary: 0)
    
    @Published var activeRep: ActiveRepresentation = .impedance
    
    @Published var refAngle: Angle = Angle(radians: 0)
    
    @Published var angleOrientation: AngleOrientation = .counterclockwise
        
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
            switch (activeRefRep) {
            case .impedance:
                return refRep
            case .admittance:
                return refRep.reciprocal;
            }
        }
        set {
            refRep = newValue
            activeRefRep = .impedance
        }
    }
    
    var referenceAdmittance: Complex {
        get {
            switch (activeRefRep) {
            case .impedance:
                return refRep.reciprocal
            case .admittance:
                return refRep;
            }
        }
        set {
            refRep = newValue
            activeRefRep = .admittance
        }
    }
    
    var impedance: Complex {
        get {
            switch (activeRep) {
            case .impedance:
                return rep
            case .admittance:
                return rep.reciprocal;
            }
        }
        set {
            rep = ensurePositiveReal(value: ensureNoNaN(value: newValue))
            activeRep = .impedance
        }
    }
    
    var admittance: Complex {
        get {
            switch (activeRep) {
            case .impedance:
                return rep.reciprocal
            case .admittance:
                return rep;
            }
        }
        set {
            rep = ensurePositiveReal(value: ensureNoNaN(value: newValue))
            activeRep = .admittance
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
            switch activeRep {
            case .impedance:
                return resistance / abs(reactance)
            case .admittance:
                return conductance / abs(susceptance)
            }
        }
        set {
            if displayMode == .impedance {
                if reactance == 0 || abs(reactance).isInfinite {
                    if resistance != 0 {
                        reactance = resistance / newValue
                    }
                } else {
                    resistance =  abs(reactance) * newValue
                }
            } else {
                if susceptance == 0 || abs(susceptance).isInfinite {
                    if conductance != 0 {
                        susceptance = conductance / newValue
                    }
                } else {
                    conductance = abs(susceptance) * newValue
                }
            }
        }
    }
    
    var qualityFactor: Double {
        get {
            switch activeRep {
            case .impedance:
                return abs(reactance) / resistance
            case .admittance:
                return abs(susceptance) / conductance
            }
        }
        set {
            if displayMode == .impedance {
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
            } else {
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
        }
    }
    
    var reflectionCoefficient: Complex {
        get {
            switch (activeRep) {
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
            switch (activeRep) {
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
            return angleSign * (reflectionCoefficient.angle.radians - refAngle.radians) / (2 * Double.pi)
        }
        set {
            reflectionCoefficient = Complex.fromPolar(magnitude: reflectionCoefficient.magnitude, angle: Angle(radians:angleSign * (2 * Double.pi) * newValue + refAngle.radians))
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
        refAngle = reflectionCoefficient.angle
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
             representation, representationMode,
             refRepresentation, refRepresentationMode,
             frequency,
             refAngle, measureOrientation
    }
    
    init() {
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        displayMode = try container.decode(DisplayMode.self, forKey: .displayMode)
        circuitMode = try container.decode(CircuitMode.self, forKey: .circuitMode)
        rep = try container.decode(Complex.self, forKey: .representation)
        activeRep = try container.decode(ActiveRepresentation.self, forKey: .representationMode)
        refRep = try container.decode(Complex.self, forKey: .refRepresentation)
        activeRefRep = try container.decode(ActiveRepresentation.self, forKey: .refRepresentationMode)
        frequency = try container.decode(Double.self, forKey: .frequency)
        let angleRadians = try container.decode(Double.self, forKey: .refAngle)
        refAngle = Angle(radians:angleRadians)
        angleOrientation = try container.decode(AngleOrientation.self, forKey: .measureOrientation)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(displayMode, forKey: .displayMode)
        try container.encode(circuitMode, forKey: .circuitMode)
        try container.encode(rep, forKey: .representation)
        try container.encode(activeRep, forKey: .representationMode)
        try container.encode(refRep, forKey: .refRepresentation)
        try container.encode(activeRefRep, forKey: .refRepresentationMode)
        try container.encode(frequency, forKey: .frequency)
        try container.encode(refAngle.radians, forKey: .refAngle)
        try container.encode(angleOrientation, forKey: .measureOrientation)
    }
    
    func update(from other: ViewModel) {
        self.displayMode = other.displayMode
        self.circuitMode = other.circuitMode
        self.rep = other.rep
        self.activeRep = other.activeRep
        self.refRep = other.refRep
        self.activeRefRep = other.activeRefRep
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
}
