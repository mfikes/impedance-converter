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
    
    func testCos() {
        // Test specific angle cases
        XCTAssertEqual(cos(angle: Angle(degrees: 0)), 1)
        XCTAssertEqual(cos(angle: Angle(degrees: 90)), 0)
        XCTAssertEqual(cos(angle: Angle(degrees: 180)), -1)
        XCTAssertEqual(cos(angle: Angle(degrees: 270)), 0)
        XCTAssertEqual(cos(angle: Angle(degrees: 360)), 1)
        
        // Test negative angles
        XCTAssertEqual(cos(angle: Angle(degrees: -90)), 0)
        XCTAssertEqual(cos(angle: Angle(degrees: -180)), -1)
        
        // Test angles > 360 and < -360
        XCTAssertEqual(cos(angle: Angle(degrees: 450)), 0)
        XCTAssertEqual(cos(angle: Angle(degrees: -450)), 0)
        
        // Test arbitrary angle
        XCTAssertEqual(cos(angle: Angle(degrees: 45)), sqrt(2)/2, accuracy: 0.0001)
    }
    
    func testSin() {
        // Test specific angle cases
        XCTAssertEqual(sin(angle: Angle(degrees: 0)), 0)
        XCTAssertEqual(sin(angle: Angle(degrees: 90)), 1)
        XCTAssertEqual(sin(angle: Angle(degrees: 180)), 0)
        XCTAssertEqual(sin(angle: Angle(degrees: 270)), -1)
        XCTAssertEqual(sin(angle: Angle(degrees: 360)), 0)
        
        // Test negative angles
        XCTAssertEqual(sin(angle: Angle(degrees: -90)), -1)
        XCTAssertEqual(sin(angle: Angle(degrees: -180)), 0)
        
        // Test angles > 360 and < -360
        XCTAssertEqual(sin(angle: Angle(degrees: 450)), 1)
        XCTAssertEqual(sin(angle: Angle(degrees: -450)), -1)
        
        // Test arbitrary angle
        XCTAssertEqual(sin(angle: Angle(degrees: 45)), sqrt(2)/2, accuracy: 0.0001)
    }
}
