import SwiftUI

struct PolarParameterView<UnitType>: View where UnitType: RawRepresentable, UnitType.RawValue == String, UnitType: UnitWithPowerOfTen {
    @Binding var complexValue: Complex
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
                    get: { self.complexValue.magnitude },
                    set: {
                        self.complexValue = Complex.fromPolar(magnitude: $0, angle: self.complexValue.angle)
                    }
                ), unit: magnitudeUnit, label: magnitudeLabel, description: magnitudeDescription)
                
                UnitInputView(value: Binding(
                    get: { self.complexValue.angle.degrees },
                    set: {
                        self.complexValue = Complex.fromPolar(magnitude: self.complexValue.magnitude, angle:Angle.init(degrees: $0))
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
    @Binding var complexValue: Complex
    var realPartUnit: UnitType
    var imaginaryPartUnit: UnitType
    var realPartLabel: String
    var imaginaryPartLabel: String
    var realPartDescription: String
    var imaginaryPartDescription: String
    
    var body: some View {
        VStack {
            HStack {
                UnitInputView(value: Binding(
                    get: { self.complexValue.real },
                    set: { self.complexValue = Complex(real: $0, imaginary: self.complexValue.imaginary) }
                ), unit: realPartUnit, label: realPartLabel, description: realPartDescription)
                UnitInputView(value: Binding(
                    get: { self.complexValue.imaginary },
                    set: { self.complexValue = Complex(real: self.complexValue.real, imaginary: $0) }
                ), unit: imaginaryPartUnit, label: imaginaryPartLabel, description: imaginaryPartDescription, showNegationDecorator: true)
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
            imaginaryPartDescription: "reactance"
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
            imaginaryPartDescription: "susceptance"
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
            imaginaryPartDescription: "imaginary part"
        )
    }
}

struct ComplexImpedanceView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        VStack {
            Picker("Mode", selection: $viewModel.complexDisplayMode) {
                Text("Impedance Z").tag(DisplayMode.impedance)
                Text("Admittance Y").tag(DisplayMode.admittance)
                Text("Refl. Coeff. Γ").tag(DisplayMode.reflectionCoefficient)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding([.horizontal], 10)
            .padding([.top], 10)
            
            DisplayView {
                switch viewModel.complexDisplayMode {
                case .impedance:
                    PolarImpedanceView(viewModel: viewModel)
                case .admittance:
                    PolarAdmittanceView(viewModel: viewModel)
                case .reflectionCoefficient:
                    PolarReflectionCoefficientView(viewModel: viewModel)
                }
            }
            DisplayView {
                switch viewModel.complexDisplayMode {
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
