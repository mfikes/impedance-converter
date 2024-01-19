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
                Text("Direction:")
                Picker("Direction", selection: $viewModel.angleOrientation) {
                    Text("↻").tag(AngleOrientation.clockwise)
                    Text("↺").tag(AngleOrientation.counterclockwise)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding([.horizontal], 10)
                .frame(maxWidth: 180)
                Spacer()
                Button("Zero") {
                    viewModel.zeroLength()
                }
                .padding()
                .frame(maxHeight: 30)
                .background(Color.baseSegmentControlTintColor)
                .foregroundColor(Color.black)
                .cornerRadius(10)
                .disabled(viewModel.reflectionCoefficient.phase.isNaN)
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
