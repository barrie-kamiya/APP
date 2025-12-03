import Foundation
import Adjust

final class AdjustManager {
    static let shared = AdjustManager()

    private init() {}

    private let appToken = "ky5nhtvqk268"
    private let environment = ADJEnvironmentProduction
    private let installDateKey = "adjustInstallDate"

    private enum EventToken: String {
        case cycle1 = "8833hv"
        case cycle50 = "uui7hv"
        case cycle100 = "7u84g6"
        case cycle150 = "seelav"
    }

    func configureAdjust() {
        guard let config = ADJConfig(appToken: appToken, environment: environment) else {
            return
        }

        registerInstallDateIfNeeded()

        config.logLevel = ADJLogLevelInfo
        config.sendInBackground = true

        Adjust.appDidLaunch(config)
    }

    func setOfflineMode(_ isOffline: Bool) {
        Adjust.setOfflineMode(isOffline)
    }

    func trackGameCycleCompletion(total cycles: Int) {
        switch cycles {
        case 1:
            track(event: .cycle1)
        case 50:
            track(event: .cycle50)
        case 100:
            track(event: .cycle100)
        case 150:
            if shouldTrackCycle150() {
                track(event: .cycle150)
            }
        default:
            break
        }
    }

    private func track(event: EventToken) {
        guard let adjustEvent = ADJEvent(eventToken: event.rawValue) else { return }
        Adjust.trackEvent(adjustEvent)
    }

    private func registerInstallDateIfNeeded() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: installDateKey) == nil {
            defaults.set(Date(), forKey: installDateKey)
        }
    }

    private func shouldTrackCycle150() -> Bool {
        let defaults = UserDefaults.standard
        guard let storedDate = defaults.object(forKey: installDateKey) as? Date else {
            return true
        }

        let elapsed = Date().timeIntervalSince(storedDate)
        let threeDays: TimeInterval = 3 * 24 * 60 * 60
        return elapsed <= threeDays
    }
}
