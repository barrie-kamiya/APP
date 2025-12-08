import SwiftUI

struct SplashView: View {
    let onFinish: () -> Void

    var body: some View {
        ZStack {
            AdaptiveBackgroundImage(imageName: "Splash")
        }
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture {
            onFinish()
        }
    }
}
