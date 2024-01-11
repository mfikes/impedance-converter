import Foundation
import SwiftUI
import Numerics

// MARK: - Math Functions

// Imitates IEEE remainder
func symmetricRemainder(dividend: Double, divisor: Double) -> Double {
    if dividend.isNaN || divisor.isNaN || divisor.isZero || dividend.isInfinite {
        return Double.nan
    } else if dividend.isFinite && divisor.isInfinite {
        return dividend
    }

    let r = dividend.truncatingRemainder(dividingBy: divisor)
    let altR = r - (abs(divisor) * (dividend < 0 ? -1 : 1))
    let result = abs(r) > abs(altR) ? altR : r

    return result == 0 ? 0 * dividend : result
}

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

extension Complex where RealType: FloatingPoint {
    var canonicalizedReal: RealType {
        return isFinite ? real : RealType.infinity
    }

    var canonicalizedImaginary: RealType {
        return isFinite ? imaginary : RealType.nan
    }
}
