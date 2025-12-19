import SwiftUI

struct SplashView: View {
    let context: LayoutContext
    let onTap: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            BackgroundImageView(name: "Splash", isPadLayout: context.isPadLayout)
                .contentShape(Rectangle())
                .onTapGesture {
                    onTap()
                }
                .frame(width: size.width, height: size.height)
        }
    }
}
