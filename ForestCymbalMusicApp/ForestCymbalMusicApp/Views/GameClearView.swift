import SwiftUI

struct GameClearView: View {
    var imageName: String
    var onFinish: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                backgroundLayer(size: proxy.size)

                VStack {
                    Spacer()
                    Button(action: onFinish) {
                        Image("OK")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .accessibilityLabel("完了")
                    }
                    .padding(.bottom, 80)
                }
            }
        }
    }

    @ViewBuilder
    private func backgroundLayer(size: CGSize) -> some View {
#if canImport(UIKit)
        if UIDevice.current.userInterfaceIdiom == .pad {
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
}
