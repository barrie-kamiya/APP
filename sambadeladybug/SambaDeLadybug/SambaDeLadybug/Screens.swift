import SwiftUI
import UIKit
struct SplashScreen: View {
    @EnvironmentObject private var viewModel: AppFlowViewModel

    var body: some View {
        Image("Splash")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture { viewModel.handleSplashTap() }
    }
}

struct HomeScreen: View {
    @EnvironmentObject private var viewModel: AppFlowViewModel
    @State private var showingCollection = false
    @State private var achievementImageName: String?
    @State private var showNoAchievementAlert = false
    @State private var showingSettings = false

    private let menuButtons: [(title: String, image: String)] = [
        ("標本", "Illustrated"),
        ("交換", "Exchange"),
        ("設定", "Setting"),
        ("達成", "Present")
    ]

    var body: some View {
        GeometryReader { proxy in
            let layout = HomeLayoutMetrics(size: proxy.size, isPad: isPadDevice)
            ZStack {
                homeBackground(in: proxy.size, isPad: layout.isPad)
                VStack(spacing: layout.mainSpacing) {
                    if layout.isPad {
                        Spacer()
                            .frame(height: proxy.size.height * 0.02)
                    }
                    GeometryReader { geo in
                        let buttonHeight: CGFloat = 150
                        let spacing: CGFloat = 16
                        let columns: CGFloat = 3
                        let itemWidth = (geo.size.width - spacing * (columns - 1)) / columns
                        let specimenCenterY = geo.size.height * (layout.isPad ? 0.3 : 0.25)
                        let menuCenterY = geo.size.height * (layout.isPad ? 0.7 : 0.4)

                        ZStack(alignment: .top) {
                            HStack(spacing: spacing) {
                                ForEach(Array(menuButtons.dropFirst().enumerated()), id: \.offset) { item in
                                    let isAchievement = item.element.title == "達成"
                                    HomeMenuButton(
                                        title: item.element.title,
                                        imageName: item.element.image,
                                        scale: 1.1,
                                        isDisabled: isAchievement && !viewModel.hasClaimableAchievement,
                                        animatePulse: isAchievement && viewModel.hasClaimableAchievement,
                                        action: actionForMenu(title: item.element.title)
                                    )
                                        .frame(width: itemWidth, height: buttonHeight)
                                }
                            }
                            .frame(width: geo.size.width, height: buttonHeight)
                            .position(x: geo.size.width / 2, y: menuCenterY)
                            if let specimen = menuButtons.first {
                                HomeMenuButton(title: specimen.title, imageName: specimen.image, scale: 1.1, action: actionForMenu(title: specimen.title))
                                    .frame(width: itemWidth, height: buttonHeight)
                                    .frame(width: geo.size.width, height: buttonHeight, alignment: .center)
                                    .position(x: geo.size.width / 2, y: specimenCenterY)
                            }
                        }
                    }
                    let startScale: CGFloat = layout.isPad ? 1.4 : 1.8
                    let startHeight: CGFloat = layout.isPad ? 210 : 300
                    let startTopPadding: CGFloat = layout.isPad ? 0 : 0
                    HomeMenuButton(title: "スタート", imageName: "Start", scale: startScale, height: startHeight, action: {
                        viewModel.startGame()
                    })
                    .padding(.top, startTopPadding)
                    .offset(y: layout.isPad ? proxy.size.height * 0.25 : 0)
                    if layout.isPad {
                        Spacer()
                            .frame(minHeight: proxy.size.height * 0.08)
                    } else {
                        Spacer()
                    }
                }
                .frame(maxWidth: layout.contentWidth ?? .infinity)
                .padding(.horizontal, layout.horizontalPadding)
                .padding(.top, layout.verticalPadding)
                .padding(.bottom, layout.verticalPadding)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .overlay(
                statusCard(maxWidth: layout.statusCardWidth, isPad: layout.isPad)
                    .padding(.horizontal, layout.horizontalPadding)
                    .allowsHitTesting(false),
                alignment: .center
            )
        }
        .overlay(settingsOverlay)
        .sheet(isPresented: $showingCollection) {
            IllustratedCollectionView()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: Binding(
            get: { achievementImageName != nil },
            set: { isPresented in
                if !isPresented {
                    achievementImageName = nil
                }
            })
        ) {
            if let imageName = achievementImageName {
                AchievementRewardView(imageName: imageName) {
                    achievementImageName = nil
                }
            }
        }
        .alert("達成報酬はありません", isPresented: $showNoAchievementAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("次の解放条件を達成すると報酬を受け取れます。")
        }
    }
}

private struct HomeMenuButton: View {
    let title: String
    let imageName: String
    let scale: CGFloat
    let height: CGFloat
    let action: () -> Void
    var isDisabled: Bool
    var animatePulse: Bool
    @State private var pulseScale: CGFloat = 1.0
    
