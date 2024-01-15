import SwiftUI

struct SWRView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        UnitInputView(value: $viewModel.swr, unit: StandingWaveRatioUnit.SWR, label: "SWR", description: "st. wave ratio")
    }
}

struct SWRDBView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        UnitInputView(value: $viewModel.swr_dB, unit: StandingWaveRatioDBUnit.dB, label: "SWR", description: "st. wave ratio")
    }
}

struct ReflectionCoefficientView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        UnitInputView(value: $viewModel.reflectionCoefficientRho, unit: ReflectionCoefficientRhoUnit.ρ, label: "ρ", description: "refl. coeff.")
    }
}

struct ReflectionCoefficientPowerView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        UnitInputView(value: $viewModel.reflectionCoefficientPower, unit: ReflectionCoefficientPowerUnit.ρ², label: "RP", description: "refl. power")
    }
}

struct TransmissionCoefficientView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        UnitInputView(value: $viewModel.transmissionCoefficientTau, unit: TransmissionCoefficientUnit.τ, label: "τ", description: "trans. coeff.")
    }
}

struct TransmissionCoefficientPowerView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        UnitInputView(value: $viewModel.transmissionCoefficientPower, unit: TransmissionCoefficientPowerUnit.P, label: "TP", description: "trans. power")
    }
}

struct ReturnLossView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        UnitInputView(value: $viewModel.returnLoss, unit: ReturnLossUnit.dB, label: "RL", description: "return loss")
    }
}

struct ReflectionLossView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        UnitInputView(value: $viewModel.reflectionLoss, unit: ReflectionLossUnit.dB, label: "RL", description: "reflection loss")
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
                    SWRDBView(viewModel: viewModel)
                }
            }
            DisplayView {
                HStack {
                    ReflectionCoefficientView(viewModel: viewModel)
                    TransmissionCoefficientView(viewModel: viewModel)
                }
            }
            DisplayView {
                HStack {
                    ReflectionCoefficientPowerView(viewModel: viewModel)
                    TransmissionCoefficientPowerView(viewModel: viewModel)
                }
            }
            DisplayView {
                HStack {
                    ReturnLossView(viewModel: viewModel)
                    ReflectionLossView(viewModel: viewModel)
                }
            }
        }
    }
}
