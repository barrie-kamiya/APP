import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct GameView: View {
    var stage: Int
    var tapCount: Int
    var targetTapCount: Int
    var vibrationEnabled: Bool
    var characterName: String
    var onTapArea: () -> Void

    private var progress: Double {
        Double(tapCount) / Double(targetTapCount)
    }

    @State private var showPoseA: Bool = true

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                backgroundLayer(for: proxy.size)

                characterView
                    .frame(width: proxy.size.width * 0.6, height: 180)
                    .position(x: proxy.size.width / 2,
                              y: proxy.size.height * characterPositionRatio)

                Button(action: {
                    triggerHapticIfNeeded()
                    showPoseA = true
                    onTapArea()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                        withAnimation(.easeInOut(duration: 0.08)) {
                            showPoseA = false
                        }
                    }
                }) {
                    Image("Tap")
                        .resizable()
                        .scaledToFit()
                        .frame(width: proxy.size.width * tapButtonWidthRatio)
                }
                .contentShape(Rectangle())
                .position(x: proxy.size.width / 2,
                          y: proxy.size.height * tapButtonPositionRatio)
                .edgesIgnoringSafeArea(.bottom)

                remainingTapIndicator
                    .padding(.top, 16)
                    .padding(.leading, 16)
            }
        }
    }

    private func triggerHapticIfNeeded() {
#if canImport(UIKit)
        guard vibrationEnabled else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
#endif
    }

    private var characterView: some View {
        Image(characterImageName)
            .resizable()
            .scaledToFit()
            .frame(height: 140)
            .shadow(radius: 6)
            .accessibilityHidden(true)
    }

    private var characterImageName: String {
        let suffix = showPoseA ? "_A" : "_B"
        return "\(characterName)\(suffix)"
    }

    private var remainingTapIndicator: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("完了まで")
            Text("あと")
            Text("\(remainingTaps)")
                .font(.title2.bold())
        }
        .font(.headline)
        .foregroundColor(.black)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.9))
        .cornerRadius(12)
        .shadow(radius: 4)
    }

    private var remainingTaps: Int {
        max(targetTapCount - tapCount, 0)
    }

    private var tapButtonWidthRatio: CGFloat {
        #if canImport(UIKit)
        return UIDevice.current.userInterfaceIdiom == .pad ? 0.5 : 0.75
        #else
        return 0.75
        #endif
    }

    private var characterPositionRatio: CGFloat {
        #if canImport(UIKit)
        return UIDevice.current.userInterfaceIdiom == .pad ? 0.14 : 0.16
        #else
        return 0.15
        #endif
    }

    private var tapButtonPositionRatio: CGFloat {
        #if canImport(UIKit)
        return UIDevice.current.userInterfaceIdiom == .pad ? 0.77 : 0.79
        #else
        return 0.78
        #endif
    }

    private var backgroundImage: Image {
        let name: String
        switch stage {
        case 1: name = "Game_01"
        case 2: name = "Game_02"
        case 3: name = "Game_03"
        case 4: name = "Game_04"
        case 5: name = "Game_05"
        default: name = "Game_06"
        }
        return Image(name)
    }

    @ViewBuilder
    private func backgroundLayer(for size: CGSize) -> some View {
#if canImport(UIKit)
        if UIDevice.current.userInterfaceIdiom == .pad {
            Color.black
                .ignoresSafeArea()
            backgroundImage
                .resizable()
                .scaledToFit()
                .frame(width: min(size.width * 0.78, 820))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            backgroundImage
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
#else
        backgroundImage
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
#endif
    }
}
