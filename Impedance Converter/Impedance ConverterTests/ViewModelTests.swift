import XCTest
import SwiftCheck
import SwiftUI
import Numerics
@testable import Impedance_Converter

class ViewModelTestBase: XCTestCase {
    var viewModel: ViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = ViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
}

class FrequencyTests: ViewModelTestBase {
    
    func testFrequencySettingAndGeting() {
        // Test setting and getting a valid frequency
        viewModel.frequency = 200000 // 200 kHz
        XCTAssertEqual(viewModel.frequency, 200000)
        
        // Test that frequency cannot be set to a non-positive value
        viewModel.frequency = -1
        XCTAssertNotEqual(viewModel.frequency, -1)
        XCTAssertTrue(viewModel.frequency > 0)
        
        // Test setting frequency to zero
        let previousFrequency = viewModel.frequency
        viewModel.frequency = 0
        XCTAssertEqual(viewModel.frequency, previousFrequency) // Should remain unchanged
    }
    
    func testOmegaCalculation() {
        // Set frequency and test omega
        viewModel.frequency = 200000 // 200 kHz
        let expectedOmega = 2 * Double.pi * 200000
        XCTAssertEqual(viewModel.omega, expectedOmega)
        
        // Test with another frequency
        viewModel.frequency = 300000 // 300 kHz
        let newExpectedOmega = 2 * Double.pi * 300000
        XCTAssertEqual(viewModel.omega, newExpectedOmega)
    }
}

class ReferenceImmittanceTests: ViewModelTestBase {
    
    func testReferenceImmittancePropertyForImpedance() {
        // Setting reference impedance and getting it back
        let referenceImpedance = Complex(75, 00)
        viewModel.referenceImpedance = referenceImpedance
        XCTAssertEqual(viewModel.referenceImpedance, referenceImpedance)
        
        // Checking the reciprocal reference admittance
        let expectedReferenceAdmittance = referenceImpedance.reciprocal
        XCTAssertEqual(viewModel.referenceAdmittance, expectedReferenceAdmittance)
    }
    
    func testReferenceImmittancePropertyForAdmittance() {
        // Setting reference admittance and getting it back
        let referenceAdmittance = Complex(0.005, 0.0)
        viewModel.referenceAdmittance = referenceAdmittance
        XCTAssertEqual(viewModel.referenceAdmittance, referenceAdmittance)
        
        // Checking the reciprocal reference impedance
        let expectedReferenceImpedance = referenceAdmittance.reciprocal
        XCTAssertEqual(viewModel.referenceImpedance, expectedReferenceImpedance)
    }
    
    func testDefaultReferenceImpedance() {
        // Default reference impedance should be 50 ohms (50 + 0j)
        let expectedReferenceImpedance = Complex(50, 0)
        XCTAssertEqual(viewModel.referenceImpedance, expectedReferenceImpedance)
    }
    
    func testDefaultReferenceAdmittance() {
        // Default reference admittance should be 20 millisiemens (0.020 + 0j)
        let expectedReferenceAdmittance = Complex(0.020, 0)
        XCTAssertEqual(viewModel.referenceAdmittance, expectedReferenceAdmittance)
    }
        
    func testReferenceImpedanceIsPositiveReal() {
        // Initial set with a valid positive real impedance
        let initialImpedance = Complex(100, 0)
        viewModel.referenceImpedance = initialImpedance

        // Attempt to set a negative real part
        let negativeRealImpedance = Complex(-50, 0)
        viewModel.referenceImpedance = negativeRealImpedance

        // Check if the impedance remains unchanged
        XCTAssertEqual(viewModel.referenceImpedance, initialImpedance)
        
        // Attempt to set an imaginary part
        let complexImpedance = Complex(50, 1)
        viewModel.referenceImpedance = complexImpedance

        // Check if the impedance remains unchanged
        XCTAssertEqual(viewModel.referenceImpedance, initialImpedance)
    }
    
    func testReferenceAdmittanceIsPositiveReal() {
        // Initial set with a valid positive real impedance
        let initialAdmittance = Complex(100, 0)
        viewModel.referenceAdmittance = initialAdmittance

        // Attempt to set a negative real part
        let negativeRealAdmittance = Complex(-50, 0)
        viewModel.referenceAdmittance = negativeRealAdmittance

        // Check if the admittance remains unchanged
        XCTAssertEqual(viewModel.referenceAdmittance, initialAdmittance)
        
        // Attempt to set an imaginary part
        let complexAdmittance = Complex(50, 1)
        viewModel.referenceAdmittance = complexAdmittance

        // Check if the admittance remains unchanged
        XCTAssertEqual(viewModel.referenceAdmittance, initialAdmittance)
    }
}

