#if canImport(UIKit)
import UIKit
#endif
import SwiftUI

struct GameView: View {
    let stage: Int
    let tapCount: Int
    let tapGoal: Int
    let characterName: String
    let characterPose: CharacterPose
    let characterOffsetRatio: CGFloat
    let isVibrationEnabled: Bool
    let cumulativeTapCount: Int
    let onTapAreaPressed: () -> Void
    @Environment(\.isPadLayout) private var isPadLayout

    private var remainingTaps: Int { max(tapGoal - tapCount, 0) }
    private var indicatorPositionRatio: CGPoint {
        if isPadLayout { return CGPoint(x: 0.15, y: 0.07) }
        return CGPoint(x: 0.17, y: 0.08)
    }
    private let indicatorWidthRatio: CGFloat = 0.16

    private var backgroundImageName: String {
        switch stage {
        case 1: return "Game_01"
        case 2: return "Game_02"
        case 3: return "Game_03"
        case 4: return "Game_04"
        case 5: return "Game_05"
        case 6: return "Game_06"
        default: return "Game_01"
        }
    }

    var body: some View {
        ZStack {
            AdaptiveBackgroundImage(imageName: backgroundImageName)
            Color.black.opacity(0.25)
                .ignoresSafeArea(isPadLayout ? [] : .all)
            GeometryReader { geometry in
                let characterWidth = geometry.size.width * 0.5
                let maxOffset = max((geometry.size.width - characterWidth) / 2, 0)
                ZStack {
                    VStack(alignment: .center, spacing: 24) {
                        Image(characterName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: characterWidth)
                            .scaleEffect(x: characterPose.scaleX, y: 1)
                            .rotationEffect(characterPose.rotation)
                            .shadow(radius: 6)
                            .padding(.top, isPadLayout ? 20 : 40)
                            .offset(x: characterOffsetRatio * maxOffset)
                        Spacer()
                        Button(action: handleTap) {
                            Image("Tap")
                                .resizable()
                                .scaledToFit()
                                .frame(width: geometry.size.width * 0.8,
                                       height: geometry.size.height * 0.35)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: geometry.size.height / 2)
                        .padding(.bottom, isPadLayout ? -20 : -10)
                        .cornerRadius(32)
                        .shadow(radius: 12)
                        .buttonStyle(.plain)
                    }
                    .padding()

                    VStack(spacing: 4) {
                        Text("完了まで")
                        Text("あと")
                        Text("\(remainingTaps)")
                            .font(.title2.bold())
                    }
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .frame(width: geometry.size.width * indicatorWidthRatio)
                    .padding(8)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(12)
                    .shadow(radius: 6)
                    .position(x: geometry.size.width * indicatorPositionRatio.x,
                              y: geometry.size.height * indicatorPositionRatio.y)

                    cumulativeTapOverlay
                        .position(x: geometry.size.width * cumulativePositionRatio.x,
                                  y: geometry.size.height * cumulativePositionRatio.y)
                }
            }
        }
        .ignoresSafeArea(edges: isPadLayout ? [] : .all)
    }

private func handleTap() {
    triggerHapticIfNeeded()
    onTapAreaPressed()
}

private func triggerHapticIfNeeded() {
    guard isVibrationEnabled else { return }
#if os(iOS)
    let generator = UIImpactFeedbackGenerator(style: .medium)
    generator.impactOccurred()
#endif
}

private var cumulativeTapOverlay: some View {
    Text("\(cumulativeTapCount)")
        .font(isPadLayout ? .largeTitle.weight(.heavy) : .title.weight(.semibold))
        .foregroundColor(.white)
        .shadow(color: .black.opacity(0.7), radius: 5, x: 0, y: 2)
        .accessibilityHidden(true)
}

private var cumulativePositionRatio: CGPoint {
    if isPadLayout { return CGPoint(x: 0.82, y: 0.43) }
    return CGPoint(x: 0.85, y: 0.45)
}
}
