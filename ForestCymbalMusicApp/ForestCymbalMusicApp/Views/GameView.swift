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
                              showPoseA.toggle()
                              onTapArea()
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
                    .frame(width: proxy.size.width * statusWidthRatio)
                    .position(x: proxy.size.width * statusPositionXRatio,
                              y: proxy.size.height * statusPositionYRatio)
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
                .font(statusCountFont)
        }
        .font(statusLabelFont)
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
        return isPadDevice ? 0.6 : 0.75
    }

    private var characterPositionRatio: CGFloat {
        return isPadDevice ? 0.17 : 0.2
    }

    private var tapButtonPositionRatio: CGFloat {
        return isPadDevice ? 0.77 : 0.74
    }

    private var statusPositionXRatio: CGFloat {
        isPadDevice ? 0.22 : 0.17
    }

    private var statusPositionYRatio: CGFloat {
        isPadDevice ? 0.1 : 0.12
    }

    private var statusWidthRatio: CGFloat {
        isPadDevice ? 0.3 : 0.6
    }

    private var statusLabelFont: Font {
        isPadDevice ? .caption : .subheadline
    }

    private var statusCountFont: Font {
        isPadDevice ? .headline.bold() : .title3.weight(.semibold)
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

    private func backgroundLayer(for size: CGSize) -> some View {
        ZStack {
            if isPadDevice {
                Color.black.ignoresSafeArea()
                backgroundImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: size.width, height: size.height)
                    .clipped()
            } else {
                backgroundImage
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .ignoresSafeArea()
            }
        }
    }
}

#if canImport(UIKit)
private var isPadDevice: Bool {
    let idiomIsPad = UIDevice.current.userInterfaceIdiom == .pad
    let modelIndicatesPad = UIDevice.current.model.lowercased().contains("ipad")
    return idiomIsPad || modelIndicatesPad
}
#else
private let isPadDevice = false
#endif