class ImmittanceTests: ViewModelTestBase {
    
    func testImmittanceWithZeroValues() {
        // Setting zero impedance
        viewModel.impedance = Complex.zero
        XCTAssertEqual(viewModel.impedance, Complex.zero)
        XCTAssertEqual(viewModel.admittance, Complex.infinity)

        // Setting zero admittance
        viewModel.admittance = Complex.zero
        XCTAssertEqual(viewModel.admittance, Complex.zero)
        XCTAssertEqual(viewModel.impedance, Complex.infinity)
    }
    
    func testImmittanceWithNegativeValues() {
        // Negative real part in impedance
        viewModel.impedance = Complex(-50, 10)
        XCTAssertEqual(viewModel.impedance, Complex(0, 10))

        // Negative imaginary part in admittance
        viewModel.admittance = Complex(0.02, -0.005)
        XCTAssertEqual(viewModel.admittance, Complex(0.02, -0.005))
    }

    func testImmittanceWithComplexValues() {
        // Complex impedance
        viewModel.impedance = Complex(30, 40)
        XCTAssertEqual(viewModel.impedance, Complex(30, 40))

        // Complex admittance
        viewModel.admittance = Complex(0.03, 0.04)
        XCTAssertEqual(viewModel.admittance, Complex(0.03, 0.04))
    }
    
    func testImpedanceGreaterThanPos90() {
        viewModel.impedance = Complex.init(length: 50, phase: Angle(degrees: 95).radians)
        XCTAssertEqual(Angle(radians: viewModel.impedance.phase).degrees, 90)
    }
    
    func testImpedanceLessThanNeg90() {
        viewModel.impedance = Complex.init(length: 50, phase: Angle(degrees: -95).radians)
        XCTAssertEqual(Angle(radians: viewModel.impedance.phase).degrees, -90)
    }
    
    func testAdmittanceGreaterThanPos90() {
        viewModel.admittance = Complex.init(length: 50, phase: Angle(degrees: 95).radians)
        XCTAssertEqual(Angle(radians: viewModel.admittance.phase).degrees, 90)
    }
    
    func testAdmittanceLessThanNeg90() {
        viewModel.admittance = Complex.init(length: 50, phase: Angle(degrees: -95).radians)
        XCTAssertEqual(Angle(radians: viewModel.admittance.phase).degrees, -90)
    }
    
    func testImpedanceAngleProperty() {
        property("Impedance real or imaginary part should be zero at multiples of 90 degrees") <- forAll { (length: Double) in
            let positiveLength = abs(length)
            return [0, 90, 180, 270].allSatisfy { angle in
                self.viewModel.impedance = Complex(length: positiveLength, phase: Angle(degrees: Double(angle)).radians)
                if angle == 0 || angle == 180 {
                    return self.viewModel.impedance.imaginary.isZero
                } else {
                    return self.viewModel.impedance.real.isZero
                }
            }
        }
    }
    
    func testAdmittanceAngleProperty() {
        property("Admittance real or imaginary part should be zero at multiples of 90 degrees") <- forAll { (length: Double) in
            let positiveLength = abs(length)
            return [0, 90, 180, 270].allSatisfy { angle in
                self.viewModel.admittance = Complex(length: positiveLength, phase: Angle(degrees: Double(angle)).radians)
                if angle == 0 || angle == 180 {
                    return self.viewModel.admittance.imaginary.isZero
                } else {
                    return self.viewModel.admittance.real.isZero
                }
            }
        }
    }
    
    func testReciprocalRelationships() {
        // Impedance and its reciprocal admittance
        let impedance = Complex(100, -50)
        viewModel.impedance = impedance
        XCTAssertEqual(viewModel.impedance, impedance)
        XCTAssertEqual(viewModel.admittance, impedance.reciprocal)

        // Admittance and its reciprocal impedance
        let admittance = Complex(0.01, 0.02)
        viewModel.admittance = admittance
        XCTAssertEqual(viewModel.admittance, admittance)
        XCTAssertEqual(viewModel.impedance, admittance.reciprocal)
    }

}

class ElectricalParametersTests: ViewModelTestBase {
    
