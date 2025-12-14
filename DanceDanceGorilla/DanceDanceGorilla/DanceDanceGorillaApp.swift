import SwiftUI

@main
struct DanceDanceGorillaApp: App {
    @Environment(\.scenePhase) private var scenePhase

    init() {
        if FeatureFlags.isAdjustEnabled {
            AdjustManager.shared.configure()
        }
        TrackingAuthorizationManager.requestTrackingAuthorizationIfNeeded()
        if FeatureFlags.isRakutenRewardEnabled {
            RakutenRewardManager.shared.configure()
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
        .onChange(of: scenePhase) { newPhase in
            guard FeatureFlags.isAdjustEnabled else { return }
            switch newPhase {
            case .active:
                AdjustManager.shared.setOfflineMode(false)
            case .background, .inactive:
                AdjustManager.shared.setOfflineMode(true)
            @unknown default:
                break
            }
        }
    }
}
