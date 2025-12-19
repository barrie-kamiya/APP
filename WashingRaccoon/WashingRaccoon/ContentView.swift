import SwiftUI

enum AppScreen {
    case splash
    case home
    case game
    case stageChange
    case clear
    case illustrated
}

final class AppViewModel: ObservableObject {
    private enum StorageKeys {
        static let hasResumeData = "WashingRaccoon.hasResumeData"
        static let savedStage = "WashingRaccoon.savedStage"
        static let savedLastStageTotalTapCount = "WashingRaccoon.savedLastStageTotalTapCount"
        static let savedClearCount = "WashingRaccoon.savedClearCount"
        static let savedUnlockedIllustrations = "WashingRaccoon.savedUnlockedIllustrations"
        static let savedPendingMilestones = "WashingRaccoon.savedPendingMilestones"
    }

    @Published var screen: AppScreen = .splash
    @Published var tapCount: Int = 0
    @Published var currentStage: Int = 1
    @Published var totalTapCount: Int = 0
    @Published var lastStageTotalTapCount: Int = 0
    @Published var clearCount: Int = 0
    @Published var unlockedIllustrations: Set<String> = []
    @Published var pendingMilestones: Set<Int> = []
    @Published var currentClearBackgroundName: String = "Clear_01"
    @Published var isVibrationEnabled: Bool = true

    let totalStages: Int = 6
    let tapsToClear: Int = LayoutConfig.useTestingAchievementRewards ? 5 : 50

    init() {
        let defaults = UserDefaults.standard
        let hasResumeData = defaults.bool(forKey: StorageKeys.hasResumeData)
        clearCount = defaults.integer(forKey: StorageKeys.savedClearCount)
        if let storedIllustrations = defaults.array(forKey: StorageKeys.savedUnlockedIllustrations) as? [String] {
            unlockedIllustrations = Set(storedIllustrations)
        }
        if let storedPending = defaults.array(forKey: StorageKeys.savedPendingMilestones) as? [Int] {
            pendingMilestones = Set(storedPending)
        }
        if hasResumeData {
            let savedStage = max(defaults.integer(forKey: StorageKeys.savedStage), 1)
            currentStage = savedStage
            totalTapCount = defaults.integer(forKey: StorageKeys.savedLastStageTotalTapCount)
            lastStageTotalTapCount = totalTapCount
            tapCount = 0
            screen = .game
        }
    }

    func showHome() {
        screen = .home
    }

    func showIllustrated() {
        screen = .illustrated
    }

    func claimAchievementReward() -> String? {
        let nextMilestone = pendingMilestones.sorted().first
        guard let milestone = nextMilestone else { return nil }
        let clearName = milestoneClearName(for: milestone)
        pendingMilestones.remove(milestone)
        unlockIllustration(for: clearName)
        return clearName
    }

    func startGame() {
        let defaults = UserDefaults.standard
        let hasResumeData = defaults.bool(forKey: StorageKeys.hasResumeData)
        if hasResumeData {
            let savedStage = max(defaults.integer(forKey: StorageKeys.savedStage), 1)
            currentStage = savedStage
            totalTapCount = defaults.integer(forKey: StorageKeys.savedLastStageTotalTapCount)
            lastStageTotalTapCount = totalTapCount
        } else {
            currentStage = 1
            totalTapCount = 0
            lastStageTotalTapCount = 0
        }
        tapCount = 0
        screen = .game
        persistResumeData()
    }

    func registerTap() {
        guard screen == .game else { return }
        tapCount = min(tapCount + 1, tapsToClear)
        totalTapCount += 1
        persistResumeData()
        if tapCount >= tapsToClear {
            handleStageCompletion()
        }
    }

    private func handleStageCompletion() {
        lastStageTotalTapCount = totalTapCount
        if currentStage < totalStages {
            screen = .stageChange
        } else {
            currentClearBackgroundName = LayoutConfig.randomClearBackground()
            if FeatureFlags.isRakutenRewardEnabled {
                RakutenRewardManager.shared.trackCycleCompletion()
            }
            screen = .clear
        }
        persistResumeData()
    }

    func proceedFromStageChange() {
        guard screen == .stageChange else { return }
        if currentStage < totalStages {
            currentStage += 1
            tapCount = 0
            screen = .game
        } else {
            screen = .clear
        }
        persistResumeData()
    }

    func finishGameClear() {
        tapCount = 0
        currentStage = 1
        totalTapCount = 0
        lastStageTotalTapCount = 0
        clearCount += 1
        if FeatureFlags.isAdjustEnabled {
            AdjustManager.shared.trackGameCycleCompletion(total: clearCount)
        }
        unlockIllustration(for: currentClearBackgroundName)
        addMilestoneIfNeeded()
        screen = .home
        clearResumeData()
        persistMetaData()
    }

