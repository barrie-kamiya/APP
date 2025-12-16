import SwiftUI
import UIKit

enum DeviceTraitHelper {
    static func isPad(for size: CGSize) -> Bool {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            return true
        }
        #endif
        return longestSide(for: size) >= 1024
    }

    static func longestSide(for size: CGSize) -> CGFloat {
        max(size.width, size.height)
    }
}
