import Foundation
import AppTrackingTransparency
import AdSupport

enum TrackingAuthorizationManager {
    static func requestTrackingAuthorizationIfNeeded() {
        guard #available(iOS 14.5, *) else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            ATTrackingManager.requestTrackingAuthorization { _ in }
        }
    }
}
