import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct HomeView: View {
    let onStart: () -> Void
    let totalClears: Int
    let nextMilestone: Int?
    let runsUntilNext: Int?
    let unlockedIllustrations: Set<String>
    let hasAchievementReward: Bool
    let onClaimAchievement: () -> (imageName: String, milestone: Int)?
    let isVibrationEnabled: Bool
    let onVibrationChange: (Bool) -> Void

    @State private var showingIllustrations = false
    @State private var rewardImageName: String?
    @State private var showingSettings = false
    @State private var selectedIllustration: String?

    private let menuButtons: [(title: String, imageName: String)] = [
        ("図鑑", "Illustrated"),
        ("交換", "Exchange"),
        ("設定", "Setting"),
        ("達成", "Present")
    ]

    var body: some View {
        GeometryReader { proxy in
            let layout = HomeLayout(size: proxy.size)
            ZStack {
                homeBackground(layout: layout)

                VStack(spacing: layout.mainSpacing) {
                    Spacer(minLength: layout.topSpacerHeight)

                    achievementsButton(layout: layout)
                    secondaryMenu(layout: layout)
                    titleView
                    statusCard(layout: layout)
                        .padding(.top, layout.statusTopPadding)
                    startButton(width: layout.startButtonSize.width,
                                height: layout.startButtonSize.height)
                        .padding(.top, layout.startButtonTopPadding)

                    Spacer()
                }
                .frame(maxWidth: layout.contentWidth)
                .padding(.horizontal, layout.horizontalPadding)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if showingIllustrations {
                    illustrationsOverlay(layout: layout)
                }

                if let rewardImageName {
                    rewardOverlay(imageName: rewardImageName, layout: layout)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: rewardImageName)
                        .zIndex(4)
                }

                if showingSettings {
                    settingsOverlay(layout: layout)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func secondaryMenu(layout: HomeLayout) -> some View {
        HStack(spacing: layout.menuSpacing) {
            ForEach(menuButtons.indices.prefix(3), id: \.self) { index in
                let item = menuButtons[index]
                HomeMenuButton(imageName: item.imageName,
                               title: item.title,
                               width: layout.menuItemWidth(for: layout.isPad),
                               height: layout.menuButtonHeight(for: layout.isPad),
                               action: { handleMenuAction(item.title) })
            }
        }
        .frame(maxWidth: layout.menuAvailableWidth)
        .padding(.bottom, layout.secondaryMenuBottomPadding)
        .offset(y: -layout.secondaryMenuLift)
    }

    private var titleView: some View {
        EmptyView()
    }

    private func statusCard(layout: HomeLayout) -> some View {
        let detailText: String
        if let runsUntilNext {
            detailText = "次の報酬まで あと \(runsUntilNext)周"
        } else {
            detailText = "全特別図鑑を解放しました"
        }

        return VStack(spacing: 2) {
            Text("\(totalClears)周クリア")
                .font(layout.isPad ? .title.bold() : .headline)
                .foregroundColor(.white)
            Text(detailText)
                .font(layout.isPad ? .title3 : .subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.9))
        }
        .frame(width: layout.statusBoxSize.width, height: layout.statusBoxSize.height)
        .background(Color.black.opacity(0.45))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.35), lineWidth: 1)
        )
    }

    private func achievementsButton(layout: HomeLayout) -> some View {
        Group {
            if let first = menuButtons.last {
                HomeMenuButton(imageName: first.imageName,
                               title: first.title,
                               width: layout.menuItemWidth(for: layout.isPad),
                               height: layout.menuButtonHeight(for: layout.isPad),
                               action: { handleMenuAction(first.title) },
                               isDisabled: !hasAchievementReward,
                               animatePulse: hasAchievementReward)
                .padding(.top, layout.isPad ? layout.menuButtonHeight(for: layout.isPad) * 0.25 : 0)
            }
        }
    }

    private func startButton(width: CGFloat, height: CGFloat) -> some View {
        Button(action: onStart) {
            Image("Start")
                .resizable()
                .scaledToFit()
                .frame(width: width, height: height)
        }
        .accessibilityLabel(Text("スタート"))
        .buttonStyle(.plain)
    }

    private func homeBackground(layout: HomeLayout) -> some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Image("HomeView")
                .resizable()
                .scaledToFit()
                .frame(width: layout.size.width, height: layout.size.height)
                .position(x: layout.size.width / 2, y: layout.size.height / 2)
        }
    }

    private func handleMenuAction(_ title: String) {
        switch title {
        case "図鑑":
            withAnimation(.easeInOut) { showingIllustrations = true }
        case "交換":
            RakutenRewardManager.shared.openPortal()
        case "達成":
            if let reward = onClaimAchievement() {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                    rewardImageName = reward.imageName
                }
            }
        case "設定":
            withAnimation(.easeInOut) { showingSettings = true }
        default:
            break
        }
    }

    private func illustrationsOverlay(layout: HomeLayout) -> some View {
        GeometryReader { proxy in
            let overlayWidth = layout.overlaySize.width
            let overlayHeight = layout.overlaySize.height
            let columns = [GridItem(.flexible()), GridItem(.flexible())]
            let items = illustrationDisplayItems

            ZStack {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut) {
                            showingIllustrations = false
                            selectedIllustration = nil
                        }
                    }

                VStack {
                    HStack {
                        Text("図鑑一覧")
                            .font(.headline)
                        Spacer()
                        Button(action: {
                            withAnimation(.easeInOut) {
                                showingIllustrations = false
                                selectedIllustration = nil
                            }
                        }) {
                            Image("Close")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 88, height: 88)
                                .accessibilityLabel(Text("閉じる"))
                        }
                    }
                    .padding(.bottom, 8)

                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(items, id: \.self) { item in
                                let unlocked = unlockedIllustrations.contains(item)
                                Button(action: {
                                    guard unlocked else { return }
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                        selectedIllustration = item
                                    }
                                }) {
                                    Image(unlocked ? item : "Ilustrated_none")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 120)
                                        .opacity(unlocked ? 1 : 0.4)
                                }
                                .buttonStyle(.plain)
                                .disabled(!unlocked)
                                .frame(maxWidth: .infinity)
                                .padding(8)
                                .background(Color.white.opacity(0.95))
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                            }
                        }
                    }
                }
                .padding()
                .frame(width: overlayWidth, height: overlayHeight)
                .background(Color.white)
                .cornerRadius(24)
                .shadow(radius: 12)

                if let selectedIllustration {
                    illustrationZoomOverlay(imageName: selectedIllustration, in: proxy)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(3)
                }
            }
        }
        .transition(.opacity)
    }

    private func rewardOverlay(imageName: String, layout: HomeLayout) -> some View {
        RewardSlideView(imageName: imageName, isPad: layout.isPad) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                rewardImageName = nil
            }
        }
    }
    
    private var illustrationDisplayItems: [String] {
        var items = [
            "Ilustrated_01",
            "Ilustrated_02",
            "Ilustrated_03",
            "Ilustrated_04",
            "Ilustrated_05",
            "Ilustrated_06",
            "Ilustrated_07",
            "Ilustrated_08",
            "Ilustrated_09"
        ]
        if items.allSatisfy({ unlockedIllustrations.contains($0) }) {
            items.append("Ilustrated_none")
        }
        return items
    }

    private func illustrationZoomOverlay(imageName: String, in proxy: GeometryProxy) -> some View {
        ZStack(alignment: .top) {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut) { selectedIllustration = nil }
                }

            VStack(spacing: 16) {
                Text("左右にスワイプして全体を表示できます")
                    .font(.footnote)
                    .foregroundColor(.white)
                    .padding(.top, proxy.safeAreaInsets.top + 8)

                ScrollView(.horizontal, showsIndicators: false) {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: proxy.size.width * 1.5,
                               height: proxy.size.height * 0.55)
                        .padding(.horizontal, 32)
                }
                .frame(height: proxy.size.height * 0.6)

                Button(action: {
                    withAnimation(.easeInOut) { selectedIllustration = nil }
                }) {
                    Image("Close")
                        .resizable()
                        .scaledToFit()
                        .frame(width: min(proxy.size.width * 0.5, 220))
                        .padding(.bottom, proxy.safeAreaInsets.bottom + 20)
                }
            }
            .frame(maxWidth: proxy.size.width)
        }
    }

    private func settingsOverlay(layout: HomeLayout) -> some View {
        let overlayWidth = layout.settingsOverlaySize.width
        let overlayHeight = layout.settingsOverlaySize.height
        return ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { withAnimation(.easeInOut) { showingSettings = false } }
            VStack(spacing: 24) {
                Text("設定")
                    .font(.headline)
                Image("Vibration")
                    .resizable()
                    .scaledToFit()
                    .frame(height: overlayHeight * 0.45)
                HStack(spacing: 16) {
                    Button(action: {
                        onVibrationChange(true)
                    }) {
                        Text("ON")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isVibrationEnabled ? Color.accentColor : Color.gray.opacity(0.2))
                            .foregroundColor(isVibrationEnabled ? .white : .black)
                            .cornerRadius(12)
                    }
                    Button(action: {
                        onVibrationChange(false)
                    }) {
                        Text("OFF")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(!isVibrationEnabled ? Color.accentColor : Color.gray.opacity(0.2))
                            .foregroundColor(!isVibrationEnabled ? .white : .black)
                            .cornerRadius(12)
                    }
                }
                Button(action: {
                    withAnimation(.easeInOut) { showingSettings = false }
                }) {
                    Image("Close")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120)
                        .padding(.vertical, 6)
                        .accessibilityLabel(Text("閉じる"))
                }
            }
            .padding()
            .frame(width: overlayWidth, height: overlayHeight)
            .background(Color.white)
            .cornerRadius(24)
            .shadow(radius: 12)
        }
        .transition(.opacity)
    }
}

