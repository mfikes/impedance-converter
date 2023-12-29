import Foundation

enum DisplayMode {
    case impedance, admittance, reflectionCoefficient
}

enum CircuitMode {
    case series, parallel
}

class ViewModel: ObservableObject {
    
    @Published var impedance: Complex = Complex(real: 50, imaginary: 0) {
        didSet {
            if impedance.real < 0 {
                impedance = Complex(real: 0, imaginary: impedance.imaginary)
            }
            if (impedance.real.isNaN) {
                impedance = Complex(real: 0, imaginary: impedance.imaginary)
            }
            if (impedance.imaginary.isNaN) {
                impedance = Complex(real: impedance.real, imaginary: 0)
            }
        }
    }

    @Published var referenceImpedance: Complex = Complex(real: 50, imaginary: 0) {
        didSet {
            if referenceImpedance.real <= 0 {
                referenceImpedance = Complex(real: 0.001, imaginary: impedance.imaginary)
            }
        }
    }
    
    @Published var complexDisplayMode: DisplayMode = .impedance {
        didSet {
            if complexDisplayMode != .reflectionCoefficient {
                smithChartDisplayMode = complexDisplayMode
            }
        }
    }
    
    @Published var smithChartDisplayMode: DisplayMode = .impedance
    
    @Published var frequency: Double = 100000 {
        didSet {
            if frequency <= 0 {
                frequency = 0.001
            }
        }
    }
    
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
