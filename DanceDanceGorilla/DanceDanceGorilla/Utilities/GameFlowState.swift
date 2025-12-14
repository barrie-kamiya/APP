import Foundation

enum AppScreen: Equatable {
    case splash
    case home
    case game
    case stageChange
    case clear
    case catalog
    case achievement
}

struct GameFlowConfig {
    static let maxStages = 6
    static var tapGoal: Int {
        FeatureFlags.useTestingAchievementRewards ? 5 : 50
    }
}
