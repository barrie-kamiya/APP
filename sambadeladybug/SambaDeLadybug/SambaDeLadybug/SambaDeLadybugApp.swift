import SwiftUI

@main
struct SambaDeLadybugApp: App {
    @StateObject private var viewModel = AppFlowViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(viewModel)
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var viewModel: AppFlowViewModel

    var body: some View {
        Group {
            switch viewModel.currentScreen {
            case .splash:
                SplashScreen()
            case .home:
                HomeScreen()
            case .game:
                GameScreen()
            case .stageChange:
                StageChangeScreen()
            case .clear:
                GameClearScreen()
            }
        }
        .animation(.easeInOut, value: viewModel.currentScreen)
    }
}
