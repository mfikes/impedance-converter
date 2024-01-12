import XCTest
import Foundation
import SwiftUI
import Numerics
@testable import Impedance_Converter

final class MathTests: XCTestCase {
    
    func testSymmetricRemainder() {
        // Regular cases
        XCTAssertEqual(symmetricRemainder(dividend: 10, divisor: 3), 1)
        XCTAssertEqual(symmetricRemainder(dividend: -10, divisor: 3), -1)
        XCTAssertEqual(symmetricRemainder(dividend: 10, divisor: -3), 1)
        XCTAssertEqual(symmetricRemainder(dividend: -10, divisor: -3), -1)
        
        // Dividend is zero
        XCTAssertEqual(symmetricRemainder(dividend: 0, divisor: 3), 0)
        
        // Divisor is zero
        XCTAssertTrue(symmetricRemainder(dividend: 10, divisor: 0).isNaN)
        
        // Dividend or divisor is NaN
        XCTAssertTrue(symmetricRemainder(dividend: Double.nan, divisor: 3).isNaN)
        XCTAssertTrue(symmetricRemainder(dividend: 10, divisor: Double.nan).isNaN)
        
        // Dividend is infinite
        XCTAssertTrue(symmetricRemainder(dividend: Double.infinity, divisor: 3).isNaN)
        XCTAssertTrue(symmetricRemainder(dividend: -Double.infinity, divisor: 3).isNaN)
        
        // Divisor is infinite
        XCTAssertEqual(symmetricRemainder(dividend: 10, divisor: Double.infinity), 10)
        XCTAssertEqual(symmetricRemainder(dividend: -10, divisor: Double.infinity), -10)
        
        // Both dividend and divisor are infinite
        XCTAssertTrue(symmetricRemainder(dividend: Double.infinity, divisor: Double.infinity).isNaN)
    }
}
