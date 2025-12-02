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

    let totalStages = 6
    let targetTaps = 50

    func handleSplashTap() {
        currentScreen = .home
    }

    func startGame() {
        resetProgress(forNewRun: true)
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
    }

    private func handleStageCompletion() {
        if currentStage < totalStages {
            currentScreen = .stageChange
        } else {
            currentScreen = .clear
        }
    }

    private func resetProgress(forNewRun: Bool) {
        tapCount = 0
        if forNewRun {
            currentStage = 1
        }
    }
}
