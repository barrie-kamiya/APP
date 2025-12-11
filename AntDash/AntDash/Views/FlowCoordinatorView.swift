import SwiftUI
import UIKit

enum AppScreen {
    case splash
    case home
    case game
    case stageChange
    case clear
}

struct CharacterGhost: Identifiable {
    let id = UUID()
    let name: String
    let offsetRatio: CGFloat
    let isFlipped: Bool
}

final class AppFlowState: ObservableObject {
    private let useTestingAchievementRewards = true
    @Published var currentScreen: AppScreen = .splash
    @Published private(set) var currentStage: Int = 1
    @Published private(set) var tapCount: Int = 0
    @Published private(set) var lastClearedStage: Int = 0
    @Published var clearBackgroundImageName: String = "Clear_01"
    @Published private(set) var currentCharacterName: String = "Chara01"
    @Published private(set) var characterOffsetRatio: CGFloat = 0
    @Published private(set) var isCharacterFlipped: Bool = false
    @Published private(set) var totalClears: Int = 0
    @Published private(set) var unlockedIllustrationIDs: Set<String> = ["Ilustrated_none"]
    @Published private(set) var claimedRewardMilestones: Set<Int> = []
    @Published var isVibrationEnabled: Bool = true
    @Published private(set) var characterGhosts: [CharacterGhost] = []

    let totalStages: Int = 6
    var tapsPerStage: Int { useTestingAchievementRewards ? 5 : 50 }
    /// 確率を調整したい場合はこのリストの weight を編集
    var clearBackgroundWeights: [(name: String, weight: Double)] {
        if useTestingAchievementRewards {
            return testingClearWeights
        } else {
            return productionClearWeights
        }
    }
    var characterWeights: [(name: String, weight: Double)] {
        if useTestingAchievementRewards {
            return testingCharacterWeights
        } else {
            return productionCharacterWeights
        }
    }
    private let characterMoveStep: CGFloat = 0.12
    private var isMovingRight = false
    private var milestoneTargets: [Int] {
        useTestingAchievementRewards ? testingMilestoneTargets : productionMilestoneTargets
    }
    private let illustrationMapping: [String: String] = [
        "Clear_01": "Ilustrated_01",
        "Clear_02": "Ilustrated_02",
        "Clear_03": "Ilustrated_03",
        "Clear_04": "Ilustrated_04",
        "Clear_05": "Ilustrated_05",
        "Clear_06": "Ilustrated_06",
        "Clear_07": "Ilustrated_07",
        "Clear_08": "Ilustrated_08",
        "Clear_09": "Ilustrated_09"
    ]
    private var specialRewardMapping: [Int: (clear: String, illustration: String)] {
        useTestingAchievementRewards ? testingSpecialRewardMapping : productionSpecialRewardMapping
    }
    
