import SwiftUI

@main
struct SambaDeLadybugApp: App {
    @StateObject private var viewModel = AppFlowViewModel()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        AdjustManager.shared.configureAdjust()
        RakutenRewardManager.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(viewModel)
                .overlay {
                    DebugBanner(isVisible: viewModel.useTestingAchievementRewards)
                }
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
                AdjustManager.shared.setOfflineMode(false)
            case .background:
                AdjustManager.shared.setOfflineMode(true)
            default:
                break
            }
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

private struct DebugBanner: View {
    let isVisible: Bool
    
    var body: some View {
        Group {
            if isVisible {
                VStack {
                    HStack {
                        Spacer()
                        Text("デバッグモード")
                            .font(.caption.bold())
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.black.opacity(0.5))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .padding(.top, 12)
                            .padding(.trailing, 12)
                    }
                    Spacer()
                }
            }
        }
        .allowsHitTesting(false)
    }
}
