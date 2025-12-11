import SwiftUI

enum AppScreen {
    case splash
    case home
    case game
    case stageChange
    case clear
}

enum CharacterPose: CaseIterable {
    case normal
    case rotate45
    case flipped
    case flippedRotate45

    var rotation: Angle {
        switch self {
        case .normal, .flipped:
            return .degrees(0)
        case .rotate45:
            return .degrees(-45)
        case .flippedRotate45:
            return .degrees(45)
        }
    }

    var scaleX: CGFloat {
        switch self {
        case .normal, .rotate45:
            return 1
        case .flipped, .flippedRotate45:
            return -1
        }
    }
}

final class AppFlowState: ObservableObject {
    private let useTestingAchievementRewards = false
    private let productionCharacterWeights: [(name: String, weight: Double)] = [
        ("Chara01", 0.75),
        ("Chara02", 0.15),
        ("Chara03", 0.035),
        ("Chara04", 0.0132),
        ("Chara05", 0.0018)
    ]
    private let productionClearImageWeights: [(name: String, weight: Double)] = [
        ("Clear_01", 0.75),
        ("Clear_02", 0.15),
        ("Clear_03", 0.035),
        ("Clear_04", 0.0132),
        ("Clear_05", 0.0018)
    ]
    private let testingCharacterWeights: [(name: String, weight: Double)] = [
        ("Chara01", 1),
        ("Chara02", 1),
        ("Chara03", 1),
        ("Chara04", 1),
        ("Chara05", 1)
    ]
    private let testingClearImageWeights: [(name: String, weight: Double)] = [
        ("Clear_01", 1),
        ("Clear_02", 1),
        ("Clear_03", 1),
        ("Clear_04", 1),
        ("Clear_05", 1)
    ]
    private let productionMilestoneRounds = [50, 100, 150, 200]
    private let testingMilestoneRounds = [1, 2, 3, 4]
    private let productionRewardMilestones: [Int: String] = [
        50: "Clear_06",
        100: "Clear_07",
        150: "Clear_08",
        200: "Clear_09"
    ]
    private let testingRewardMilestones: [Int: String] = [
        1: "Clear_06",
        2: "Clear_07",
        3: "Clear_08",
        4: "Clear_09"
    ]
    private let productionMilestoneClearMapping: [Int: String] = [
        50: "Clear_01",
        100: "Clear_02",
        150: "Clear_03",
        200: "Clear_04"
    ]
    private let testingMilestoneClearMapping: [Int: String] = [
        1: "Clear_01",
        2: "Clear_02",
        3: "Clear_03",
        4: "Clear_04"
    ]
    private let productionClearUnlockRequirements: [String: Int] = [
        "Clear_06": 50,
        "Clear_07": 100,
        "Clear_08": 150,
        "Clear_09": 200
    ]
    private let testingClearUnlockRequirements: [String: Int] = [
        "Clear_06": 1,
        "Clear_07": 2,
        "Clear_08": 3,
        "Clear_09": 4
    ]

    @Published var currentScreen: AppScreen = .splash
    @Published var currentStage: Int = 1
    @Published var tapCount: Int = 0
    @Published var clearBackgroundName: String = "Clear_01"
    @Published var currentCharacterName: String = "Chara01"
    @Published var currentCharacterPose: CharacterPose = .normal
    @Published var characterOffsetRatio: CGFloat = 0
    @Published var totalClears: Int = 0
    @Published private(set) var unlockedMilestones: Set<Int> = []
    @Published private(set) var unlockedIllustrations: Set<String> = ["Ilustrated_none"]
    @Published var isVibrationEnabled: Bool = true
    @Published private(set) var cumulativeTapCount: Int = 0

    let totalStages: Int = 6
    var tapsPerStage: Int { useTestingAchievementRewards ? 5 : 50 }
    private let characterMoveStep: CGFloat = 0.12
    private var isMovingRight: Bool = false
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
    private var claimedRewardMilestones: Set<Int> = []
    private var forcedClearBackground: String?

