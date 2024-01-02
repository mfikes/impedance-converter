import SwiftUI

struct FrequencyView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        UnitInputView(value: Binding(
            get: { viewModel.frequency },
            set: { viewModel.frequency = $0 }
        ), unit: FrequencyUnit.Hz, label: "F", description: "frequency")
    }
}

struct ReferenceView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        if (viewModel.displayMode != .admittance) {
            UnitInputView(value: Binding(
                get: { viewModel.referenceImpedance.real },
                set: { viewModel.referenceImpedance = Complex(real: $0, imaginary: 0)}
            ), unit: ResistanceUnit.Ω, label: "Z₀", description: "ref. impedance")
        } else {
            UnitInputView(value: Binding(
                get: { viewModel.referenceAdmittance.real },
                set: { viewModel.referenceAdmittance = Complex(real: $0, imaginary: 0)}
            ), unit: ConductanceUnit.S, label: "Y₀", description: "ref. admittance")
        }
    }
}

struct ParametersView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        DisplayView {
            HStack {
                FrequencyView(viewModel: viewModel)
                ReferenceView(viewModel: viewModel)
            }
        }
    }
}
