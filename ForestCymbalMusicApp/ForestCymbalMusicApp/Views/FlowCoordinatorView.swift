import SwiftUI

struct FlowCoordinatorView: View {
    private enum Screen {
        case splash
        case home
        case game
        case stageChange
        case clear
    }

    @State private var screen: Screen = .splash
    @State private var currentStage: Int = 1
    @State private var completedStage: Int = 0
    @State private var tapCount: Int = 0
    @State private var vibrationEnabled: Bool = true
    @State private var clearImageName: String = "Clear_01"
    @State private var currentCharacter: String = "Chara01"
    @State private var completedRuns: Int = 0
    @State private var unlockedClearFlags: [String: Bool] = {
        var flags: [String: Bool] = [:]
        for index in 1...9 {
            flags[String(format: "Clear_%02d", index)] = false
        }
        return flags
    }()

    private let useTestingAchievementRewards = true
    private let totalStages = 6
    private var targetTapCount: Int { useTestingAchievementRewards ? 5 : 50 }
    private var clearImageWeights: [(name: String, weight: Double)] {
        useTestingAchievementRewards ? testingClearImageWeights : productionClearImageWeights
    }
    private var characterWeights: [(name: String, weight: Double)] {
        useTestingAchievementRewards ? testingCharacterWeights : productionCharacterWeights
    }
    private let productionClearImageWeights: [(name: String, weight: Double)] = [
        ("Clear_01", 0.75),
        ("Clear_02", 0.15),
        ("Clear_03", 0.035),
        ("Clear_04", 0.0132),
        ("Clear_05", 0.0018)
    ]
    private let testingClearImageWeights: [(name: String, weight: Double)] = [
        ("Clear_01", 1),
        ("Clear_02", 1),
        ("Clear_03", 1),
        ("Clear_04", 1),
        ("Clear_05", 1)
    ]
    private let productionCharacterWeights: [(name: String, weight: Double)] = [
        ("Chara01", 0.75),
        ("Chara02", 0.15),
        ("Chara03", 0.035),
        ("Chara04", 0.0132),
        ("Chara05", 0.0018)
    ]
    private let testingCharacterWeights: [(name: String, weight: Double)] = [
        ("Chara01", 1),
        ("Chara02", 1),
        ("Chara03", 1),
        ("Chara04", 1),
        ("Chara05", 1)
    ]
    private let illustratedMappings: [(clear: String, illustrated: String)] = [
        ("Clear_01", "Ilustrated_01"),
        ("Clear_02", "Ilustrated_02"),
        ("Clear_03", "Ilustrated_03"),
        ("Clear_04", "Ilustrated_04"),
        ("Clear_05", "Ilustrated_05"),
        ("Clear_06", "Ilustrated_06"),
        ("Clear_07", "Ilustrated_07"),
        ("Clear_08", "Ilustrated_08"),
        ("Clear_09", "Ilustrated_09")
    ]
    private var achievementMilestones: [(runs: Int, clear: String)] {
        useTestingAchievementRewards ? testingAchievementMilestones : productionAchievementMilestones
    }
    private let productionAchievementMilestones: [(runs: Int, clear: String)] = [
        (50, "Clear_06"),
        (100, "Clear_07"),
        (150, "Clear_08"),
        (200, "Clear_09")
    ]
    private let testingAchievementMilestones: [(runs: Int, clear: String)] = [
        (1, "Clear_06"),
        (2, "Clear_07"),
        (3, "Clear_08"),
        (4, "Clear_09")
    ]

