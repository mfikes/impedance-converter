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
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.baseAppBackgroundColor.edgesIgnoringSafeArea(.all)
                if geometry.size.width > geometry.size.height {
                    HStack(spacing: 10) {
                        LeftColumnView(viewModel: viewModel)
                        RightColumnView(viewModel: viewModel)
                    }
                    .padding(10)
                } else {
                    ScrollView {
                        VStack {
                            LeftColumnView(viewModel: viewModel)
                            RightColumnView(viewModel: viewModel)
                        }
                        .frame(maxWidth: 500)
                    }
                }
            }
            .dynamicTypeSize(.medium)
        }
    }
}

struct LeftColumnView: View {
    var viewModel: ViewModel
    var body: some View {
        VStack {
            ComplexImpedanceView(viewModel: viewModel)
            ParametersView(viewModel: viewModel)
            CircuitView(viewModel: viewModel)
        }
    }
}

struct RightColumnView: View {
    var viewModel: ViewModel
    var body: some View {
        VStack {
            SmithChartView(viewModel: viewModel)
            CharacterizationView(viewModel: viewModel)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
