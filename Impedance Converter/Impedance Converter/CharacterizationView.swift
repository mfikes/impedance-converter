import SwiftUI

struct SWRView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        UnitInputView(value: $viewModel.swr, unit: StandingWaveRatioUnit.SWR, label: "SWR", description: "st. wave ratio")
    }
}

struct ReturnLossView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        UnitInputView(value: $viewModel.returnLoss, unit: ReturnLossUnit.dB, label: "RL", description: "return loss")
    }
}

struct TransmissionCoefficientView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        UnitInputView(value: $viewModel.transmissionCoefficient, unit: TransmissionCoefficientUnit.T, label: "T", description: "transmission coeff.")
    }
}

struct TransmissionLossView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        UnitInputView(value: $viewModel.transmissionLoss, unit: TransmissionLossUnit.dB, label: "TL", description: "transmission loss")
    }
}

struct CharacterizationView: View {
    
    @AppStorage("showCharacterization") private var showCharacterization = false
    
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        if (showCharacterization) {
            DisplayView {
                HStack {
                    SWRView(viewModel: viewModel)
                    ReturnLossView(viewModel: viewModel)
                }
            }
            DisplayView {
                HStack {
                    TransmissionCoefficientView(viewModel: viewModel)
                    TransmissionLossView(viewModel: viewModel)
                }
            }
        }
    }
}