    init(title: String, imageName: String, scale: CGFloat = 1.0, height: CGFloat = 140, isDisabled: Bool = false, animatePulse: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.imageName = imageName
        self.scale = scale
        self.height = height
        self.isDisabled = isDisabled
        self.animatePulse = animatePulse
        self.action = action
    }


    var body: some View {
        GeometryReader { proxy in
            Button(action: action) {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: proxy.size.width * scale)
                    .accessibilityLabel(Text(title))
            }
            .disabled(isDisabled)
            .opacity(isDisabled ? 0.4 : 1)
            .scaleEffect(animatePulse ? pulseScale : 1)
            .frame(width: proxy.size.width, height: proxy.size.height)
            .onAppear(perform: configurePulse)
            .onChange(of: animatePulse) { _ in
                configurePulse()
            }
        }
        .frame(height: height)
    }
    
    private func configurePulse() {
        if animatePulse && !isDisabled {
            pulseScale = 1.0
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                pulseScale = 1.05
            }
        } else {
            pulseScale = 1.0
        }
    }
}

private extension HomeScreen {
    func statusCard(maxWidth: CGFloat? = nil, isPad: Bool = false) -> some View {
        let verticalOffset: CGFloat = isPad ? 30 : 0
        return VStack(alignment: .leading, spacing: 8) {
            Text("総クリア数: \(viewModel.completedRuns)")
                .font(.title3.bold())
                .foregroundColor(.black)
            Text("次の解放まであと \(runsUntilNextMilestone) 周")
                .font(.subheadline)
                .foregroundColor(.black)
        }
        .padding(16)
        .frame(maxWidth: maxWidth ?? .infinity, alignment: .leading)
        .background(Color.white.opacity(0.9))
        .cornerRadius(12)
        .shadow(radius: 4)
        .offset(y: verticalOffset)
    }

    @ViewBuilder
    func homeBackground(in size: CGSize, isPad: Bool) -> some View {
        if isPad {
            Color.black.opacity(0.95)
                .ignoresSafeArea()
            Image("HomeView")
                .resizable()
                .scaledToFit()
                .frame(width: min(size.width * 0.78, 820))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Image("HomeView")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
    }
    
    var runsUntilNextMilestone: Int {
        let upcoming = viewModel.nextAchievementMilestone(after: viewModel.completedRuns)
        guard let target = upcoming else { return 0 }
        return max(target - viewModel.completedRuns, 0)
    }
    
    func actionForMenu(title: String) -> () -> Void {
        switch title {
        case "標本":
            return { showingCollection = true }
        case "交換":
            return {
                RakutenRewardManager.shared.openPortal()
            }
        case "達成":
            return {
                if let imageName = viewModel.claimNextAchievementReward() {
                    achievementImageName = imageName
                } else {
                    showNoAchievementAlert = true
                }
            }
        case "設定":
            return { showingSettings = true }
        default:
            return {}
        }
    }
    
    var settingsOverlay: some View {
        Group {
            if showingSettings {
                ZStack {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showingSettings = false
                        }
                    SettingsPanel(
                        isPresented: $showingSettings,
                        isVibrationEnabled: Binding(
                            get: { viewModel.isVibrationEnabled },
                            set: { viewModel.isVibrationEnabled = $0 }
                        )
                    )
                }
            }
        }
    }
}

