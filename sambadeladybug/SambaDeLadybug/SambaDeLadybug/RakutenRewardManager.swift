import Foundation

#if canImport(RakutenRewardSDK)
import RakutenRewardSDK
#endif

final class RakutenRewardManager {
    static let shared = RakutenRewardManager()

    private let appKey = "anAuY28ucmFrdXRlbi5yZXdhcmQuaW9zLXpyUENiMWNTZDJ4Rlk4UU8wflNDYTg4a3VubTYwZlVv"
    private let missionActionCode = "h5vJfiWkAZKtRTEi"
    private let missionDailyLimit = 25
    private let missionDailyCountKey = "rakutenRewardMissionDailyCount"
    private let missionLastResetDateKey = "rakutenRewardMissionLastResetDate"
    private let defaults = UserDefaults.standard
    private let calendar = Calendar(identifier: .gregorian)

    private init() {}

    func configure() {
        #if canImport(RakutenRewardSDK)
        RakutenReward.sharedInstance.isDebug = false
        RakutenReward.sharedInstance.environment = .production
        RakutenReward.sharedInstance.startSession(appCode: appKey)
        #endif
    }

    func openPortal() {
        #if canImport(RakutenRewardSDK)
        RakutenReward.sharedInstance.openPortal()
        #endif
    }

    func triggerMissionActionIfNeeded() {
        #if canImport(RakutenRewardSDK)
        guard shouldTriggerMissionAction() else { return }
        RakutenReward.sharedInstance.logAction(actionCode: missionActionCode)
        incrementMissionDailyCount()
        #endif
    }

    private func shouldTriggerMissionAction() -> Bool {
        resetMissionCountIfNeeded()
        let count = defaults.integer(forKey: missionDailyCountKey)
        return count < missionDailyLimit
    }

    private func incrementMissionDailyCount() {
        resetMissionCountIfNeeded()
        let count = defaults.integer(forKey: missionDailyCountKey)
        defaults.set(count + 1, forKey: missionDailyCountKey)
    }

    private func resetMissionCountIfNeeded() {
        let today = Date()
        guard let last = defaults.object(forKey: missionLastResetDateKey) as? Date else {
            defaults.set(today, forKey: missionLastResetDateKey)
            defaults.set(0, forKey: missionDailyCountKey)
            return
        }

        if !calendar.isDate(today, inSameDayAs: last) {
            defaults.set(today, forKey: missionLastResetDateKey)
            defaults.set(0, forKey: missionDailyCountKey)
        }
    }
}
