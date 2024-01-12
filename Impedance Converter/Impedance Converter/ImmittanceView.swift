import SwiftUI
import Numerics

struct PolarParameterView<UnitType>: View where UnitType: RawRepresentable, UnitType.RawValue == String, UnitType: UnitWithPowerOfTen {
    @Binding var complexValue: Complex<Double>
    var magnitudeUnit: UnitType
    var angleUnit: AngleUnit
    var magnitudeLabel: String
    var angleLabel: String
    var magnitudeDescription: String
    var angleDescription: String
    
    var body: some View {
        VStack {
            HStack {
                UnitInputView(value: Binding(
                    get: { self.complexValue.length },
                    set: {
                        self.complexValue = Complex.init(length: $0, phase: self.complexValue.phase)
                    }
                ), unit: magnitudeUnit, label: magnitudeLabel, description: magnitudeDescription)
                
                UnitInputView(value: Binding(
                    get: { Angle(radians: self.complexValue.phase).degrees },
                    set: {
                        print("complex \(Complex.init(length: self.complexValue.length, phase:Angle(degrees: $0).radians))")
                        print("angle \(Angle(degrees: $0).radians)")
                        print("pi/2 \(Double.pi / 2)")
                        self.complexValue = Complex.init(length: self.complexValue.length, phase:Angle(degrees: $0).radians)
                    }
                ), unit: angleUnit, label: angleLabel, description: angleDescription, showNegationDecorator: true)
            }
        }
    }
}

struct PolarImpedanceView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        PolarParameterView<ResistanceUnit>(
            complexValue: $viewModel.impedance,
            magnitudeUnit: .Ω,
            angleUnit: .degree,
            magnitudeLabel: "|Z|",
            angleLabel: "θ",
            magnitudeDescription: "magnitude",
            angleDescription: "phase angle"
        )
    }
}

struct PolarAdmittanceView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        PolarParameterView<ConductanceUnit>(
            complexValue: $viewModel.admittance,
            magnitudeUnit: .S,
            angleUnit: .degree,
            magnitudeLabel: "|Y|",
            angleLabel: "θ",
            magnitudeDescription: "magnitude",
            angleDescription: "phase angle"
        )
    }
}

struct PolarReflectionCoefficientView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        PolarParameterView<ReflectionCoefficientUnit>(
            complexValue: $viewModel.reflectionCoefficient,
            magnitudeUnit: .Γ,
            angleUnit: .degree,
            magnitudeLabel: "|Γ|",
            angleLabel: "θ",
            magnitudeDescription: "magnitude",
            angleDescription: "phase angle"
        )
    }
}

struct RectangularParameterView<UnitType: UnitWithPowerOfTen>: View {
    @Binding var complexValue: Complex<Double>
    var realPartUnit: UnitType
    var imaginaryPartUnit: UnitType
    var realPartLabel: String
    var imaginaryPartLabel: String
    var realPartDescription: String
    var imaginaryPartDescription: String
    var realCanBeNegative: Bool
    var imaginaryCanBeNegative: Bool
    
    var body: some View {
        VStack {
            HStack {
                UnitInputView(value: Binding(
                    get: { self.complexValue.canonicalizedReal },
                    set: { self.complexValue = Complex($0, self.complexValue.canonicalizedImaginary) }
                ), unit: realPartUnit, label: realPartLabel, description: realPartDescription,
                              showNegationDecorator: realCanBeNegative)
                UnitInputView(value: Binding(
                    get: { self.complexValue.canonicalizedImaginary },
                    set: { self.complexValue = Complex(self.complexValue.canonicalizedReal, $0) }
                ), unit: imaginaryPartUnit, label: imaginaryPartLabel, description: imaginaryPartDescription,
                              showNegationDecorator: imaginaryCanBeNegative)
            }
        }
    }
}

struct RectangularImpedanceView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        RectangularParameterView<ResistanceUnit>(
            complexValue: $viewModel.impedance,
            realPartUnit: .Ω,
            imaginaryPartUnit: .Ω,
            realPartLabel: "R",
            imaginaryPartLabel: "X",
            realPartDescription: "resistance",
            imaginaryPartDescription: "reactance",
            realCanBeNegative: false,
            imaginaryCanBeNegative: true
        )
    }
}

struct RectangularAdmittanceView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        RectangularParameterView<ConductanceUnit>(
            complexValue: $viewModel.admittance,
            realPartUnit: .S,
            imaginaryPartUnit: .S,
            realPartLabel: "G",
            imaginaryPartLabel: "B",
            realPartDescription: "conductance",
            imaginaryPartDescription: "susceptance",
            realCanBeNegative: false,
            imaginaryCanBeNegative: true
        )
    }
}

struct RectangularReflectionCoefficientView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        RectangularParameterView<ReflectionCoefficientUnit>(
            complexValue: $viewModel.reflectionCoefficient,
            realPartUnit: .Γ,
            imaginaryPartUnit: .Γ,
            realPartLabel: "Re(Γ)",
            imaginaryPartLabel: "Im(Γ)",
            realPartDescription: "real part",
            imaginaryPartDescription: "imaginary part",
            realCanBeNegative: true,
            imaginaryCanBeNegative: true
        )
    }
}

struct ImmittanceView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        VStack {
            DisplayView {
                switch viewModel.displayMode {
                case .impedance:
                    PolarImpedanceView(viewModel: viewModel)
                case .admittance:
                    PolarAdmittanceView(viewModel: viewModel)
                case .reflectionCoefficient:
                    PolarReflectionCoefficientView(viewModel: viewModel)
                }
            }
            DisplayView {
                switch viewModel.displayMode {
                case .impedance:
                    RectangularImpedanceView(viewModel: viewModel)
                case .admittance:
                    RectangularAdmittanceView(viewModel: viewModel)
                case .reflectionCoefficient:
                    RectangularReflectionCoefficientView(viewModel: viewModel)
                }
            }
        }
    }
}
