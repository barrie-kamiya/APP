import SwiftUI

struct IllustratedView: View {
    let context: LayoutContext
    let unlockedIllustrations: Set<String>
    let onClose: () -> Void
    @State private var selectedIllustration: String? = nil

    var body: some View {
        let allIllustrations = (1...10).map { String(format: "Ilustrated_%02d", $0) }
        let isAllUnlocked = allIllustrations.allSatisfy { unlockedIllustrations.contains($0) }
        let displayList = allIllustrations + (isAllUnlocked ? ["Ilustrated_none"] : [])

        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                Color.white.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: context.isPadLayout ? 24 : 16) {
                        ForEach(displayList, id: \.self) { name in
                            let isUnlocked = unlockedIllustrations.contains(name)
                            Button(action: {
                                guard isUnlocked else { return }
                                selectedIllustration = name
                            }) {
                                Image(isUnlocked ? name : "Ilustrated_none")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: context.isPadLayout ? 480 : 320)
                                    .opacity(isUnlocked ? 1.0 : 0.5)
                            }
                            .buttonStyle(.plain)
                            .disabled(!isUnlocked)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, context.isPadLayout ? 80 : 64)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }

                Button(action: onClose) {
                    Image("Close")
                        .resizable()
                        .scaledToFit()
                        .frame(width: context.isPadLayout ? 90 : 72,
                               height: context.isPadLayout ? 90 : 72)
                }
                .buttonStyle(.plain)
                .padding(.leading, 16)
                .padding(.top, 16)
                .zIndex(2)

                if let selected = selectedIllustration {
                    ZStack(alignment: .topTrailing) {
                        Color.black.opacity(0.7)
                            .ignoresSafeArea()
                            .onTapGesture {
                                selectedIllustration = nil
                            }

                        VStack(spacing: 10) {
                            Text("左右にスワイプして全体を表示できます")
                                .font(.footnote)
                                .foregroundColor(.white)
                                .padding(.top, proxy.safeAreaInsets.top + 12)

                            ScrollView(.horizontal, showsIndicators: false) {
                                Image(selected)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: proxy.size.width * 1.6,
                                           height: proxy.size.height * 0.7)
                                    .padding(.horizontal, 32)
                            }
                            .frame(height: proxy.size.height * 0.7)

                            Button(action: { selectedIllustration = nil }) {
                                Image("Close")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: context.isPadLayout ? 220 : 180,
                                           height: context.isPadLayout ? 220 : 180)
                                    .padding(.bottom, proxy.safeAreaInsets.bottom + 20)
                            }
                        }
                    }
                    .zIndex(3)
                }
            }
        }
    }
}
