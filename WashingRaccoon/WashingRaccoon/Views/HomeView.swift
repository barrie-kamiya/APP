import SwiftUI

struct HomeView: View {
    let context: LayoutContext
    let clearCount: Int
    let canAchievement: Bool
    @Binding var vibrationEnabled: Bool
    let onIllustrated: () -> Void
    let achievementsAction: () -> String?
    let onStart: () -> Void
    @State private var achievementPulse = false
    @State private var isSettingsPresented = false
    @State private var showingAchievementImage: String? = nil
    @State private var achievementSlideIn = false

    var body: some View {
        GeometryReader { proxy in
            let layout = LayoutConfig.home(isPad: context.isPadLayout)
            let size = proxy.size
            let nextGoal = LayoutConfig.achievementMilestones.first(where: { $0 > clearCount })
            let remaining = max((nextGoal ?? clearCount) - clearCount, 0)
            ZStack {
                BackgroundImageView(name: "HomeView", isPadLayout: context.isPadLayout)

                VStack(spacing: 4) {
                    Text("\(clearCount)週クリア")
                    Text(nextGoal == nil ? "次の報酬まであと??周" : "次の報酬まであと\(remaining)周")
                }
                .font(.system(size: context.isPadLayout ? 18 : 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: layout.statusSize.width, height: layout.statusSize.height)
                .background(Color.black.opacity(0.4))
                .cornerRadius(10)
                .position(LayoutConfig.point(layout.statusCenter, in: size))

                Button(action: onIllustrated) {
                    Image("Illustrated")
                        .resizable()
                        .scaledToFit()
                }
                .frame(width: layout.actionButtonSize.width, height: layout.actionButtonSize.height)
                .position(LayoutConfig.point(layout.illustrated, in: size))

                Button(action: {
                    RakutenRewardManager.shared.openPortal()
                }) {
                    Image("Exchange")
                        .resizable()
                        .scaledToFit()
                }
                .frame(width: layout.actionButtonSize.width, height: layout.actionButtonSize.height)
                .position(LayoutConfig.point(layout.exchange, in: size))

                Button(action: {
                    isSettingsPresented = true
                }) {
                    Image("Setting")
                        .resizable()
                        .scaledToFit()
                }
                .frame(width: layout.actionButtonSize.width, height: layout.actionButtonSize.height)
                .position(LayoutConfig.point(layout.settings, in: size))

                Button(action: {
                    if let rewardImage = achievementsAction() {
                        presentAchievement(image: rewardImage)
                    }
                }) {
                    Image("Present")
                        .resizable()
                        .scaledToFit()
                }
                .frame(width: layout.achievementButtonSize.width, height: layout.achievementButtonSize.height)
                .position(LayoutConfig.point(layout.achievement, in: size))
                .opacity(canAchievement ? 1.0 : 0.5)
                .scaleEffect(canAchievement && achievementPulse ? 1.08 : 1.0)
                .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true),
                           value: achievementPulse)
                .disabled(!canAchievement)
                .onAppear {
                    if canAchievement {
                        achievementPulse = true
                    }
                }
                .onChange(of: canAchievement) { isEnabled in
                    achievementPulse = isEnabled
                }

                Button(action: onStart) {
                    Image("Start")
                        .resizable()
                        .scaledToFit()
                }
                .frame(width: layout.startButtonSize.width, height: layout.startButtonSize.height)
                .position(LayoutConfig.point(layout.start, in: size))

                if isSettingsPresented {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            isSettingsPresented = false
                        }

                    VStack(spacing: context.isPadLayout ? 24 : 16) {
                        Image("Vibration")
                            .resizable()
                            .scaledToFit()
                            .frame(width: context.isPadLayout ? 280 : 220)

                        HStack(spacing: context.isPadLayout ? 20 : 12) {
                            Button("ON") {
                                vibrationEnabled = true
                            }
                            .frame(width: context.isPadLayout ? 120 : 90,
                                   height: context.isPadLayout ? 44 : 36)
                            .background(vibrationEnabled ? Color.green.opacity(0.8) : Color.gray.opacity(0.4))
                            .cornerRadius(8)

                            Button("OFF") {
                                vibrationEnabled = false
                            }
                            .frame(width: context.isPadLayout ? 120 : 90,
                                   height: context.isPadLayout ? 44 : 36)
                            .background(!vibrationEnabled ? Color.red.opacity(0.8) : Color.gray.opacity(0.4))
                            .cornerRadius(8)
                        }
                        .font(.system(size: context.isPadLayout ? 18 : 14, weight: .semibold))
                        .foregroundColor(.white)

                        Button(action: {
                            isSettingsPresented = false
                        }) {
                            Image("Close")
                                .resizable()
                                .scaledToFit()
                                .frame(width: context.isPadLayout ? 90 : 72,
                                       height: context.isPadLayout ? 90 : 72)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(context.isPadLayout ? 28 : 20)
                    .frame(maxWidth: context.isPadLayout ? 520 : 360)
                    .background(Color.white)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.black.opacity(0.1), lineWidth: 1)
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .onTapGesture {
                        // 背景タップで閉じるための受け皿
                    }
                }

                if let achievementImage = showingAchievementImage {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()

                    GeometryReader { overlayProxy in
                        VStack(spacing: 0) {
                            Image(achievementImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: overlayProxy.size.width,
                                       height: overlayProxy.size.height)
                                .clipped()
                        }
                        .overlay(alignment: .bottom) {
                            Button {
                                hideAchievementOverlay()
                            } label: {
                                Image("Close")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: context.isPadLayout ? 90 : 72,
                                           height: context.isPadLayout ? 90 : 72)
                                    .padding(.bottom, overlayProxy.safeAreaInsets.bottom + 12)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("閉じる")
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .offset(y: achievementSlideIn ? 0 : overlayProxy.size.height)
                        .animation(.spring(response: 0.55, dampingFraction: 0.85, blendDuration: 0.2),
                                   value: achievementSlideIn)
                    }
                    .onAppear {
                        achievementSlideIn = false
                        withAnimation(.spring(response: 0.55, dampingFraction: 0.85, blendDuration: 0.2)) {
                            achievementSlideIn = true
                        }
                    }
                }
            }
            .frame(width: size.width, height: size.height)
        }
    }

    private func presentAchievement(image: String) {
        achievementSlideIn = false
        showingAchievementImage = image
        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85, blendDuration: 0.2)) {
                achievementSlideIn = true
            }
        }
    }

    private func hideAchievementOverlay() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.9, blendDuration: 0.2)) {
            achievementSlideIn = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            showingAchievementImage = nil
        }
    }
}
