import SwiftUI

@main
struct AntDashApp: App {
    @StateObject private var flowState = AppFlowState()

    var body: some Scene {
        WindowGroup {
            FlowCoordinatorView()
                .environmentObject(flowState)
        }
    }
}
