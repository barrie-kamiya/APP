import SwiftUI

struct HomeView: View {
    let onStart: () -> Void
    let onAttemptAchievementClaim: () -> AchievementRewardMapping?
    let progress: GameProgress
    @Binding var hapticsEnabled: Bool

    private let buttonRows: [[MenuButtonItem]] = [
        [
            .init(title: "こうかん", assetName: "Exchange", action: .exchange),
            .init(title: "たっせい", assetName: "Present", action: .achievement)
        ],
        [
            .init(title: "ずかん", assetName: "Illustrated", action: .catalog),
            .init(title: "せってい", assetName: "Setting", action: .settings)
        ]
    ]
    @State private var showSettings = false
    @State private var showCatalog = false
    @State private var selectedIllustration: IllustrationID?
    @State private var rewardToDisplay: AchievementRewardMapping?
    @State private var showNoAchievementAlert = false

    var body: some View {
        GeometryReader { proxy in
            let isPad = DeviceTraitHelper.isPad(for: proxy.size)
            let padding = DeviceTraitHelper.primaryPadding(for: proxy.size)
            let buttonTopSpacingRatio: CGFloat = isPad ? 0.16 : 0.095
            let buttonTopSpacing = max(proxy.size.height * buttonTopSpacingRatio, padding)
            let statusLift = proxy.size.height * (isPad ? 0.08 : 0.15)
            let startLift = proxy.size.height * (isPad ? 0.05 : 0.08)

            ZStack {
                AspectFitBackground(imageName: "HomeView")

                VStack(spacing: padding) {
                    ButtonGrid(buttonRows: buttonRows, isPad: isPad, progress: progress) { action in
                        handleMenuAction(action)
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
                .padding([.leading, .trailing], padding)
                .padding(.top, buttonTopSpacing)

                VStack(spacing: padding) {
                    HomeStatusView(progress: progress, isPad: isPad)
                        .padding(.horizontal, isPad ? 80 : 40)
                        .padding(.bottom, padding * 0.5)
                        .offset(y: -statusLift)
                    StartButton(isPad: isPad, action: onStart)
                        .padding(.bottom, padding * 1.5)
                        .offset(y: -startLift)
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                if showSettings {
                    SettingsOverlay(isPresented: $showSettings, hapticsEnabled: $hapticsEnabled, isPad: isPad)
                }
            }
            .overlay {
                if showCatalog {
                    CatalogOverlay(progress: progress,
                                   isPad: isPad,
                                   isPresented: $showCatalog,
                                   selectedIllustration: $selectedIllustration)
                }
            }
            .overlay {
                if let reward = rewardToDisplay {
                    ZStack {
                        Color.black
                            .ignoresSafeArea()
                            .opacity(0.65)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                                    rewardToDisplay = nil
                                }
                            }
                        AchievementRewardOverlay(reward: reward,
                                                  isPad: isPad,
                                                  dismiss: {
                                                      withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                                                          rewardToDisplay = nil
                                                      }
                                                  })
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
        }
        .alert("現在受け取れる達成報酬はありません", isPresented: $showNoAchievementAlert) {
            Button("OK", role: .cancel) { }
        }
    }
}

private struct MenuButtonItem: Identifiable {
    let id = UUID()
    let title: String
    let assetName: String
    let action: MenuAction
}

private enum MenuAction {
    case exchange
    case catalog
    case settings
    case achievement
}

private struct ButtonGrid: View {
    let buttonRows: [[MenuButtonItem]]
    let isPad: Bool
    let progress: GameProgress
    let action: (MenuAction) -> Void

    var body: some View {
        VStack(spacing: isPad ? 24 : 16) {
            ForEach(buttonRows.indices, id: \.self) { rowIndex in
                let row = buttonRows[rowIndex]
                HStack(spacing: spacing(for: rowIndex)) {
                    ForEach(row) { item in
                        MenuButtonView(item: item,
                                       isPad: isPad,
                                       isEnabled: isEnabled(for: item),
                                       showPulse: shouldPulse(for: item),
                                       action: { action(item.action) })
                        .frame(maxWidth: isPad ? nil : .infinity)
                    }
                }
            }
        }
    }

    private func spacing(for rowIndex: Int) -> CGFloat {
        guard isPad else { return 16 }
        return rowIndex == 0 ? 12 : 12
    }

    private func isEnabled(for item: MenuButtonItem) -> Bool {
        switch item.action {
        case .achievement:
            return hasClaimableAchievement
        default:
            return true
        }
    }

    private func shouldPulse(for item: MenuButtonItem) -> Bool {
        item.action == .achievement && hasClaimableAchievement
    }

    private var hasClaimableAchievement: Bool {
        progress.claimableAchievements.count > 0
    }
}

private struct MenuButtonView: View {
    let item: MenuButtonItem
    let isPad: Bool
    let isEnabled: Bool
    let showPulse: Bool
    let action: () -> Void

    @State private var pulseScale: CGFloat = 1

    var body: some View {
        Button(action: action) {
            Image(item.assetName)
                .resizable()
                .scaledToFit()
                .frame(width: isPad ? 250 : nil)
                .frame(height: isPad ? 70 : 60)
                .contentShape(Rectangle())
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.4)
        .scaleEffect(showPulse ? pulseScale : 1)
        .onAppear(perform: configurePulse)
        .onChange(of: showPulse) { _ in configurePulse() }
        .onChange(of: isEnabled) { _ in configurePulse() }
    }

    private func configurePulse() {
        guard showPulse, isEnabled else {
            pulseScale = 1
            return
        }
        pulseScale = 1
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            pulseScale = 1.05
        }
    }
}

private struct StartButton: View {
    let isPad: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image("Start")
                .resizable()
                .scaledToFit()
                .frame(width: isPad ? 300 : 220, height: isPad ? 300 : 220)
        }
        .accessibilityLabel("スタート")
    }
}

