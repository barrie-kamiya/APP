import SwiftUI

struct GameClearView: View {
    let context: LayoutContext
    let backgroundName: String
    let onFinish: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let layout = LayoutConfig.gameClear(isPad: context.isPadLayout)
            let size = proxy.size
            ZStack {
                BackgroundImageView(name: backgroundName, isPadLayout: context.isPadLayout)

                Button(action: onFinish) {
                    Image("OK")
                        .resizable()
                        .scaledToFit()
                }
                .frame(width: context.isPadLayout ? 200 : 160, height: context.isPadLayout ? 64 : 52)
                .position(LayoutConfig.point(layout.finishButton, in: size))
            }
            .frame(width: size.width, height: size.height)
        }
    }
}
