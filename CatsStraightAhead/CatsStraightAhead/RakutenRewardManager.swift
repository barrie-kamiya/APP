import Foundation
import RakutenRewardSDK

final class RakutenRewardManager {
    static let shared = RakutenRewardManager()

    private let appKey = "anAuY28ucmFrdXRlbi5yZXdhcmQuaW9zLUd1YkVra2tmV3UwdXFSLVdIbzFIOHhVLUNuNkhqd1V0"
    private let clearActionCode = "9~J__RX~JOK~_JS~"
    private var hasStartedSession = false

    private init() {}

    func configureIfNeeded() {
        guard !hasStartedSession else { return }
        hasStartedSession = true
        RakutenReward.sharedInstance.isDebug = false
        RakutenReward.sharedInstance.environment = .production
        RakutenReward.sharedInstance.startSession(appCode: appKey)
    }

    func openPortal() {
        configureIfNeeded()
        RakutenReward.sharedInstance.openPortal()
    }

    func logClearAction() {
        configureIfNeeded()
        RakutenReward.sharedInstance.logAction(actionCode: clearActionCode)
    }
}
