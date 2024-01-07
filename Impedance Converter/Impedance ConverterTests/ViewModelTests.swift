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