    func returnHomeFromGame() {
        tapCount = 0
        screen = .home
        persistResumeData()
        persistMetaData()
    }

    private func unlockIllustration(for clearBackground: String) {
        let map: [String: String] = [
            "Clear_01": "Ilustrated_01",
            "Clear_02": "Ilustrated_02",
            "Clear_03": "Ilustrated_03",
            "Clear_04": "Ilustrated_04",
            "Clear_05": "Ilustrated_05",
            "Clear_06": "Ilustrated_06",
            "Clear_07": "Ilustrated_07",
            "Clear_08": "Ilustrated_08",
            "Clear_09": "Ilustrated_09",
            "Clear_10": "Ilustrated_10"
        ]
        if let illustrated = map[clearBackground] {
            unlockedIllustrations.insert(illustrated)
            persistMetaData()
        }
    }

    private func addMilestoneIfNeeded() {
        let milestones = LayoutConfig.useTestingAchievementRewards ? [1, 2, 3, 4] : [50, 100, 150, 200]
        if milestones.contains(clearCount) {
            pendingMilestones.insert(clearCount)
            persistMetaData()
        }
    }

    private func milestoneClearName(for milestone: Int) -> String {
        if LayoutConfig.useTestingAchievementRewards {
            switch milestone {
            case 1: return "Clear_07"
            case 2: return "Clear_08"
            case 3: return "Clear_09"
            case 4: return "Clear_10"
            default: return "Clear_07"
            }
        }
        switch milestone {
        case 50: return "Clear_07"
        case 100: return "Clear_08"
        case 150: return "Clear_09"
        case 200: return "Clear_10"
        default: return "Clear_07"
        }
    }

    private func persistResumeData() {
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: StorageKeys.hasResumeData)
        defaults.set(currentStage, forKey: StorageKeys.savedStage)
        defaults.set(lastStageTotalTapCount, forKey: StorageKeys.savedLastStageTotalTapCount)
    }

    private func clearResumeData() {
        let defaults = UserDefaults.standard
        defaults.set(false, forKey: StorageKeys.hasResumeData)
    }

    private func persistMetaData() {
        let defaults = UserDefaults.standard
        defaults.set(clearCount, forKey: StorageKeys.savedClearCount)
        defaults.set(Array(unlockedIllustrations), forKey: StorageKeys.savedUnlockedIllustrations)
        defaults.set(Array(pendingMilestones), forKey: StorageKeys.savedPendingMilestones)
    }
}

struct LayoutContext {
    let size: CGSize
    let isPadLayout: Bool
    let longSide: CGFloat
    let deviceId: String

    init(size: CGSize) {
        self.size = size
        self.longSide = max(size.width, size.height)
        let deviceIsPad = UIDevice.current.userInterfaceIdiom == .pad
        self.isPadLayout = deviceIsPad || longSide >= 1024
        self.deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
    }
}

struct ContentView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        GeometryReader { proxy in
            let context = LayoutContext(size: proxy.size)
            ZStack {
                switch viewModel.screen {
                case .splash:
                    SplashView(context: context) {
                        viewModel.showHome()
                    }
                case .home:
                    HomeView(context: context,
                             clearCount: viewModel.clearCount,
                             canAchievement: !viewModel.pendingMilestones.isEmpty,
                             vibrationEnabled: $viewModel.isVibrationEnabled,
                             onIllustrated: {
                                viewModel.showIllustrated()
                             },
                             achievementsAction: {
                                viewModel.claimAchievementReward()
                             },
                             onStart: {
                                viewModel.startGame()
                             })
                case .game:
                    GameView(context: context,
                             stage: viewModel.currentStage,
                             totalStages: viewModel.totalStages,
                             tapCount: viewModel.tapCount,
                             requiredTaps: viewModel.tapsToClear,
                             totalTapCount: viewModel.totalTapCount,
                             isVibrationEnabled: viewModel.isVibrationEnabled,
                             onHome: {
                                viewModel.returnHomeFromGame()
                             },
                             onTap: {
                                viewModel.registerTap()
                             })
                case .stageChange:
                    StageChangeView(context: context,
                                    stage: viewModel.currentStage,
                                    totalStages: viewModel.totalStages,
                                    onNext: {
                                        viewModel.proceedFromStageChange()
                                    })
                case .clear:
                    GameClearView(context: context,
                                  backgroundName: viewModel.currentClearBackgroundName,
                                  onFinish: {
                        viewModel.finishGameClear()
                    })
                case .illustrated:
                    IllustratedView(context: context,
                                    unlockedIllustrations: viewModel.unlockedIllustrations,
                                    onClose: {
                        viewModel.showHome()
                    })
                }

            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppViewModel())
}
