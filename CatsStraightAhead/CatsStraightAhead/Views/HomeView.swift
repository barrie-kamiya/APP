import SwiftUI

struct HomeView: View {
    let onStart: () -> Void
    let onClaimAchievement: () -> (imageName: String, milestone: Int)?
    let vibrationEnabled: Bool
    let onVibrationChange: (Bool) -> Void
    let hasAchievementReward: Bool
    let unlockedIllustrations: Set<String>
    let totalClears: Int
    let nextMilestone: Int?
    let runsUntilNext: Int?

    private let menuButtons: [(label: String, imageName: String)] = [
        ("図鑑", "Illustrated"),
        ("交換", "Exchange"),
        ("設定", "Setting"),
        ("達成", "Present")
    ]
    private let illustrationItems: [IllustrationItem] = [
        IllustrationItem(id: "Ilustrated_01", title: "01", requirement: "Clear_01"),
        IllustrationItem(id: "Ilustrated_02", title: "02", requirement: "Clear_02"),
        IllustrationItem(id: "Ilustrated_03", title: "03", requirement: "Clear_03"),
        IllustrationItem(id: "Ilustrated_04", title: "04", requirement: "Clear_04"),
        IllustrationItem(id: "Ilustrated_05", title: "05", requirement: "Clear_05"),
        IllustrationItem(id: "Ilustrated_06", title: "06", requirement: "Clear_06"),
        IllustrationItem(id: "Ilustrated_07", title: "07", requirement: "Clear_07"),
        IllustrationItem(id: "Ilustrated_08", title: "08", requirement: "Clear_08"),
        IllustrationItem(id: "Ilustrated_09", title: "09", requirement: "Clear_09"),
        IllustrationItem(id: "Ilustrated_none", title: "Default", requirement: "通常")
    ]

    @State private var isShowingSettings = false
    @State private var isShowingCollection = false
    @State private var rewardImageName: String?
    @State private var rewardMilestone: Int?
    @State private var showingRewardOverlay = false
    @State private var selectedIllustration: IllustrationItem?
    @Environment(\.isPadLayout) private var isPadLayout

    private var orderedIllustrations: [IllustrationItem] {
        var items = illustrationItems.filter { $0.id != "Ilustrated_none" }
        let allUnlocked = items.allSatisfy { unlockedIllustrations.contains($0.id) }
        if allUnlocked, let defaultItem = illustrationItems.first(where: { $0.id == "Ilustrated_none" }) {
            items.append(defaultItem)
        }
        return items
    }

