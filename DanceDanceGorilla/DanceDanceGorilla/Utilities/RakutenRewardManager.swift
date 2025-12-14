import Foundation
import RakutenRewardSDK

final class RakutenRewardManager {
    static let shared = RakutenRewardManager()

    private let appKey = "anAuY28ucmFrdXRlbi5yZXdhcmQuaW9zLX5JaU5NUnVOWjdHRUJEQXlVYjlGendHT0lZNXF+b2Vj"
    private let clearActionCode = "kdc2Hvt9t2M5~OAG"
    private let dailyLimit = 30
    private let dailyCountKey = "rakutenRewardClearDailyCount"
    private let lastResetDateKey = "rakutenRewardClearLastReset"
    private let defaults = UserDefaults.standard
    private let calendar = Calendar(identifier: .gregorian)
    private var isConfigured = false

    private init() {}

    func configure() {
        guard FeatureFlags.isRakutenRewardEnabled, !isConfigured else { return }
        RakutenReward.sharedInstance.isDebug = false
        RakutenReward.sharedInstance.environment = .production
        RakutenReward.sharedInstance.startSession(appCode: appKey)
        isConfigured = true
    }

    func openPortal() {
        guard FeatureFlags.isRakutenRewardEnabled else { return }
        configure()
        DispatchQueue.main.async {
            RakutenReward.sharedInstance.openPortal()
        }
    }

    func trackGameClearReward() {
        guard FeatureFlags.isRakutenRewardEnabled else { return }
        configure()
        guard shouldTriggerAction() else { return }
        RakutenReward.sharedInstance.logAction(actionCode: clearActionCode)
        incrementDailyCount()
    }

    private func shouldTriggerAction() -> Bool {
        resetIfNeeded()
        return defaults.integer(forKey: dailyCountKey) < dailyLimit
    }

    private func incrementDailyCount() {
        resetIfNeeded()
        let current = defaults.integer(forKey: dailyCountKey)
        defaults.set(current + 1, forKey: dailyCountKey)
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
