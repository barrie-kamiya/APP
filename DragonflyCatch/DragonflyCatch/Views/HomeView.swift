import SwiftUI

struct HomeView: View {
    var status: RunProgressStatus
    var catalogImages: [String]
    var isHapticsEnabled: Bool
    var canClaimAchievement: Bool

    private enum HomeButton: CaseIterable, Identifiable {
        case specimen
        case trade
        case settings
        case achievements
        case start

        var id: String { title }

        var title: String {
            switch self {
            case .specimen:
                return "図鑑"
            case .trade:
                return "交換"
            case .settings:
                return "設定"
            case .achievements:
                return "達成"
            case .start:
                return "スタート"
            }
        }

        var accessibilityLabel: String { title }
    }

    private let buttonLayouts: [HomeButton: ResponsiveFrame] = [
        .specimen: ResponsiveFrame(
            phone: RelativeFrame(xPercent: 0.02, yPercent: 0.20, widthPercent: 0.7, heightPercent: 0.15),
            pad: RelativeFrame(xPercent: 0.18, yPercent: 0.20, widthPercent: 0.45, heightPercent: 0.15)
        ),
        .trade: ResponsiveFrame(
            phone: RelativeFrame(xPercent: 0.02, yPercent: 0.38, widthPercent: 0.7, heightPercent: 0.15),
            pad: RelativeFrame(xPercent: 0.18, yPercent: 0.38, widthPercent: 0.45, heightPercent: 0.15)
        ),
        .achievements: ResponsiveFrame(
            phone: RelativeFrame(xPercent: 0.02, yPercent: 0.56, widthPercent: 0.7, heightPercent: 0.15),
            pad: RelativeFrame(xPercent: 0.18, yPercent: 0.56, widthPercent: 0.45, heightPercent: 0.15)
        ),
        .settings: ResponsiveFrame(
            phone: RelativeFrame(xPercent: 0.02, yPercent: 0.74, widthPercent: 0.7, heightPercent: 0.15),
            pad: RelativeFrame(xPercent: 0.18, yPercent: 0.74, widthPercent: 0.45, heightPercent: 0.15)
        ),
        .start: ResponsiveFrame(
            phone: RelativeFrame(xPercent: 0.5, yPercent: 0.82, widthPercent: 0.75, heightPercent: 0.35),
            pad: RelativeFrame(xPercent: 0.5, yPercent: 0.78, widthPercent: 0.5, heightPercent: 0.3)
        )
    ]

    private let statusLayout = ResponsiveFrame(
        phone: RelativeFrame(xPercent: 0.5, yPercent: 0.5, widthPercent: 0.65, heightPercent: 0.1),
        pad: RelativeFrame(xPercent: 0.5, yPercent: 0.5, widthPercent: 0.5, heightPercent: 0.12)
    )

    private let buttonImages: [HomeButton: String] = [
        .specimen: "Illustrated",
        .trade: "Exchange",
        .settings: "Setting",
        .achievements: "Present",
        .start: "Start"
    ]

    private let startAction: () -> Void
    private let specimenAction: () -> Void
    private let tradeAction: () -> Void
    private let settingsAction: () -> Void
    private let achievementsAction: () -> String?
    private let onHapticsChange: (Bool) -> Void

    @State private var showingCatalog = false
    @State private var showingAchievementImage: String?
    @State private var showingSettings = false
    @State private var achievementPulse = false
    @State private var achievementSlideIn = false
    @State private var selectedCatalogImage: String?

    init(status: RunProgressStatus,
         catalogImages: [String],
         isHapticsEnabled: Bool,
         canClaimAchievement: Bool,
         startAction: @escaping () -> Void,
         specimenAction: @escaping () -> Void = {},
         tradeAction: @escaping () -> Void = {},
         settingsAction: @escaping () -> Void = {},
         achievementsAction: @escaping () -> String? = { nil },
         onHapticsChange: @escaping (Bool) -> Void = { _ in }) {
        self.status = status
        self.catalogImages = catalogImages
        self.isHapticsEnabled = isHapticsEnabled
        self.canClaimAchievement = canClaimAchievement
        self.startAction = startAction
        self.specimenAction = specimenAction
        self.tradeAction = tradeAction
        self.settingsAction = settingsAction
        self.achievementsAction = achievementsAction
        self.onHapticsChange = onHapticsChange
    }