    // Testing Resistance
    func testResistance() {
        viewModel.impedance = Complex(50, 30)
        XCTAssertEqual(viewModel.resistance, 50)
        
        viewModel.resistance = 75
        XCTAssertEqual(viewModel.impedance, Complex(75, 30))
    }
    
    // Testing Reactance
    func testReactance() {
        viewModel.impedance = Complex(50, 30)
        XCTAssertEqual(viewModel.reactance, 30)
        
        viewModel.reactance = 40
        XCTAssertEqual(viewModel.impedance, Complex(50, 40))
    }
    
    // Testing Conductance
    func testConductance() {
        viewModel.admittance = Complex(0.02, 0.01)
        XCTAssertEqual(viewModel.conductance, 0.02)
        
        viewModel.conductance = 0.03
        XCTAssertEqual(viewModel.admittance, Complex(0.03, 0.01))
    }
    
    // Testing Susceptance
    func testSusceptance() {
        viewModel.admittance = Complex(0.02, 0.01)
        XCTAssertEqual(viewModel.susceptance, 0.01)
        
        viewModel.susceptance = 0.015
        XCTAssertEqual(viewModel.admittance, Complex(0.02, 0.015))
    }
    
    // Testing Interconnected Behavior
    func testInterconnectedBehavior() {
        // Set resistance and reactance and verify conductance and susceptance
        viewModel.resistance = 100
        viewModel.reactance = 50
        // Add asserts to check corresponding conductance and susceptance values
        
        // Set conductance and susceptance and verify resistance and reactance
        viewModel.conductance = 0.01
        viewModel.susceptance = 0.005
        // Add asserts to check corresponding resistance and reactance values
    }
    
    func testResistanceAndReactanceEdgeCases() {
        // Resistance = 0, Reactance = 0
        viewModel.resistance = 0
        viewModel.reactance = 0
        XCTAssertEqual(viewModel.conductance, Double.infinity)
        XCTAssertTrue(viewModel.susceptance.isNaN)
        
        // Resistance = ∞, Reactance = 0
        viewModel.resistance = Double.infinity
        viewModel.reactance = 0
        XCTAssertEqual(viewModel.conductance, 0)
        XCTAssertEqual(viewModel.susceptance, 0)
        
        // Resistance = 0, Reactance = ∞
        viewModel.resistance = 0
        viewModel.reactance = Double.infinity
        XCTAssertEqual(viewModel.conductance, 0)
        XCTAssertEqual(viewModel.susceptance, 0)
        
        // Resistance = ∞, Reactance = ∞
        viewModel.resistance = Double.infinity
        viewModel.reactance = Double.infinity
        XCTAssertEqual(viewModel.conductance, 0)
        XCTAssertEqual(viewModel.susceptance, 0)
    }
    
    func testConductanceAndSusceptanceEdgeCases() {
        // Conductance = 0, Susceptance = 0
        viewModel.conductance = 0
        viewModel.susceptance = 0
        XCTAssertEqual(viewModel.resistance, Double.infinity)
        XCTAssertTrue(viewModel.reactance.isNaN)
        
        // Conductance = ∞, Susceptance = 0
        viewModel.conductance = Double.infinity
        viewModel.susceptance = 0
        XCTAssertEqual(viewModel.resistance, 0)
        XCTAssertEqual(viewModel.reactance, 0)
        
        // Conductance = 0, Susceptance = ∞
        viewModel.conductance = 0
        viewModel.susceptance = Double.infinity
        XCTAssertEqual(viewModel.resistance, 0)
        XCTAssertEqual(viewModel.reactance, 0)
        
        // Conductance = ∞, Susceptance = ∞
        viewModel.conductance = Double.infinity
        viewModel.susceptance = Double.infinity
        XCTAssertEqual(viewModel.resistance, 0)
        XCTAssertEqual(viewModel.reactance, 0)
    }
    
}

class ReactiveParametersTests: ViewModelTestBase {

    // Testing Inductance
    func testInductance() {
        // Example: Series mode, positive reactance
        viewModel.circuitMode = .series
        viewModel.reactance = 50
        viewModel.frequency = 100000 // 100 kHz
        XCTAssertEqual(viewModel.inductance, viewModel.reactance / viewModel.omega)

        // Set inductance and verify reactance
        let newInductance = 1e-6 // 1 µH
        viewModel.inductance = newInductance
        XCTAssertEqual(viewModel.reactance, newInductance * viewModel.omega)
    }
    
