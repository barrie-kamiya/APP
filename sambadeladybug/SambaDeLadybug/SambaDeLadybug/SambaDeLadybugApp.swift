import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum FeatureFlags {
    static let isAdjustEnabled = true
    static let isRakutenRewardEnabled = true
    static let isFiveAdEnabled = true
}

@main
struct SambaDeLadybugApp: App {
    @StateObject private var viewModel = AppFlowViewModel()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        if FeatureFlags.isAdjustEnabled {
            AdjustManager.shared.configureAdjust()
        }
        if FeatureFlags.isRakutenRewardEnabled {
            RakutenRewardManager.shared.configure()
        }
        TrackingAuthorizationManager.requestTrackingAuthorizationIfNeeded()
        if FeatureFlags.isFiveAdEnabled {
            FiveAdManager.shared.configureIfNeeded()
#if canImport(UIKit)
            let width = Float(UIScreen.main.bounds.width * 0.92)
            FiveAdBannerLoader.shared.preloadBannerIfNeeded(width: width)
#endif
            FiveAdVideoRewardManager.shared.preloadRewardIfNeeded()
        }
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
                if FeatureFlags.isAdjustEnabled {
                    AdjustManager.shared.setOfflineMode(false)
                }
            case .background:
                if FeatureFlags.isAdjustEnabled {
                    AdjustManager.shared.setOfflineMode(true)
                }
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
