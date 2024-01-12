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

extension Complex where RealType: FloatingPoint {
    var canonicalizedReal: RealType {
        return isFinite ? real : RealType.infinity
    }

    var canonicalizedImaginary: RealType {
        return isFinite ? imaginary : RealType.nan
    }
}
