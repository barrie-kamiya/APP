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
    let onExitToHome: () -> Void
    @State private var showHomeAlert = false
    @Environment(\.isPadLayout) private var isPadLayout

    private var remainingTaps: Int { max(tapGoal - tapCount, 0) }
    private var indicatorPositionRatio: CGPoint {
        if isPadLayout { return CGPoint(x: 0.15, y: 0.07) }
        return CGPoint(x: 0.17, y: 0.11)
    }
    private var indicatorWidthRatio: CGFloat {
        isPadLayout ? 0.32 : 0.16
    }

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
                    topControlsOverlay(in: geometry.size)
                    VStack(alignment: .center, spacing: 24) {
                        Image(characterName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: characterWidth)
                            .scaleEffect(x: characterPose.scaleX, y: 1)
                            .rotationEffect(characterPose.rotation)
                            .shadow(radius: 6)
                            .padding(.top, isPadLayout ? 50 : 70)
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
                        Text("次の狩り")
                            .font(.headline)
                        Text("まで")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("\(remainingTaps)")
                            .font(.title2.bold())
                    }
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .frame(width: geometry.size.width * indicatorWidthRatio)
                    .padding(isPadLayout ? 4 : 8)
                    .background(Color.white.opacity(0.7))
                    .cornerRadius(12)
                    .shadow(radius: 6)
                    .scaleEffect(isPadLayout ? 0.5 : 1)
                    .position(x: geometry.size.width * indicatorPositionRatio.x,
                              y: geometry.size.height * indicatorPositionRatio.y)

                    cumulativeTapOverlay
                        .position(x: geometry.size.width * cumulativePositionRatio.x,
                                  y: geometry.size.height * cumulativePositionRatio.y)
                }
            }
        }
        .ignoresSafeArea(edges: isPadLayout ? [] : .all)
        .alert("ホームに戻る", isPresented: $showHomeAlert) {
            Button("Yes") {
                showHomeAlert = false
                onExitToHome()
            }
            Button("No", role: .cancel) {
                showHomeAlert = false
            }
        } message: {
            Text("ホームに戻ると、このステージのハント数はリセットされます。戻ってよろしいですか？")
        }
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
    let background = RoundedRectangle(cornerRadius: isPadLayout ? 18 : 12, style: .continuous)
    return Text("累計ハント数：\(cumulativeTapCount)")
        .font(isPadLayout ? .title2.bold() : .headline.bold())
        .foregroundColor(.white)
        .padding(.horizontal, isPadLayout ? 20 : 14)
        .padding(.vertical, isPadLayout ? 10 : 6)
        .background(background.fill(Color.black.opacity(0.35)))
        .overlay(background.stroke(Color.black.opacity(0.5), lineWidth: 1))
        .shadow(color: .black.opacity(0.6), radius: 6, x: 0, y: 2)
        .scaleEffect(isPadLayout ? 0.5 : 1)
        .accessibilityHidden(true)
}

private var cumulativePositionRatio: CGPoint {
    if isPadLayout { return CGPoint(x: 0.74, y: 0.48) }
    return CGPoint(x: 0.75, y: 0.47)
}

    private func topControlsOverlay(in size: CGSize) -> some View {
        VStack {
            HStack {
                Spacer()
                backHomeButton
            }
            Spacer()
        }
        .padding(.horizontal, isPadLayout ? 32 : 28)
        .padding(.top, isPadLayout ? 25 : 55)
    }
    
    @ViewBuilder
    private var backHomeButton: some View {
        Button(action: { showHomeAlert = true }) {
            Text("ホームに戻る")
                .font(isPadLayout ? .headline : .caption.bold())
                .foregroundColor(.white)
                .padding(.horizontal, isPadLayout ? 16 : 12)
                .padding(.vertical, isPadLayout ? 8 : 6)
                .background(Color.red.opacity(0.35))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.8), lineWidth: isPadLayout ? 1.5 : 1)
                )
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPadLayout ? 0.5 : 1, anchor: .topTrailing)
    }
}