    var body: some View {
        GeometryReader { geometry in
            let layout = HomeLayoutMetrics(size: geometry.size, isPadLayout: isPadLayout)
            ZStack {
                AdaptiveBackgroundImage(imageName: "HomeView")

                statusPanel
                    .frame(width: layout.statusPanelWidth)
                    .position(x: geometry.size.width * layout.statusPosition.x,
                              y: geometry.size.height * layout.statusPosition.y)

                menuStack(layout: layout)
                    .frame(width: layout.menuContentWidth, alignment: .leading)
                    .position(x: geometry.size.width * layout.menuStackHorizontalRatio,
                              y: geometry.size.height * layout.menuStackVerticalRatio)

                HomeMenuButton(imageName: "Start",
                               accessibilityLabelText: "スタート",
                               width: layout.startButtonWidth,
                               height: layout.startButtonHeight,
                               imageScale: layout.startButtonImageScale,
                               isDisabled: false,
                               animatePulse: false,
                               action: onStart)
                    .position(x: geometry.size.width / 2,
                              y: geometry.size.height * layout.startButtonVerticalRatio)

                if isShowingSettings {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea(isPadLayout ? [] : .all)
                        .onTapGesture { isShowingSettings = false }
                    settingsPanel
                        .frame(maxWidth: min(geometry.size.width * 0.8, layout.settingsPanelMaxWidth))
                }

                if showingRewardOverlay, let rewardImageName, let rewardMilestone {
                    AchievementRewardOverlay(imageName: rewardImageName,
                                              milestone: rewardMilestone,
                                              onClose: closeRewardOverlay)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(2)
                }

                if isShowingCollection {
                    illustratedOverlay(in: geometry)
                        .transition(.opacity)
                        .zIndex(3)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea(isPadLayout ? [] : .all)
    }

    private var statusPanel: some View {
        let statusText: String
        if let next = nextMilestone, let remaining = runsUntilNext {
            statusText = "次の解放(\(next)周)まで あと \(remaining)周"
        } else {
            statusText = "全特別図鑑を解放しました"
        }

        let titleFontSize: CGFloat = isPadLayout ? 20 : 24
        let detailFontSize: CGFloat = isPadLayout ? 13 : 16

        return VStack(spacing: 6) {
            Text("累計クリア: \(totalClears)周")
                .font(.system(size: titleFontSize, weight: .bold))
            Text(statusText)
                .font(.system(size: detailFontSize, weight: .semibold))
        }
        .foregroundColor(.black)
        .padding(.vertical, isPadLayout ? 12 : 16)
        .padding(.horizontal, isPadLayout ? 16 : 20)
        .background(Color.white.opacity(0.95))
        .cornerRadius(16)
        .shadow(radius: 10)
        .scaleEffect(isPadLayout ? 0.85 : 1.0)
    }

    private var settingsPanel: some View {
        VStack(spacing: 16) {
            Image("Vibration")
                .resizable()
                .scaledToFit()
                .frame(height: 120)
            HStack(spacing: 20) {
                Button {
                    onVibrationChange(true)
                } label: {
                    Text("ON")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(vibrationEnabled ? Color.accentColor : Color.white.opacity(0.8))
                        .foregroundColor(vibrationEnabled ? .white : .black)
                        .cornerRadius(12)
                }
                Button {
                    onVibrationChange(false)
                } label: {
                    Text("OFF")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(!vibrationEnabled ? Color.accentColor : Color.white.opacity(0.8))
                        .foregroundColor(!vibrationEnabled ? .white : .black)
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 10)
    }

    private func menuStack(layout: HomeLayoutMetrics) -> some View {
        VStack(spacing: layout.menuSpacing) {
            ForEach(menuButtons, id: \.label) { item in
                let isAchievement = item.label == "達成"
                HomeMenuButton(imageName: item.imageName,
                               accessibilityLabelText: item.label,
                               width: layout.menuButtonWidth,
                               height: layout.menuButtonHeight,
                               imageScale: layout.menuButtonImageScale,
                               isDisabled: isAchievement && !hasAchievementReward,
                               animatePulse: isAchievement && hasAchievementReward,
                               action: { handleAction(item.label) })
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func handleAction(_ label: String) {
        switch label {
        case "図鑑":
            withAnimation {
                isShowingCollection = true
                selectedIllustration = nil
            }
        case "交換":
            RakutenRewardManager.shared.openPortal()
        case "達成":
            guard hasAchievementReward,
                  let reward = onClaimAchievement() else { return }
            rewardImageName = reward.imageName
            rewardMilestone = reward.milestone
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                showingRewardOverlay = true
            }
        case "設定":
            withAnimation { isShowingSettings = true }
        default:
            break
        }
    }

    private func closeRewardOverlay() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
            showingRewardOverlay = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            rewardImageName = nil
            rewardMilestone = nil
        }
    }

    private func illustratedOverlay(in geometry: GeometryProxy) -> some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.opacity(0.7)
                    .ignoresSafeArea(isPadLayout ? [] : .all)
                    .onTapGesture {
                        withAnimation {
                            isShowingCollection = false
                        }
                        selectedIllustration = nil
                    }
                VStack(spacing: 20) {
                    Text("図鑑")
                        .font(.title.bold())
                        .foregroundColor(.black)
                    let columns = [GridItem(.flexible()), GridItem(.flexible())]
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(orderedIllustrations) { item in
                                let isUnlocked = unlockedIllustrations.contains(item.id)
                                Image(isUnlocked ? item.id : "Ilustrated_none")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 120)
                                    .cornerRadius(12)
                                    .opacity(isUnlocked ? 1 : 0.7)
                                    .onTapGesture {
                                        if isUnlocked {
                                            selectedIllustration = item
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    Button(action: {
                        withAnimation {
                            isShowingCollection = false
                        }
                        selectedIllustration = nil
                    }) {
                        Image("Close")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120)
                    }
                }
                .padding(24)
                .frame(maxWidth: min(geometry.size.width * 0.9, 500), maxHeight: geometry.size.height * 0.85)
                .background(Color.gray.opacity(0.85))
                .cornerRadius(32)
                .shadow(radius: 16)
                if let selected = selectedIllustration {
                    illustratedZoomOverlay(imageName: selected.id, in: proxy)
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
        }
    }

    private func illustratedZoomOverlay(imageName: String, in proxy: GeometryProxy) -> some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea(isPadLayout ? [] : .all)
                .onTapGesture { selectedIllustration = nil }

            VStack(spacing: 12) {
                Text("左右にスワイプして全体を表示できます")
                    .font(.footnote)
                    .foregroundColor(.white)
                    .padding(.top, proxy.safeAreaInsets.top + 12)
                ScrollView(.horizontal, showsIndicators: false) {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: proxy.size.width * 1.4, height: proxy.size.height * 0.6)
                        .padding(.horizontal, 32)
                }
                .frame(height: proxy.size.height * 0.6)
                Button {
                    selectedIllustration = nil
                } label: {
                    Image("Close")
                        .resizable()
                        .scaledToFit()
                        .frame(width: min(proxy.size.width * 0.6, 300))
                }
                .padding(.bottom, proxy.safeAreaInsets.bottom + 20)
            }
        }
    }
}

private struct AchievementRewardOverlay: View {
    let imageName: String
    let milestone: Int
    let onClose: () -> Void
    @State private var offsetRatio: CGFloat = 1
    @Environment(\.isPadLayout) private var isPadLayout

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                Color.black.opacity(0.7)
                    .ignoresSafeArea(isPadLayout ? [] : .all)
                    .onTapGesture { dismiss() }
                VStack(spacing: 16) {
                    Text("\(milestone)周達成！")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: geometry.size.width * 2.0,
                               maxHeight: geometry.size.height * 2.0)
                        .cornerRadius(30)
                        .shadow(radius: 15)
                    Button(action: dismiss) {
                        Image("Close")
                            .resizable()
                            .scaledToFit()
                            .frame(width: min(geometry.size.width * 0.4, 200))
                    }
                }
                .padding(.bottom, 40)
                .frame(maxWidth: geometry.size.width * 0.9)
                .offset(y: offsetRatio * geometry.size.height)
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                        offsetRatio = 0
                    }
                }
            }
        }
    }

    private func dismiss() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
            offsetRatio = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            onClose()
        }
    }
}