private struct HomeStatusView: View {
    let progress: GameProgress
    let isPad: Bool

    var body: some View {
        VStack(spacing: 6) {
            Text("\(progress.totalClears)周クリア")
                .font(isPad ? .system(size: 36, weight: .bold) : .title2.bold())
            if let remaining = progress.remainingToNextMilestone, let milestone = progress.nextMilestone {
                Text("次の報酬まであと \(remaining)周")
                    .font(isPad ? .system(size: 32, weight: .bold) : .title2.bold())
            } else {
                Text("全ての特別図鑑を解放済み")
                    .font(isPad ? .title2 : .headline)
            }
        }
        .foregroundStyle(.white)
        .multilineTextAlignment(.center)
        .padding(isPad ? 26 : 14)
        .background(.black.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: isPad ? 32 : 30, style: .continuous))
    }
}

private struct SettingsOverlay: View {
    @Binding var isPresented: Bool
    @Binding var hapticsEnabled: Bool
    let isPad: Bool

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
                .opacity(0.5)
                .onTapGesture {
                    isPresented = false
                }
            VStack(spacing: isPad ? 24 : 16) {
                HStack {
                    Spacer()
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(isPad ? .title : .title2)
                            .foregroundStyle(.white)
                    }
                }
                Image("Vibration")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: isPad ? 240 : 180)
                HStack(spacing: isPad ? 24 : 16) {
                    SettingToggleButton(title: "ON", isSelected: hapticsEnabled, isPad: isPad) {
                        hapticsEnabled = true
                    }
                    SettingToggleButton(title: "OFF", isSelected: !hapticsEnabled, isPad: isPad) {
                        hapticsEnabled = false
                    }
                }
            }
            .padding(isPad ? 32 : 20)
            .background(Color.white.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: isPad ? 36 : 24, style: .continuous))
            .padding(isPad ? 80 : 40)
        }
    }
}

private struct SettingToggleButton: View {
    let title: String
    let isSelected: Bool
    let isPad: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(isPad ? .title2.bold() : .headline.bold())
                .foregroundStyle(isSelected ? Color.white : Color.gray)
                .padding(.horizontal, isPad ? 32 : 20)
                .padding(.vertical, isPad ? 16 : 10)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: isPad ? 28 : 20, style: .continuous))
        }
    }
}

private struct CatalogOverlay: View {
    let progress: GameProgress
    let isPad: Bool
    @Binding var isPresented: Bool
    @Binding var selectedIllustration: IllustrationID?

    private var displayList: [IllustrationID] {
        var ids = IllustrationID.allCases.filter { $0 != .none }
        let allUnlocked = ids.allSatisfy { progress.unlockedIllustrations.contains($0) }
        if allUnlocked {
            ids.append(.none)
        }
        return ids
    }