private struct HomeLayoutMetrics {
    let size: CGSize
    let isPad: Bool

    var contentWidth: CGFloat? {
        guard isPad else { return nil }
        return min(size.width * 0.7, 780)
    }

    var horizontalPadding: CGFloat {
        if let contentWidth {
            return max((size.width - contentWidth) / 2, 40)
        } else {
            return 24
        }
    }

    var verticalPadding: CGFloat {
        isPad ? max(size.height * 0.08, 32) : 24
    }

    var mainSpacing: CGFloat {
        isPad ? 36 : 24
    }

    var statusCardWidth: CGFloat? {
        guard isPad else { return nil }
        if let contentWidth {
            return min(contentWidth, 520)
        }
        return min(size.width * 0.7, 520)
    }
}

struct IllustratedCollectionView: View {
    @EnvironmentObject private var viewModel: AppFlowViewModel
    @Environment(\.dismiss) private var dismiss
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]
    @State private var zoomImageName: String?
    
    var body: some View {
        ZStack {
            NavigationStack {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(displayIllustrationIDs, id: \.self) { id in
                            Button(action: {
                                if let target = zoomTargetName(for: id) {
                                    zoomImageName = target
                                }
                            }) {
                                Image(imageName(for: id))
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 120)
                                    .opacity(opacity(for: id))
                                    .padding(8)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                            }
                            .disabled(!isTapEnabled(for: id))
                        }
                    }
                    .padding()
                }
                .background(Color(UIColor.systemGroupedBackground))
                .navigationTitle("ひょうほん")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(action: { dismiss() }) {
                            Image("Close")
                                .renderingMode(.original)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 24)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            if let imageName = zoomImageName {
                Color.clear
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .onTapGesture { zoomImageName = nil }
                ZoomedIllustrationView(imageName: imageName) {
                    zoomImageName = nil
                }
            }
        }
    }
    
    private var displayIllustrationIDs: [Int] {
        var ids = Array(1...9)
        if viewModel.unlockedIllustrations.count >= 9 {
            ids.append(0)
        }
        return ids
    }
    
    private func imageName(for id: Int) -> String {
        if id == 0 {
            return "Ilustrated_none"
        }
        if viewModel.unlockedIllustrations.contains(id) {
            return String(format: "Ilustrated_%02d", id)
        } else {
            return "Ilustrated_none"
        }
    }
    
    private func opacity(for id: Int) -> Double {
        if id == 0 { return 1.0 }
        return viewModel.unlockedIllustrations.contains(id) ? 1.0 : 0.4
    }
    
    private func isTapEnabled(for id: Int) -> Bool {
        guard id > 0 else { return false }
        return viewModel.unlockedIllustrations.contains(id)
    }

    private func zoomTargetName(for id: Int) -> String? {
        guard isTapEnabled(for: id) else { return nil }
        return String(format: "Ilustrated_%02d", id)
    }
}

private struct ZoomedIllustrationView: View {
    let imageName: String
    let dismiss: () -> Void
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.opacity(0.85)
                    .ignoresSafeArea()
                    .onTapGesture { dismiss() }
                VStack(spacing: 16) {
                    Spacer()
                    Text("左右にスワイプして全体を表示できます")
                        .font(.footnote.bold())
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.bottom, -12)
                    ScrollView(.horizontal, showsIndicators: false) {
                        Image(imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: proxy.size.width * 1.6)
                            .padding(.horizontal, proxy.size.width * 0.2)
                            .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 6)
                    }
                    .frame(height: proxy.size.height * 0.55)
                Button(action: dismiss) {
                    Image("Close")
                        .renderingMode(.original)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 36)
                        .padding(.vertical, 2)
                }
                    Spacer()
                }
                .padding(.top, proxy.safeAreaInsets.top + 40)
                .padding(.bottom, proxy.safeAreaInsets.bottom + 40)
            }
        }
    }
}

