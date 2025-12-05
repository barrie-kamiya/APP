import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct HomeView: View {
    var onStart: () -> Void
    @Binding var vibrationEnabled: Bool
    var unlockedIllustrations: [String]
    var isAchievementAvailable: Bool
    var claimAchievementReward: () -> String?
    var completedRuns: Int
    var nextMilestoneRemaining: Int?

    @State private var isSettingsVisible = false
    @State private var isIllustratedVisible = false
    @State private var selectedIllustration: String?
    @State private var achievementImageName: String?
    @State private var showNoAchievementAlert = false

    private let menuButtons: [(title: String, image: String)] = [
        ("図鑑", "Illustrated"),
        ("交換", "Exchange"),
        ("設定", "Setting"),
        ("達成", "Present")
    ]

    var body: some View {
        GeometryReader { proxy in
            let layout = HomeLayoutMetrics(size: proxy.size,
                                           profile: isPadDevice ? .pad : .phone)
            let baseStartWidth = layout.contentWidth ?? proxy.size.width * 0.8
            let startButtonWidth = layout.isPad ? baseStartWidth * 0.5 : baseStartWidth
            ZStack {
                homeBackground(for: proxy.size)
                menuStack(size: proxy.size, layout: layout)
                HomeMenuButton(title: "スタート",
                               imageName: "Start",
                               scale: layout.startButtonScale,
                               height: layout.startButtonHeight,
                               action: onStart)
                    .frame(width: startButtonWidth,
                           height: layout.startButtonHeight)
                    .position(x: proxy.size.width / 2,
                              y: proxy.size.height * layout.startButtonVerticalRatio)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .overlay(alignment: .top) {
            statusBanner
                .padding(.top, statusTopPadding)
                .padding(.horizontal, 20)
                .allowsHitTesting(false)
        }
        .overlay(settingsOverlay)
        .overlay(illustratedOverlay)
        .sheet(isPresented: Binding(
            get: { achievementImageName != nil },
            set: { isPresented in
                if !isPresented {
                    achievementImageName = nil
                }
            })
        ) {
            if let imageName = achievementImageName {
                AchievementRewardSheet(imageName: imageName) {
                    achievementImageName = nil
                }
            }
        }
        .alert("達成報酬はありません", isPresented: $showNoAchievementAlert) {
            Button("OK", role: .cancel) { }
        }
    }

    private var statusBanner: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("クリア回数: \(completedRuns) 周")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
            Text(statusDetailText)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.black.opacity(0.8))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.85))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    }

    private var statusDetailText: String {
        if let remain = nextMilestoneRemaining {
            return "次の特別図鑑まであと \(remain) 周"
        } else {
            return "特別図鑑はすべて解放済みです"
        }
    }

    private var statusTopPadding: CGFloat {
        isPadDevice ? 80 : 100
    }

    private func menuStack(size: CGSize, layout: HomeLayoutMetrics) -> some View {
        let contentWidth = layout.contentWidth ?? (size.width - layout.horizontalPadding * 2)
        let adjustedSpacing = layout.isPad ? layout.menuSpacing * 0.5 : layout.menuSpacing
        let rowButtonWidth = max((contentWidth - adjustedSpacing * 2) / 3, 10)

        let scaleMultiplier: CGFloat = layout.isPad ? 1.0 : 1.0

        return ZStack {
            if let specimen = menuButtons.first {
                HomeMenuButton(title: specimen.title,
                               imageName: specimen.image,
                               scale: 1.1 * scaleMultiplier,
                               height: layout.menuButtonHeight,
                               action: actionFor(title: specimen.title))
                    .frame(width: rowButtonWidth, height: layout.menuButtonHeight)
                    .position(x: size.width / 2,
                              y: size.height * layout.specimenVerticalRatio)
            }

            HStack(spacing: adjustedSpacing) {
                ForEach(Array(menuButtons.dropFirst()), id: \.title) { item in
                    let isAchievement = item.title == "達成"
                    HomeMenuButton(title: item.title,
                                   imageName: item.image,
                                   scale: 1.1 * scaleMultiplier,
                                   height: layout.menuButtonHeight,
                                   isDisabled: isAchievement && !isAchievementAvailable,
                                   animatePulse: isAchievement && isAchievementAvailable,
                                   action: actionFor(title: item.title))
                        .frame(width: rowButtonWidth, height: layout.menuButtonHeight)
                }
            }
            .frame(width: rowButtonWidth * 3 + adjustedSpacing * 2)
            .position(x: size.width / 2,
                      y: size.height * layout.menuRowVerticalRatio)
        }
    }

    private func homeBackground(for size: CGSize) -> some View {
        ZStack {
            if isPadDevice {
                Color.black.ignoresSafeArea()
                Image("HomeView")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size.width, height: size.height)
                    .clipped()
            } else {
                Image("HomeView")
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .ignoresSafeArea()
            }
        }
    }

    private func handleAchievementTap() {
        if let reward = claimAchievementReward() {
            achievementImageName = reward
        } else {
            showNoAchievementAlert = true
        }
    }

    private func actionFor(title: String) -> () -> Void {
        switch title {
        case "設定":
            return { isSettingsVisible = true }
        case "交換":
            return { RakutenRewardManager.shared.openPortal() }
        case "図鑑":
            return { isIllustratedVisible = true }
        case "達成":
            return { handleAchievementTap() }
        default:
            return {}
        }
    }

    @ViewBuilder
    private var settingsOverlay: some View {
        if isSettingsVisible {
            ZStack {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isSettingsVisible = false
                    }

                VStack(spacing: 24) {
                    Image("Vibration")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 320)
                        .accessibilityHidden(true)
                    HStack(spacing: 24) {
                        SettingToggleButton(title: "ON",
                                            isSelected: vibrationEnabled) {
                            vibrationEnabled = true
                        }
                        SettingToggleButton(title: "OFF",
                                            isSelected: !vibrationEnabled) {
                            vibrationEnabled = false
                        }
                    }
                    Button(action: { isSettingsVisible = false }) {
                        Image("Close")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 48)
                            .accessibilityLabel("閉じる")
                    }
                }
                .padding(32)
                .frame(maxWidth: 420)
                .background(.ultraThinMaterial)
                .cornerRadius(32)
                .shadow(radius: 12)
            }
            .transition(.opacity)
        }
    }

    @ViewBuilder
    private var illustratedOverlay: some View {
        if isIllustratedVisible {
            GeometryReader { proxy in
                ZStack {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                        .onTapGesture {
                            isIllustratedVisible = false
                            selectedIllustration = nil
                        }

                    illustratedBookOverlay(in: proxy)
                }
            }
            .transition(.opacity)
        }
    }

    private func illustratedBookOverlay(in proxy: GeometryProxy) -> some View {
        let overlayWidth = proxy.size.width * 0.88
        let overlayHeight = proxy.size.height * 0.8
        let contentWidth = overlayWidth * 0.9
        let whiteWidth = overlayWidth + 12
        let whiteHeight = overlayHeight + 12

        return VStack(spacing: overlayHeight * 0.04) {
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(Color.white.opacity(0.95))
                    .frame(width: whiteWidth, height: whiteHeight)
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 12)

                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(red: 0.78, green: 0.9, blue: 0.33))
                    .frame(width: overlayWidth, height: overlayHeight)

                VStack(spacing: 18) {
                    Image("Illustrated")
                        .resizable()
                        .scaledToFit()
                        .frame(width: overlayWidth * 0.55)
                        .padding(.top, 12)

                    ScrollView {
                        VStack(spacing: 14) {
                            ForEach(illustrationDisplayList, id: \.self) { name in
                                let isUnlocked = unlockedIllustrations.contains(name)
                                Button(action: {
                                    guard isUnlocked else { return }
                                    selectedIllustration = name
                                }) {
                                    Image(name)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: contentWidth * 0.95)
                                        .opacity(isUnlocked ? 1 : 0.5)
                                }
                                .buttonStyle(.plain)
                                .disabled(!isUnlocked)
                            }
                            if illustrationDisplayList.count == unlockedIllustrations.count && !illustrationDisplayList.contains("Ilustrated_none") {
                                Image("Ilustrated_none")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: contentWidth * 0.95)
                                    .opacity(0.7)
                                    .padding(.top, 10)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.bottom, 12)
                    }
                    .frame(maxHeight: overlayHeight * 0.7)
                }
                .frame(width: contentWidth, height: overlayHeight * 0.88)
            }

            Button(action: {
                isIllustratedVisible = false
                selectedIllustration = nil
            }) {
                Image("Close")
                    .resizable()
                    .scaledToFit()
                    .frame(width: overlayWidth * 0.64)
                    .accessibilityLabel("閉じる")
            }
        }
        .frame(width: whiteWidth)
        .overlay {
            if let selected = selectedIllustration {
                illustratedZoomOverlay(imageName: selected, in: proxy)
            }
        }
    }

    private func illustratedZoomOverlay(imageName: String, in proxy: GeometryProxy) -> some View {
        ZStack(alignment: .topTrailing) {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    selectedIllustration = nil
                }

            VStack(spacing: 10) {
                Text("左右にスワイプして全体を表示できます")
                    .font(.footnote)
                    .foregroundColor(.white)
                    .padding(.top, proxy.safeAreaInsets.top + 12)

                ScrollView(.horizontal, showsIndicators: false) {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: proxy.size.width * 1.6, height: proxy.size.height * 0.7)
                        .padding(.horizontal, 32)
                }
                .frame(height: proxy.size.height * 0.7)

                Button(action: { selectedIllustration = nil }) {
                    Image("Close")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .padding(.bottom, proxy.safeAreaInsets.bottom + 20)
                }
            }
        }
    }

    private var illustrationDisplayList: [String] {
        var list = unlockedIllustrations
        if list.isEmpty { return ["Ilustrated_none"] }
        if list.count >= totalIllustrationCount && !list.contains("Ilustrated_none") {
            list.append("Ilustrated_none")
        }
        return list
    }

    private var totalIllustrationCount: Int { 9 }
}

