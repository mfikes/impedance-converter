import Foundation

enum DisplayMode {
    case impedance, admittance, reflectionCoefficient
}

enum CircuitMode {
    case series, parallel
}

enum ActiveRepresentation {
    case impedance, admittance
}

class ViewModel: ObservableObject {
        
    @Published var frequency: Double = 100000 {
        didSet {
            if frequency <= 0 {
                frequency = 0.001
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
            rep = ensureNoNaN(value: newValue)
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
            rep = ensureNoNaN(value: newValue)
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
            switch activeRep {
            case .impedance:
                resistance =  newValue * abs(reactance)
            case .admittance:
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
            switch (activeRep) {
            case .impedance:
                return (impedance - referenceImpedance) / (impedance + referenceImpedance)
            case .admittance:
                return (referenceAdmittance - admittance) / (referenceAdmittance + admittance)
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
    
    @Published var complexDisplayMode: DisplayMode = .impedance {
        didSet {
            if complexDisplayMode != .reflectionCoefficient {
                displayMode = complexDisplayMode
            }
        }
    }
    
    @Published var circuitMode: CircuitMode = .series
    
    @Published var displayMode: DisplayMode = .impedance
}
