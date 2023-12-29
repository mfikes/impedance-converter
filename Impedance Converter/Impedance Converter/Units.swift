import Foundation

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
