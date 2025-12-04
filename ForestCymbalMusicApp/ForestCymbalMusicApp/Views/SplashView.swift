import SwiftUI

struct SplashView: View {
    var onTap: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Image("Splash")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .accessibilityLabel(Text("スプラッシュ"))
    }
}