private struct HomeMenuButton: View {
    var title: String
    var imageName: String
    var scale: CGFloat
    var height: CGFloat
    var isDisabled: Bool = false
    var animatePulse: Bool = false
    var action: () -> Void
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        GeometryReader { proxy in
            Button(action: action) {
                menuImage
                    .frame(width: proxy.size.width * scale, height: proxy.size.height)
                    .clipped()
                    .accessibilityLabel(Text(title))
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .disabled(isDisabled)
            .opacity(isDisabled ? 0.4 : 1.0)
            .scaleEffect(animatePulse ? pulseScale : 1.0)
            .frame(width: proxy.size.width, height: proxy.size.height)
            .onAppear(perform: configurePulse)
            .onChange(of: animatePulse) { _ in
                configurePulse()
            }
        }
        .frame(height: height)
    }

    private var menuImage: some View {
        Group {
#if canImport(UIKit)
            if let uiImage = UIImage(named: imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
            } else {
                fallbackLabel
            }
#else
            Image(imageName)
                .resizable()
                .scaledToFit()
#endif
        }
    }

    private var fallbackLabel: some View {
        Text(title)
            .font(.title3)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.gray.opacity(0.4))
            .cornerRadius(16)
    }

    private func configurePulse() {
        guard animatePulse && !isDisabled else {
            pulseScale = 1.0
            return
        }
        pulseScale = 1.0
        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
            pulseScale = 1.07
        }
    }
}

