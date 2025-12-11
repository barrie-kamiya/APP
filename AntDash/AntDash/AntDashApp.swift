import SwiftUI

@main
struct AntDashApp: App {
    @StateObject private var flowState = AppFlowState()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        TrackingAuthorizationManager.requestTrackingAuthorizationIfNeeded()
        AdjustManager.shared.configureAdjust()
        RakutenRewardManager.shared.configureIfNeeded()
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
            case .background:
                AdjustManager.shared.setOfflineMode(true)
            default:
                break
            }
        }
    }
}
