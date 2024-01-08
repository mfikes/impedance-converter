import XCTest
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
        let referenceImpedance = Complex(real: 75, imaginary: 00)
        viewModel.referenceImpedance = referenceImpedance
        XCTAssertEqual(viewModel.referenceImpedance, referenceImpedance)
        
        // Checking the reciprocal reference admittance
        let expectedReferenceAdmittance = referenceImpedance.reciprocal
        XCTAssertEqual(viewModel.referenceAdmittance, expectedReferenceAdmittance)
    }
    
    func testReferenceImmittancePropertyForAdmittance() {
        // Setting reference admittance and getting it back
        let referenceAdmittance = Complex(real: 0.005, imaginary: 0.0)
        viewModel.referenceAdmittance = referenceAdmittance
        XCTAssertEqual(viewModel.referenceAdmittance, referenceAdmittance)
        
        // Checking the reciprocal reference impedance
        let expectedReferenceImpedance = referenceAdmittance.reciprocal
        XCTAssertEqual(viewModel.referenceImpedance, expectedReferenceImpedance)
    }
    
    func testDefaultReferenceImpedance() {
        // Default reference impedance should be 50 ohms (50 + 0j)
        let expectedReferenceImpedance = Complex(real: 50, imaginary: 0)
        XCTAssertEqual(viewModel.referenceImpedance, expectedReferenceImpedance)
    }
    
    func testDefaultReferenceAdmittance() {
        // Default reference admittance should be 20 millisiemens (0.020 + 0j)
        let expectedReferenceAdmittance = Complex(real: 0.020, imaginary: 0)
        XCTAssertEqual(viewModel.referenceAdmittance, expectedReferenceAdmittance)
    }
        
    func testReferenceImpedanceIsPositiveReal() {
        // Initial set with a valid positive real impedance
        let initialImpedance = Complex(real: 100, imaginary: 0)
        viewModel.referenceImpedance = initialImpedance

        // Attempt to set a negative real part
        let negativeRealImpedance = Complex(real: -50, imaginary: 0)
        viewModel.referenceImpedance = negativeRealImpedance

        // Check if the impedance remains unchanged
        XCTAssertEqual(viewModel.referenceImpedance, initialImpedance)
        
        // Attempt to set an imaginary part
        let complexImpedance = Complex(real: 50, imaginary: 1)
        viewModel.referenceImpedance = complexImpedance

        // Check if the impedance remains unchanged
        XCTAssertEqual(viewModel.referenceImpedance, initialImpedance)
    }
    
    func testReferenceAdmittanceIsPositiveReal() {
        // Initial set with a valid positive real impedance
        let initialAdmittance = Complex(real: 100, imaginary: 0)
        viewModel.referenceAdmittance = initialAdmittance

        // Attempt to set a negative real part
        let negativeRealAdmittance = Complex(real: -50, imaginary: 0)
        viewModel.referenceAdmittance = negativeRealAdmittance

        // Check if the admittance remains unchanged
        XCTAssertEqual(viewModel.referenceAdmittance, initialAdmittance)
        
        // Attempt to set an imaginary part
        let complexAdmittance = Complex(real: 50, imaginary: 1)
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
        XCTAssertEqual(viewModel.admittance.real, Double.infinity)

        // Setting zero admittance
        viewModel.admittance = Complex.zero
        XCTAssertEqual(viewModel.admittance, Complex.zero)
        XCTAssertEqual(viewModel.impedance.real, Double.infinity)
    }
    
    func testImmittanceWithNegativeValues() {
        // Negative real part in impedance
        viewModel.impedance = Complex(real: -50, imaginary: 10)
        XCTAssertEqual(viewModel.impedance, Complex(real: -50, imaginary: 10))

        // Negative imaginary part in admittance
        viewModel.admittance = Complex(real: 0.02, imaginary: -0.005)
        XCTAssertEqual(viewModel.admittance, Complex(real: 0.02, imaginary: -0.005))
    }

    func testImmittanceWithComplexValues() {
        // Complex impedance
        viewModel.impedance = Complex(real: 30, imaginary: 40)
        XCTAssertEqual(viewModel.impedance, Complex(real: 30, imaginary: 40))

        // Complex admittance
        viewModel.admittance = Complex(real: 0.03, imaginary: 0.04)
        XCTAssertEqual(viewModel.admittance, Complex(real: 0.03, imaginary: 0.04))
    }

    func testImmittanceWithNaNAndInfiniteValues() {
        // Infinite impedance
        viewModel.impedance = Complex(real: Double.infinity, imaginary: Double.infinity)
        XCTAssertTrue(viewModel.impedance.real.isInfinite)
        XCTAssertTrue(viewModel.impedance.imaginary.isInfinite)

        // NaN impedance
        viewModel.impedance = Complex(real: Double.nan, imaginary: Double.nan)
        XCTAssertTrue(viewModel.impedance.real.isNaN)
        XCTAssertTrue(viewModel.impedance.imaginary.isNaN)

        // Infinite admittance
        viewModel.admittance = Complex(real: Double.infinity, imaginary: Double.infinity)
        XCTAssertTrue(viewModel.admittance.real.isInfinite)
        XCTAssertTrue(viewModel.admittance.imaginary.isInfinite)

        // NaN admittance
        viewModel.admittance = Complex(real: Double.nan, imaginary: Double.nan)
        XCTAssertTrue(viewModel.admittance.real.isNaN)
        XCTAssertTrue(viewModel.admittance.imaginary.isNaN)
    }
    
    func testReciprocalRelationships() {
        // Impedance and its reciprocal admittance
        let impedance = Complex(real: 100, imaginary: -50)
        viewModel.impedance = impedance
        XCTAssertEqual(viewModel.impedance, impedance)
        XCTAssertEqual(viewModel.admittance, impedance.reciprocal)

        // Admittance and its reciprocal impedance
        let admittance = Complex(real: 0.01, imaginary: 0.02)
        viewModel.admittance = admittance
        XCTAssertEqual(viewModel.admittance, admittance)
        XCTAssertEqual(viewModel.impedance, admittance.reciprocal)
    }

}

class ElectricalParametersTests: ViewModelTestBase {
    
    // Testing Resistance
    func testResistance() {
        viewModel.impedance = Complex(real: 50, imaginary: 30)
        XCTAssertEqual(viewModel.resistance, 50)
        
        viewModel.resistance = 75
        XCTAssertEqual(viewModel.impedance, Complex(real: 75, imaginary: 30))
    }
    
    // Testing Reactance
    func testReactance() {
        viewModel.impedance = Complex(real: 50, imaginary: 30)
        XCTAssertEqual(viewModel.reactance, 30)
        
        viewModel.reactance = 40
        XCTAssertEqual(viewModel.impedance, Complex(real: 50, imaginary: 40))
    }
    
    // Testing Conductance
    func testConductance() {
        viewModel.admittance = Complex(real: 0.02, imaginary: 0.01)
        XCTAssertEqual(viewModel.conductance, 0.02)
        
        viewModel.conductance = 0.03
        XCTAssertEqual(viewModel.admittance, Complex(real: 0.03, imaginary: 0.01))
    }
    
    // Testing Susceptance
    func testSusceptance() {
        viewModel.admittance = Complex(real: 0.02, imaginary: 0.01)
        XCTAssertEqual(viewModel.susceptance, 0.01)
        
        viewModel.susceptance = 0.015
        XCTAssertEqual(viewModel.admittance, Complex(real: 0.02, imaginary: 0.015))
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
