import Foundation

struct GameProgress {
    static var milestoneLoops: [Int] {
        if FeatureFlags.useTestingAchievementRewards {
            return [1, 2, 3, 4]
        }
        return [50, 100, 150, 200]
    }

    var totalClears: Int = 0
    var unlockedMilestones: Set<Int> = []
    var unlockedIllustrations: Set<IllustrationID> = [.none]
    var claimedAchievementMilestones: Set<Int> = []

    mutating func recordLoopClear() -> LoopClearResult {
        totalClears += 1

        var newlyUnlockedMilestones: [Int] = []
        for milestone in Self.milestoneLoops where totalClears >= milestone && !unlockedMilestones.contains(milestone) {
            unlockedMilestones.insert(milestone)
            newlyUnlockedMilestones.append(milestone)
        }

        return LoopClearResult(
            newlyUnlockedMilestones: newlyUnlockedMilestones
        )
    }

    mutating func unlockIllustration(_ illustration: IllustrationID) {
        unlockedIllustrations.insert(illustration)
    }

    var nextMilestone: Int? {
        Self.milestoneLoops.first { $0 > totalClears }
    }

    var remainingToNextMilestone: Int? {
        guard let next = nextMilestone else { return nil }
        return max(next - totalClears, 0)
    }

    var unlockedMilestonesSorted: [Int] {
        unlockedMilestones.sorted()
    }

    var claimableAchievements: [Int] {
        Self.milestoneLoops.filter { totalClears >= $0 && !claimedAchievementMilestones.contains($0) }
    }

    var nextClaimableAchievement: Int? {
        claimableAchievements.sorted().first
    }

    mutating func claimAchievement(for milestone: Int) -> AchievementRewardMapping? {
        guard Self.milestoneLoops.contains(milestone),
              totalClears >= milestone,
              !claimedAchievementMilestones.contains(milestone),
              let reward = AchievementRewardMapping.mapping(for: milestone) else {
            return nil
        }
        claimedAchievementMilestones.insert(milestone)
        unlockedIllustrations.insert(reward.illustration)
        return reward
    }
}

struct LoopClearResult {
    let newlyUnlockedMilestones: [Int]
}

enum IllustrationID: String, CaseIterable, Hashable {
    case none = "Ilustrated_none"
    case one = "Ilustrated_01"
    case two = "Ilustrated_02"
    case three = "Ilustrated_03"
    case four = "Ilustrated_04"
    case five = "Ilustrated_05"
    case six = "Ilustrated_06"
    case seven = "Ilustrated_07"
    case eight = "Ilustrated_08"
    case nine = "Ilustrated_09"

    var displayName: String {
        switch self {
        case .none:
            return "図鑑 (デフォルト)"
        case .one:
            return "図鑑 01"
        case .two:
            return "図鑑 02"
        case .three:
            return "図鑑 03"
        case .four:
            return "図鑑 04"
        case .five:
            return "図鑑 05"
        case .six:
            return "図鑑 06"
        case .seven:
            return "図鑑 07"
        case .eight:
            return "図鑑 08"
        case .nine:
            return "図鑑 09"
        }
    }
}

struct AchievementRewardMapping {
    let milestone: Int
    let clearImageName: String
    let illustration: IllustrationID

    static var mappings: [AchievementRewardMapping] {
        if FeatureFlags.useTestingAchievementRewards {
            return [
                AchievementRewardMapping(milestone: 1, clearImageName: "Clear_06", illustration: .six),
                AchievementRewardMapping(milestone: 2, clearImageName: "Clear_07", illustration: .seven),
                AchievementRewardMapping(milestone: 3, clearImageName: "Clear_08", illustration: .eight),
                AchievementRewardMapping(milestone: 4, clearImageName: "Clear_09", illustration: .nine)
            ]
        }
        return [
            AchievementRewardMapping(milestone: 50, clearImageName: "Clear_06", illustration: .six),
            AchievementRewardMapping(milestone: 100, clearImageName: "Clear_07", illustration: .seven),
            AchievementRewardMapping(milestone: 150, clearImageName: "Clear_08", illustration: .eight),
            AchievementRewardMapping(milestone: 200, clearImageName: "Clear_09", illustration: .nine)
        ]
    }

    static func mapping(for milestone: Int) -> AchievementRewardMapping? {
        mappings.first { $0.milestone == milestone }
    }
}
