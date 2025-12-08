import SwiftUI

struct SplashView: View {
    let onFinish: () -> Void
    @Environment(\.isPadLayout) private var isPadLayout

    var body: some View {
        ZStack {
            AdaptiveBackgroundImage(imageName: "Splash")
        }
        .ignoresSafeArea(isPadLayout ? [] : .all)
        .contentShape(Rectangle())
        .onTapGesture {
            onFinish()
        }
    }
}
