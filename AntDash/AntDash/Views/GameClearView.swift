import SwiftUI

struct GameClearView: View {
    let backgroundImageName: String
    let onFinish: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.ignoresSafeArea()
                Image(backgroundImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)

                VStack(spacing: 24) {
                    Spacer()
                    Button(action: onFinish) {
                        Image("OK")
                            .resizable()
                            .scaledToFit()
                            .frame(width: min(proxy.size.width * 0.6, 260),
                                   height: min(proxy.size.height * 0.12, 90))
                    }
                    .accessibilityLabel(Text("完了"))
                    .padding(.bottom, proxy.size.height * 0.05)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