private struct SettingsPanel: View {
    @Binding var isPresented: Bool
    @Binding var isVibrationEnabled: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Spacer()
                Button(action: { isPresented = false }) {
                    Image("Close")
                        .renderingMode(.original)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 24)
                        .padding(4)
                }
            }
            .padding(.top, 8)
            Image("Vibration")
                .resizable()
                .scaledToFit()
                .frame(height: 320)
            HStack(spacing: 32) {
                settingButton(title: "ON", isActive: isVibrationEnabled) {
                    isVibrationEnabled = true
                }
                settingButton(title: "OFF", isActive: !isVibrationEnabled) {
                    isVibrationEnabled = false
                }
            }
        }
        .padding(32)
        .frame(maxWidth: 420)
        .background(Color.white)
        .cornerRadius(28)
        .shadow(color: Color.black.opacity(0.3), radius: 16, x: 0, y: 6)
    }
    
    private func settingButton(title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.title3.bold())
                .foregroundColor(isActive ? .white : .black)
                .frame(width: 100, height: 48)
                .background(isActive ? Color.black : Color.gray.opacity(0.2))
                .cornerRadius(12)
        }
    }
}

private struct AchievementRewardView: View {
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
                        .frame(width: proxy.size.width * 0.9)
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
                        .renderingMode(.original)
                        .resizable()
                        .scaledToFit()
                        .frame(width: proxy.size.width * 0.4)
                        .padding(.vertical, 4)
                }
                .padding(.bottom, isPad ? max(proxy.safeAreaInsets.bottom + 60, 60) : max(proxy.safeAreaInsets.bottom + 36, 36))
            }
        }
    }
}

struct GameScreen: View {
    @EnvironmentObject private var viewModel: AppFlowViewModel
    
    private enum CharacterRotation: CaseIterable {
        case standard, tiltRight, tiltLeft, flipped
        
        var angle: Angle {
            switch self {
            case .standard: return .degrees(0)
            case .tiltRight: return .degrees(45)
            case .tiltLeft: return .degrees(45)
            case .flipped: return .degrees(0)
            }
        }
        
        var isMirrored: Bool {
            switch self {
            case .tiltLeft, .flipped:
                return true
            default:
                return false
            }
        }
    }
    
    @State private var characterName: String = "Chara01"
    @State private var rotationState: CharacterRotation = .standard