    var body: some View {
        GeometryReader { geometry in
            let device = LayoutDevice.resolve(for: geometry.size)

            let isPad = device == .pad

            ZStack {
                FittedBackgroundImage(imageName: "HomeView")
                VStack { Spacer() }
                ForEach(HomeButton.allCases) { button in
                    if let layout = buttonLayouts[button] {
                        let rect = layout.rect(for: device, in: geometry.size)
                        let isAchievementsButton = button == .achievements
                        Button {
                            switch button {
                            case .specimen:
                                showingCatalog = true
                                specimenAction()
                            case .trade:
                                tradeAction()
                            case .settings:
                                showingSettings = true
                                settingsAction()
                            case .achievements:
                                if canClaimAchievement, let rewardImage = achievementsAction() {
                                    presentAchievement(image: rewardImage)
                                }
                            case .start:
                                startAction()
                            }
                        } label: {
                            if let assetName = buttonImages[button] {
                                Image(assetName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: rect.width, height: rect.height)
                                    .contentShape(Rectangle())
                                    .opacity(isAchievementsButton && !canClaimAchievement ? 0.4 : 1)
                                    .scaleEffect(isAchievementsButton && canClaimAchievement ? (achievementPulse ? 1.05 : 0.95) : 1)
                                    .animation(isAchievementsButton && canClaimAchievement ? .easeInOut(duration: 0.9).repeatForever(autoreverses: true) : .default,
                                               value: achievementPulse)
                            } else {
                                Text(button.title)
                                    .font(button == .start ? .title2.bold() : .headline)
                                    .foregroundColor(.white)
                                    .frame(width: rect.width, height: rect.height)
                                    .background(
                                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                                            .fill(button == .start ? Color.orange : Color.blue)
                                            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 6)
                                    )
                                    .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                            }
                        }
                        .accessibilityLabel(button.accessibilityLabel)
                        .buttonStyle(.plain)
                        .disabled(isAchievementsButton && !canClaimAchievement)
                        .position(x: rect.midX, y: rect.midY)
                    }
                }

                let statusRect = statusLayout.rect(for: device, in: geometry.size)
                VStack(spacing: 6) {
                    Text("\(status.totalRuns)周クリア")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(status.descriptionText)
                        .font(.headline)
                        .foregroundColor(Color.white.opacity(0.85))
                }
                .frame(width: statusRect.width, height: statusRect.height)
                .background(Color.black.opacity(0.6))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.4), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                .position(x: statusRect.midX, y: statusRect.midY)

                if showingCatalog {
                    Color.black.opacity(0.45)
                        .ignoresSafeArea()

                    let displayCatalog = catalogImages.last == "Ilustrated_none"
                        ? catalogImages
                        : catalogImages + ["Ilustrated_none"]

                    VStack(spacing: 20) {
                        Text("図鑑")
                            .font(.title.bold())
                            .foregroundColor(.white)
                        ScrollView {
                            VStack(spacing: 16) {
                                ForEach(displayCatalog, id: \.self) { imageName in
                                    Button {
                                        selectedCatalogImage = imageName
                                    } label: {
                                        Image(imageName)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(maxWidth: geometry.size.width * 0.75)
                                            .cornerRadius(24)
                                            .shadow(radius: 8)
                                            .padding(.horizontal)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .frame(height: geometry.size.height * 0.6)

                        Button {
                            showingCatalog = false
                        } label: {
                            Image("Close")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("閉じる")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                if let achievementImage = showingAchievementImage {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                    GeometryReader { proxy in
                        VStack(spacing: 0) {
                            Image(achievementImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: proxy.size.width,
                                       height: proxy.size.height)
                                .clipped()
                        }
                        .overlay(alignment: .bottom) {
                            Button {
                                hideAchievementOverlay()
                            } label: {
                                Image("Close")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .padding(.bottom, proxy.safeAreaInsets.bottom + 12)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("閉じる")
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .offset(y: achievementSlideIn ? 0 : proxy.size.height)
                        .animation(.spring(response: 0.55, dampingFraction: 0.85, blendDuration: 0.2), value: achievementSlideIn)
                    }
                    .onAppear {
                        achievementSlideIn = false
                        withAnimation(.spring(response: 0.55, dampingFraction: 0.85, blendDuration: 0.2)) {
                            achievementSlideIn = true
                        }
                    }
                }

                if let highlightedImage = selectedCatalogImage {
                    Color.black.opacity(0.65)
                        .ignoresSafeArea()
                        .onTapGesture {
                            hideCatalogZoom()
                        }

                    GeometryReader { proxy in
                        VStack(spacing: 12) {
                            Text("画像をスワイプすると全体を確認できます")
                                .font(.footnote)
                                .foregroundColor(.white)
                                .padding(.top, proxy.safeAreaInsets.top + 12)

                            ScrollView([.horizontal, .vertical], showsIndicators: false) {
                                Image(highlightedImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: proxy.size.width * 1.2)
                                    .padding()
                            }
                            .frame(height: proxy.size.height * 0.65)

                            Button {
                                hideCatalogZoom()
                            } label: {
                                Image("Close")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 70, height: 70)
                                    .padding(.bottom, proxy.safeAreaInsets.bottom + 16)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("閉じる")
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }

                if showingSettings {
                    Color.black.opacity(0.45)
                        .ignoresSafeArea()
                    VStack(spacing: 20) {
                        Text("設定")
                            .font(.title.bold())
                            .foregroundColor(.white)
                        Image("Vibration")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: geometry.size.width * 0.6,
                                   maxHeight: geometry.size.height * 0.4)
                        HStack(spacing: 24) {
                            SettingToggleButton(label: "ON",
                                                 isSelected: isHapticsEnabled) {
                                onHapticsChange(true)
                            }
                            SettingToggleButton(label: "OFF",
                                                 isSelected: !isHapticsEnabled) {
                                onHapticsChange(false)
                            }
                        }
                        Button {
                            showingSettings = false
                        } label: {
                            Image("Close")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("閉じる")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .ignoresSafeArea()
            .frame(width: geometry.size.width, height: geometry.size.height)
            .modifier(BackgroundClipModifier(isPad: isPad, imageName: "HomeView"))
        }
        .onAppear {
            updateAchievementAnimation()
        }
        .onChange(of: canClaimAchievement) { _ in
            updateAchievementAnimation()
        }
    }
}

private struct SettingToggleButton: View {
    var label: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.title3.bold())
                .foregroundColor(isSelected ? .white : .black)
                .frame(width: 100, height: 44)
                .background(isSelected ? Color.green : Color.white)
                .cornerRadius(22)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.black.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

private extension HomeView {
    func updateAchievementAnimation() {
        if canClaimAchievement {
            achievementPulse = false
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    achievementPulse = true
                }
            }
        } else {
            achievementPulse = false
        }
    }

    func presentAchievement(image: String) {
        achievementSlideIn = false
        showingAchievementImage = image
        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85, blendDuration: 0.2)) {
                achievementSlideIn = true
            }
        }
    }

    func hideAchievementOverlay() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.9, blendDuration: 0.2)) {
            achievementSlideIn = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            showingAchievementImage = nil
        }
    }

    func hideCatalogZoom() {
        selectedCatalogImage = nil
    }
}

private struct BackgroundClipModifier: ViewModifier {
    let isPad: Bool
    let imageName: String

    func body(content: Content) -> some View {
        if isPad {
            content
                .clipShape(Rectangle())
                .mask(FittedBackgroundImage(imageName: imageName))
        } else {
            content
        }
    }
}
