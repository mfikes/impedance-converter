import SwiftUI

struct WavelengthsView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        UnitInputView(value: $viewModel.wavelengths, unit: WavelengthsUnit.λ, label: "×λ", description: "wavelengths", showNegationDecorator: true, precision: 3)
    }
}

struct DistanceView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        UnitInputView(value: $viewModel.distance, unit: DistanceUnit.m, label: "D", description: "distance", showNegationDecorator: true)
    }
}

struct LengthView: View {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        HStack {
            Spacer()
            Text("Direction:")
            Picker("Direction", selection: $viewModel.angleOrientation) {
                Text("↺").tag(AngleOrientation.counterclockwise)
                Text("↻").tag(AngleOrientation.clockwise)
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
            .disabled(viewModel.reflectionCoefficient.angle.radians.isNaN)
            Spacer()
        }
        DisplayView {
            HStack {
                WavelengthsView(viewModel: viewModel)
                DistanceView(viewModel: viewModel)
            }
        }
    }
}
