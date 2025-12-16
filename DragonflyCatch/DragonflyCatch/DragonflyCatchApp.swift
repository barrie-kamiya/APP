import SwiftUI

@main
struct DragonflyCatchApp: App {
    @Environment(\.scenePhase) private var scenePhase

    init() {
        AdjustManager.shared.configureAdjust()
        TrackingAuthorizationManager.requestTrackingAuthorizationIfNeeded()
        RakutenRewardManager.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            FlowCoordinatorView()
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
