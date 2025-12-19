import SwiftUI

struct AchievementView: View {
    let context: LayoutContext
    let clearImageName: String?
    let onClose: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let name = clearImageName {
                BackgroundImageView(name: name, isPadLayout: context.isPadLayout)
            } else {
                Color.white.ignoresSafeArea()
            }

            Button("戻る") {
                onClose()
            }
            .font(.system(size: context.isPadLayout ? 16 : 14, weight: .semibold))
            .foregroundColor(.black)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.85))
            .cornerRadius(8)
            .padding(.trailing, 16)
            .padding(.top, 16)
        }
    }
}