    var isDebugModeEnabled: Bool { useTestingAchievementRewards }
    private var milestoneRounds: [Int] {
        useTestingAchievementRewards ? testingMilestoneRounds : productionMilestoneRounds
    }
    private var rewardMilestones: [Int: String] {
        useTestingAchievementRewards ? testingRewardMilestones : productionRewardMilestones
    }
    private var milestoneClearMapping: [Int: String] {
        useTestingAchievementRewards ? testingMilestoneClearMapping : productionMilestoneClearMapping
    }
    private var clearUnlockRequirements: [String: Int] {
        useTestingAchievementRewards ? testingClearUnlockRequirements : productionClearUnlockRequirements
    }
    private var characterWeights: [(name: String, weight: Double)] {
        useTestingAchievementRewards ? testingCharacterWeights : productionCharacterWeights
    }
    private var clearImageWeights: [(name: String, weight: Double)] {
        useTestingAchievementRewards ? testingClearImageWeights : productionClearImageWeights
    }

    var nextMilestoneTarget: Int? {
        milestoneRounds.first(where: { $0 > totalClears })
    }

    var runsUntilNextMilestone: Int? {
        guard let target = nextMilestoneTarget else { return nil }
        return max(target - totalClears, 0)
    }

    var milestoneTargets: [Int] {
        milestoneRounds
    }

    private var availableRewardMilestone: Int? {
        rewardMilestones.keys.sorted().first(where: { totalClears >= $0 && !claimedRewardMilestones.contains($0) })
    }

    var hasClaimableReward: Bool { availableRewardMilestone != nil }

    func claimAchievementReward() -> (imageName: String, milestone: Int)? {
        guard let milestone = availableRewardMilestone,
              let clearName = rewardMilestones[milestone] else { return nil }
        claimedRewardMilestones.insert(milestone)
        unlockIllustration(for: clearName)
        return (clearName, milestone)
    }

    func showHome() {
        currentScreen = .home
    }

    func setVibration(enabled: Bool) {
        isVibrationEnabled = enabled
    }

    func startGame() {
        currentStage = 1
        tapCount = 0
        selectNewCharacter()
        resetCharacterPose()
        resetCharacterPosition()
        currentScreen = .game
    }

    func registerTap() {
        guard currentScreen == .game else { return }
        tapCount += 1
        cumulativeTapCount += 1
        updateCharacterPoseAfterTap()
        updateCharacterPositionAfterTap()
        if tapCount >= tapsPerStage {
            if currentStage >= totalStages {
                registerCompletion()
                selectClearBackground()
                tapCount = 0
                currentScreen = .clear
            } else {
                selectNewCharacter()
                resetCharacterPose()
                resetCharacterPosition()
                currentScreen = .stageChange
            }
        }
    }

    func proceedFromStageChange() {
        guard currentStage < totalStages else {
            tapCount = 0
            currentScreen = .clear
            return
        }
        currentStage += 1
        tapCount = 0
        selectNewCharacter()
        resetCharacterPose()
        resetCharacterPosition()
        currentScreen = .game
    }

    func finishGame() {
        currentStage = 1
        tapCount = 0
        selectNewCharacter()
        resetCharacterPose()
        resetCharacterPosition()
        currentScreen = .home
    }

    private func selectClearBackground() {
        if let forced = forcedClearBackground {
            clearBackgroundName = forced
            forcedClearBackground = nil
            unlockIllustration(for: clearBackgroundName)
            return
        }

        let totalWeight = clearImageWeights.reduce(0.0) { $0 + max($1.weight, 0) }
        guard totalWeight > 0 else {
            clearBackgroundName = clearImageWeights.first?.name ?? "Clear_01"
            unlockIllustration(for: clearBackgroundName)
            return
        }
        let randomPoint = Double.random(in: 0..<totalWeight)
        var cumulative = 0.0
        for entry in clearImageWeights {
            let weight = max(entry.weight, 0)
            cumulative += weight
            if randomPoint < cumulative {
                clearBackgroundName = entry.name
                unlockIllustration(for: clearBackgroundName)
                return
            }
        }
        clearBackgroundName = clearImageWeights.last?.name ?? "Clear_01"
        unlockIllustration(for: clearBackgroundName)
    }

    private func selectNewCharacter() {
        let totalWeight = characterWeights.reduce(0.0) { $0 + max($1.weight, 0) }
        guard totalWeight > 0 else {
            currentCharacterName = characterWeights.first?.name ?? "Chara01"
            return
        }
        let randomPoint = Double.random(in: 0..<totalWeight)
        var cumulative = 0.0
        for entry in characterWeights {
            let weight = max(entry.weight, 0)
            cumulative += weight
            if randomPoint < cumulative {
                currentCharacterName = entry.name
                return
            }
        }
        currentCharacterName = characterWeights.last?.name ?? "Chara01"
    }