private struct HomeMenuButton: View {
    let imageName: String
    let title: String
    let width: CGFloat
    let height: CGFloat
    let action: () -> Void
    var isDisabled: Bool = false
    var animatePulse: Bool = false
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        Button(action: action) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: width, height: height)
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.4 : 1)
        .scaleEffect(animatePulse ? pulseScale : 1)
        .onAppear(perform: configurePulse)
        .onChange(of: animatePulse) { _ in
            configurePulse()
        }
        .accessibilityLabel(Text(title))
        .buttonStyle(.plain)
    }

    private func configurePulse() {
        pulseScale = 1.0
        guard animatePulse && !isDisabled else { return }
        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
            pulseScale = 1.05
        }
    }
}

private struct HomeLayout {
    let size: CGSize
    let isPad: Bool
    let mainSpacing: CGFloat
    let topSpacerHeight: CGFloat
    let horizontalPadding: CGFloat
    let menuAvailableWidth: CGFloat
    let menuSpacing: CGFloat
    let menuItemWidthPhone: CGFloat
    let menuButtonHeightPhone: CGFloat
    let menuItemWidthPad: CGFloat
    let menuButtonHeightPad: CGFloat
    let achievementButtonSize: CGSize
    let startButtonSize: CGSize
    let startButtonTopPadding: CGFloat
    let statusBoxSize: CGSize
    let overlaySize: CGSize
    let settingsOverlaySize: CGSize
    let secondaryMenuBottomPadding: CGFloat
    let secondaryMenuLift: CGFloat
    let contentWidth: CGFloat
    let statusTopPadding: CGFloat

