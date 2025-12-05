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

    private func backgroundLayer(size: CGSize) -> some View {
        ZStack {
            if isPadDevice {
                Color.black.ignoresSafeArea()
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size.width, height: size.height)
                    .clipped()
            } else {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .ignoresSafeArea()
            }
        }
    }

    private func okButtonWidth(for size: CGSize) -> CGFloat {
        let baseWidth = size.width * 0.6
        return isPadDevice ? baseWidth * 0.8 : baseWidth
    }

    private var okButtonVerticalRatio: CGFloat {
        isPadDevice ? 0.9 : 0.87
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
