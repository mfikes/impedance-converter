import Foundation
import SwiftUI

// MARK: - Math Functions

func cos(angle: Angle) -> Double {
    let normalizedAngle = angle.degrees.truncatingRemainder(dividingBy: 360)
    
    switch abs(normalizedAngle) {
    case 90, 270:
        return 0
    case 180:
        return -1
    case 0, 360:
        return 1
    default:
        return Darwin.cos(angle.radians)
    }
}

func sin(angle: Angle) -> Double {
    let normalizedAngle = angle.degrees.truncatingRemainder(dividingBy: 360)
    
    switch normalizedAngle {
    case -270, 90:
        return 1
    case 270, -90:
        return -1
    case 0, 180, -180, 360:
        return 0
    default:
        return Darwin.sin(angle.radians)
    }
}

// MARK: - Complex Number Implementation

struct Complex: Codable, Equatable {
    let real: Double
    let imaginary: Double
    
    static func == (lhs: Complex, rhs: Complex) -> Bool {
        return lhs.real == rhs.real && lhs.imaginary == rhs.imaginary
    }
    
    static var zero: Complex {
        return Complex(real: 0, imaginary: 0)
    }
    
    static var one: Complex {
        return Complex(real: 1, imaginary: 0)
    }
    
    var magnitude: Double {
        if (real.isInfinite || imaginary.isInfinite) {
            return Double.infinity
        } else {
            return sqrt(real * real + imaginary * imaginary)
        }
    }
    
    var angle: Angle {
        if (magnitude == 0) {
            return Angle.init(radians: Double.nan)
        } else if (imaginary == 0) {
            return Angle.init(degrees: real < 0 ? 180 : 0)
        } else {
            return Angle.init(radians: atan2(imaginary, real))
        }
    }
    
    static func fromPolar(magnitude: Double, angle: Angle) -> Complex {
        if (angle.radians.isNaN) {
            return Complex(real: magnitude, imaginary: 0)
        } else {
            return Complex(real: magnitude * cos(angle: angle), imaginary: magnitude * sin(angle: angle))
        }
    }
    
    static prefix func - (value: Complex) -> Complex {
            return Complex(real: -value.real, imaginary: -value.imaginary)
        }
    
    var reciprocal: Complex {
        return Complex.one / self
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
        if (right.magnitude.isInfinite && !left.magnitude.isInfinite) {
            return zero
        } else {
            let denominator = right.real * right.real + right.imaginary * right.imaginary
            if (denominator == 0) {
                return Complex(real: left.real / denominator,
                               imaginary: Double.nan)
            } else {
                return Complex(real: (left.real * right.real + left.imaginary * right.imaginary) / denominator,
                               imaginary: (left.imaginary * right.real - left.real * right.imaginary) / denominator)
            }
        }
    }
}
