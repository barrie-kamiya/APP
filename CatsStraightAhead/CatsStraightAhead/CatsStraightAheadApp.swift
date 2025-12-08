import SwiftUI
import RakutenRewardSDK

@main
struct CatsStraightAheadApp: App {
    @StateObject private var flowState = AppFlowState()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        AdjustManager.shared.configureAdjust()
        RakutenRewardManager.shared.configureIfNeeded()
        TrackingAuthorizationManager.requestTrackingAuthorizationIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            FlowCoordinatorView()
                .environmentObject(flowState)
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
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