    var body: some View {
        GeometryReader { proxy in
            let safeInsets = proxy.safeAreaInsets
            let containerWidth = min(proxy.size.width * (isPad ? 0.55 : 0.9), isPad ? 540 : 360)
            let itemHeight = containerWidth * (isPad ? 0.5 : 0.6)

            ZStack {
                Color.black
                    .ignoresSafeArea()
                    .opacity(0.6)
                    .onTapGesture { closeOverlay() }

                VStack(spacing: isPad ? 24 : 16) {
                    Image("Illustrated")
                        .resizable()
                        .scaledToFit()
                        .frame(width: containerWidth * (isPad ? 0.25 : 0.3))

                    ScrollView {
                        VStack(spacing: isPad ? 18 : 12) {
                            ForEach(displayList, id: \.self) { illustration in
                                let unlocked = illustration == .none || progress.unlockedIllustrations.contains(illustration)
                                Button(action: {
                                    guard unlocked else { return }
                                    selectedIllustration = illustration
                                }) {
                                    Image(unlocked ? illustration.rawValue : IllustrationID.none.rawValue)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: .infinity)
                                        .frame(height: itemHeight)
                                        .opacity(unlocked ? 1 : 0.35)
                                        .background(Color.white.opacity(0.08))
                                        .clipShape(RoundedRectangle(cornerRadius: isPad ? 28 : 22, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: isPad ? 28 : 22, style: .continuous)
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                                .disabled(!unlocked)
                            }
                        }
                        .padding(.horizontal, isPad ? 18 : 12)
                        .padding(.bottom, 8)
                    }
                    .frame(maxHeight: proxy.size.height * (isPad ? 0.55 : 0.5))

                    Button(action: { closeOverlay() }) {
                        Image("Close")
                            .resizable()
                            .scaledToFit()
                            .frame(width: isPad ? 110 : 80, height: isPad ? 110 : 80)
                            .accessibilityLabel("閉じる")
                    }
                    .padding(.bottom, safeInsets.bottom)
                }
                .frame(width: containerWidth)
                .padding(isPad ? 32 : 20)
                .background(Color.white.opacity(0.92))
                .clipShape(RoundedRectangle(cornerRadius: isPad ? 40 : 28, style: .continuous))
                .shadow(radius: 12)
            }
            .overlay {
                if let selected = selectedIllustration {
                    SelectedIllustrationOverlay(imageName: selected.rawValue,
                                                containerSize: proxy.size,
                                                safeInsets: safeInsets,
                                                isPad: isPad) {
                        selectedIllustration = nil
                    }
                }
            }
        }
        .transition(.opacity)
    }

    private func closeOverlay() {
        selectedIllustration = nil
        isPresented = false
    }
}

private struct SelectedIllustrationOverlay: View {
    let imageName: String
    let containerSize: CGSize
    let safeInsets: EdgeInsets
    let isPad: Bool
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
                .opacity(0.8)
                .onTapGesture(perform: onClose)

            VStack(spacing: isPad ? 24 : 16) {
                Spacer(minLength: safeInsets.top + 20)

                ScrollView(.horizontal, showsIndicators: false) {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: containerSize.width * (isPad ? 1.2 : 1.4))
                        .padding(.horizontal, isPad ? 32 : 20)
                }
                .frame(height: containerSize.height * (isPad ? 0.55 : 0.5))

                Button(action: onClose) {
                    Image("Close")
                        .resizable()
                        .scaledToFit()
                        .frame(width: isPad ? 140 : 96, height: isPad ? 140 : 96)
                        .padding(.bottom, safeInsets.bottom + 20)
                }
            }
        }
    }
}

private struct AchievementRewardOverlay: View {
    let reward: AchievementRewardMapping
    let isPad: Bool
    let dismiss: () -> Void
    @State private var slideIn = false

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                rewardBackground(in: proxy.size)

                VStack(spacing: isPad ? 24 : 16) {
                    Button(action: dismiss) {
                        Image("Close")
                            .resizable()
                            .scaledToFit()
                            .frame(width: isPad ? 120 : 90)
                            .padding(.bottom, max(proxy.safeAreaInsets.bottom, isPad ? 32 : 20))
                    }
                }
                .padding(.horizontal, isPad ? 40 : 24)
                .padding(.bottom, 20)
                .frame(maxWidth: .infinity)
                .offset(y: slideIn ? 0 : proxy.size.height * 0.4)
                .onAppear {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                        slideIn = true
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func rewardBackground(in size: CGSize) -> some View {
        Image(reward.clearImageName)
            .resizable()
            .scaledToFit()
            .frame(height: size.height)
            .frame(maxWidth: .infinity)
            .background(Color.black)
            .ignoresSafeArea()
    }
}

private extension HomeView {
    func handleMenuAction(_ action: MenuAction) {
        switch action {
        case .exchange:
            handleExchangeTap()
        case .catalog:
            showCatalog = true
        case .settings:
            showSettings = true
        case .achievement:
            handleAchievementTap()
        }
    }

    func handleExchangeTap() {
        RakutenRewardManager.shared.openPortal()
    }

    func handleAchievementTap() {
        if let reward = onAttemptAchievementClaim() {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                rewardToDisplay = reward
            }
        } else {
            showNoAchievementAlert = true
        }
    }
}

#Preview {
    HomeView(onStart: {}, onAttemptAchievementClaim: { nil }, progress: GameProgress(), hapticsEnabled: .constant(true))
}
