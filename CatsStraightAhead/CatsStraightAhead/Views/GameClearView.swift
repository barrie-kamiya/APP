import SwiftUI

struct GameClearView: View {
    let backgroundImageName: String
    let onFinish: () -> Void
    @Environment(\.isPadLayout) private var isPadLayout

    var body: some View {
        ZStack {
            AdaptiveBackgroundImage(imageName: backgroundImageName)
            Color.black.opacity(0.15)
                .ignoresSafeArea(isPadLayout ? [] : .all)
            VStack {
                Spacer()
                Button(action: onFinish) {
                    Image("OK")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
    }
}
