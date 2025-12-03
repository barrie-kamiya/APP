import Combine
import Foundation

final class AppFlowViewModel: ObservableObject {
    enum Screen {
        case splash
        case home
        case game
        case stageChange
        case clear
    }

    @Published var currentScreen: Screen = .splash
    @Published private(set) var currentStage: Int = 1
    @Published private(set) var tapCount: Int = 0
    @Published private(set) var unlockedIllustrations: Set<Int> = []
    @Published private(set) var currentIllustrationID: Int?
    @Published private(set) var currentClearImageName: String = "Clear_01"
    @Published private(set) var completedRuns: Int = 0
    @Published private(set) var claimedAchievementMilestones: Set<Int> = []
    @Published var isVibrationEnabled: Bool = true
    var hasClaimableAchievement: Bool {
        nextAchievementReward() != nil
    }

    let totalStages = 6
    private let defaultTargetTaps = 50
    private let testingTargetTaps = 5
    private let totalIllustrations = 9
    private let standardIllustrationIDs = Array(1...5)
    private let defaultClearImageRules: [(name: String, weight: Double)] = [
        ("Clear_01", 0.75),
        ("Clear_02", 0.15),
        ("Clear_03", 0.035),
        ("Clear_04", 0.0132),
        ("Clear_05", 0.0018)
    ]
    private let testingClearImageRules: [(name: String, weight: Double)] = [
        ("Clear_01", 1),
        ("Clear_02", 1),
        ("Clear_03", 1),
        ("Clear_04", 1),
        ("Clear_05", 1)
    ]
    private let defaultCharacterWeights: [(name: String, weight: Double)] = [
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
    private let defaultAchievementRewards: [(milestone: Int, clearImageName: String, illustrationID: Int)] = [
        (50, "Clear_06", 6),
        (100, "Clear_07", 7),
        (150, "Clear_08", 8),
        (200, "Clear_09", 9)
    ]
    private let testingAchievementRewards: [(milestone: Int, clearImageName: String, illustrationID: Int)] = [
        (1, "Clear_06", 6),
        (2, "Clear_07", 7),
        (3, "Clear_08", 8),
        (4, "Clear_09", 9)
    ]
    let useTestingAchievementRewards = true

    private var achievementRewards: [(milestone: Int, clearImageName: String, illustrationID: Int)] {
        useTestingAchievementRewards ? testingAchievementRewards : defaultAchievementRewards
    }
    
    private var currentClearImageRules: [(name: String, weight: Double)] {
        useTestingAchievementRewards ? testingClearImageRules : defaultClearImageRules
    }
    
    var characterWeights: [(name: String, weight: Double)] {
        useTestingAchievementRewards ? testingCharacterWeights : defaultCharacterWeights
    }
    
    var targetTaps: Int {
        useTestingAchievementRewards ? testingTargetTaps : defaultTargetTaps
    }
    
    var achievementMilestoneValues: [Int] {
        achievementRewards.map { $0.milestone }.sorted()
    }

    func handleSplashTap() {
        currentScreen = .home
    }

    func startGame() {
        resetProgress(forNewRun: true)
        currentIllustrationID = nil
        currentScreen = .game
    }

    func recordTap() {
        guard currentScreen == .game, tapCount < targetTaps else { return }
        tapCount += 1

        if tapCount >= targetTaps {
            handleStageCompletion()
        }
    }

    func proceedToNextStage() {
        guard currentStage < totalStages else { return }
        currentStage += 1
        tapCount = 0
        currentScreen = .game
    }

    func finishGame() {
        currentScreen = .home
        resetProgress(forNewRun: true)
        currentIllustrationID = nil
    }

    private func handleStageCompletion() {
        if currentStage < totalStages {
            currentScreen = .stageChange
        } else {
            completedRuns += 1
            AdjustManager.shared.trackGameCycleCompletion(total: completedRuns)
            let clearImageName = selectClearImageName()
            currentClearImageName = clearImageName
            assignIllustrationFlag(fromClearImage: clearImageName)
            currentScreen = .clear
        }
    }

    func markIllustrationUnlocked(id: Int) {
        guard (1...totalIllustrations).contains(id) else { return }
        unlockedIllustrations.insert(id)
        currentIllustrationID = id
    }

    private func resetProgress(forNewRun: Bool) {
        tapCount = 0
        if forNewRun {
            currentStage = 1
        }
    }

    private func assignIllustrationFlag(fromClearImage clearImageName: String) {
        if let clearID = illustrationID(from: clearImageName) {
            markIllustrationUnlocked(id: clearID)
            return
        }

        let pending = standardIllustrationIDs.first(where: { !unlockedIllustrations.contains($0) })
        let target = pending ?? (standardIllustrationIDs.randomElement() ?? 1)
        markIllustrationUnlocked(id: target)
    }

    private func illustrationID(from clearImageName: String) -> Int? {
        guard let suffix = clearImageName.split(separator: "_").last,
              let id = Int(suffix) else {
            return nil
        }
        return id
    }

    func claimNextAchievementReward() -> String? {
        guard let reward = nextAchievementReward() else { return nil }
        claimedAchievementMilestones.insert(reward.milestone)
        markIllustrationUnlocked(id: reward.illustrationID)
        return reward.clearImageName
    }

    private func nextAchievementReward() -> (milestone: Int, clearImageName: String, illustrationID: Int)? {
        achievementRewards.first(where: { completedRuns >= $0.milestone && !claimedAchievementMilestones.contains($0.milestone) })
    }

    func nextAchievementMilestone(after runCount: Int) -> Int? {
        achievementMilestoneValues.first(where: { $0 > runCount })
    }

    private func selectClearImageName() -> String {
        let rules = currentClearImageRules
        let totalWeight = rules.reduce(0) { $0 + $1.weight }
        guard totalWeight > 0 else { return rules.first?.name ?? "Clear_01" }

        let randomValue = Double.random(in: 0..<totalWeight)
        var cumulative: Double = 0
        for rule in rules {
            cumulative += rule.weight
            if randomValue < cumulative {
                return rule.name
            }
        }
        return rules.first?.name ?? "Clear_01"
    }
}
