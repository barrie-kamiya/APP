import Foundation
import RakutenRewardSDK

final class RakutenRewardManager {
    static let shared = RakutenRewardManager()

    private let appCode = "anAuY28ucmFrdXRlbi5yZXdhcmQuaW9zLTNZUzBCSEZjd3FYYUIzNmFZTDJRNk5RSzRwTG1hTDNq"
    private let actionCode = "QanLvltS9vhF0gIb"
    private let dailyLimit = 30
    private let dailyCountKey = "rakutenRewardDailyCount"
    private let lastResetDateKey = "rakutenRewardLastResetDate"
    private let defaults = UserDefaults.standard
    private let calendar = Calendar(identifier: .gregorian)

    private init() {}

    func configure() {
        RakutenReward.sharedInstance.isDebug = false
        RakutenReward.sharedInstance.environment = .production
        RakutenReward.sharedInstance.startSession(appCode: appCode)
    }

    func trackCycleCompletion() {
        guard shouldTriggerAction() else { return }
        RakutenReward.sharedInstance.logAction(actionCode: actionCode)
        incrementDailyCount()
    }

    func openPortal() {
        RakutenReward.sharedInstance.openPortal()
    }

    private func shouldTriggerAction() -> Bool {
        resetIfNeeded()
        let count = defaults.integer(forKey: dailyCountKey)
        return count < dailyLimit
    }

    private func incrementDailyCount() {
        resetIfNeeded()
        let count = defaults.integer(forKey: dailyCountKey)
        defaults.set(count + 1, forKey: dailyCountKey)
    }

    private func resetIfNeeded() {
        let today = Date()
        guard let last = defaults.object(forKey: lastResetDateKey) as? Date else {
            defaults.set(today, forKey: lastResetDateKey)
            defaults.set(0, forKey: dailyCountKey)
            return
        }

        if !calendar.isDate(today, inSameDayAs: last) {
            defaults.set(today, forKey: lastResetDateKey)
            defaults.set(0, forKey: dailyCountKey)
        }
    }
}
