import Foundation
#if canImport(UIKit)
import UIKit
#endif
#if canImport(FiveAd)
import FiveAd
#endif

final class FiveAdManager {
    static let shared = FiveAdManager()

    private init() {}

    func configureIfNeeded() {
#if canImport(FiveAd)
        guard !FADSettings.isConfigRegistered() else { return }
        guard let config = FADConfig.loadFromInfoDictionary() else {
#if DEBUG
            print("[FiveAd] FIVE_APP_ID is not configured")
#endif
            return
        }
        FADSettings.register(config)
#endif
    }
}

final class FiveAdBannerLoader: NSObject {
    static let shared = FiveAdBannerLoader()

#if canImport(FiveAd)
    private let slotId = "69770687"
    private var preloadedAd: FADAdViewCustomLayout?
    private var loadingAd: FADAdViewCustomLayout?
    private var isLoading = false
    private var lastRequestedWidth: Float = 320
#endif

    private override init() {
        super.init()
    }

    func preloadBannerIfNeeded(width: Float) {
#if canImport(FiveAd)
        lastRequestedWidth = width
        guard preloadedAd == nil, !isLoading else { return }
        startLoading(width: width)
#endif
    }

    func takePreparedBanner(width: Float) -> UIView? {
#if canImport(FiveAd)
        lastRequestedWidth = width
        if let ad = preloadedAd {
            preloadedAd = nil
            preloadBannerIfNeeded(width: width)
            return ad
        }
        preloadBannerIfNeeded(width: width)
#endif
        return nil
    }

#if canImport(FiveAd)
    private func startLoading(width: Float) {
        guard !isLoading else { return }
        isLoading = true
        let ad = FADAdViewCustomLayout(slotId: slotId, width: width)
        ad?.setLoadDelegate(self)
        loadingAd = ad
        ad?.loadAdAsync()
    }
#endif
}

#if canImport(FiveAd)
extension FiveAdBannerLoader: FADLoadDelegate {
    func fiveAdDidLoad(_ ad: FADAdInterface!) {
        guard let loadingAd = loadingAd as? FADAdViewCustomLayout else { return }
        preloadedAd = loadingAd
        self.loadingAd = nil
        isLoading = false
    }

    func fiveAd(_ ad: FADAdInterface!, didFailedToReceiveAdWithError errorCode: FADErrorCode) {
#if DEBUG
        print("[FiveAd] Preload failed: errorCode=\(errorCode.rawValue)")
#endif
        loadingAd = nil
        isLoading = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self else { return }
            self.startLoading(width: self.lastRequestedWidth)
        }
    }
}
#endif
