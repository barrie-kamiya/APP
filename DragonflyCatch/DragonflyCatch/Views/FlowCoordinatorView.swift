import SwiftUI

struct FlowCoordinatorView: View {
    @StateObject private var viewModel = GameFlowViewModel()

    var body: some View {
        ZStack {
            switch viewModel.scene {
            case .splash:
                SplashView {
                    viewModel.goToHome()
                }
            case .home:
                HomeView(status: viewModel.runStatus,
                         catalogImages: viewModel.catalogGalleryImages,
                         isHapticsEnabled: viewModel.isHapticsEnabled,
                         canClaimAchievement: viewModel.hasPendingAchievementReward,
                         startAction: {
                             viewModel.startStageSequence()
                         }, tradeAction: {
                             RakutenRewardManager.shared.openPortal()
                         }, achievementsAction: {
                             viewModel.claimAchievementReward()
                         }, onHapticsChange: { enabled in
                             viewModel.setHapticsEnabled(enabled)
                         })
            case .game(let stage):
                GameView(stageIndex: stage,
                         tapCount: viewModel.tapCount,
                         tapsRequired: viewModel.tapsToClear,
                         totalTapCount: viewModel.totalTapCount,
                         characterImage: viewModel.currentCharacterImage,
                         netSwingID: viewModel.netSwingID,
                         isDebugMode: viewModel.isDebugMode,
                         isHapticsEnabled: viewModel.isHapticsEnabled,
                         onRequestHome: {
                             viewModel.pauseStageAndReturnHome()
                         },
                         onTapButton: {
                             viewModel.registerTap()
                         })
            case .stageChange(let stage):
                StageChangeView(stageIndex: stage) {
                    viewModel.proceedAfterStageChange()
                }
            case .clear:
                GameClearView(backgroundName: viewModel.pendingClearBackground) {
                    viewModel.finishAndReturnHome()
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.scene.identity)
    }
}
