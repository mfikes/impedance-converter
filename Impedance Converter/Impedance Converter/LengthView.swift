import SwiftUI

struct WavelengthsView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        UnitInputView(value: $viewModel.wavelengths, unit: WavelengthsUnit.λ, label: "×λ", description: "wavelengths")
    }
}

struct LengthView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        UnitInputView(value: $viewModel.length, unit: LengthUnit.m, label: "L", description: "length")
    }
}

struct WavelengthView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        UnitInputView(value: $viewModel.wavelength, unit: WavelengthUnit.m, label: "λ", description: "wavelength")
    }
}

struct VelocityFactorView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        UnitInputView(value: $viewModel.velocityFactor, unit: VelocityFactorUnit.V, label: "V", description: "velocity factor")
    }
}

struct ElectricalLengthView: View {
    
    @AppStorage("showLength") private var showLength = false
    
    @ObservedObject var viewModel: ViewModel

    var body: some View {
        if (showLength) {
            HStack {
                Spacer()
                HStack {
                    Spacer(minLength: 15)
                    HStack(spacing: 2) {
                        Text("↻")
                        ToggleButtonView(isOn: Binding(
                            get: { viewModel.angleOrientation == .clockwise },
                            set: { if $0 { viewModel.angleOrientation = .clockwise }}
                        ))
                    }
                    Spacer()
                    HStack(spacing: 2) {
                        Text("↺")
                        ToggleButtonView(isOn: Binding(
                            get: { viewModel.angleOrientation == .counterclockwise },
                            set: { if $0 { viewModel.angleOrientation = .counterclockwise }}
                        ))
                    }
                    Spacer()
                }
                .padding(.vertical, -2)
                .frame(maxWidth: 180, maxHeight: 50)
                Spacer()
                HStack {
                    Text("Zero")
                    ButtonView() {
                        if !viewModel.reflectionCoefficient.phase.isNaN {
                            viewModel.zeroLength()
                        }
                    }
                }
                .padding(.vertical, -2)
                .frame(maxWidth: 100, maxHeight: 50)
                Spacer()
            }
            DisplayView {
                HStack {
                    WavelengthsView(viewModel: viewModel)
                    LengthView(viewModel: viewModel)
                }
            }
            DisplayView {
                HStack {
                    VelocityFactorView(viewModel: viewModel)
                    WavelengthView(viewModel: viewModel)
                }
            }
        }
    }
}
