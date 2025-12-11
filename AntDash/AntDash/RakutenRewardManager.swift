import Foundation
import RakutenRewardSDK

final class RakutenRewardManager {
    static let shared = RakutenRewardManager()

    private let appCode = "anAuY28ucmFrdXRlbi5yZXdhcmQuaW9zLUVqMGZ0WFRZamxHLTJMQ3NLU0t5QWJSQUZvQ3pUQ05Y"
    private let clearActionCode = "E-pCFcIYfV3B1EDQ"
    private var hasConfigured = false

    private init() {}

    func configureIfNeeded() {
        guard !hasConfigured else { return }
        RakutenReward.sharedInstance.isDebug = false
        RakutenReward.sharedInstance.environment = .production
        RakutenReward.sharedInstance.startSession(appCode: appCode)
        hasConfigured = true
    }

    func openPortal() {
        RakutenReward.sharedInstance.openPortal()
    }

    func logClearAction() {
        RakutenReward.sharedInstance.logAction(actionCode: clearActionCode)
    }
}
