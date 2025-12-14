import SwiftUI
import UIKit

struct GameView: View {
    let stageIndex: Int
    let tapGoal: Int
    @Binding var totalTapCount: Int
    @Binding var hapticsEnabled: Bool
    let onStageComplete: () -> Void
    let onExitToHome: (Int) -> Void

    @State private var tapCount: Int = 0
    @State private var character: StageCharacter = StageCharacter.random()
    @State private var showingPoseA: Bool = true
    @State private var characterOrientation: CharacterOrientation = .normal
    @State private var lastOrientation: CharacterOrientation = .normal
    @State private var movementFlipped: Bool = false
    @State private var characterOffset: CGFloat = 0
    @State private var movingLeft: Bool = true
    @State private var horizontalLimit: CGFloat = 0
    @State private var movementStep: CGFloat = 3
    @State private var showExitConfirmation = false

    private var progressText: String {
        "タップ \(tapCount)/\(tapGoal)"
    }

    private var remainingTaps: Int {
        max(tapGoal - tapCount, 0)
    }
    
    private var backgroundAssetName: String {
        switch stageIndex {
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
        GeometryReader { proxy in
            let isPad = DeviceTraitHelper.isPad(for: proxy.size)
            let padding = DeviceTraitHelper.primaryPadding(for: proxy.size)
            let characterWidth: CGFloat = isPad ? 340 : 240
            let limit = max((proxy.size.width - characterWidth) / 2 + (isPad ? 30 : 20), 0)
            let step = (isPad ? 3.5 : 2.5) * 10
            let bottomSpacerHeight = proxy.size.height * (isPad ? 0.08 : 0.08)
            let buttonHorizontalPadding = padding
            let topStatusOffset = proxy.safeAreaInsets.top + proxy.size.height * (isPad ? 0.05 : 0.07)
            let cumulativeOffset = proxy.safeAreaInsets.top + proxy.size.height * (isPad ? 0.48 : 0.48)

            ZStack {
                Color.clear
                    .onAppear {
                        horizontalLimit = limit
                        movementStep = step
                    }
                    .onChange(of: proxy.size.width) { newWidth in
                        let newLimit = max((newWidth - characterWidth) / 2 + (isPad ? 30 : 20), 0)
                        horizontalLimit = newLimit
                        movementStep = step
                    }
                AspectFitBackground(imageName: backgroundAssetName)

                VStack(spacing: padding) {
                    VStack {
                        Spacer(minLength: padding * (isPad ? 6.5 : 10.5))
                        characterSprite(width: characterWidth)
                            .frame(height: characterWidth)
                            .padding(.top, padding * (isPad ? 0.15 : 0.4))
                        Spacer(minLength: padding * (isPad ? 0.3 : 0.55))
                    }
                    .frame(maxHeight: .infinity, alignment: .top)

                    VStack {
                        Button(action: handleTap) {
                            Image("Tap")
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: isPad ? 420 : 320)
                                .padding(.vertical, padding * 0.15)
                        }
                        .padding(.horizontal, buttonHorizontalPadding)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, bottomSpacerHeight + proxy.safeAreaInsets.bottom)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .topLeading) {
            VStack(spacing: 4) {
                Text("次のライブ")
                    .font(isPad ? .headline : .subheadline)
                Text("まで")
                    .font(isPad ? .headline : .subheadline)
                Text("\(remainingTaps)")
                    .font(isPad ? .title3.bold() : .headline.bold())
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(.white.opacity(0.7))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.leading, DeviceTraitHelper.primaryPadding(for: proxy.size) * (isPad ? 5 : 1))
            .padding(.top, topStatusOffset)
        }
        .overlay(alignment: isPad ? .topTrailing : .topTrailing) {
            homeButton(isPad: isPad)
                .padding(.trailing, isPad ? DeviceTraitHelper.primaryPadding(for: proxy.size) * 4.5 : DeviceTraitHelper.primaryPadding(for: proxy.size))
                .padding(.top, topStatusOffset)
        }
        .overlay(alignment: .topTrailing) {
            cumulativeTapView(isPad: DeviceTraitHelper.isPad(for: proxy.size))
                .padding(.trailing, DeviceTraitHelper.primaryPadding(for: proxy.size) * (isPad ? 4.15 : 1))
                .padding(.top, cumulativeOffset)
        }
        }
        .ignoresSafeArea()
        .onChange(of: stageIndex) { _ in
            tapCount = 0
            resetCharacter()
        }
        .onAppear {
            resetCharacter()
        }
        .alert("確認", isPresented: $showExitConfirmation) {
            Button("Yes") {
                onExitToHome(tapCount)
            }
            Button("No", role: .cancel) { }
        } message: {
            Text("ホームに戻ると、このステージのステップ数はリセットされます。戻ってよろしいですか？")
        }
    }

    private func handleTap() {
        if hapticsEnabled {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
        moveCharacter(step: movementStep)
        totalTapCount += 1
        if tapCount + 1 >= tapGoal {
            tapCount = tapGoal
            onStageComplete()
        } else {
            tapCount += 1
            showingPoseA.toggle()
            updateCharacterOrientation()
        }
    }

    @ViewBuilder
    private func characterSprite(width: CGFloat) -> some View {
        let imageName = character.imageName(isPoseA: showingPoseA)
        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(width: width, height: width)
            .rotationEffect(characterOrientation.rotation)
            .scaleEffect(x: (characterOrientation.isMirrored ? -1 : 1) * (movementFlipped ? -1 : 1), y: 1)
            .offset(x: characterOffset, y: 0)
            .animation(.linear(duration: 0.03), value: characterOffset)
            .animation(.easeInOut(duration: 0.2), value: showingPoseA)
            .animation(.easeInOut(duration: 0.2), value: characterOrientation)
    }

    private func updateCharacterOrientation() {
        let next = CharacterOrientation.random(excluding: lastOrientation)
        lastOrientation = next
        characterOrientation = next
    }

    private func resetCharacter() {
        character = StageCharacter.random()
        showingPoseA = true
        characterOrientation = .normal
        lastOrientation = .normal
        characterOffset = 0
        movingLeft = true
        movementFlipped = false
    }

    private func moveCharacter(step: CGFloat) {
        guard horizontalLimit > 0 else { return }
        if movingLeft {
            characterOffset -= step
            if characterOffset <= -horizontalLimit {
                characterOffset = -horizontalLimit
                movingLeft = false
                movementFlipped = true
            }
        } else {
            characterOffset += step
            if characterOffset >= horizontalLimit {
                characterOffset = horizontalLimit
                movingLeft = true
                movementFlipped = false
            }
        }
    }

    private func cumulativeTapView(isPad: Bool) -> some View {
        Text("累計ステップ数：\(totalTapCount)")
            .font(isPad ? .title2.bold() : .headline.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, isPad ? 24 : 16)
            .padding(.vertical, isPad ? 14 : 10)
            .background(Color.black.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: isPad ? 28 : 20, style: .continuous))
    }

    private func homeButton(isPad: Bool) -> some View {
        Button(action: { showExitConfirmation = true }) {
            Text("ホームに戻る")
                .font(isPad ? .footnote.bold() : .caption.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(red: 0.97, green: 0.27, blue: 0.75).opacity(0.7))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    GameView(stageIndex: 1, tapGoal: 50, totalTapCount: .constant(0), hapticsEnabled: .constant(true), onStageComplete: {}, onExitToHome: { _ in })
}

private struct StageCharacter {
    let index: Int

    func imageName(isPoseA: Bool) -> String {
        let suffix = isPoseA ? "A" : "B"
        return String(format: "Chara%02d_%@", index, suffix)
    }

    static func random() -> StageCharacter {
        if FeatureFlags.useTestingAchievementRewards {
            return StageCharacter(index: Int.random(in: 1...5))
        }

        let weighted = weightedCharacters
        let totalWeight = weighted.reduce(0.0) { $0 + $1.weight }
        let randomValue = Double.random(in: 0..<max(totalWeight, 0.0001))
        var cumulative: Double = 0
        for entry in weighted {
            cumulative += entry.weight
            if randomValue < cumulative {
                return StageCharacter(index: entry.index)
            }
        }
        return StageCharacter(index: weighted.last?.index ?? 1)
    }

    private static var weightedCharacters: [(index: Int, weight: Double)] {
        [
            (1, 0.75),
            (2, 0.15),
            (3, 0.035),
            (4, 0.0132),
            (5, 0.0018)
        ]
    }
}

private enum CharacterOrientation: CaseIterable {
    case normal
    case tiltLeft
    case mirrored
    case mirroredTilt

    var rotation: Angle {
        switch self {
        case .normal, .mirrored:
            return .degrees(0)
        case .tiltLeft, .mirroredTilt:
            return .degrees(-45)
        }
    }

    var isMirrored: Bool {
        switch self {
        case .mirrored, .mirroredTilt:
            return true
        default:
            return false
        }
    }

    static func random(excluding previous: CharacterOrientation) -> CharacterOrientation {
        var candidates = CharacterOrientation.allCases.filter { $0 != previous }
        if candidates.isEmpty {
            candidates = CharacterOrientation.allCases
        }
        return candidates.randomElement() ?? .normal
    }
}
