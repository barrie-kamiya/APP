import SwiftUI
import UIKit

struct GameView: View {
    let context: LayoutContext
    let stage: Int
    let totalStages: Int
    let tapCount: Int
    let requiredTaps: Int
    let totalTapCount: Int
    let isVibrationEnabled: Bool
    let onHome: () -> Void
    let onTap: () -> Void

    @State private var isShowingHomeConfirm = false
    @State private var characterName: String = "Chara01"
    @State private var characterAngle: CGFloat = 0
    @State private var characterDirection: CGFloat = 1
    @State private var isFlipped: Bool = false
    @State private var bubbles: [Bubble] = []

    private var backgroundImageName: String {
        switch stage {
        case 1: return "Game_01"
        case 2: return "Game_02"
        case 3: return "Game_03"
        case 4: return "Game_04"
        case 5: return "Game_05"
        default: return "Game_06"
        }
    }

    var body: some View {
        GeometryReader { proxy in
            let layout = LayoutConfig.game(isPad: context.isPadLayout)
            let size = proxy.size
            let remainingTaps = max(requiredTaps - tapCount, 0)
            let characterPos = characterPosition(in: size, layout: layout)
            let characterScale = characterScale(for: characterPos.y, in: size, layout: layout)
            ZStack {
                BackgroundImageView(name: backgroundImageName, isPadLayout: context.isPadLayout)

                if LayoutConfig.useTestingAchievementRewards {
                    Text("デバッグモード")
                        .font(.system(size: context.isPadLayout ? 16 : 12, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(width: layout.debugBadgeSize.width, height: layout.debugBadgeSize.height)
                        .background(Color.white.opacity(0.6))
                        .cornerRadius(8)
                        .position(LayoutConfig.point(layout.debugBadgeCenter, in: size))
                }

                Image(characterName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: layout.characterSize.width, height: layout.characterSize.height)
                    .scaleEffect(x: (isFlipped ? -1 : 1) * characterScale,
                                 y: characterScale)
                    .position(characterPos)

                ForEach(bubbles) { bubble in
                    Circle()
                        .fill(Color.white.opacity(0.6))
                        .frame(width: bubble.size, height: bubble.size)
                        .position(bubble.position)
                        .scaleEffect(bubble.scale)
                        .opacity(bubble.opacity)
                }

                VStack(spacing: 6) {
                    Text("洗い切る")
                    Text("まで")
                    Text("\(remainingTaps)")
                        .font(.system(size: context.isPadLayout ? 24 : 20, weight: .bold))
                }
                .font(.system(size: context.isPadLayout ? 14 : 12, weight: .semibold))
                .multilineTextAlignment(.center)
                .frame(width: layout.remainingInfoSize.width, height: layout.remainingInfoSize.height)
                .background(Color.white.opacity(0.7))
                .cornerRadius(10)
                .position(LayoutConfig.point(layout.remainingInfoCenter, in: size))

                Text("累計ウォッシュ数：\(totalTapCount)")
                    .font(.system(size: context.isPadLayout ? 18 : 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: layout.totalInfoSize.width, height: layout.totalInfoSize.height)
                    .background(Color.black.opacity(0.35))
                    .cornerRadius(8)
                    .position(LayoutConfig.point(layout.totalInfoCenter, in: size))

                Button("ホームに戻る") {
                    isShowingHomeConfirm = true
                }
                .font(.system(size: context.isPadLayout ? 14 : 12, weight: .semibold))
                .foregroundColor(Color.gray.opacity(0.9))
                .frame(width: layout.homeButtonSize.width, height: layout.homeButtonSize.height)
                .background(Color(red: 0.925, green: 0.969, blue: 0.478).opacity(0.7))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.black, lineWidth: 1)
                )
                .position(LayoutConfig.point(layout.homeButtonCenter, in: size))

                Button(action: {
                    handleTap(in: size, layout: layout)
                }) {
                    Image("Tap")
                        .resizable()
                        .scaledToFill()
                        .clipped()
                }
                .frame(width: layout.tapButtonSize.width, height: layout.tapButtonSize.height)
                .position(LayoutConfig.point(layout.tapAreaCenter, in: size))
            }
            .alert("ホームに戻ると、このステージのウォッシュ数はリセットされます。戻ってよろしいですか？", isPresented: $isShowingHomeConfirm) {
                Button("Yes", role: .destructive) {
                    onHome()
                }
                Button("No", role: .cancel) { }
            }
            .frame(width: size.width, height: size.height)
            .onAppear {
                resetCharacter(in: size, layout: layout)
            }
            .onChange(of: stage) { _ in
                resetCharacter(in: size, layout: layout)
            }
        }
    }

    private func handleTap(in size: CGSize, layout: GameLayout) {
        triggerVibrationIfNeeded()
        onTap()
        withAnimation(.easeInOut(duration: 0.12)) {
            updateCharacterPosition(in: size, layout: layout)
            isFlipped.toggle()
        }
        spawnBubble(in: size, layout: layout)
    }

    private func resetCharacter(in size: CGSize, layout: GameLayout) {
        characterName = LayoutConfig.randomCharacterName()
        characterAngle = .pi / 2
        characterDirection = 1
        isFlipped = false
    }

    private func updateCharacterPosition(in size: CGSize, layout: GameLayout) {
        let step = layout.characterAngleStep
        characterAngle += step * characterDirection
        let twoPi = CGFloat.pi * 2
        if characterAngle > twoPi {
            characterAngle -= twoPi
        } else if characterAngle < 0 {
            characterAngle += twoPi
        }
    }

    private func characterPosition(in size: CGSize, layout: GameLayout) -> CGPoint {
        let center = LayoutConfig.point(layout.characterCenter, in: size)
        let x = center.x + cos(characterAngle) * layout.characterOrbitRadius.width
        let y = center.y + sin(characterAngle) * layout.characterOrbitRadius.height
        return CGPoint(x: x, y: y)
    }

    private func characterScale(for y: CGFloat, in size: CGSize, layout: GameLayout) -> CGFloat {
        let center = LayoutConfig.point(layout.characterCenter, in: size)
        let radiusY = max(layout.characterOrbitRadius.height, 1)
        let minY = center.y - radiusY
        let maxY = center.y + radiusY
        let clampedY = min(max(y, minY), maxY)
        let t = (clampedY - minY) / (maxY - minY)
        let minScale: CGFloat = 0.6
        let maxScale: CGFloat = 1.0
        return minScale + (maxScale - minScale) * t
    }

    private func spawnBubble(in size: CGSize, layout: GameLayout) {
        let basePos = characterPosition(in: size, layout: layout)
        let bubbleCount = 3
        for _ in 0..<bubbleCount {
            let offsetX = CGFloat.random(in: -26...26)
            let offsetY = CGFloat.random(in: 8...30)
            let startPos = CGPoint(x: basePos.x + offsetX, y: basePos.y + offsetY)
            let bubble = Bubble(position: startPos, size: CGFloat.random(in: 16...30))
            bubbles.append(bubble)
            let id = bubble.id

            withAnimation(.easeOut(duration: 0.7)) {
                if let index = bubbles.firstIndex(where: { $0.id == id }) {
                    bubbles[index].scale = 1.5
                    bubbles[index].opacity = 0
                    bubbles[index].position.y -= 30
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                bubbles.removeAll { $0.id == id }
            }
        }
    }

    private func triggerVibrationIfNeeded() {
        guard isVibrationEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
}

private struct Bubble: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    var scale: CGFloat = 1.0
    var opacity: CGFloat = 1.0
}