private struct HomeLayoutMetrics {
    let isPad: Bool
    let horizontalPadding: CGFloat
    let menuSpacing: CGFloat
    let menuButtonHeight: CGFloat
    let startButtonHeight: CGFloat
    let startButtonScale: CGFloat
    let contentWidth: CGFloat?
    let specimenVerticalRatio: CGFloat
    let menuRowVerticalRatio: CGFloat
    let startButtonVerticalRatio: CGFloat

    init(size: CGSize, profile: HomeLayoutProfile) {
        isPad = profile.isPad
        horizontalPadding = profile.horizontalPadding
        menuSpacing = profile.menuSpacing
        menuButtonHeight = profile.menuButtonHeight
        startButtonHeight = profile.startButtonHeight
        startButtonScale = profile.startButtonScale
        if let multiplier = profile.contentWidthMultiplier {
            let maxWidth = profile.contentWidthMaximum ?? size.width
            contentWidth = min(size.width * multiplier, maxWidth)
        } else {
            contentWidth = nil
        }
        specimenVerticalRatio = profile.specimenVerticalRatio
        menuRowVerticalRatio = profile.menuRowVerticalRatio
        startButtonVerticalRatio = profile.startButtonVerticalRatio
    }
}

private struct HomeLayoutProfile {
    let isPad: Bool
    let horizontalPadding: CGFloat
    let menuSpacing: CGFloat
    let menuButtonHeight: CGFloat
    let startButtonHeight: CGFloat
    let startButtonScale: CGFloat
    let contentWidthMultiplier: CGFloat?
    let contentWidthMaximum: CGFloat?
    let specimenVerticalRatio: CGFloat
    let menuRowVerticalRatio: CGFloat
    let startButtonVerticalRatio: CGFloat

