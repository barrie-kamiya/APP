import SwiftUI

struct SplashView: View {
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Image("Splash")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
            .contentShape(Rectangle())
            .onTapGesture {
                onContinue()
            }
    }
}
