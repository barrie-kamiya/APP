import SwiftUI

struct AchievementView: View {
    @Binding var progress: GameProgress
    let onClose: () -> Void
    @State private var claimedReward: AchievementRewardMapping?

    private var nextReward: AchievementRewardMapping? {
        guard let milestone = progress.nextClaimableAchievement else { return nil }
        return AchievementRewardMapping.mapping(for: milestone)
    }

    var body: some View {
        GeometryReader { proxy in
            let padding = DeviceTraitHelper.primaryPadding(for: proxy.size)
            VStack(spacing: padding) {
                HStack {
                    Button(action: onClose) {
                        Text("戻る")
                            .font(.headline)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.9))
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                    Spacer()
                }
                .padding(.top, padding)

                Text("達成報酬")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                if let reward = claimedReward {
                    AchievementRewardDisplay(reward: reward)
                        .transition(.opacity)
                } else if let availableReward = nextReward {
                    VStack(spacing: padding) {
                        Text("\(availableReward.milestone)周の報酬が受け取れます")
                            .font(.title3)
                            .foregroundStyle(.white)
        Button(action: {
            claim(reward: availableReward)
        }) {
            Text("受け取る")
                .font(.title2.bold())
                .foregroundStyle(.black)
                                .padding(.horizontal, 40)
                                .padding(.vertical, 14)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                        }
                    }
                } else {
                    Text("現在受け取れる報酬はありません")
                        .font(.title3)
                        .foregroundStyle(.white)
                }

                Spacer()
            }
            .padding(padding)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                LinearGradient(colors: [.black, .blue.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            )
        }
        .ignoresSafeArea()
    }

    private func claim(reward: AchievementRewardMapping) {
        if let confirmedReward = progress.claimAchievement(for: reward.milestone) {
            claimedReward = confirmedReward
        }
    }
}

private struct AchievementRewardDisplay: View {
    let reward: AchievementRewardMapping

    var body: some View {
        VStack(spacing: 16) {
            Image(reward.clearImageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 420)
                .shadow(radius: 10)
            Text("\(reward.milestone)周クリア達成！")
                .font(.title)
                .foregroundStyle(.white)
            Text("図鑑 \(reward.illustration.displayName) を解放しました")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 32)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    var sample = GameProgress()
    sample.totalClears = 120
    return AchievementView(progress: .constant(sample), onClose: {})
}
