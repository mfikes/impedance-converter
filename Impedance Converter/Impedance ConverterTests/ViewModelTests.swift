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

    // Testing Transmission Coefficient
    func testTransmissionCoefficient() {
        let reflectionCoefficient = Complex(0.5, 0)
        viewModel.reflectionCoefficient = reflectionCoefficient

        // Check transmission coefficient calculation
        let expectedTransmissionCoefficient = 1 - pow(reflectionCoefficient.magnitude, 2)
        XCTAssertEqual(viewModel.transmissionCoefficient, expectedTransmissionCoefficient)

        // Set transmission coefficient and check reflection coefficient changes
        let newTransmissionCoefficient = 0.75
        viewModel.transmissionCoefficient = newTransmissionCoefficient
        let expectedReflectionCoefficientMagnitude = sqrt(1 - newTransmissionCoefficient)
        XCTAssertEqual(viewModel.reflectionCoefficient.magnitude, expectedReflectionCoefficientMagnitude, accuracy: 1e-6)
    }

    // Testing Transmission Loss
    func testTransmissionLoss() {
        viewModel.reactance = 50
        viewModel.transmissionCoefficient = 0.75

        // Check transmission loss calculation
        let expectedTransmissionLoss = -10 * log10(viewModel.transmissionCoefficient)
        XCTAssertEqual(viewModel.transmissionLoss, expectedTransmissionLoss)

        // Set transmission loss and check transmission coefficient changes
        let newTransmissionLoss = 3.0
        viewModel.transmissionLoss = newTransmissionLoss
        let expectedTransmissionCoefficientValue = pow(10, -newTransmissionLoss / 10)
        XCTAssertEqual(viewModel.transmissionCoefficient, expectedTransmissionCoefficientValue, accuracy: 1e-6)
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

    // Testing Distance
    func testDistance() {
        // Set frequency and wavelengths
        viewModel.reactance = 30 // ohms
        viewModel.frequency = 300e6 // 300 MHz
        viewModel.wavelengths = 0.3 // Example value

        // Calculate and verify distance
        let expectedDistance = viewModel.wavelengths * viewModel.wavelength
        XCTAssertEqual(viewModel.distance, expectedDistance)

        // Set distance and verify wavelengths
        let newDistance = 0.250 // meters
        viewModel.distance = newDistance
        XCTAssertEqual(viewModel.wavelengths, newDistance / viewModel.wavelength, accuracy: 1e-6)
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