    static let phone = HomeLayoutProfile(
        isPad: false,
        horizontalPadding: 24,
        menuSpacing: 16,
        menuButtonHeight: 140,
        startButtonHeight: 240,
        startButtonScale: 1.2,
        contentWidthMultiplier: nil,
        contentWidthMaximum: nil,
        specimenVerticalRatio: 0.42,
        menuRowVerticalRatio: 0.52,
        startButtonVerticalRatio: 0.8
    )

    static let pad = HomeLayoutProfile(
        isPad: true,
        horizontalPadding: 64,
        menuSpacing: 32,
        menuButtonHeight: 220,
        startButtonHeight: 340,
        startButtonScale: 1.7,
        contentWidthMultiplier: 0.74,
        contentWidthMaximum: 780,
        specimenVerticalRatio: 0.42,
        menuRowVerticalRatio: 0.52,
        startButtonVerticalRatio: 0.8
    )
}

private struct SettingToggleButton: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.title3.bold())
                .foregroundColor(isSelected ? .white : .black)
                .frame(minWidth: 80)
                .padding(.vertical, 10)
                .background(isSelected ? Color.green : Color.white.opacity(0.8))
                .cornerRadius(16)
                .shadow(radius: isSelected ? 6 : 2)
        }
    }
}

private struct AchievementRewardSheet: View {
    let imageName: String
    let dismiss: () -> Void
    private var isPad: Bool { isPadDevice }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                if isPad {
                    Color.black
                        .ignoresSafeArea()
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: proxy.size.width * 0.88)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                } else {
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                        .ignoresSafeArea()
                }

                Button(action: dismiss) {
                    Image("Close")
                        .resizable()
                        .scaledToFit()
                        .frame(width: isPad ? proxy.size.width * 0.35 : proxy.size.width * 0.3)
                        .padding(.vertical, 4)
                }
                .padding(.bottom, isPad ? max(proxy.safeAreaInsets.bottom + 60, 60) : max(proxy.safeAreaInsets.bottom + 40, 40))
            }
        }
    }
}

#if canImport(UIKit)
private var isPadDevice: Bool {
    let idiomIsPad = UIDevice.current.userInterfaceIdiom == .pad
    let modelIndicatesPad = UIDevice.current.model.lowercased().contains("ipad")
    return idiomIsPad || modelIndicatesPad
}
#else
private let isPadDevice = false
#endif
