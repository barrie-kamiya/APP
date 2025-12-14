import SwiftUI

struct AppRootView: View {
    @State private var screen: AppScreen
    @State private var stageIndex: Int
    @State private var progress = GameProgress()
    @State private var totalTapCount: Int
    @State private var hapticsEnabled: Bool = true
    @State private var stageStartTotalTapCount: Int = 0

    init() {
        let savedStage = Persistence.stageIndex()
        let savedTaps = Persistence.totalTapCount()
        let resumeGame = Persistence.wasInGame()
        _stageIndex = State(initialValue: max(savedStage, 1))
        _totalTapCount = State(initialValue: savedTaps)
        _screen = State(initialValue: resumeGame ? .game : .splash)
        _stageStartTotalTapCount = State(initialValue: savedTaps)
    }

    var body: some View {
        Group {
            switch screen {
            case .splash:
                SplashView {
                    screen = .home
                }
            case .home:
                HomeView(
                    onStart: startGame,
                    onAttemptAchievementClaim: attemptAchievementRewardClaim,
                    progress: progress,
                    hapticsEnabled: $hapticsEnabled
                )
            case .game:
                GameView(
                    stageIndex: stageIndex,
                    tapGoal: GameFlowConfig.tapGoal,
                    totalTapCount: $totalTapCount,
                    hapticsEnabled: $hapticsEnabled,
                    onStageComplete: {
                        Persistence.saveTotalTapCount(totalTapCount)
                        if stageIndex < GameFlowConfig.maxStages {
                            screen = .stageChange
                        } else {
                            screen = .clear
                        }
                    },
                    onExitToHome: { _ in
                        exitToHome()
                    }
                )
                .id(stageIndex)
            case .stageChange:
                StageChangeView(stageIndex: stageIndex) {
                    if stageIndex < GameFlowConfig.maxStages {
                        stageIndex += 1
                        screen = .game
                    } else {
                        screen = .clear
                    }
                }
            case .clear:
                GameClearView(progress: $progress) {
                    _ = progress.recordLoopClear()
                    if FeatureFlags.isAdjustEnabled {
                        AdjustManager.shared.trackLoopCompletion(total: progress.totalClears)
                    }
                    stageIndex = 1
                    totalTapCount = 0
                    Persistence.saveTotalTapCount(totalTapCount)
                    screen = .home
                }
            case .catalog:
                CatalogView(progress: progress) {
                    screen = .home
                }
            case .achievement:
                AchievementView(progress: $progress) {
                    screen = .home
                }
            }
        }
        .animation(.easeInOut, value: screen)
        .overlay(alignment: .top) {
            if FeatureFlags.useTestingAchievementRewards {
                Text("デバッグモード")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding(.top, 12)
            }
        }
        .onChange(of: stageIndex) { Persistence.saveStageIndex($0) }
        .onChange(of: screen) { newValue in
            Persistence.saveWasInGame(newValue == .game)
            if newValue == .game {
                stageStartTotalTapCount = totalTapCount
            }
        }
        .onAppear {
            Persistence.saveStageIndex(stageIndex)
            Persistence.saveTotalTapCount(totalTapCount)
            Persistence.saveWasInGame(screen == .game)
            if screen == .game {
                stageStartTotalTapCount = totalTapCount
            }
        }
    }

    private func startGame() {
        stageIndex = 1
        screen = .game
    }

    private func attemptAchievementRewardClaim() -> AchievementRewardMapping? {
        guard let milestone = progress.nextClaimableAchievement else { return nil }
        return progress.claimAchievement(for: milestone)
    }

    private func exitToHome() {
        totalTapCount = stageStartTotalTapCount
        Persistence.saveTotalTapCount(totalTapCount)
        screen = .home
    }

    private enum Persistence {
        private enum Keys {
            static let stageIndex = "ddg_stage_index"
            static let totalTaps = "ddg_total_taps"
            static let wasInGame = "ddg_was_in_game"
        }

        static func stageIndex() -> Int {
            UserDefaults.standard.integer(forKey: Keys.stageIndex)
        }

        static func saveStageIndex(_ value: Int) {
            UserDefaults.standard.set(value, forKey: Keys.stageIndex)
        }

        static func totalTapCount() -> Int {
            UserDefaults.standard.integer(forKey: Keys.totalTaps)
        }

        static func saveTotalTapCount(_ value: Int) {
            UserDefaults.standard.set(value, forKey: Keys.totalTaps)
        }

        static func wasInGame() -> Bool {
            UserDefaults.standard.bool(forKey: Keys.wasInGame)
        }

        static func saveWasInGame(_ value: Bool) {
            UserDefaults.standard.set(value, forKey: Keys.wasInGame)
        }
    }
}
