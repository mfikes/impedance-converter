import SwiftUI

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

struct CircuitView: View {
    
    @AppStorage("showLCQD") private var showLCQD = true
    
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        if (showLCQD) {
            Picker("Mode", selection: $viewModel.circuitMode) {
                Image("Series").tag(CircuitMode.series)
                Image("Parallel").tag(CircuitMode.parallel)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding([.horizontal], 10)
            .frame(maxWidth: 200)
            InductanceView(viewModel: viewModel)
            CapacitanceView(viewModel: viewModel)
        }
    }
}
