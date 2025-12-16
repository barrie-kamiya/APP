import Foundation
import RakutenRewardSDK

final class RakutenRewardManager {
    static let shared = RakutenRewardManager()

    private let appCode = "anAuY28ucmFrdXRlbi5yZXdhcmQuaW9zLUJhNldSUEF0UERWQXNkVk1MZDFfTGFTQ3FsUldFM3Za"
    private let actionCode = "uObnevhxwtaKXDjz"
    private var sessionStarted = false

    private init() {}

    func configure() {
        startSessionIfNeeded()
    }

    func openPortal() {
        startSessionIfNeeded()
        DispatchQueue.main.async {
            RakutenReward.sharedInstance.openPortal()
        }
    }

    func logClearAction() {
        startSessionIfNeeded()
        RakutenReward.sharedInstance.logAction(actionCode: actionCode)
    }

    private func startSessionIfNeeded() {
        guard !sessionStarted else { return }
        RakutenReward.sharedInstance.isDebug = false
        RakutenReward.sharedInstance.environment = .production
        RakutenReward.sharedInstance.startSession(appCode: appCode)
        sessionStarted = true
    }
}
