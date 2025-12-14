import Foundation
import Adjust

final class AdjustManager {
    static let shared = AdjustManager()

    private init() {}

    private let appToken = "bfzsx6fttedc"
    private let environment = ADJEnvironmentProduction
    private let installDateKey = "ddg_adjust_install_date"

    private enum EventToken: String {
        case firstLoop = "h2euqw"
        case fiftyLoops = "vihvq4"
        case hundredLoops = "p3va86"
        case hundredFiftyLoops = "a6c5b9"
    }

    func configure() {
        guard let config = ADJConfig(appToken: appToken, environment: environment) else { return }

        registerInstallDateIfNeeded()

        config.logLevel = ADJLogLevelInfo
        config.sendInBackground = true

        Adjust.appDidLaunch(config)
    }

    func setOfflineMode(_ isOffline: Bool) {
        Adjust.setOfflineMode(isOffline)
    }

    func trackLoopCompletion(total loops: Int) {
        switch loops {
        case 1:
            track(event: .firstLoop)
        case 50:
            track(event: .fiftyLoops)
        case 100:
            track(event: .hundredLoops)
        case 150:
            if shouldTrackHundredFiftyLoop() {
                track(event: .hundredFiftyLoops)
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

    private func shouldTrackHundredFiftyLoop() -> Bool {
        let defaults = UserDefaults.standard
        guard let storedDate = defaults.object(forKey: installDateKey) as? Date else {
            return true
        }
        let elapsed = Date().timeIntervalSince(storedDate)
        let threeDays: TimeInterval = 3 * 24 * 60 * 60
        return elapsed <= threeDays
    }
}
