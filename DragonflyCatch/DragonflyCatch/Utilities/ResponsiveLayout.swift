import SwiftUI
import UIKit

/// デバイスをiPhone/iPad相当で判定するための区分。
enum LayoutDevice {
    case phone
    case pad

    static func resolve(for size: CGSize) -> LayoutDevice {
        DeviceTraitHelper.isPad(for: size) ? .pad : .phone
    }
}

/// 画面サイズに対する相対座標・サイズをまとめた構造体。
struct RelativeFrame {
    var xPercent: CGFloat
    var yPercent: CGFloat
    var widthPercent: CGFloat
    var heightPercent: CGFloat

    func rect(in size: CGSize) -> CGRect {
        let clampedX = clamp(xPercent)
        let clampedY = clamp(yPercent)
        let clampedWidth = clamp(widthPercent)
        let clampedHeight = clamp(heightPercent)
        let width = size.width * clampedWidth
        let height = size.height * clampedHeight
        let centerX = size.width * clampedX
        let centerY = size.height * clampedY
        return CGRect(x: centerX - width / 2, y: centerY - height / 2, width: width, height: height)
    }

    private func clamp(_ value: CGFloat) -> CGFloat {
        min(max(value, 0), 1)
    }
}

/// デバイス種別ごとに異なるレイアウト値を保持する。
struct ResponsiveFrame {
    var phone: RelativeFrame
    var pad: RelativeFrame

    func rect(for device: LayoutDevice, in size: CGSize) -> CGRect {
        switch device {
        case .phone:
            return phone.rect(in: size)
        case .pad:
            return pad.rect(in: size)
        }
    }
}

/// 値そのものをiPhone/iPadで分岐させたい場合に利用。
struct DeviceAdaptiveValue<Value> {
    var phone: Value
    var pad: Value

    func value(for device: LayoutDevice) -> Value {
        switch device {
        case .phone:
            return phone
        case .pad:
            return pad
        }
    }
}

extension View {
    /// 相対レイアウトから算出されたCGRectに合わせて表示する。
    func positioned(in rect: CGRect) -> some View {
        frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
    }
}