    func testInductanceWithZeroSusceptance() {
        viewModel.susceptance = 0
        viewModel.circuitMode = .parallel
        XCTAssertEqual(viewModel.inductance, Double.infinity)
    }

    // Testing Capacitance
    func testCapacitance() {
        // Example: Parallel mode, positive susceptance
        viewModel.circuitMode = .parallel
        viewModel.susceptance = 0.01 // S
        viewModel.frequency = 100000 // 100 kHz
        XCTAssertEqual(viewModel.capacitance, viewModel.susceptance / viewModel.omega)

        // Set capacitance and verify susceptance
        let newCapacitance = 1e-6 // 1 µF
        viewModel.capacitance = newCapacitance
        XCTAssertEqual(viewModel.susceptance, newCapacitance * viewModel.omega)
    }
    
    func testCapacitanceWithZeroReactance() {
        viewModel.reactance = 0
        viewModel.circuitMode = .series
        XCTAssertEqual(viewModel.capacitance, Double.infinity)
    }

    // Testing Dissipation Factor (D)
    func testDissipationFactor() {
        viewModel.resistance = 100 // Ohms
        viewModel.reactance = 50 // Ohms

        // Normal case
        let expectedD = viewModel.resistance / abs(viewModel.reactance)
        XCTAssertEqual(viewModel.dissipationFactor, expectedD)

        // Edge cases
        viewModel.reactance = 0
        XCTAssertEqual(viewModel.dissipationFactor, Double.infinity)
    }

    // Testing Quality Factor (Q)
    func testQualityFactor() {
        viewModel.resistance = 100 // Ohms
        viewModel.reactance = 50 // Ohms
        
        // Normal case
        let expectedQ = abs(viewModel.reactance) / viewModel.resistance
        XCTAssertEqual(viewModel.qualityFactor, expectedQ)
        
        // Edge cases
        viewModel.reactance = 0
        XCTAssertEqual(viewModel.qualityFactor, 0)
        
        viewModel.resistance = 0
        XCTAssertTrue(viewModel.qualityFactor.isNaN)
    }
    
    func testDissipationAndQualityFactorReciprocalAndExtremes() {
        // Set initial values for resistance and reactance
        viewModel.resistance = 100 // Ohms
        viewModel.reactance = 50 // Ohms
        
        // Calculate expected D and Q
        let expectedD = viewModel.resistance / abs(viewModel.reactance)
        let expectedQ = abs(viewModel.reactance) / viewModel.resistance
        
        // Check if D and Q are reciprocals of each other
        XCTAssertEqual(viewModel.dissipationFactor, expectedD)
        XCTAssertEqual(viewModel.qualityFactor, expectedQ)
        XCTAssertEqual(viewModel.dissipationFactor * viewModel.qualityFactor, 1, accuracy: 1e-6)
    }
    
    func testDissipationAndQualityFactorReciprocalAndExtremes2() {
        // Set D to zero and check if Q is infinity
        viewModel.reactance = 50
        viewModel.dissipationFactor = 0
        XCTAssertEqual(viewModel.qualityFactor, Double.infinity)
    }
    
    func testDissipationAndQualityFactorReciprocalAndExtremes3() {
        // Set Q to zero and check if D is infinity
        viewModel.reactance = 50
        viewModel.qualityFactor = 0
        XCTAssertEqual(viewModel.dissipationFactor, Double.infinity)
    }
}

class ReactiveParametersModeSwitchTests: ViewModelTestBase {

    func testInductanceWithModeSwitch() {
        // Set base values
        viewModel.frequency = 100000 // 100 kHz
        let baseReactance = 50.0 // Ohms

        // Set D near unity in series mode
        viewModel.circuitMode = .series
        viewModel.resistance = baseReactance // D = 1 when resistance = reactance
        viewModel.reactance = baseReactance
        let seriesInductance = viewModel.inductance

        // Switch to parallel mode
        viewModel.circuitMode = .parallel
        let parallelInductance = viewModel.inductance

        // Assert inductances are different
        XCTAssertNotEqual(seriesInductance, parallelInductance)

        // Set D very small (Q very large) in series mode
        viewModel.circuitMode = .series
        viewModel.resistance = 0.001 // Very small resistance
        let smallD_SeriesInductance = viewModel.inductance

        // Switch to parallel mode
        viewModel.circuitMode = .parallel
        let smallD_ParallelInductance = viewModel.inductance

        // Assert inductances are approximately equal
        XCTAssertEqual(smallD_SeriesInductance, smallD_ParallelInductance, accuracy: 1e-8)
    }