    init(size: CGSize) {
        self.size = size
        isPad = isPadDevice
        if isPad {
            mainSpacing = size.height * 0.03
            topSpacerHeight = size.height * 0.05
            horizontalPadding = min(size.width * 0.1, 110)
            menuAvailableWidth = min(size.width * 0.85, 820)
            menuSpacing = 20
            let computedPhoneMenuItemWidth = (menuAvailableWidth - menuSpacing * 2) / 3 * 1.2
            let computedPhoneMenuButtonHeight = min(size.height * 0.2, 140)
            let computedPadMenuItemWidth = min(size.width * 0.18, 180)
            let computedPadMenuButtonHeight = min(size.height * 0.12, 115)
            menuItemWidthPhone = computedPhoneMenuItemWidth
            menuButtonHeightPhone = computedPhoneMenuButtonHeight
            menuItemWidthPad = computedPadMenuItemWidth
            menuButtonHeightPad = computedPadMenuButtonHeight
            achievementButtonSize = CGSize(width: min(menuAvailableWidth * 0.6, 320),
                                           height: computedPadMenuButtonHeight)
            startButtonSize = CGSize(width: min(size.width * 0.68, 500),
                                     height: size.height * 0.26)
            startButtonTopPadding = size.height * 0.05
            statusBoxSize = CGSize(width: min(size.width * 0.45, 360),
                                   height: min(size.height * 0.12, 120))
            overlaySize = CGSize(width: min(size.width * 0.6, 520),
                                 height: min(size.height * 0.7, 620))
            settingsOverlaySize = CGSize(width: min(size.width * 0.5, 420),
                                         height: min(size.height * 0.55, 460))
            secondaryMenuBottomPadding = size.height * 0.015
            secondaryMenuLift = computedPadMenuButtonHeight * 0.1
            contentWidth = min(size.width * 0.85, 820)
            statusTopPadding = size.height * 0.1
        } else {
            mainSpacing = size.height * 0.025
            topSpacerHeight = size.height * 0.05
            horizontalPadding = max(size.width * 0.08, 20)
            menuAvailableWidth = size.width - horizontalPadding * 2
            menuSpacing = 16
            let sharedMenuItemWidth = (menuAvailableWidth - menuSpacing * 2) / 3 * 1.1
            let sharedMenuButtonHeight = min(size.height * 0.18, 130)
            menuItemWidthPad = sharedMenuItemWidth
            menuButtonHeightPad = sharedMenuButtonHeight
            menuItemWidthPhone = sharedMenuItemWidth
            menuButtonHeightPhone = sharedMenuButtonHeight
            achievementButtonSize = CGSize(width: min(menuAvailableWidth * 0.7, 260),
                                           height: sharedMenuButtonHeight)
            startButtonSize = CGSize(width: min(size.width * 0.95, 480),
                                     height: size.height * 0.3)
            startButtonTopPadding = size.height * 0.02
            statusBoxSize = CGSize(width: min(size.width * 0.6, 320),
                                   height: min(size.height * 0.14, 70))
            overlaySize = CGSize(width: min(size.width * 0.9, 420),
                                 height: min(size.height * 0.75, 520))
            settingsOverlaySize = CGSize(width: min(size.width * 0.85, 360),
                                         height: min(size.height * 0.6, 400))
            secondaryMenuBottomPadding = size.height * 0.02
            secondaryMenuLift = sharedMenuButtonHeight * 0.7
            contentWidth = menuAvailableWidth
            statusTopPadding = 0
        }
#if DEBUG
        debugLogHomeLayoutMetrics(
            size: size,
            isPad: isPad,
            contentWidth: contentWidth,
            menuAvailableWidth: menuAvailableWidth,
            menuItemWidth: isPad ? menuItemWidthPad : menuItemWidthPhone,
            menuButtonHeight: isPad ? menuButtonHeightPad : menuButtonHeightPhone,
            startButtonSize: startButtonSize
        )
#endif
    }
    func menuItemWidth(for isPad: Bool) -> CGFloat {
        isPad ? menuItemWidthPad : menuItemWidthPhone
    }