    private func resetCharacterPose() {
        currentCharacterPose = .normal
    }

    private func updateCharacterPoseAfterTap() {
        let candidates = CharacterPose.allCases.filter { $0 != currentCharacterPose }
        if let nextPose = candidates.randomElement() {
            currentCharacterPose = nextPose
        }
    }

    private func resetCharacterPosition() {
        characterOffsetRatio = 0
        isMovingRight = false
    }

    private func updateCharacterPositionAfterTap() {
        let direction: CGFloat = isMovingRight ? 1 : -1
        var nextRatio = characterOffsetRatio + characterMoveStep * direction
        if nextRatio <= -1 {
            nextRatio = -1
            isMovingRight = true
        } else if nextRatio >= 1 {
            nextRatio = 1
            isMovingRight = false
        }
        characterOffsetRatio = nextRatio
    }

    private func registerCompletion() {
        totalClears += 1
        for milestone in milestoneRounds where totalClears >= milestone {
            unlockedMilestones.insert(milestone)
        }
        RakutenRewardManager.shared.logClearAction()
        AdjustManager.shared.trackGameCycleCompletion(total: totalClears)
        if let forced = milestoneClearMapping[totalClears] {
            forcedClearBackground = forced
        }
    }

    private func unlockIllustration(for clearName: String) {
        if let illustration = illustrationMapping[clearName] {
            let requirement = clearUnlockRequirements[clearName] ?? 0
            if totalClears >= requirement {
                unlockedIllustrations.insert(illustration)
            }
        } else {
            unlockedIllustrations.insert("Ilustrated_none")
        }
    }
}

struct FlowCoordinatorView: View {
    @EnvironmentObject private var state: AppFlowState

    var body: some View {
        GeometryReader { geometry in
            let padLayout = DeviceLayoutResolver.isPadLayout(for: geometry.size)
            let contentWidth = DeviceLayoutResolver.contentWidth(for: geometry.size, isPadLayout: padLayout)
            ZStack {
                if padLayout {
                    Color.black.ignoresSafeArea()
                }
                ZStack(alignment: .top) {
                    Group {
                        switch state.currentScreen {
                        case .splash:
                            SplashView(onFinish: state.showHome)
                        case .home:
                            HomeView(onStart: state.startGame,
                                     onClaimAchievement: state.claimAchievementReward,
                                     vibrationEnabled: state.isVibrationEnabled,
                                     onVibrationChange: state.setVibration,
                                     hasAchievementReward: state.hasClaimableReward,
                                     unlockedIllustrations: state.unlockedIllustrations,
                                     totalClears: state.totalClears,
                                     nextMilestone: state.nextMilestoneTarget,
                                     runsUntilNext: state.runsUntilNextMilestone)
        case .game:
            GameView(stage: state.currentStage,
                     tapCount: state.tapCount,
                     tapGoal: state.tapsPerStage,
                     characterName: state.currentCharacterName,
                     characterPose: state.currentCharacterPose,
                     characterOffsetRatio: state.characterOffsetRatio,
                     isVibrationEnabled: state.isVibrationEnabled,
                     cumulativeTapCount: state.cumulativeTapCount,
                     onTapAreaPressed: state.registerTap)
                        case .stageChange:
                            StageChangeView(currentStage: state.currentStage,
                                            totalStages: state.totalStages,
                                            onNext: state.proceedFromStageChange)
                        case .clear:
                            GameClearView(backgroundImageName: state.clearBackgroundName,
                                          onFinish: state.finishGame)
                        }
                    }
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
                .frame(width: contentWidth, height: geometry.size.height)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .environment(\.isPadLayout, padLayout)
        }
        .animation(.easeInOut, value: state.currentScreen)
    }
}

struct AdaptiveBackgroundImage: View {
    let imageName: String
    @Environment(\.isPadLayout) private var isPadLayout

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if isPadLayout {
                    Color.black
                        .ignoresSafeArea()
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width,
                               height: geometry.size.height)
                        .clipped()
                        .position(x: geometry.size.width / 2,
                                  y: geometry.size.height / 2)
                        .accessibilityHidden(true)
                } else {
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width,
                               height: geometry.size.height)
                        .clipped()
                        .ignoresSafeArea()
                        .accessibilityHidden(true)
                }
            }
        }
        .ignoresSafeArea(edges: isPadLayout ? [] : .all)
        .allowsHitTesting(false)
    }
}
