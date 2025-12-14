import SwiftUI
import UIKit

enum DeviceTraitHelper {
    static func isPad(for size: CGSize) -> Bool {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            return true
        }
        #endif
        return max(size.width, size.height) >= 1024
    }

    static func primaryPadding(for size: CGSize) -> CGFloat {
        isPad(for: size) ? 32 : 16
    }
}