    func menuButtonHeight(for isPad: Bool) -> CGFloat {
        isPad ? menuButtonHeightPad : menuButtonHeightPhone
    }
}

private struct RewardSlideView: View {
    let imageName: String
    let isPad: Bool
    let onDismiss: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                backgroundImage(in: proxy.size)
                    .contentShape(Rectangle())
                    .onTapGesture { onDismiss() }

                Button(action: onDismiss) {
                    Image("Close")
                        .resizable()
                        .scaledToFit()
                        .frame(width: min(proxy.size.width * (isPad ? 0.25 : 0.4), isPad ? 260 : 220))
                        .padding(.vertical, 6)
                }
                .padding(.bottom, max(proxy.safeAreaInsets.bottom + (isPad ? 60 : 36), isPad ? 60 : 36))
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .background(Color.black.opacity(isPad ? 1.0 : 0.95))
            .ignoresSafeArea()
        }
    }

    @ViewBuilder
    private func backgroundImage(in size: CGSize) -> some View {
        if isPad {
            VStack {
                Spacer()
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size.width * 0.85)
                    .padding(.bottom, size.height * 0.08)
            }
            .frame(width: size.width, height: size.height)
            .background(Color.black)
        } else {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: size.width, height: size.height)
                .clipped()
        }
    }
}

#if canImport(UIKit)
private var isPadDevice: Bool {
    let idiomIsPad = UIDevice.current.userInterfaceIdiom == .pad
    let bounds = UIScreen.main.bounds
    let longSide = max(bounds.width, bounds.height)
    return idiomIsPad || longSide >= 1024
}
#else
private let isPadDevice = false
#endif

#if DEBUG
private var lastHomeLayoutLog: (CGSize, Bool)?

private func debugLogHomeLayoutMetrics(size: CGSize,
                                       isPad: Bool,
                                       contentWidth: CGFloat,
                                       menuAvailableWidth: CGFloat,
                                       menuItemWidth: CGFloat,
                                       menuButtonHeight: CGFloat,
                                       startButtonSize: CGSize) {
    if let lastLog = lastHomeLayoutLog,
       lastLog.0 == size,
       lastLog.1 == isPad {
        return
    }
    lastHomeLayoutLog = (size, isPad)
    let formattedSize = "\(Int(size.width))x\(Int(size.height))"
    let menuInfo = "menuWidth=\(menuItemWidth.rounded()) menuHeight=\(menuButtonHeight.rounded())"
    let contentInfo = "contentWidth=\(contentWidth.rounded()) availableMenu=\(menuAvailableWidth.rounded())"
    let startButtonInfo = "startButton=\(Int(startButtonSize.width))x\(Int(startButtonSize.height))"
    print("[HomeLayout] size=\(formattedSize) isPad=\(isPad) \(contentInfo) \(menuInfo) \(startButtonInfo)")
}
#endif
