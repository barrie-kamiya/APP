import SwiftUI

struct SplashView: View {
    let onProceed: () -> Void

    var body: some View {
        ZStack {
            AspectFitBackground(imageName: "Splash")
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    onProceed()
                }
        }
    }
}

#Preview {
    SplashView(onProceed: {})
}
