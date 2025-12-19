import SwiftUI

struct PercentPoint {
    let x: CGFloat
    let y: CGFloat
}

struct HomeLayout {
    let illustrated: PercentPoint
    let exchange: PercentPoint
    let settings: PercentPoint
    let achievement: PercentPoint
    let start: PercentPoint
    let statusCenter: PercentPoint
    let statusSize: CGSize
    let actionButtonSize: CGSize
    let achievementButtonSize: CGSize
    let startButtonSize: CGSize
}

struct GameLayout {
    let tapAreaCenter: PercentPoint
    let tapAreaHeight: CGFloat
    let tapButtonSize: CGSize
    let remainingInfoCenter: PercentPoint
    let remainingInfoSize: CGSize
    let totalInfoCenter: PercentPoint
    let totalInfoSize: CGSize
    let homeButtonCenter: PercentPoint
    let homeButtonSize: CGSize
    let characterCenter: PercentPoint
    let characterSize: CGSize
    let characterOrbitRadius: CGSize
    let characterAngleStep: CGFloat
    let debugBadgeCenter: PercentPoint
    let debugBadgeSize: CGSize
}

struct StageChangeLayout {
    let nextButton: PercentPoint
    let nextButtonSize: CGSize
}

struct GameClearLayout {
    let finishButton: PercentPoint
}

enum LayoutConfig {
    static let characterWeights: [Double] = useTestingAchievementRewards
        ? [1, 1, 1, 1, 1, 1]
        : [0.75, 0.15, 0.045, 0.025, 0.02, 0.01]
    static let clearBackgroundWeights: [Double] = useTestingAchievementRewards
        ? [1, 1, 1, 1, 1, 1]
        : [0.75, 0.15, 0.045, 0.025, 0.02, 0.01]
    static let useTestingAchievementRewards: Bool = false
    static let achievementMilestones: [Int] = useTestingAchievementRewards ? [1, 2, 3, 4] : [50, 100, 150, 200]

    static func point(_ percent: PercentPoint, in size: CGSize) -> CGPoint {
        CGPoint(x: size.width * percent.x, y: size.height * percent.y)
    }

    static func home(isPad: Bool) -> HomeLayout {
        if isPad {
            return HomeLayout(
                illustrated: PercentPoint(x: 0.29, y: 0.38),
                exchange: PercentPoint(x: 0.5, y: 0.38),
                settings: PercentPoint(x: 0.71, y: 0.38),
                achievement: PercentPoint(x: 0.5, y: 0.28),
                start: PercentPoint(x: 0.5, y: 0.75),
                statusCenter: PercentPoint(x: 0.5, y: 0.5),
                statusSize: CGSize(width: 320, height: 70),
                actionButtonSize: CGSize(width: 200, height: 70),
                achievementButtonSize: CGSize(width: 210, height: 70),
                startButtonSize: CGSize(width: 420, height: 300)
            )
        }

        return HomeLayout(
            illustrated: PercentPoint(x: 0.18, y: 0.36),
            exchange: PercentPoint(x: 0.5, y: 0.36),
            settings: PercentPoint(x: 0.82, y: 0.36),
            achievement: PercentPoint(x: 0.5, y: 0.28),
            start: PercentPoint(x: 0.5, y: 0.78),
            statusCenter: PercentPoint(x: 0.5, y: 0.49),
            statusSize: CGSize(width: 220, height: 56),
            actionButtonSize: CGSize(width: 140, height: 52),
            achievementButtonSize: CGSize(width: 150, height: 52),
            startButtonSize: CGSize(width: 280, height: 250)
        )
    }

    static func game(isPad: Bool) -> GameLayout {
        if isPad {
            return GameLayout(
                tapAreaCenter: PercentPoint(x: 0.5, y: 0.75),
                tapAreaHeight: 0.48,
                tapButtonSize: CGSize(width: 400, height: 280),
                remainingInfoCenter: PercentPoint(x: 0.25, y: 0.1),
                remainingInfoSize: CGSize(width: 100, height: 90),
                totalInfoCenter: PercentPoint(x: 0.68, y: 0.48),
                totalInfoSize: CGSize(width: 220, height: 40),
                homeButtonCenter: PercentPoint(x: 0.75, y: 0.07),
                homeButtonSize: CGSize(width: 100, height: 30),
                characterCenter: PercentPoint(x: 0.5, y: 0.35),
                characterSize: CGSize(width: 170, height: 170),
                characterOrbitRadius: CGSize(width: 120, height: 50),
                characterAngleStep: 0.22,
                debugBadgeCenter: PercentPoint(x: 0.5, y: 0.06),
                debugBadgeSize: CGSize(width: 220, height: 40)
            )
        }

        return GameLayout(
            tapAreaCenter: PercentPoint(x: 0.5, y: 0.75),
            tapAreaHeight: 0.5,
            tapButtonSize: CGSize(width: 320, height: 260),
            remainingInfoCenter: PercentPoint(x: 0.15, y: 0.06),
            remainingInfoSize: CGSize(width: 80, height: 80),
            totalInfoCenter: PercentPoint(x: 0.74, y: 0.49),
            totalInfoSize: CGSize(width: 180, height: 30),
            homeButtonCenter: PercentPoint(x: 0.85, y: 0.03),
            homeButtonSize: CGSize(width: 80, height: 20),
            characterCenter: PercentPoint(x: 0.5, y: 0.25),
            characterSize: CGSize(width: 160, height: 160),
            characterOrbitRadius: CGSize(width: 90, height: 70),
            characterAngleStep: 0.26,
            debugBadgeCenter: PercentPoint(x: 0.5, y: 0.07),
            debugBadgeSize: CGSize(width: 180, height: 34)
        )
    }

    static func stageChange(isPad: Bool) -> StageChangeLayout {
        if isPad {
            return StageChangeLayout(
                nextButton: PercentPoint(x: 0.5, y: 0.5),
                nextButtonSize: CGSize(width: 260, height: 90)
            )
        }
        return StageChangeLayout(
            nextButton: PercentPoint(x: 0.5, y: 0.47),
            nextButtonSize: CGSize(width: 200, height: 72)
        )
    }

    static func gameClear(isPad: Bool) -> GameClearLayout {
        GameClearLayout(
            finishButton: PercentPoint(x: 0.5, y: isPad ? 0.9 : 0.9)
        )
    }

    static func randomClearBackground() -> String {
        let names = ["Clear_01", "Clear_02", "Clear_03", "Clear_04", "Clear_05", "Clear_06"]
        let weights = clearBackgroundWeights
        guard names.count == weights.count else { return "Clear_01" }
        let total = weights.reduce(0, +)
        if total <= 0 { return "Clear_01" }
        let roll = Double.random(in: 0..<total)
        var running = 0.0
        for (index, weight) in weights.enumerated() {
            running += weight
            if roll < running {
                return names[index]
            }
        }
        return names.last ?? "Clear_01"
    }

    static func randomCharacterName() -> String {
        let names = ["Chara01", "Chara02", "Chara03", "Chara04", "Chara05", "Chara06"]
        let weights = characterWeights
        guard names.count == weights.count else { return "Chara01" }
        let total = weights.reduce(0, +)
        if total <= 0 { return "Chara01" }
        let roll = Double.random(in: 0..<total)
        var running = 0.0
        for (index, weight) in weights.enumerated() {
            running += weight
            if roll < running {
                return names[index]
            }
        }
        return names.last ?? "Chara01"
    }
}
