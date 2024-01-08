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

class ReferenceImmittanceTests: ViewModelTestBase {
    
    func testReferenceImmittancePropertyForImpedance() {
        // Setting reference impedance and getting it back
        let referenceImpedance = Complex(real: 75, imaginary: 00)
        viewModel.referenceImmittance = Immittance(impedance: referenceImpedance)
        XCTAssertEqual(viewModel.referenceImmittance.impedance, referenceImpedance)
        
        // Checking the reciprocal reference admittance
        let expectedReferenceAdmittance = referenceImpedance.reciprocal
        XCTAssertEqual(viewModel.referenceImmittance.admittance, expectedReferenceAdmittance)
    }
    
    func testReferenceImmittancePropertyForAdmittance() {
        // Setting reference admittance and getting it back
        let referenceAdmittance = Complex(real: 0.005, imaginary: 0.0)
        viewModel.referenceImmittance = Immittance(admittance: referenceAdmittance)
        XCTAssertEqual(viewModel.referenceImmittance.admittance, referenceAdmittance)
        
        // Checking the reciprocal reference impedance
        let expectedReferenceImpedance = referenceAdmittance.reciprocal
        XCTAssertEqual(viewModel.referenceImmittance.impedance, expectedReferenceImpedance)
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
    
    func testSettingReferenceImpedanceSetsType() {
        // Set reference impedance
        viewModel.referenceImmittance = Immittance(impedance: Complex(real: 100, imaginary: 50))
        XCTAssertEqual(viewModel.referenceImmittance.type, .impedance)
    }
    
    func testSettingReferenceAdmittanceSetsType() {
        // Set reference admittance
        viewModel.referenceImmittance = Immittance(admittance: Complex(real: 0.005, imaginary: -0.002))
        XCTAssertEqual(viewModel.referenceImmittance.type, .admittance)
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
    
    func testImmittancePropertyForImpedance() {
        // Setting impedance and getting it back
        let impedance = Complex(real: 100, imaginary: -50)
        viewModel.immittance = Immittance(impedance: impedance)
        XCTAssertEqual(viewModel.immittance.impedance, impedance)
        
        // Checking the reciprocal admittance
        let expectedAdmittance = impedance.reciprocal
        XCTAssertEqual(viewModel.immittance.admittance, expectedAdmittance)
    }
    
    func testImmittancePropertyForAdmittance() {
        // Setting admittance and getting it back
        let admittance = Complex(real: 0.01, imaginary: 0.02)
        viewModel.immittance = Immittance(admittance: admittance)
        XCTAssertEqual(viewModel.immittance.admittance, admittance)
        
        // Checking the reciprocal impedance
        let expectedImpedance = admittance.reciprocal
        XCTAssertEqual(viewModel.immittance.impedance, expectedImpedance)
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
