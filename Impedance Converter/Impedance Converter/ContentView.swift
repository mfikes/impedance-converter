import SwiftUI

struct DisplayView<Content: View>: View {
    var content: Content
    var backgroundColor: Color
    
    init(backgroundColor: Color = .baseComponentBackgroundColor, @ViewBuilder content: () -> Content) {
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

    @SceneStorage("ContentView.viewModel") var storedViewModel: String?
    
    @State private var showUndoConfirmation = false
    
    init() {
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor(Color.baseSegmentControlTintColor)
        UIButton.appearance().backgroundColor = UIColor(Color.baseSegmentControlTintColor)
    }
    
    var body: some View {
                
        GeometryReader { geometry in
            ZStack {
                Color.baseAppBackgroundColor.edgesIgnoringSafeArea(.all)
                if geometry.size.width > geometry.size.height {
                    VStack {
                        ModePickerView(viewModel: viewModel)
                        ScrollView {
                            HStack(alignment: .top, spacing: 10) {
                                VStack {
                                    Spacer()
                                    ImmittanceView(viewModel: viewModel)
                                    CircuitView(viewModel: viewModel)
                                    ParametersView(viewModel: viewModel)
                                    CharacterizationView(viewModel: viewModel)
                                    Spacer()
                                }
                                VStack {
                                    Spacer()
                                    SmithChartView(viewModel: viewModel)
                                    ElectricalLengthView(viewModel: viewModel)
                                    Spacer(minLength: 46)
                                }
                            }
                        }
                    }
                    .padding(10)
                } else {
                    VStack {
                        ModePickerView(viewModel: viewModel)
                        ScrollView {
                            LazyVStack {
                                ImmittanceView(viewModel: viewModel)
                                CircuitView(viewModel: viewModel)
                                SmithChartView(viewModel: viewModel)
                                ParametersView(viewModel: viewModel)
                                CharacterizationView(viewModel: viewModel)
                                ElectricalLengthView(viewModel: viewModel)
                                Spacer()
                            }
                        }
                    }
                    .frame(maxWidth: 500)
                    .padding(.top, 1)
                }
                ShakeDetectorView() {
                    showUndoConfirmation = true
                }
                .frame(width: 0, height: 0)
            }
            .dynamicTypeSize(.medium)
        }
        .onAppear {
            SmoothAnimation.isAnimationDisabled = true
            if let storedViewModel = storedViewModel,
               let restoredViewModel = ViewModel.decodeFromJSON(storedViewModel) {
                viewModel.update(from: restoredViewModel)
            }
            viewModel.addCheckpoint()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                SmoothAnimation.isAnimationDisabled = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            if let jsonString = viewModel.encodeToJSON() {
                storedViewModel = jsonString
            }
        }
        .alert(isPresented: $showUndoConfirmation) {
            if viewModel.canUndo {
                return Alert(
                    title: Text("Undo Action"),
                    primaryButton: .destructive(Text("Undo")) {
                        viewModel.undo()
                    },
                    secondaryButton: .cancel()
                )
            } else {
                return Alert(
                    title: Text("Cannot Undo")
                )
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            viewModel.appDidBecomeActive()
        }
    }
}

struct ModePickerView: View {
    @ObservedObject var viewModel: ViewModel
    var body: some View {
        HStack {
            Picker("Mode", selection: $viewModel.displayMode) {
                Text("Impedance Z").tag(DisplayMode.impedance)
                Text("Admittance Y").tag(DisplayMode.admittance)
                Text("Refl. Coeff. Γ").tag(DisplayMode.reflectionCoefficient)
            }
            .pickerStyle(SegmentedPickerStyle())
            SettingsButtonView()
        }
        .padding([.horizontal], 10)
        .padding([.top], 10)
        .frame(maxWidth: 500)
    }
}

struct SettingsButtonView: View {
    var body: some View {
        Button(action: {
            if let url = URL(string: UIApplication.openSettingsURLString),
               UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }) {
            Image(systemName: "gear")
                .imageScale(.medium)
                .foregroundColor(.black)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