    var body: some View {
        GeometryReader { proxy in
            let backgroundName = String(format: "Game_%02d", min(max(viewModel.currentStage, 1), viewModel.totalStages))
            let halfHeight = proxy.size.height / 2
            let safeInsets = proxy.safeAreaInsets
            let topSafePadding = safeInsets.top
            let bottomSafePadding = safeInsets.bottom
            let isPad = isPadDevice

            let buttonWidthRatio: CGFloat = isPad ? 0.6 : 0.8
            let buttonHeightRatio: CGFloat = isPad ? 0.65 : 0.8
            let buttonTopPadding = topSafePadding + proxy.size.height * (isPad ? 0.025 : 0.04)
            let buttonBottomPadding = bottomSafePadding + proxy.size.height * (isPad ? 0.1 : 0.07)
            let buttonVerticalOffset = proxy.size.height * (isPad ? 0.3 : 0.2)
            let topSpacerMinHeight = halfHeight * (isPad ? 0.25 : 0.0)
            let bottomSpacerMinHeight = halfHeight * (isPad ? 0.35 : 0.25)

            ZStack {
                // 背景は専用のレイヤーで中央配置
                GeometryReader { bgProxy in
                    Image(backgroundName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: bgProxy.size.width, height: bgProxy.size.height, alignment: .center)
                        .background(Color.black)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .clipped()
                        .ignoresSafeArea()
                }

                VStack {
                    remainingTapView
                        .frame(maxWidth: .infinity, alignment: isPad ? .center : .leading)
                        .padding(.top, 16 + topSafePadding)
                        .padding(.horizontal, 16)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                
                cumulativeTapOverlay(in: proxy.size)

                VStack(spacing: 0) {
                    Spacer()
                        .frame(minHeight: topSpacerMinHeight)
                    Button(action: handleTap) {
                        Image("Tap")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: proxy.size.width * buttonWidthRatio, maxHeight: halfHeight * buttonHeightRatio)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .accessibilityLabel("タップする")
                    }
                    .frame(height: halfHeight)
                    Spacer()
                        .frame(minHeight: bottomSpacerMinHeight)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, buttonTopPadding)
                .padding(.bottom, buttonBottomPadding)
                .offset(y: buttonVerticalOffset)

                VStack {
                    Spacer()
                        .frame(height: topSafePadding + proxy.size.height * (isPad ? 0.2 : 0.13))
                    Image(characterName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: min(proxy.size.width * 0.28, 140) * 1.5)
                        .rotationEffect(rotationState.angle)
                        .scaleEffect(x: rotationState.isMirrored ? -1 : 1, y: 1)
                        .animation(.easeInOut(duration: 0.2), value: rotationState)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .onAppear(perform: configureCharacter)
            .onChange(of: viewModel.currentStage) { _ in
                configureCharacter()
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .statusBar(hidden: true)
    }
    
    private func configureCharacter() {
        characterName = selectCharacterName()
        rotationState = CharacterRotation.allCases.randomElement() ?? .standard
    }
    
    private func handleTap() {
        updateRotationForTap()
        if viewModel.isVibrationEnabled {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
        }
        viewModel.recordTap()
    }

    private func updateRotationForTap() {
        let options = CharacterRotation.allCases.filter { $0 != rotationState }
        rotationState = options.randomElement() ?? rotationState
    }
    
    private func selectCharacterName() -> String {
        let weights = viewModel.characterWeights
        let totalWeight = weights.reduce(0) { $0 + $1.weight }
        guard totalWeight > 0 else { return weights.first?.name ?? "Chara01" }
        
        let randomValue = Double.random(in: 0..<totalWeight)
        var cumulative: Double = 0
        for entry in weights {
            cumulative += entry.weight
            if randomValue < cumulative {
                return entry.name
            }
        }
        return weights.first?.name ?? "Chara01"
    }
}

private extension GameScreen {
    var remainingTapView: some View {
        let remaining = max(viewModel.targetTaps - viewModel.tapCount, 0)
        return VStack(spacing: 4) {
            Text("完了まで")
                .font(.caption)
                .foregroundColor(.black)
            Text("あと")
                .font(.caption)
                .foregroundColor(.black)
            Text("\(remaining)")
                .font(.headline.bold())
                .foregroundColor(.black)
        }
        .padding(8)
        .background(Color.white.opacity(0.95))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
    
    func cumulativeTapOverlay(in size: CGSize) -> some View {
        let isPad = isPadDevice
        let position = CGPoint(x: size.width * (isPad ? 0.8 : 0.85),
                               y: size.height * (isPad ? 0.47 : 0.45))
        return Text("\(viewModel.cumulativeTapCount)")
            .font(isPad ? .largeTitle.weight(.heavy) : .title.weight(.semibold))
            .foregroundColor(.white)
            .shadow(color: .black.opacity(0.65), radius: 5, x: 0, y: 2)
            .position(position)
            .accessibilityLabel(Text("累計タップ \(viewModel.cumulativeTapCount)"))
    }
}

struct StageChangeScreen: View {
    @EnvironmentObject private var viewModel: AppFlowViewModel
    
    private func backgroundName(for stage: Int) -> String? {
        switch stage {
        case 1: return "Change_01"
        case 2: return "Change_02"
        case 3: return "Change_03"
        case 4: return "Change_04"
        case 5: return "Change_05"
        default: return nil
        }
    }

    var body: some View {
        GeometryReader { proxy in
            let isPad = isPadDevice
            ZStack {
                Color.black
                    .ignoresSafeArea()
                stageBackground(in: proxy.size, isPad: isPad)
                stageOverlay(in: proxy, isPad: isPad)
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private var remainingStagesView: some View {
        let remaining = max(viewModel.totalStages - viewModel.currentStage, 0)
        return Text("残りのステージ: \(remaining)")
            .font(.title3.bold())
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.5))
            .cornerRadius(12)
    }

    @ViewBuilder
    private func stageBackground(in size: CGSize, isPad: Bool) -> some View {
        if let imageName = backgroundName(for: viewModel.currentStage) {
            let image = Image(imageName)
                .resizable()

            if isPad {
                image
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size.width, height: size.height, alignment: .center)
                    .background(Color.black)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .clipped()
                    .ignoresSafeArea()
            } else {
                image
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size.width, height: size.height, alignment: .center)
                    .background(Color.black)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .clipped()
                    .ignoresSafeArea()
            }
        } else {
            Color.clear
                .frame(width: size.width, height: size.height)
        }
    }

    @ViewBuilder
    private func stageOverlay(in proxy: GeometryProxy, isPad: Bool) -> some View {
        if isPad {
            let cardTopPadding = proxy.safeAreaInsets.top + 50
            let cardVerticalOffset = proxy.size.height * 0.3
            let buttonVerticalOffset = proxy.size.height * 0.03
            let buttonHorizontalPadding = min(proxy.size.width * 0.2, 100)

            ZStack {
                Color.clear
                    .frame(width: proxy.size.width, height: proxy.size.height)

                VStack {
                    if remainingStages > 0 {
                        Text("残り\(remainingStages)ステージ")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .clipShape(Capsule())
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top, cardTopPadding)
                .offset(y: cardVerticalOffset)

                VStack {
                    Spacer()
                    Button(action: { viewModel.proceedToNextStage() }) {
                        Image("Next")
                            .resizable()
                            .scaledToFit()
                            .frame(width: min(proxy.size.width * 0.45, 360), height: 180)
                            .accessibilityLabel("次へ")
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, buttonHorizontalPadding)
                .offset(y: buttonVerticalOffset)
            }
            .ignoresSafeArea()
        } else {
            VStack(spacing: 12) {
                remainingStagesView
                Button(action: { viewModel.proceedToNextStage() }) {
                    Image("Next")
                        .resizable()
                        .scaledToFit()
                        .frame(width: min(proxy.size.width * 0.5, 240))
                        .accessibilityLabel("次へ")
                }
            }
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2.2)
        }
    }

    private var remainingStages: Int {
        max(viewModel.totalStages - viewModel.currentStage, 0)
    }
}

struct GameClearScreen: View {
    @EnvironmentObject private var viewModel: AppFlowViewModel
    @State private var hasTriggeredMissionAction = false

    var body: some View {
        let isPad = isPadDevice
        let buttonHorizontalPadding: CGFloat = isPad ? 120 : 24
        let buttonBottomPadding: CGFloat = isPad ? 70 : 24
        let buttonVerticalPadding: CGFloat = isPad ? 32 : 18
        let buttonOffset: CGFloat = isPad ? -20 : 0

        ZStack {
            Image(viewModel.currentClearImageName)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea()
            VStack {
                Spacer()
                Button(action: {
                    viewModel.finishGame()
                }) {
                    Image("OK")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, buttonVerticalPadding)
                }
                .padding(.horizontal, buttonHorizontalPadding)
                .padding(.bottom, buttonBottomPadding)
                .offset(y: buttonOffset)
            }
        }
        .onAppear {
            triggerMissionActionIfNeeded()
        }
    }
}

private extension GameClearScreen {
    var illustrationView: some View {
        Group {
            if let illustrationName = currentIllustrationName {
                Image(illustrationName)
                    .resizable()
                    .scaledToFit()
            } else {
                Image("Ilustrated_none")
                    .resizable()
                    .scaledToFit()
            }
        }
    }

    var currentIllustrationName: String? {
        guard let id = viewModel.currentIllustrationID else { return nil }
        return String(format: "Ilustrated_%02d", id)
    }

    func triggerMissionActionIfNeeded() {
        guard !hasTriggeredMissionAction else { return }
        hasTriggeredMissionAction = true
        RakutenRewardManager.shared.triggerMissionActionIfNeeded()
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
