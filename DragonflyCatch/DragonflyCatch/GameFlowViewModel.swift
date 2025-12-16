import SwiftUI

enum AppScene: Equatable {
    case splash
    case home
    case game(stage: Int)
    case stageChange(stage: Int)
    case clear

    var identity: String {
        switch self {
        case .splash:
            return "splash"
        case .home:
            return "home"
        case .game(let stage):
            return "game_\(stage)"
        case .stageChange(let stage):
            return "stageChange_\(stage)"
        case .clear:
            return "clear"
        }
    }
}

struct RunProgressStatus {
    let totalRuns: Int
    let runsUntilNext: Int?

    var descriptionText: String {
        if let runsUntilNext {
            return "次の報酬まであと\(runsUntilNext)周"
        } else {
            return "次の報酬まで？？周"
        }
    }
}

final class GameFlowViewModel: ObservableObject {
    static let totalStages = 6
    static let useTestingAchievementRewards = false
    private let stageTransitionDelay: Double = 0.35

    private static let totalRunsKey = "dragonfly_total_runs"
    private static let unlockedMilestonesKey = "dragonfly_unlocked_milestones"
    private static let claimedRewardsKey = "dragonfly_claimed_rewards"
    private static let hapticsEnabledKey = "dragonfly_haptics_enabled"
    private static let unlockedCatalogKey = "dragonfly_unlocked_catalog"
    private static let savedStageKey = "dragonfly_saved_stage"
    private static let savedTotalTapKey = "dragonfly_saved_total_tap"
    private static let savedCharacterKey = "dragonfly_saved_character"
    private static let defaultCatalogImage = "Ilustrated_none"
    private static let productionMilestones = [50, 100, 150, 200]
    private static let testingMilestones = [1, 2, 3, 4]
    private static let productionTapsToClear = 50
    private static let testingTapsToClear = 5
    private static let clearCatalogMap: [String: String] = [
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
    private static let catalogPriority = [
        "Ilustrated_09",
        "Ilustrated_08",
        "Ilustrated_07",
        "Ilustrated_06",
        "Ilustrated_05",
        "Ilustrated_04",
        "Ilustrated_03",
        "Ilustrated_02",
        "Ilustrated_01"
    ]
    private static let catalogDisplayOrder = [
        "Ilustrated_01",
        "Ilustrated_02",
        "Ilustrated_03",
        "Ilustrated_04",
        "Ilustrated_05",
        "Ilustrated_06",
        "Ilustrated_07",
        "Ilustrated_08",
        "Ilustrated_09"
    ]
    private static let productionCatalogMilestoneRewards: [Int: (clear: String, illustrated: String)] = [
        50: ("Clear_06", "Ilustrated_06"),
        100: ("Clear_07", "Ilustrated_07"),
        150: ("Clear_08", "Ilustrated_08"),
        200: ("Clear_09", "Ilustrated_09")
    ]

    private static var milestoneThresholds: [Int] {
        Self.useTestingAchievementRewards ? Self.testingMilestones : Self.productionMilestones
    }

    var tapsToClear: Int {
        Self.useTestingAchievementRewards ? Self.testingTapsToClear : Self.productionTapsToClear
    }

    private var characterWeights: [(name: String, weight: Double)] {
        if Self.useTestingAchievementRewards {
            return [
                ("Chara01", 1),
                ("Chara02", 1),
                ("Chara03", 1),
                ("Chara04", 1),
                ("Chara05", 1)
            ]
        } else {
            return [
                ("Chara01", 0.75),
                ("Chara02", 0.15),
                ("Chara03", 0.035),
                ("Chara04", 0.0132),
                ("Chara05", 0.0018)
            ]
        }
    }

    var isDebugMode: Bool {
        Self.useTestingAchievementRewards
    }

    var hasPendingAchievementReward: Bool {
        Self.catalogMilestoneRewards.keys.contains { totalRuns >= $0 && !claimedRewards.contains($0) }
    }

    var clearBackgroundPicker: WeightedBackgroundPicker {
        if Self.useTestingAchievementRewards {
            let entries = ["Clear_01", "Clear_02", "Clear_03", "Clear_04", "Clear_05"].map {
                WeightedBackgroundPicker.Entry(name: $0, weight: 1)
            }
            return WeightedBackgroundPicker(entries: entries)
        } else {
            return .default
        }
    }

    private static var catalogMilestoneRewards: [Int: (clear: String, illustrated: String)] {
        if useTestingAchievementRewards {
            return [
                1: ("Clear_06", "Ilustrated_06"),
                2: ("Clear_07", "Ilustrated_07"),
                3: ("Clear_08", "Ilustrated_08"),
                4: ("Clear_09", "Ilustrated_09")
            ]
        } else {
            return productionCatalogMilestoneRewards
        }
    }

    @Published var scene: AppScene = .splash
    @Published var currentStage: Int = 1
    @Published var tapCount: Int = 0
    @Published private(set) var runStatus: RunProgressStatus
    @Published private(set) var unlockedMilestones: Set<Int>
    @Published private(set) var currentCharacterImage: String = "Chara01"
    @Published private(set) var totalTapCount: Int = 0
    @Published private(set) var netSwingID: Int = 0
    @Published private(set) var currentCatalogImage: String = defaultCatalogImage
    @Published private(set) var catalogGalleryImages: [String] = [defaultCatalogImage]
    @Published private(set) var pendingClearBackground: String = "Clear_01"
    @Published private(set) var isHapticsEnabled: Bool = true

    private let defaults: UserDefaults
    private var totalRuns: Int
    private var unlockedCatalogs: Set<String>
    private var claimedRewards: Set<Int>
    private var stageBaselineTotal: Int = 0

    init(userDefaults: UserDefaults = .standard) {
        self.defaults = userDefaults
        self.totalRuns = defaults.integer(forKey: Self.totalRunsKey)
        let savedMilestones = defaults.array(forKey: Self.unlockedMilestonesKey) as? [Int] ?? []
        self.unlockedMilestones = Set(savedMilestones)
        let catalogArray = defaults.array(forKey: Self.unlockedCatalogKey) as? [String] ?? []
        self.unlockedCatalogs = Set(catalogArray)
        let claimedArray = defaults.array(forKey: Self.claimedRewardsKey) as? [Int] ?? []
        self.claimedRewards = Set(claimedArray)
        self.currentCatalogImage = Self.catalogImage(from: unlockedCatalogs)
        self.catalogGalleryImages = Self.makeCatalogGallery(from: unlockedCatalogs)
        self.runStatus = Self.makeStatus(totalRuns: totalRuns, milestones: Self.milestoneThresholds)
        if defaults.object(forKey: Self.hapticsEnabledKey) == nil {
            defaults.set(true, forKey: Self.hapticsEnabledKey)
            self.isHapticsEnabled = true
        } else {
            self.isHapticsEnabled = defaults.bool(forKey: Self.hapticsEnabledKey)
        }
        resumeSavedStageIfNeeded()
    }

    func goToHome(resettingProgress: Bool = true) {
        tapCount = 0
        netSwingID = 0
        if resettingProgress {
            currentStage = 1
            totalTapCount = 0
            stageBaselineTotal = 0
            clearSavedStageState()
        } else {
            totalTapCount = stageBaselineTotal
            persistStageState()
        }
        scene = .home
    }

    func startStageSequence() {
        if defaults.integer(forKey: Self.savedStageKey) > 0 {
            resumeSavedStageIfNeeded()
        } else {
            prepareStage(startingAt: 1, preserveTotalTap: false)
        }
    }

    func registerTap() {
        guard case .game = scene else { return }
        guard tapCount < tapsToClear else { return }
        tapCount = min(tapCount + 1, tapsToClear)
        totalTapCount += 1
        netSwingID &+= 1
        persistStageState()
        if tapCount >= tapsToClear {
            completeStage()
        }
    }

    private func completeStage() {
        DispatchQueue.main.asyncAfter(deadline: .now() + stageTransitionDelay) { [weak self] in
            guard let self = self else { return }
            if self.currentStage >= Self.totalStages {
                let background = self.selectClearBackground()
                self.pendingClearBackground = background
                self.unlockCatalogIfNeeded(for: background)
                self.registerFullRun()
                RakutenRewardManager.shared.logClearAction()
                self.scene = .clear
            } else {
                self.scene = .stageChange(stage: self.currentStage)
            }
        }
    }

    private func registerFullRun() {
        totalRuns += 1
        defaults.set(totalRuns, forKey: Self.totalRunsKey)

        var updatedMilestones = unlockedMilestones
        var didUnlock = false
        for milestone in Self.milestoneThresholds where totalRuns >= milestone && !updatedMilestones.contains(milestone) {
            updatedMilestones.insert(milestone)
            didUnlock = true
        }
        if didUnlock {
            unlockedMilestones = updatedMilestones
            defaults.set(Array(updatedMilestones), forKey: Self.unlockedMilestonesKey)
        }

        runStatus = Self.makeStatus(totalRuns: totalRuns, milestones: Self.milestoneThresholds)
        AdjustManager.shared.trackRunCompletion(total: totalRuns)
    }

    func proceedAfterStageChange() {
        guard currentStage < Self.totalStages else { return }
        prepareStage(startingAt: currentStage + 1, preserveTotalTap: true, preservedTotal: totalTapCount)
    }

    func finishAndReturnHome() {
        netSwingID = 0
        clearSavedStageState()
        goToHome(resettingProgress: true)
    }

    func pauseStageAndReturnHome() {
        totalTapCount = stageBaselineTotal
        persistStageState()
        goToHome(resettingProgress: false)
    }

    func setHapticsEnabled(_ enabled: Bool) {
        guard isHapticsEnabled != enabled else { return }
        isHapticsEnabled = enabled
        defaults.set(enabled, forKey: Self.hapticsEnabledKey)
    }

    func claimAchievementReward() -> String? {
        let sortedMilestones = Self.catalogMilestoneRewards.keys.sorted()
        for milestone in sortedMilestones {
            guard totalRuns >= milestone else { continue }
            guard !claimedRewards.contains(milestone) else { continue }
            claimedRewards.insert(milestone)
            defaults.set(Array(claimedRewards), forKey: Self.claimedRewardsKey)
            if let reward = Self.catalogMilestoneRewards[milestone] {
                unlockCatalogIfNeeded(for: reward.clear)
                return reward.clear
            }
        }
        return nil
    }

    private func randomCharacterImage() -> String {
        let totalWeight = characterWeights.reduce(0) { $0 + max($1.weight, 0) }
        guard totalWeight > 0 else { return "Chara01" }

        let point = Double.random(in: 0..<totalWeight)
        var cumulative: Double = 0
        for entry in characterWeights {
            cumulative += max(entry.weight, 0)
            if point < cumulative {
                return entry.name
            }
        }
        return "Chara01"
    }

    private static func makeStatus(totalRuns: Int, milestones: [Int]) -> RunProgressStatus {
        if let next = milestones.first(where: { $0 > totalRuns }) {
            return RunProgressStatus(totalRuns: totalRuns, runsUntilNext: next - totalRuns)
        } else {
            return RunProgressStatus(totalRuns: totalRuns, runsUntilNext: nil)
        }
    }

    private func selectClearBackground() -> String {
        clearBackgroundPicker.pick()
    }

    private func unlockCatalogIfNeeded(for background: String) {
        guard let catalogName = Self.clearCatalogMap[background] else { return }
        if !unlockedCatalogs.contains(catalogName) {
            unlockedCatalogs.insert(catalogName)
            defaults.set(Array(unlockedCatalogs), forKey: Self.unlockedCatalogKey)
            currentCatalogImage = Self.catalogImage(from: unlockedCatalogs)
            catalogGalleryImages = Self.makeCatalogGallery(from: unlockedCatalogs)
        }
    }

    private static func catalogImage(from unlocked: Set<String>) -> String {
        for name in catalogPriority {
            if unlocked.contains(name) {
                return name
            }
        }
        return defaultCatalogImage
    }

    private static func makeCatalogGallery(from unlocked: Set<String>) -> [String] {
        let unlockedList = catalogDisplayOrder.filter { unlocked.contains($0) }
        if unlockedList.count == catalogDisplayOrder.count {
            return unlockedList + [defaultCatalogImage]
        } else if unlockedList.isEmpty {
            return [defaultCatalogImage]
        } else {
            return unlockedList
        }
    }

    private func prepareStage(startingAt stage: Int, preserveTotalTap: Bool, preservedTotal: Int? = nil, preservedCharacter: String? = nil) {
        currentStage = stage
        tapCount = 0
        netSwingID = 0
        let newBaseline = preserveTotalTap ? (preservedTotal ?? stageBaselineTotal) : totalTapCount
        stageBaselineTotal = newBaseline
        totalTapCount = newBaseline
        currentCharacterImage = preservedCharacter ?? randomCharacterImage()
        persistStageState()
        scene = .game(stage: currentStage)
    }

    private func persistStageState() {
        defaults.set(currentStage, forKey: Self.savedStageKey)
        defaults.set(stageBaselineTotal, forKey: Self.savedTotalTapKey)
        defaults.set(currentCharacterImage, forKey: Self.savedCharacterKey)
    }

    private func clearSavedStageState() {
        defaults.removeObject(forKey: Self.savedStageKey)
        defaults.removeObject(forKey: Self.savedTotalTapKey)
        defaults.removeObject(forKey: Self.savedCharacterKey)
    }

    private func resumeSavedStageIfNeeded() {
        let savedStage = defaults.integer(forKey: Self.savedStageKey)
        guard savedStage > 0 else { return }
        let savedTotal = defaults.integer(forKey: Self.savedTotalTapKey)
        let savedCharacter = defaults.string(forKey: Self.savedCharacterKey)
        prepareStage(startingAt: savedStage,
                     preserveTotalTap: true,
                     preservedTotal: savedTotal,
                     preservedCharacter: savedCharacter)
    }
}
