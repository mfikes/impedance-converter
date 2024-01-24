import SwiftUI

struct CircuitPickerView: View {
    @ObservedObject var viewModel: ViewModel
    var body: some View {
        HStack {
            Spacer()
            Picker("Mode", selection: $viewModel.circuitMode) {
                Image("Series").tag(CircuitMode.series)
                Image("Parallel").tag(CircuitMode.parallel)
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(maxWidth: 200)
            Spacer()
        }
        .padding(10)
    }
}

struct CapacitanceView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        DisplayView {
            VStack {
                HStack {
                    UnitInputView(value: $viewModel.capacitance, unit: CapacitanceUnit.F, label: "C", description: "capacitance")
                    UnitInputView(value: $viewModel.dissipationFactor, unit: DissipationUnit.D, label: "D", description: "dissipation factor")
                }
            }
        }
    }
}

struct InductanceView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        DisplayView {
            VStack {
                HStack {
                    UnitInputView(value: $viewModel.inductance, unit: InductanceUnit.H, label: "L", description: "inductance")
                    UnitInputView(value: $viewModel.qualityFactor, unit: QualityUnit.Q, label: "Q", description: "quality factor")
                }
            }
        }
    }
}

extension Binding where Value: BinaryFloatingPoint {
    static func reciprocal(_ source: Binding<Value>) -> Binding<Value> {
        Binding(
            get: { 1 / source.wrappedValue },
            set: { source.wrappedValue = 1 / $0 }
        )
    }
}

struct ResistorView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        switch (viewModel.circuitMode, viewModel.displayMode) {
        case (.series, .impedance), (.series, .reflectionCoefficient):
            UnitInputView(value: $viewModel.resistance, unit: ResistanceUnit.Ω, label: "ESR", description: "eq. series res.")
        case (.parallel, .impedance), (.parallel, .reflectionCoefficient):
            UnitInputView(value: .reciprocal($viewModel.conductance), unit: ResistanceUnit.Ω, label: "Rₚ", description: "eq. parallel res.")
        case (.series, .admittance):
            UnitInputView(value: .reciprocal($viewModel.resistance), unit: ConductanceUnit.S, label: "Gₛ", description: "eq. series cond.")
        case (.parallel, .admittance):
            UnitInputView(value: $viewModel.conductance, unit: ConductanceUnit.S, label: "Gₚ", description: "eq. parallel cond.")
        }
    }
}

struct CircuitView: View {
    
    @AppStorage("showLCQD") private var showLCQD = true
    
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        if (showLCQD) {
            CircuitPickerView(viewModel: viewModel)
            InductanceView(viewModel: viewModel)
            CapacitanceView(viewModel: viewModel)
            DisplayView {
                HStack {
                    ResistorView(viewModel: viewModel)
                    FrequencyView(viewModel: viewModel)
                }
            }
        }
    }
}
