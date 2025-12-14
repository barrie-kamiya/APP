import SwiftUI

struct GameClearView: View {
    @Binding var progress: GameProgress
    let onFinish: () -> Void
    @State private var rewardImageName: String = "Clear_01"

    var body: some View {
        GeometryReader { proxy in
            let isPad = DeviceTraitHelper.isPad(for: proxy.size)
            let padding = DeviceTraitHelper.primaryPadding(for: proxy.size)

            ZStack {
                AspectFitBackground(imageName: rewardImageName)

                VStack {
                    Spacer()
                    Button(action: onFinish) {
                        Image("OK")
                            .resizable()
                            .scaledToFit()
                            .frame(width: isPad ? 320 : 220, height: isPad ? 100 : 72)
                            .contentShape(Rectangle())
                            .shadow(radius: 8)
                    }
                    .padding(.bottom, padding * (isPad ? 2.2 : 1.6))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea()
        .onAppear {
            selectRewardIllustration()
            RakutenRewardManager.shared.trackGameClearReward()
        }
    }

    private func selectRewardIllustration() {
        let reward = WeightedClearReward.randomReward()
        rewardImageName = reward.imageName
        progress.unlockIllustration(reward.illustration)
    }
}

private struct WeightedClearReward {
    let imageName: String
    let illustration: IllustrationID
    let weight: Double

    static var table: [WeightedClearReward] {
        if FeatureFlags.useTestingAchievementRewards {
            let rewards: [WeightedClearReward] = [
                WeightedClearReward(imageName: "Clear_01", illustration: .one, weight: 1),
                WeightedClearReward(imageName: "Clear_02", illustration: .two, weight: 1),
                WeightedClearReward(imageName: "Clear_03", illustration: .three, weight: 1),
                WeightedClearReward(imageName: "Clear_04", illustration: .four, weight: 1),
                WeightedClearReward(imageName: "Clear_05", illustration: .five, weight: 1)
            ]
            return rewards
        }
        return [
            WeightedClearReward(imageName: "Clear_01", illustration: .one, weight: 0.75),
            WeightedClearReward(imageName: "Clear_02", illustration: .two, weight: 0.15),
            WeightedClearReward(imageName: "Clear_03", illustration: .three, weight: 0.035),
            WeightedClearReward(imageName: "Clear_04", illustration: .four, weight: 0.0132),
            WeightedClearReward(imageName: "Clear_05", illustration: .five, weight: 0.0018)
        ]
    }

    static func randomReward() -> WeightedClearReward {
        let total = table.reduce(0.0) { $0 + $1.weight }
        let randomValue = Double.random(in: 0..<max(total, 0.0001))
        var cumulative: Double = 0
        for reward in table {
            cumulative += reward.weight
            if randomValue < cumulative {
                return reward
            }
        }
        return table.last ?? table[0]
    }
}

#Preview {
    GameClearView(progress: .constant(GameProgress()), onFinish: {})
}
