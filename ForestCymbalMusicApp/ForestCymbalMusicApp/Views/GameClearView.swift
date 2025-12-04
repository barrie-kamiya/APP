import SwiftUI

struct GameClearView: View {
    var imageName: String
    var onFinish: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                backgroundLayer(size: proxy.size)

                Button(action: onFinish) {
                    Image("OK")
                        .resizable()
                        .scaledToFit()
                        .frame(width: okButtonWidth(for: proxy.size))
                        .accessibilityLabel("完了")
                }
                .position(x: proxy.size.width / 2,
                          y: proxy.size.height * okButtonVerticalRatio)
            }
        }
    }

    @ViewBuilder
    private func backgroundLayer(size: CGSize) -> some View {
#if canImport(UIKit)
        if isPadDevice {
            Color.black
                .ignoresSafeArea()
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: min(size.width * 0.78, 820))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
#else
        Image(imageName)
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
#endif
    }

    private func okButtonWidth(for size: CGSize) -> CGFloat {
        let baseWidth = size.width * 0.6
        return isPadDevice ? baseWidth * 0.8 : baseWidth
    }

    private var okButtonVerticalRatio: CGFloat {
        isPadDevice ? 0.9 : 0.93
    }
}

#if canImport(UIKit)
private var isPadDevice: Bool {
    let idiomIsPad = UIDevice.current.userInterfaceIdiom == .pad
    let modelIndicatesPad = UIDevice.current.model.lowercased().contains("ipad")
    return idiomIsPad || modelIndicatesPad
}
#else
private let isPadDevice = false
#endif
