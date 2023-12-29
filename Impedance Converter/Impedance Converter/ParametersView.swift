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

struct ReferenceImpedanceView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        UnitInputView(value: Binding(
            get: { viewModel.referenceImpedance.real },
            set: { viewModel.referenceImpedance = Complex(real: $0, imaginary: 0)}
        ), unit: ResistanceUnit.Ω, label: "Z0", description: "ref. impedance")
    }
}

struct ParametersView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        DisplayView {
            HStack {
                FrequencyView(viewModel: viewModel)
                ReferenceImpedanceView(viewModel: viewModel)
            }
        }
    }
}
