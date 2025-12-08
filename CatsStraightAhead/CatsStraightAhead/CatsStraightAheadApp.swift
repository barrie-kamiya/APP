import SwiftUI

@main
struct CatsStraightAheadApp: App {
    @StateObject private var flowState = AppFlowState()

    var body: some Scene {
        WindowGroup {
            FlowCoordinatorView()
                .environmentObject(flowState)
        }
    }
}
