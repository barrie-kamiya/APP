import Foundation
import RakutenRewardSDK

final class RakutenRewardManager {
    static let shared = RakutenRewardManager()

    private let appKey = "anAuY28ucmFrdXRlbi5yZXdhcmQuaW9zLUd1YkVra2tmV3UwdXFSLVdIbzFIOHhVLUNuNkhqd1V0"
    private let actionCode = "9~J__RX~JOK~_JS~"
    private let dailyLimit = 30
    private let dailyCountKey = "rakutenRewardDailyCount"
    private let lastResetDateKey = "rakutenRewardLastResetDate"
    private let defaults = UserDefaults.standard
    private let calendar = Calendar(identifier: .gregorian)
    private var hasStartedSession = false
    private let queue = DispatchQueue(label: "jp.forestcymbalmusicapp.rakuten-reward", qos: .userInitiated)

    private init() {}

    func configureIfNeeded() {
        guard !hasStartedSession else { return }
        hasStartedSession = true
        queue.async { [appKey] in
            RakutenReward.sharedInstance.isDebug = false
            RakutenReward.sharedInstance.environment = .production
            RakutenReward.sharedInstance.startSession(appCode: appKey)
        }
    }

    func openPortal() {
        configureIfNeeded()
        DispatchQueue.main.async {
            RakutenReward.sharedInstance.openPortal()
        }
    }

    func trackGameClearAction() {
        configureIfNeeded()
        guard shouldTriggerAction() else { return }
        RakutenReward.sharedInstance.logAction(actionCode: actionCode)
        incrementDailyCount()
    }

    private func shouldTriggerAction() -> Bool {
        resetIfNeeded()
        let current = defaults.integer(forKey: dailyCountKey)
        return current < dailyLimit
    }

    private func incrementDailyCount() {
        resetIfNeeded()
        let current = defaults.integer(forKey: dailyCountKey)
        defaults.set(current + 1, forKey: dailyCountKey)
    }

    private func resetIfNeeded() {
        let today = Date()
        if let last = defaults.object(forKey: lastResetDateKey) as? Date {
            if !calendar.isDate(today, inSameDayAs: last) {
                defaults.set(today, forKey: lastResetDateKey)
                defaults.set(0, forKey: dailyCountKey)
            }
        } else {
            defaults.set(today, forKey: lastResetDateKey)
            defaults.set(0, forKey: dailyCountKey)
        }
    }
}