private struct HomeMenuButton: View {
    let imageName: String
    let accessibilityLabelText: String
    let width: CGFloat
    let height: CGFloat
    let imageScale: CGFloat
    let isDisabled: Bool
    let animatePulse: Bool
    let action: () -> Void

    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        Button(action: action) {
            ZStack {
                Color.clear
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: width * imageScale, height: height)
            }
        }
        .frame(width: width, height: height)
        .contentShape(Rectangle())
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.4 : 1)
        .scaleEffect(animatePulse ? pulseScale : 1)
        .accessibilityLabel(Text(accessibilityLabelText))
        .onAppear(perform: configurePulse)
        .onChange(of: animatePulse) { _ in
            configurePulse()
        }
    }

    private func configurePulse() {
        if animatePulse {
            pulseScale = 1.0
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                pulseScale = 1.05
            }
        } else {
            pulseScale = 1.0
        }
    }
}

private struct HomeLayoutMetrics {
    let size: CGSize
    let isPadLayout: Bool

    private var isPad: Bool { isPadLayout }
    private var baseContentWidth: CGFloat {
        let ratio: CGFloat = isPad ? 0.5 : 0.78
        let maxWidth: CGFloat = isPad ? 520 : 420
        return min(size.width * ratio, maxWidth)
    }

    var titleVerticalRatio: CGFloat { isPad ? 0.14 : 0.12 }
    var menuStackVerticalRatio: CGFloat { isPad ? 0.48 : 0.43 }
    var menuStackHorizontalRatio: CGFloat { isPad ? 0.05 : -0.05 }
    var startButtonVerticalRatio: CGFloat { isPad ? 0.8 : 0.78 }
    var menuContentWidth: CGFloat { baseContentWidth }
    var menuButtonWidth: CGFloat { baseContentWidth * (isPad ? 1.1 : 1.25) }
    var menuButtonHeight: CGFloat {
        let ratio: CGFloat = isPad ? 0.12 : 0.14
        let minHeight: CGFloat = isPad ? 100 : 100
        return max(size.height * ratio, minHeight)
    }
    var menuSpacing: CGFloat {
        let ratio: CGFloat = isPad ? 0.025 : 0.02
        return size.height * ratio
    }
    var menuButtonImageScale: CGFloat { isPad ? 0.95 : 1.15 }
    var startButtonWidth: CGFloat { min(baseContentWidth * 1.2, size.width * 0.85) }
    var startButtonHeight: CGFloat {
        let ratio: CGFloat = isPad ? 0.38 : 0.32
        let minHeight: CGFloat = isPad ? 220 : 180
        return max(size.height * ratio, minHeight)
    }
    var startButtonImageScale: CGFloat { isPad ? 1.0 : 1.0 }
    var settingsPanelMaxWidth: CGFloat { isPad ? 420 : 320 }
    var statusPanelWidth: CGFloat {
        if isPad {
            return min(baseContentWidth * 1.35, size.width * 0.85)
        } else {
            return min(baseContentWidth * 1.0, size.width * 0.7)
        }
    }
    var statusPosition: CGPoint {
        if isPad {
            return CGPoint(x: 0.5, y: 0.4)
        } else {
            return CGPoint(x: 0.5, y: 0.4)
        }
    }
}

private struct IllustrationItem: Identifiable {
    let id: String
    let title: String
    let requirement: String
}