    func testCapacitanceWithModeSwitch() {
        // Set base values
        viewModel.frequency = 100000 // 100 kHz
        let baseSusceptance = 0.0002 // Siemens

        // Set D near unity in parallel mode
        viewModel.circuitMode = .parallel
        viewModel.conductance = baseSusceptance // D = 1 when conductance = susceptance
        viewModel.susceptance = baseSusceptance
        let parallelCapacitance = viewModel.capacitance

        // Switch to series mode
        viewModel.circuitMode = .series
        let seriesCapacitance = viewModel.capacitance

        // Assert capacitances are different
        XCTAssertNotEqual(seriesCapacitance, parallelCapacitance)

        // Set D very small (Q very large) in parallel mode
        viewModel.circuitMode = .parallel
        viewModel.conductance = 0.001 // Very small conductance
        let smallD_ParallelCapacitance = viewModel.capacitance

        // Switch to series mode
        viewModel.circuitMode = .series
        let smallD_SeriesCapacitance = viewModel.capacitance

        // Assert capacitances are approximately equal
        XCTAssertEqual(smallD_ParallelCapacitance, smallD_SeriesCapacitance, accuracy: 1e-8)
    }
}

class TransmissionParametersTests: ViewModelTestBase {

    // Testing Reflection Coefficient
    func testReflectionCoefficient() {
        viewModel.impedance = Complex(100, 50)
        viewModel.referenceImpedance = Complex(50, 0)

        // Check reflection coefficient calculation for impedance
        let expectedReflectionCoefficientForImpedance = (viewModel.impedance - viewModel.referenceImpedance) / (viewModel.impedance + viewModel.referenceImpedance)
        XCTAssertEqual(viewModel.reflectionCoefficient, expectedReflectionCoefficientForImpedance)

        // Set reflection coefficient and verify impedance changes
        let newReflectionCoefficient = Complex(0.3, 0.4)
        viewModel.reflectionCoefficient = newReflectionCoefficient
        let expectedImpedance = viewModel.referenceImpedance * (Complex.one + newReflectionCoefficient) / (Complex.one - newReflectionCoefficient)
        XCTAssertEqual(viewModel.impedance, expectedImpedance)
    }
    
    func testReflectionCoefficientAngleProperty() {
        property("Reflection coefficient real or imaginary part should be zero at multiples of 90 degrees") <- forAll( Gen<Double>.choose((0, 1)) ) { length in
            return [0, 90, 180, 270].allSatisfy { angle in
                self.viewModel.reflectionCoefficient = Complex(length: length, phase: Angle(degrees: Double(angle)).radians)
                if angle == 0 || angle == 180 {
                    return self.viewModel.reflectionCoefficient.imaginary.isZero
                } else {
                    return self.viewModel.reflectionCoefficient.real.isZero
                }
            }
        }
    }


    // Testing Standing Wave Ratio (SWR)
    func testSWR() {
        let reflectionCoefficient = Complex(0.5, 0)
        viewModel.reflectionCoefficient = reflectionCoefficient

        // Check SWR calculation
        let expectedSWR = (1 + reflectionCoefficient.magnitude) / (1 - reflectionCoefficient.magnitude)
        XCTAssertEqual(viewModel.swr, expectedSWR)

        // Set SWR and check reflection coefficient changes
        let newSWR = 2.0
        viewModel.swr = newSWR
        let expectedReflectionCoefficientMagnitude = (newSWR - 1) / (newSWR + 1)
        XCTAssertEqual(viewModel.reflectionCoefficient.magnitude, expectedReflectionCoefficientMagnitude, accuracy: 1e-6)
    }
    
    func testSWRInfinity() {
        property("SWR should be infinity for reflection coefficient length of 1 at any phase") <- forAll { (phase: Double) in
            self.viewModel.reflectionCoefficient = Complex(length: 1.0, phase: phase)
            return self.viewModel.swr.isInfinite
        }
    }
    
    func testSetSWRWhenPhaseUndefined() {
        viewModel.impedance = Complex(50, 0)
        viewModel.swr = 2
        XCTAssertEqual(viewModel.swr, 1)
    }

