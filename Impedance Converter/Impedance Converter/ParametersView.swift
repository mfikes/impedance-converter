import SwiftUI
import Numerics

struct FrequencyView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        UnitInputView(value: $viewModel.frequency, unit: FrequencyUnit.Hz, label: "F", description: "frequency")
    }
}

struct ReferenceView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        if (viewModel.displayMode != .admittance) {
            UnitInputView(value: Binding(
                get: { viewModel.referenceImpedance.real },
                set: {
                    viewModel.setValueRecordingTrace(from: viewModel.referenceImpedance.real, to: $0) {
                        intermediateValue in
                        viewModel.referenceImpedance = Complex(intermediateValue, 0)
                    }
                }
            ), unit: ResistanceUnit.Ω, label: "Z₀", description: "ref. impedance")
        } else {
            UnitInputView(value: Binding(
                get: { viewModel.referenceAdmittance.real },
                set: { viewModel.referenceAdmittance = Complex($0, 0)}
            ), unit: ConductanceUnit.S, label: "Y₀", description: "ref. admittance")
        }
    }
}

struct ParametersView: View {
    
    @AppStorage("showParameters") private var showParameters = false
    
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        if (showParameters) {
            DisplayView {
                HStack {
                    ReferenceView(viewModel: viewModel)
                    FrequencyView(viewModel: viewModel)
                }
            }
        }
    }
}