    private let productionClearWeights: [(name: String, weight: Double)] = [
        ("Clear_01", 0.75),
        ("Clear_02", 0.15),
        ("Clear_03", 0.035),
        ("Clear_04", 0.0132),
        ("Clear_05", 0.0018)
    ]
    private let testingClearWeights: [(name: String, weight: Double)] = [
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
    private let productionMilestoneTargets = [50, 100, 150, 200]
    private let testingMilestoneTargets = [1, 2, 3, 4]
    private let productionSpecialRewardMapping: [Int: (clear: String, illustration: String)] = [
        50: ("Clear_06", "Ilustrated_06"),
        100: ("Clear_07", "Ilustrated_07"),
        150: ("Clear_08", "Ilustrated_08"),
        200: ("Clear_09", "Ilustrated_09")
    ]
    private let testingSpecialRewardMapping: [Int: (clear: String, illustration: String)] = [
        1: ("Clear_06", "Ilustrated_06"),
        2: ("Clear_07", "Ilustrated_07"),
        3: ("Clear_08", "Ilustrated_08"),
        4: ("Clear_09", "Ilustrated_09")
    ]

    func handleSplashTap() {
        currentScreen = .home
    }

    func startGame() {
        currentStage = 1
        tapCount = 0
        lastClearedStage = 0
        prepareCharacterForNewStage()
        currentScreen = .game
    }

    func registerTap() {
        guard currentScreen == .game else { return }
        if tapCount < tapsPerStage {
            tapCount += 1
            if isVibrationEnabled {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
            updateCharacterPositionAfterTap()
        }
        if tapCount >= tapsPerStage {
            handleStageCompletion()
        }
    }
    
    func setVibrationEnabled(_ enabled: Bool) {
        isVibrationEnabled = enabled
    }

    private func handleStageCompletion() {
        lastClearedStage = currentStage
        tapCount = 0
        if currentStage >= totalStages {
            let prospectiveRunCount = totalClears + 1
            clearBackgroundImageName = selectClearBackgroundImage()
            recordRunCompletion(runCount: prospectiveRunCount, clearName: clearBackgroundImageName)
            currentScreen = .clear
        } else {
            currentStage += 1
            prepareCharacterForNewStage()
            currentScreen = .stageChange
        }
    }

    func proceedToNextStage() {
        guard currentStage <= totalStages else { return }
        tapCount = 0
        currentScreen = .game
    }

    func returnHomeFromClear() {
        currentStage = 1
        tapCount = 0
        lastClearedStage = 0
        prepareCharacterForNewStage()
        currentScreen = .home
    }
    
    var nextMilestoneTarget: Int? {
        milestoneTargets.first(where: { $0 > totalClears })
    }
    
    var runsUntilNextMilestone: Int? {
        guard let target = nextMilestoneTarget else { return nil }
        return max(target - totalClears, 0)
    }
    
    var hasAchievementReward: Bool {
        availableRewardMilestone != nil
    }
    
    var isDebugModeEnabled: Bool { useTestingAchievementRewards }
    
    private func selectClearBackgroundImage() -> String {
        let totalWeight = clearBackgroundWeights.reduce(0.0) { $0 + max($1.weight, 0) }
        guard totalWeight > 0 else {
            return clearBackgroundWeights.first?.name ?? "Clear_01"
        }
        let randomPoint = Double.random(in: 0..<totalWeight)
        var cumulative = 0.0
        for entry in clearBackgroundWeights {
            let weight = max(entry.weight, 0)
            cumulative += weight
            if randomPoint < cumulative {
                return entry.name
            }
        }
        return clearBackgroundWeights.last?.name ?? "Clear_01"
    }

    private func prepareCharacterForNewStage() {
        currentCharacterName = selectRandomCharacter()
        characterOffsetRatio = 0
        isMovingRight = false
        isCharacterFlipped = false
        characterGhosts.removeAll()
    }

    private func updateCharacterPositionAfterTap() {
        let ghost = CharacterGhost(name: currentCharacterName,
                                   offsetRatio: characterOffsetRatio,
                                   isFlipped: isCharacterFlipped)
        characterGhosts.insert(ghost, at: 0)
        if characterGhosts.count > 3 {
            characterGhosts.removeLast(characterGhosts.count - 3)
        }
        let step: CGFloat = isMovingRight ? characterMoveStep : -characterMoveStep
        var nextRatio = characterOffsetRatio + step
        let minRatio: CGFloat = -1
        let maxRatio: CGFloat = 1
        if nextRatio <= minRatio {
            nextRatio = minRatio
            isMovingRight = true
            isCharacterFlipped = true
        } else if nextRatio >= maxRatio {
            nextRatio = maxRatio
            isMovingRight = false
            isCharacterFlipped = false
        }
        characterOffsetRatio = nextRatio
    }
    
    private func selectRandomCharacter() -> String {
        let totalWeight = characterWeights.reduce(0.0) { $0 + max($1.weight, 0) }
        guard totalWeight > 0 else {
            return characterWeights.first?.name ?? "Chara01"
        }
        let randomPoint = Double.random(in: 0..<totalWeight)
        var cumulative = 0.0
        for entry in characterWeights {
            let weight = max(entry.weight, 0)
            cumulative += weight
            if randomPoint < cumulative {
                return entry.name
            }
        }
        return characterWeights.last?.name ?? "Chara01"
    }
    
    private func recordRunCompletion(runCount: Int, clearName: String) {
        totalClears = runCount
        if !isSpecialClearImage(clearName) {
            unlockIllustration(for: clearName)
        }
    }
    
    private func unlockIllustration(for clearName: String) {
        if let illustrationID = illustrationMapping[clearName] {
            unlockedIllustrationIDs.insert(illustrationID)
        }
    }
    
    private var availableRewardMilestone: Int? {
        specialRewardMapping.keys.sorted().first(where: { totalClears >= $0 && !claimedRewardMilestones.contains($0) })
    }
    
    func claimAchievementReward() -> (imageName: String, milestone: Int)? {
        guard let milestone = availableRewardMilestone,
              let reward = specialRewardMapping[milestone] else { return nil }
        claimedRewardMilestones.insert(milestone)
        unlockIllustration(for: reward.clear)
        return (reward.clear, milestone)
    }
    
    private func isSpecialClearImage(_ name: String) -> Bool {
        specialRewardMapping.values.contains(where: { $0.clear == name })
    }
}

struct FlowCoordinatorView: View {
    @EnvironmentObject private var state: AppFlowState

    var body: some View {
        ZStack(alignment: .top) {
            contentView
            if state.isDebugModeEnabled {
                Text("デバッグモード")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(16)
                    .padding(.top, 12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut, value: state.currentScreen)
        .background(Color.black.ignoresSafeArea())
        .ignoresSafeArea()
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch state.currentScreen {
        case .splash:
            SplashView(onContinue: state.handleSplashTap)
        case .home:
            HomeView(onStart: state.startGame,
                     totalClears: state.totalClears,
                     nextMilestone: state.nextMilestoneTarget,
                     runsUntilNext: state.runsUntilNextMilestone,
                     unlockedIllustrations: state.unlockedIllustrationIDs,
                     hasAchievementReward: state.hasAchievementReward,
                     onClaimAchievement: state.claimAchievementReward,
                     isVibrationEnabled: state.isVibrationEnabled,
                     onVibrationChange: state.setVibrationEnabled)
        case .game:
            GameView(stage: state.currentStage,
                     tapCount: state.tapCount,
                     tapGoal: state.tapsPerStage,
                     characterName: state.currentCharacterName,
                     characterOffsetRatio: state.characterOffsetRatio,
                     isCharacterFlipped: state.isCharacterFlipped,
                     characterGhosts: state.characterGhosts,
                     onTap: state.registerTap)
        case .stageChange:
            StageChangeView(currentStage: state.currentStage,
                            totalStages: state.totalStages,
                            lastClearedStage: state.lastClearedStage,
                            onNext: state.proceedToNextStage)
        case .clear:
            GameClearView(backgroundImageName: state.clearBackgroundImageName,
                          onFinish: state.returnHomeFromClear)
        }
    }
}