    // Testing Standing Wave Ratio (SWR) dB
    func testSWR_db() {
        viewModel.reactance = 40
        viewModel.swr = 10
        XCTAssertEqual(viewModel.swr_dB, 20, accuracy: 1e-6)
        
        viewModel.swr = 100
        XCTAssertEqual(viewModel.swr_dB, 40, accuracy: 1e-6)
        
        viewModel.swr_dB = 20
        XCTAssertEqual(viewModel.swr, 10, accuracy: 1e-6)
        
        viewModel.swr = 1
        XCTAssertEqual(viewModel.swr_dB, 0, accuracy: 1e-6)
        
        viewModel.reactance = 40
        viewModel.swr_dB = 0
        XCTAssertEqual(viewModel.swr, 1, accuracy: 1e-6)
    }
    
    // Testing Reflection Coefficient Power
    func testReflectionCoefficientPower() {
        let reflectionCoefficient = Complex(0.5, 0)
        viewModel.reflectionCoefficient = reflectionCoefficient

        let expectedReflectionCoefficientPower = reflectionCoefficient.lengthSquared
        XCTAssertEqual(viewModel.reflectionCoefficientPower, expectedReflectionCoefficientPower)

        let newReflectionCoefficientPower = 0.3
        viewModel.reflectionCoefficientPower = newReflectionCoefficientPower
        let expectedReflectionCoefficientMagnitude = sqrt(newReflectionCoefficientPower)
        XCTAssertEqual(viewModel.reflectionCoefficient.magnitude, expectedReflectionCoefficientMagnitude, accuracy: 1e-6)
    }
    
    // Testing Transmission Coefficient Power
    func testTransmissionCoefficientPower() {
        let reflectionCoefficient = Complex(0.5, 0)
        viewModel.reflectionCoefficient = reflectionCoefficient

        let expectedTransmisionCoefficientPower = 1 - reflectionCoefficient.lengthSquared
        XCTAssertEqual(viewModel.transmissionCoefficientPower, expectedTransmisionCoefficientPower)
    }
    
    func testReflectionCoefficientTransmissionCoefficient() {
        property("Reflection coefficient power plus transmission coefficient power must sum to 1") <- forAll( Gen<Double>.choose((0, 1)) ) { rho in
            self.viewModel.reactance = 3
            self.viewModel.reactance = 4
            self.viewModel.reflectionCoefficientPower = rho
            return abs(rho + self.viewModel.transmissionCoefficientPower - 1) < 1e-6
        }
    }
    
    func testTransmissionCoefficientReflectionCoefficient() {
        property("Reflection coefficient power plus transmission coefficient power must sum to 1") <- forAll( Gen<Double>.choose((0, 1)) ) { tau in
            self.viewModel.reactance = 3
            self.viewModel.reactance = 4
            self.viewModel.transmissionCoefficientPower = tau
            return abs(self.viewModel.reflectionCoefficientPower + tau - 1) < 1e-6
        }
    }
    
    // Testing Return Loss
    func testReturnLoss() {
        let reflectionCoefficient = Complex(0.5, 0)
        viewModel.reflectionCoefficient = reflectionCoefficient

        // Check return loss calculation
        let expectedReturnLoss = -20 * log10(reflectionCoefficient.magnitude)
        XCTAssertEqual(viewModel.returnLoss, expectedReturnLoss)

        // Set return loss and check reflection coefficient changes
        let newReturnLoss = 6.0
        viewModel.returnLoss = newReturnLoss
        let expectedReflectionCoefficientMagnitude = pow(10, -newReturnLoss / 20)
        XCTAssertEqual(viewModel.reflectionCoefficient.magnitude, expectedReflectionCoefficientMagnitude, accuracy: 1e-6)
    }
    
    func testReturnLossZero() {
        property("Return loss should be zero for reflection coefficient length of 1 at any phase") <- forAll { (phase: Double) in
            self.viewModel.reflectionCoefficient = Complex(length: 1.0, phase: phase)
            return self.viewModel.returnLoss.isZero
        }
    }
    
