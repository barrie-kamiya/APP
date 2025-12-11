import SwiftUI

struct FlowCoordinatorView: View {
    private enum PersistenceKey {
        static let stage = "ForestCymbal.stage"
        static let cumulative = "ForestCymbal.cumulative"
        static let hasProgress = "ForestCymbal.hasProgress"
    }
    
    private static let initialProgress: (stage: Int, cumulative: Int, hasProgress: Bool, character: String) = {
        let defaults = UserDefaults.standard
        let has = defaults.bool(forKey: PersistenceKey.hasProgress)
        let stage = has ? max(defaults.integer(forKey: PersistenceKey.stage), 1) : 1
        let cumulative = has ? max(defaults.integer(forKey: PersistenceKey.cumulative), 0) : 0
        let character = defaults.string(forKey: "ForestCymbal.character") ?? "Chara01"
        return (stage, cumulative, has, character)
    }()
    private enum Screen {
        case splash
        case home
        case game
        case stageChange
        case clear
    }

    @State private var screen: Screen = .splash
    @State private var currentStage: Int = FlowCoordinatorView.initialProgress.stage
    @State private var completedStage: Int = 0
    @State private var tapCount: Int = 0
    @State private var vibrationEnabled: Bool = true
    @State private var clearImageName: String = "Clear_01"
    @State private var currentCharacter: String = FlowCoordinatorView.initialProgress.character
    @State private var completedRuns: Int = 0
    @State private var unlockedClearFlags: [String: Bool] = {
        var flags: [String: Bool] = [:]
        for index in 1...9 {
            flags[String(format: "Clear_%02d", index)] = false
        }
        return flags
    }()
    @State private var cumulativeTapCount: Int = FlowCoordinatorView.initialProgress.cumulative
    @State private var stageStartCumulative: Int = FlowCoordinatorView.initialProgress.cumulative

    private let useTestingAchievementRewards = false
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
                    if FlowCoordinatorView.initialProgress.hasProgress {
                        GameView(stage: currentStage,
                                 tapCount: tapCount,
                                 targetTapCount: targetTapCount,
                                 vibrationEnabled: vibrationEnabled,
                                 characterName: currentCharacter,
                                 cumulativeTapCount: cumulativeTapCount,
                                 onTapArea: handleTap,
                                 onExitToHome: transitionToHomeFromGame)
                            .onAppear {
                                startGame(resumeOnly: true)
                            }
                    } else {
                        SplashView {
                            transition(to: .home)
                        }
                    }
                case .home:
                    HomeView(onStart: { startGame() },
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
                             characterName: currentCharacter,
                             cumulativeTapCount: cumulativeTapCount,
                             onTapArea: handleTap,
                             onExitToHome: transitionToHomeFromGame)
                case .stageChange:
                    StageChangeView(stage: completedStage,
                                    totalStages: totalStages) {
                        advanceFromStageChange()
                    }
                case .clear:
                    GameClearView(imageName: clearImageName) {
                        returnHomeFromClear()
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
        .ignoresSafeArea()
    }

    private func transition(to newScreen: Screen) {
        screen = newScreen
    }

    private func startGame(resumeOnly: Bool = false) {
        tapCount = 0
        let saved = loadSavedProgress()
        if resumeOnly, let saved = saved {
            currentStage = saved.stage
            stageStartCumulative = saved.cumulative
            cumulativeTapCount = saved.cumulative
        } else if let saved = saved {
            currentStage = saved.stage
            stageStartCumulative = saved.cumulative
            cumulativeTapCount = saved.cumulative
            currentCharacter = pickCharacter()
        } else {
            resetProgress()
        }
        persistProgress(stage: currentStage, cumulative: stageStartCumulative)
        screen = .game
    }

    private func resetProgress() {
        currentStage = 1
        completedStage = 0
        tapCount = 0
        cumulativeTapCount = 0
        stageStartCumulative = 0
        currentCharacter = pickCharacter()
        clearSavedProgress()
    }

    private func handleTap() {
        guard screen == .game else { return }
        tapCount += 1
        cumulativeTapCount += 1
        if tapCount >= targetTapCount {
            completedStage = currentStage
            stageStartCumulative = cumulativeTapCount
            persistProgress(stage: min(currentStage + 1, totalStages), cumulative: stageStartCumulative)
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
            persistProgress(stage: currentStage, cumulative: stageStartCumulative)
        }
    }
    
    private func transitionToHomeFromGame() {
        guard screen == .game else { return }
        tapCount = 0
        cumulativeTapCount = stageStartCumulative
        persistProgress(stage: currentStage, cumulative: stageStartCumulative)
        screen = .home
    }
    
    private func returnHomeFromClear() {
        resetProgress()
        screen = .home
    }

    private func finishFinalStage() {
        screen = .clear
        clearImageName = pickClearImage()
        unlockedClearFlags[clearImageName] = true
        completedRuns += 1
        RakutenRewardManager.shared.trackGameClearAction()
        AdjustManager.shared.trackGameCycleCompletion(total: completedRuns)
        clearSavedProgress()
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
    
    private func loadSavedProgress() -> (stage: Int, cumulative: Int)? {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: PersistenceKey.hasProgress) else { return nil }
        let stage = max(defaults.integer(forKey: PersistenceKey.stage), 1)
        let cumulative = max(defaults.integer(forKey: PersistenceKey.cumulative), 0)
        return (stage, cumulative)
    }
    
    private func persistProgress(stage: Int, cumulative: Int) {
        let defaults = UserDefaults.standard
        defaults.set(max(stage, 1), forKey: PersistenceKey.stage)
        defaults.set(max(cumulative, 0), forKey: PersistenceKey.cumulative)
        defaults.set(currentCharacter, forKey: "ForestCymbal.character")
        defaults.set(true, forKey: PersistenceKey.hasProgress)
    }
    
    private func clearSavedProgress() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: PersistenceKey.stage)
        defaults.removeObject(forKey: PersistenceKey.cumulative)
        defaults.set(false, forKey: PersistenceKey.hasProgress)
    }
}