    var body: some View {
        ZStack(alignment: .top) {
            Group {
                switch screen {
                case .splash:
                    SplashView {
                        transition(to: .home)
                    }
                case .home:
                    HomeView(onStart: startGame,
                             vibrationEnabled: $vibrationEnabled,
                             unlockedIllustrations: unlockedIllustrationNames,
                             isAchievementAvailable: hasAchievementToClaim(),
                             claimAchievementReward: claimAchievementReward,
                             completedRuns: completedRuns,
                             nextMilestoneRemaining: runsUntilNextMilestone)
                case .game:
                    GameView(stage: currentStage,
                             tapCount: tapCount,
                             targetTapCount: targetTapCount,
                             vibrationEnabled: vibrationEnabled,
                             characterName: currentCharacter) {
                        handleTap()
                    }
                case .stageChange:
                    StageChangeView(stage: completedStage,
                                    totalStages: totalStages) {
                        advanceFromStageChange()
                    }
                case .clear:
                    GameClearView(imageName: clearImageName) {
                        transition(to: .home)
                    }
                }
            }

            if useTestingAchievementRewards {
                Text("デバッグモード")
                    .font(.caption.bold())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.5))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.top, 12)
            }
        }
        .animation(.easeInOut, value: screen)
    }

    private func transition(to newScreen: Screen) {
        if newScreen == .home {
            resetProgress()
        }
        screen = newScreen
    }

    private func startGame() {
        resetProgress()
        screen = .game
    }

    private func resetProgress() {
        currentStage = 1
        completedStage = 0
        tapCount = 0
        currentCharacter = pickCharacter()
    }

    private func handleTap() {
        guard screen == .game else { return }
        tapCount += 1
        if tapCount >= targetTapCount {
            completedStage = currentStage
            if currentStage >= totalStages {
                finishFinalStage()
            } else {
                screen = .stageChange
            }
        }
    }

    private func advanceFromStageChange() {
        if completedStage >= totalStages {
            finishFinalStage()
        } else {
            currentStage = completedStage + 1
            tapCount = 0
            currentCharacter = pickCharacter()
            screen = .game
        }
    }

    private func finishFinalStage() {
        screen = .clear
        clearImageName = pickClearImage()
        unlockedClearFlags[clearImageName] = true
        completedRuns += 1
        RakutenRewardManager.shared.trackGameClearAction()
        AdjustManager.shared.trackGameCycleCompletion(total: completedRuns)
    }

    private func pickClearImage() -> String {
        let totalWeight = clearImageWeights.map(\.weight).reduce(0, +)
        guard totalWeight > 0 else { return clearImageWeights.first?.name ?? "Clear_01" }
        let random = Double.random(in: 0..<totalWeight)
        var cumulative: Double = 0
        for item in clearImageWeights {
            cumulative += item.weight
            if random < cumulative {
                return item.name
            }
        }
        return clearImageWeights.last?.name ?? "Clear_01"
    }

    private func pickCharacter() -> String {
        let totalWeight = characterWeights.map(\.weight).reduce(0, +)
        guard totalWeight > 0 else { return characterWeights.first?.name ?? "Chara01" }
        let random = Double.random(in: 0..<totalWeight)
        var cumulative: Double = 0
        for item in characterWeights {
            cumulative += item.weight
            if random < cumulative {
                return item.name
            }
        }
        return characterWeights.last?.name ?? "Chara01"
    }

    private func hasAchievementToClaim() -> Bool {
        achievementMilestones.contains { milestone in
            completedRuns >= milestone.runs && unlockedClearFlags[milestone.clear] != true
        }
    }

    private func claimAchievementReward() -> String? {
        for milestone in achievementMilestones {
            if completedRuns >= milestone.runs,
               unlockedClearFlags[milestone.clear] != true {
                unlockedClearFlags[milestone.clear] = true
                return milestone.clear
            }
        }
        return nil
    }

    private var unlockedIllustrationNames: [String] {
        illustratedMappings.compactMap { mapping in
            unlockedClearFlags[mapping.clear] == true ? mapping.illustrated : nil
        }
    }

    private var runsUntilNextMilestone: Int? {
        guard let next = achievementMilestones.map(\.runs).sorted().first(where: { $0 > completedRuns }) else {
            return nil
        }
        return max(next - completedRuns, 0)
    }
}