    // Testing Transmission Loss
    func testTransmissionLoss() {
        viewModel.reactance = 50
        viewModel.transmissionCoefficientPower = 0.75

        // Check reflection loss calculation
        let expectedReflectionLoss = -10 * log10(viewModel.transmissionCoefficientPower)
        XCTAssertEqual(viewModel.reflectionLoss, expectedReflectionLoss)

        // Set reflection loss and check transmission coefficient changes
        let newReflectionLoss = 3.0
        viewModel.reflectionLoss = newReflectionLoss
        let expectedTransmissionCoefficientPower = pow(10, -newReflectionLoss / 10)
        XCTAssertEqual(viewModel.transmissionCoefficientPower, expectedTransmissionCoefficientPower, accuracy: 1e-6)
    }
}

class ElectricalLengthTests: ViewModelTestBase {

    // Testing Wavelength
    func testWavelength() {
        // Set a frequency and verify the wavelength calculation
        viewModel.frequency = 300e6 // 300 MHz
        let expectedWavelength = 3e8 / 300e6
        XCTAssertEqual(viewModel.wavelength, expectedWavelength)
    }
    
    // Testing Wavelength with velocity factor
    func testWavelengthWithVelocityFactory() {
        // Set a frequency and verify the wavelength calculation
        viewModel.frequency = 300e6 // 300 MHz
        viewModel.velocityFactor = 0.5
        let expectedWavelength = 0.5 * 3e8 / 300e6
        XCTAssertEqual(viewModel.wavelength, expectedWavelength)
    }
    
    func testSetWavelength() {
        // Set a wavelength and verify the frequency calculation
        viewModel.wavelength = 40
        let expectedFrequency = 3e8 / 40
        XCTAssertEqual(viewModel.frequency, expectedFrequency)
    }
    
    func testSetWavelengthWithVelocityFactor() {
        // Set a wavelength and verify the frequency calculation
        viewModel.velocityFactor = 0.5
        viewModel.wavelength = 40
        let expectedFrequency = 0.5 * 3e8 / 40
        XCTAssertEqual(viewModel.frequency, expectedFrequency)
    }
    
    // Testing Wavelengths (Electrical Length in terms of Wavelength)
    func testWavelengths() {
        // Set frequency, reflection coefficient angle, and reference angle
        viewModel.frequency = 300e6 // 300 MHz
        viewModel.reflectionCoefficient = Complex.init(length: 0.7, phase: .pi / 4)
        viewModel.refAngle = Angle(radians: .pi / 6)
        viewModel.angleOrientation = .counterclockwise

        // Calculate expected wavelengths
        let originalRemainder = symmetricRemainder(dividend: viewModel.angleSign * (viewModel.reflectionCoefficient.phase - viewModel.refAngle.radians), divisor: 2 * Double.pi)
        let adjustedRemainder = (originalRemainder + 2 * Double.pi).truncatingRemainder(dividingBy: 2 * Double.pi)
        let expectedWavelengths = adjustedRemainder / (4 * Double.pi)
        XCTAssertEqual(viewModel.wavelengths, expectedWavelengths)

        // Set wavelengths and verify the change in reflection coefficient angle
        let newWavelengths = 0.3 // Example value
        viewModel.wavelengths = newWavelengths
        let expectedNewAngle = Angle(radians: viewModel.angleSign * (4 * Double.pi) * newWavelengths + viewModel.refAngle.radians - 2 * Double.pi)
        XCTAssertEqual(viewModel.reflectionCoefficient.phase, expectedNewAngle.radians, accuracy: 1e-6)
    }

    // Testing Length
    func testLength() {
        // Set frequency and wavelengths
        viewModel.reactance = 30 // ohms
        viewModel.frequency = 300e6 // 300 MHz
        viewModel.wavelengths = 0.3 // Example value

        // Calculate and verify length
        let expectedDistance = viewModel.wavelengths * viewModel.wavelength
        XCTAssertEqual(viewModel.length, expectedDistance)

        // Set length and verify wavelengths
        let newLength = 0.250 // meters
        viewModel.length = newLength
        XCTAssertEqual(viewModel.wavelengths, newLength / viewModel.wavelength, accuracy: 1e-6)
    }

    // Testing Zero Length Function
    func testZeroLength() {
        // Set reflection coefficient angle
        viewModel.reflectionCoefficient = Complex.init(length: 1, phase: .pi / 4)

        // Call zeroLength() and verify that refAngle is set to reflection coefficient angle
        viewModel.zeroLength()
        XCTAssertEqual(viewModel.refAngle.radians, viewModel.reflectionCoefficient.phase)
    }
}

class FullTests: ViewModelTestBase {
    
