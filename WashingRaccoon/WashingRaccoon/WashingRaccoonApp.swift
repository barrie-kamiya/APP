import SwiftUI

enum FeatureFlags {
    static let isRakutenRewardEnabled = true
    static let isAdjustEnabled = true
}

@main
struct WashingRaccoonApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel = AppViewModel()

    init() {
        if FeatureFlags.isAdjustEnabled {
            AdjustManager.shared.configureAdjust()
        }
        TrackingAuthorizationManager.requestTrackingAuthorizationIfNeeded()
        if FeatureFlags.isRakutenRewardEnabled {
            RakutenRewardManager.shared.configure()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
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
