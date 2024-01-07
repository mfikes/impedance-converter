import XCTest
import Foundation
import SwiftUI
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

final class ComplexTests: XCTestCase {

    func testInitializationAndEquality() {
        // Test initialization
        let complex = Complex(real: 3, imaginary: 4)
        XCTAssertEqual(complex.real, 3)
        XCTAssertEqual(complex.imaginary, 4)

        // Test static properties
        XCTAssertEqual(Complex.zero.real, 0)
        XCTAssertEqual(Complex.zero.imaginary, 0)
        XCTAssertEqual(Complex.one.real, 1)
        XCTAssertEqual(Complex.one.imaginary, 0)
    }

    func testMagnitude() {
        // Regular cases
        XCTAssertEqual(Complex(real: 3, imaginary: 4).magnitude, 5)

        // Infinite cases
        XCTAssertEqual(Complex(real: Double.infinity, imaginary: 0).magnitude, Double.infinity)
    }

    func testAngle() {
        // Regular cases
        XCTAssertEqual(Complex(real: 1, imaginary: 1).angle.radians, .pi / 4, accuracy: 0.0001)

        // Zero magnitude
        XCTAssertTrue(Complex.zero.angle.radians.isNaN)

        // Infinite cases
        XCTAssertEqual(Complex(real: -1, imaginary: 0).angle.degrees, 180)
    }

    func testFromPolar() {
        // Regular case
        let result = Complex.fromPolar(magnitude: 5, angle: Angle(degrees: 53.13))
        XCTAssertEqual(result.real, 3, accuracy: 0.01)
        XCTAssertEqual(result.imaginary, 4, accuracy: 0.01)

        // NaN angle
        let nanResult = Complex.fromPolar(magnitude: 5, angle: Angle(radians: Double.nan))
        XCTAssertEqual(nanResult.real, 5)
        XCTAssertEqual(nanResult.imaginary, 0)
    }

    func testUnaryMinus() {
        let result = -Complex(real: 3, imaginary: -4)
        XCTAssertEqual(result.real, -3)
        XCTAssertEqual(result.imaginary, 4)
    }

    func testAddition() {
        let result = Complex(real: 1, imaginary: 2) + Complex(real: 3, imaginary: 4)
        XCTAssertEqual(result.real, 4)
        XCTAssertEqual(result.imaginary, 6)
    }

    func testSubtraction() {
        let result = Complex(real: 3, imaginary: 4) - Complex(real: 1, imaginary: 2)
        XCTAssertEqual(result.real, 2)
        XCTAssertEqual(result.imaginary, 2)
    }

    func testMultiplication() {
        let result = Complex(real: 1, imaginary: 2) * Complex(real: 3, imaginary: 4)
        XCTAssertEqual(result.real, -5)
        XCTAssertEqual(result.imaginary, 10)
    }

    func testDivision() {
        // Regular case
        let result = Complex(real: 3, imaginary: 4) / Complex(real: 1, imaginary: 2)
        XCTAssertEqual(result.real, 2.2, accuracy: 0.1)
        XCTAssertEqual(result.imaginary, -0.4, accuracy: 0.1)

        // Division by zero
        let zeroResult = Complex(real: 1, imaginary: 2) / Complex.zero
        XCTAssertTrue(zeroResult.real.isNaN || zeroResult.imaginary.isNaN)

        // Division by infinity
        let infResult = Complex(real: 1, imaginary: 2) / Complex(real: Double.infinity, imaginary: 0)
        XCTAssertEqual(infResult.real, 0)
        XCTAssertEqual(infResult.imaginary, 0)
        
        // Division of infinity by infinity
        let infComplex = Complex(real: Double.infinity, imaginary: Double.infinity)
        let undefined = infComplex / infComplex
        
        XCTAssertTrue(undefined.real.isNaN)
        XCTAssertTrue(undefined.imaginary.isNaN)
    }

    func testReciprocal() {
        let result = Complex(real: 1, imaginary: 2).reciprocal
        XCTAssertEqual(result.real, 0.2, accuracy: 0.1)
        XCTAssertEqual(result.imaginary, -0.4, accuracy: 0.1)
    }
}