    // From https://youtu.be/FeDm4iFXcX0?si=Tmp6rgcy1vIlVTut
    func testLengthSwr() {
        viewModel.resistance = 100
        viewModel.reactance = 40
        XCTAssertEqual(viewModel.swr, 2.4, accuracy: 1e-2)
        viewModel.frequency = 3e9
        XCTAssertEqual(viewModel.wavelength, 0.10, accuracy: 1e-6)
        viewModel.zeroLength()
        viewModel.angleOrientation = .clockwise
        viewModel.length = 0.025
        XCTAssertEqual(viewModel.wavelengths, 0.25, accuracy: 1e-6)
        XCTAssertEqual(viewModel.resistance, 21.5, accuracy: 1e-1)
        XCTAssertEqual(viewModel.reactance, -8.5, accuracy: 2e-1)
        viewModel.angleOrientation = .counterclockwise
        viewModel.length = 0.025
        XCTAssertEqual(viewModel.wavelengths, 0.25, accuracy: 1e-6)
        XCTAssertEqual(viewModel.resistance, 21.5, accuracy: 1e-1)
        XCTAssertEqual(viewModel.reactance, -8.5, accuracy: 2e-1)
    }
    
    // From https://youtu.be/qkyQqE_g6Q8?si=JZrVj5qaxOlLhXCY
    func testSmithChartCalc() {
        viewModel.resistance = 25
        viewModel.reactance = 50
        XCTAssertEqual(viewModel.swr, 4.2, accuracy: 1e-1)
        XCTAssertEqual(Angle(radians: viewModel.reflectionCoefficient.phase).degrees, 82, accuracy: 1)
        viewModel.zeroLength()
        viewModel.angleOrientation = .clockwise
        viewModel.wavelengths = 3.3
        XCTAssertEqual(viewModel.resistance, 12, accuracy: 2)
        XCTAssertEqual(viewModel.reactance, -20, accuracy: 3e-1)
    }
    
    // From https://youtu.be/3JOtWxpUtbI?si=rqXUsoBqzEacU-8d
    func testQuarterWaveMatch() {
        viewModel.resistance = 50
        viewModel.reactance = 70
        viewModel.angleOrientation = .counterclockwise
        let rotateBy = viewModel.wavelengths
        XCTAssertEqual(rotateBy, 0.077, accuracy: 1e-3)
        viewModel.zeroLength()
        viewModel.angleOrientation = .clockwise
        viewModel.wavelengths = rotateBy
        XCTAssertEqual(viewModel.resistance, 180, accuracy: 5)
        viewModel.referenceImpedance = Complex(sqrt(viewModel.resistance * 50), 0)
        viewModel.zeroLength()
        viewModel.wavelengths = 0.25
        XCTAssertEqual(viewModel.resistance, 50, accuracy: 1e-6)
    }
    
    // From https://youtu.be/ImNRca5ecF0?si=Q6Rw7vBU9ROjMRVQ (W2AEW)
    func testSmithChartExample() {
        viewModel.frequency = 14.2e6
        viewModel.circuitMode = .series
        viewModel.resistance = 33
        viewModel.capacitance = 220e-12
        XCTAssertEqual(viewModel.reactance, -51, accuracy: 5e-1)
        XCTAssertEqual(viewModel.reflectionCoefficient.length, 0.54, accuracy: 5e-2)
        XCTAssertEqual(Angle(radians: viewModel.reflectionCoefficient.phase).degrees, -76.4, accuracy: 8e-1)
        XCTAssertEqual(viewModel.reflectionCoefficientPower, 0.3, accuracy: 5e-2)
        XCTAssertEqual(viewModel.returnLoss, 5.25, accuracy: 1e-1)
        XCTAssertEqual(viewModel.swr, 3.4, accuracy: 1e-1)
        XCTAssertEqual(viewModel.swr_dB, 10.6, accuracy: 3e-1)
        XCTAssertEqual(viewModel.wavelength, 21.13, accuracy: 5e-2)
        viewModel.velocityFactor = 0.66
        XCTAssertEqual(viewModel.wavelength, 13.95, accuracy: 5e-2)
        viewModel.angleOrientation = .clockwise
        viewModel.zeroLength()
        viewModel.length = 1
        XCTAssertEqual(viewModel.wavelengths, 0.0717, accuracy: 5e-2)
        XCTAssertEqual(viewModel.resistance, 17.8, accuracy: 2)
        XCTAssertEqual(viewModel.reactance, -22, accuracy: 5e-1)
    }
}
