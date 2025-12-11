import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(FiveAd)
import FiveAd
#endif

enum FiveAdVideoRewardResult {
    case completed
    case failed(FiveAdVideoRewardError)
}

struct FiveAdVideoRewardError: LocalizedError {
    enum ErrorKind {
        case load(code: Int?)
        case show(code: Int?)
        case presenterMissing
        case unavailable
    }

    let kind: ErrorKind

    var errorDescription: String? {
        switch kind {
        case .load:
            return "広告の読み込みに失敗しました。時間を置いて再試行してください。"
        case .show:
            return "広告の表示に失敗しました。通信環境をご確認ください。"
        case .presenterMissing:
            return "表示先を取得できませんでした。アプリを再起動して再度お試しください。"
        case .unavailable:
            return "広告モジュールが無効のため表示できません。"
        }
    }
}

final class FiveAdVideoRewardManager: NSObject {
    static let shared = FiveAdVideoRewardManager()

#if canImport(FiveAd)
    private let slotId = "39055329"
    private var rewardAd: FADVideoReward?
    private var completion: ((FiveAdVideoRewardResult) -> Void)?
    private var isLoading = false
    private var isShowing = false
    private var isAdReady = false
    private var shouldAutoShowOnLoad = false
    private var currentRetryCount = 0
    private let maxRetryCount = 2
#endif

    private override init() {
        super.init()
    }

    func preloadRewardIfNeeded(force: Bool = false) {
#if canImport(FiveAd)
        DispatchQueue.main.async {
            if force {
                self.resetAdState()
            }
            guard !self.isLoading, !self.isAdReady else { return }
            self.startLoading(resetRetryCount: true)
        }
#endif
    }

    func presentRewardAd(onFinish: @escaping (FiveAdVideoRewardResult) -> Void) {
#if canImport(FiveAd)
        DispatchQueue.main.async {
            self.completion = onFinish
            guard !self.isShowing else { return }
            if self.isAdReady, let ad = self.rewardAd {
                self.shouldAutoShowOnLoad = false
                self.show(ad: ad)
            } else {
                self.shouldAutoShowOnLoad = true
                if !self.isLoading {
                    self.startLoading(resetRetryCount: true)
                }
            }
        }
#else
        onFinish(.failed(FiveAdVideoRewardError(kind: .unavailable)))
#endif
    }

    func cancelPendingPresentation() {
#if canImport(FiveAd)
        DispatchQueue.main.async {
            self.completion = nil
            self.resetAdState()
        }
#endif
    }

#if canImport(FiveAd)
    private func startLoading(resetRetryCount: Bool = false) {
        guard !isLoading else { return }
        if resetRetryCount { currentRetryCount = 0 }
        isLoading = true
        isAdReady = false
        let ad = FADVideoReward(slotId: slotId)
        ad?.setLoadDelegate(self)
        ad?.setEventListener(self)
        rewardAd = ad
        ad?.loadAdAsync()
    }

    private func show(ad: FADVideoReward) {
        guard !isShowing else { return }
        guard let presenter = Self.topViewController() else {
            finish(with: .failed(FiveAdVideoRewardError(kind: .presenterMissing)))
            resetAdState()
            return
        }
        isShowing = true
        isAdReady = false
        shouldAutoShowOnLoad = false
        currentRetryCount = 0
        ad.show(with: presenter)
    }

    private static func topViewController(from root: UIViewController? = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap { $0.windows }
        .first { $0.isKeyWindow }?.rootViewController) -> UIViewController? {
        if let presented = root?.presentedViewController {
            return topViewController(from: presented)
        }
        if let nav = root as? UINavigationController {
            return topViewController(from: nav.visibleViewController)
        }
        if let tab = root as? UITabBarController {
            return topViewController(from: tab.selectedViewController)
        }
        return root
    }

    private func finish(with result: FiveAdVideoRewardResult) {
        completion?(result)
        completion = nil
    }

    private func resetAdState() {
        rewardAd?.setLoadDelegate(nil)
        rewardAd?.setEventListener(nil)
        rewardAd = nil
        isLoading = false
        isShowing = false
        isAdReady = false
        shouldAutoShowOnLoad = false
        currentRetryCount = 0
    }
#endif
}

#if canImport(FiveAd)
extension FiveAdVideoRewardManager: FADLoadDelegate, FADVideoRewardEventListener {
    func fiveAdDidLoad(_ ad: FADAdInterface!) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.isAdReady = true
            self.currentRetryCount = 0
            guard self.shouldAutoShowOnLoad, let rewardAd = self.rewardAd else { return }
            self.show(ad: rewardAd)
        }
    }

    func fiveAd(_ ad: FADAdInterface!, didFailedToReceiveAdWithError errorCode: FADErrorCode) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.isShowing = false
            self.isAdReady = false
            if self.currentRetryCount < self.maxRetryCount {
                self.currentRetryCount += 1
                let delay = DispatchTimeInterval.seconds(1 * self.currentRetryCount)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    self.startLoading(resetRetryCount: false)
                }
            } else {
                self.finish(with: .failed(FiveAdVideoRewardError(kind: .load(code: errorCode.rawValue))))
                self.resetAdState()
            }
        }
    }

    func fiveVideoRewardAd(_ ad: FADVideoReward, didFailedToShowAdWithError errorCode: FADErrorCode) {
        DispatchQueue.main.async {
            self.finish(with: .failed(FiveAdVideoRewardError(kind: .show(code: errorCode.rawValue))))
            self.resetAdState()
        }
    }

    func fiveVideoRewardAdFullScreenDidClose(_ ad: FADVideoReward) {
        DispatchQueue.main.async {
            self.finish(with: .completed)
            self.resetAdState()
            self.preloadRewardIfNeeded()
        }
    }

    func fiveVideoRewardAdDidReward(_ ad: FADVideoReward) {}
}
#endif
