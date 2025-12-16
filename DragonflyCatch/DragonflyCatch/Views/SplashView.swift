import SwiftUI

struct SplashView: View {
    var onTap: () -> Void

    var body: some View {
        FittedBackgroundImage(imageName: "Splash")
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }
    }
}
