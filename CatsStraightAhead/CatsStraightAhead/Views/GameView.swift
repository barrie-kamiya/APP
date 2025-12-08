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
    let onTapAreaPressed: () -> Void

    private var remainingTaps: Int { max(tapGoal - tapCount, 0) }
    private let indicatorPositionRatio = CGPoint(x: 0.2, y: 0.02)
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
                .ignoresSafeArea()
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
                            .padding(.top, -10)
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
                }
            }
        }
        .background(Color(.systemBackground))
        .ignoresSafeArea(edges: .bottom)
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
}
