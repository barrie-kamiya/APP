import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct DeviceLayoutResolver {
    private static let phoneWidthToHeightRatio: CGFloat = 9.0 / 16.0
    private static let maxPadContentWidthScale: CGFloat = 0.78

    static func isPadLayout(for size: CGSize) -> Bool {
        let shortSide = min(size.width, size.height)
        if shortSide >= 500 {
            return true
        }
        return actualPadDevice
    }

    static func contentWidth(for size: CGSize, isPadLayout: Bool) -> CGFloat {
        guard isPadLayout else { return size.width }
        let widthBasedOnHeight = size.height * Self.phoneWidthToHeightRatio
        let maxWidth = size.width * Self.maxPadContentWidthScale
        return min(max(widthBasedOnHeight, 320), maxWidth)
    }

    private static var actualPadDevice: Bool {
#if canImport(UIKit)
        let idiomIsPad = UIDevice.current.userInterfaceIdiom == .pad
        let modelIndicatesPad = UIDevice.current.model.lowercased().contains("ipad")
        return idiomIsPad || modelIndicatesPad
#else
        return false
#endif
    }
}

private struct PadLayoutEnvironmentKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var isPadLayout: Bool {
        get { self[PadLayoutEnvironmentKey.self] }
        set { self[PadLayoutEnvironmentKey.self] = newValue }
    }
}
