import SwiftUI

struct DisplayView<Content: View>: View {
    var content: Content
    var backgroundColor: Color
    
    init(backgroundColor: Color = Color(hex: "#232521"), @ViewBuilder content: () -> Content) {
        self.backgroundColor = backgroundColor
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(.bottom, 12)
            .padding(.horizontal, 5)
            .background(backgroundColor)
            .edgesIgnoringSafeArea(.bottom)
    }
}

struct ContentView: View {
    
    @StateObject var viewModel = ViewModel()
    
    init() {
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor(Color.baseSegmentControlTintColor.adjusted(brightness: 1.2)
        )
    }
    
    var body: some View {
        ZStack {
            Color.baseAppBackgroundColor.edgesIgnoringSafeArea(.all)
            ScrollView {
                VStack {
                    VStack {
                        ComplexImpedanceView(viewModel: viewModel)
                        ParametersView(viewModel: viewModel)
                        CircuitView(viewModel: viewModel)
                    }
                    SmithChartView(viewModel: viewModel)
                    CharacterizationView(viewModel:viewModel)
                }
            }
            .frame(maxWidth: 500)
            .padding(.top, 1)
            .dynamicTypeSize(.medium)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
