import SwiftUI
import UIKit
import Combine

// MARK: - App Screen

private enum AppScreen: Equatable {
    case splash
    case home
    case game(stage: Int)
    case stageChange(stage: Int)
    case illustrated
    case clear(clearImage: String)
}

@main
struct ChargingUnicornApp: App {
    /// trueでテスト設定（周回条件・確率・必要タップ数の緩和）を有効化
    private let useTestingAchievementRewards = true

    var body: some Scene {
        WindowGroup {
            AppRootView(useTestingAchievementRewards: useTestingAchievementRewards)
        }
    }
}

// MARK: - Root

private struct AppRootView: View {
    let useTestingAchievementRewards: Bool

    @AppStorage("CU_savedStageIndex") private var savedStageIndex: Int = 0
    @AppStorage("CU_savedTotalTapCount") private var savedTotalTapCount: Int = 0
    @AppStorage("CU_clearCount") private var storedClearCount: Int = 0
    @AppStorage("CU_unlockedIllustrations") private var storedUnlockedIllustrations: String = ""
    @AppStorage("CU_pendingAchievements") private var storedPendingAchievements: String = ""

    @State private var screen: AppScreen = .splash
    @State private var totalTapCount: Int = 0
    @State private var clearCount: Int = 0
    @State private var unlockedIllustrations: Set<String> = []
    @State private var vibrationEnabled: Bool = true
    @State private var clearPicker: ClearBackgroundPicker
    @State private var characterWeights: [String: Double]
    @State private var pendingAchievements: [String] = []
    @State private var claimingRewards: Bool = false

    init(useTestingAchievementRewards: Bool) {
        self.useTestingAchievementRewards = useTestingAchievementRewards
        _clearPicker = State(initialValue: ClearBackgroundPicker(useTesting: useTestingAchievementRewards))
        let defaultWeights: [String: Double] = [
            "Chara01": 0.75,
            "Chara02": 0.15,
            "Chara03": 0.035,
            "Chara04": 0.0132,
            "Chara05": 0.0018
        ]
        let testWeights: [String: Double] = [
            "Chara01": 1, "Chara02": 1, "Chara03": 1, "Chara04": 1, "Chara05": 1
        ]
        _characterWeights = State(initialValue: useTestingAchievementRewards ? testWeights : defaultWeights)
        _pendingAchievements = State(initialValue: [])
    }

    private let totalStages = 6

    var body: some View {
        let initialScreen: AppScreen = {
            if savedStageIndex > 0 && savedStageIndex <= totalStages {
                return .game(stage: savedStageIndex)
            } else {
                return .splash
            }
        }()

        Group {
            switch screen {
        case .splash:
            SplashView(onNext: {
                screen = .home
            }, useTestingAchievementRewards: useTestingAchievementRewards)
        case .home:
            HomeView(
                layout: .defaultLayout,
                clearCount: clearCount,
                unlockedIllustrations: unlockedIllustrations,
                vibrationEnabled: $vibrationEnabled,
                useTestingAchievementRewards: useTestingAchievementRewards,
                canClaimAchievement: !pendingAchievements.isEmpty,
                claimAchievementReward: {
                    if let rewardImage = pendingAchievements.first {
                        pendingAchievements.removeFirst()
                        storedPendingAchievements = serializeArray(pendingAchievements)
                        unlockIllustration(for: rewardImage, into: &unlockedIllustrations)
                        storedUnlockedIllustrations = serializeSet(unlockedIllustrations)
                        return rewardImage
                    }
                    return nil
                },
                onIllustrated: { screen = .illustrated },
                onAchievement: {
                    // 既存の遷移処理は使用せず、HomeView内でスライド表示を行う
                },
                onStart: {
                    let startStage = savedStageIndex > 0 ? savedStageIndex : 1
                    totalTapCount = savedTotalTapCount
                    savedStageIndex = startStage
                    screen = .game(stage: startStage)
                }
            )
        case let .game(stage):
            GameView(
                stageIndex: stage,
                totalTapsRequired: useTestingAchievementRewards ? 5 : 50,
                layout: .defaultLayout,
                totalTapCount: $totalTapCount,
                vibrationEnabled: $vibrationEnabled,
                characterWeights: characterWeights,
                useTestingAchievementRewards: useTestingAchievementRewards,
                onStageComplete: { stageTotal in
                    let nextStageIndex = stage + 1
                    savedTotalTapCount = stageTotal
                    totalTapCount = stageTotal
                    savedStageIndex = nextStageIndex > totalStages ? 0 : nextStageIndex
                    if stage >= totalStages {
                        // 周回完了時は累計ダッシュ数をリセットして次周へ
                        totalTapCount = 0
                        savedTotalTapCount = 0
                        savedStageIndex = 0
                        let nextCount = clearCount + 1
                        let reward = pendingAchievementReward(clearCount: nextCount, unlocked: unlockedIllustrations, pending: pendingAchievements, useTesting: useTestingAchievementRewards)
                        let clearImage: String
                        if let reward = reward {
                            // 報酬は未受領として保持し、表示は通常ドロップ
                            if !pendingAchievements.contains(reward.clearImage) {
                                pendingAchievements.append(reward.clearImage)
                                storedPendingAchievements = serializeArray(pendingAchievements)
                            }
                        }
                        clearImage = selectClearImage(picker: clearPicker)
                        unlockIllustration(for: clearImage, into: &unlockedIllustrations) // 表示された背景は図鑑に反映
                        storedUnlockedIllustrations = serializeSet(unlockedIllustrations)
                        clearCount = nextCount
                        storedClearCount = clearCount
                        screen = .clear(clearImage: clearImage)
                    } else {
                        screen = .stageChange(stage: stage)
                    }
                },
                onBackHome: { stageBaseline in
                    savedStageIndex = stage
                    savedTotalTapCount = stageBaseline
                    totalTapCount = stageBaseline
                    screen = .home
                }
            )
            .onAppear {
                savedStageIndex = stage
                savedTotalTapCount = totalTapCount
            }
        case let .stageChange(stage):
            StageChangeView(stageIndex: stage, layout: .defaultLayout, useTestingAchievementRewards: useTestingAchievementRewards) {
                savedStageIndex = stage + 1
                savedTotalTapCount = totalTapCount
                screen = .game(stage: stage + 1)
            }
        case .illustrated:
            IllustratedView(unlocked: unlockedIllustrations.sorted(), useTestingAchievementRewards: useTestingAchievementRewards) {
                screen = .home
            }
        case let .clear(clearImage):
            ClearView(layout: .defaultLayout, onFinish: {
                if claimingRewards, let rewardImage = pendingAchievements.first {
                    pendingAchievements.removeFirst()
                    storedPendingAchievements = serializeArray(pendingAchievements)
                    unlockIllustration(for: rewardImage, into: &unlockedIllustrations)
                    storedUnlockedIllustrations = serializeSet(unlockedIllustrations)
                    screen = .clear(clearImage: rewardImage)
                } else {
                    claimingRewards = false
                    savedStageIndex = 0
                    screen = .home
                }
            }, imageName: clearImage, useTestingAchievementRewards: useTestingAchievementRewards)
        }
        }
        .onAppear {
            clearCount = storedClearCount
            unlockedIllustrations = deserializeSet(storedUnlockedIllustrations)
            pendingAchievements = deserializeArray(storedPendingAchievements)
            if screen == .splash, initialScreen != .splash {
                screen = initialScreen
                totalTapCount = savedTotalTapCount
            }
        }
    }
}

// MARK: - Helpers

private enum DeviceKind { case iPhone, iPad }

private struct DeviceTraits {
    static func kind(for size: CGSize) -> DeviceKind {
        max(size.width, size.height) >= 1024 ? .iPad : .iPhone
    }
}

private struct PercentPosition {
    var x: CGFloat
    var y: CGFloat
    func point(in size: CGSize) -> CGPoint {
        CGPoint(x: size.width * x, y: size.height * y)
    }
}

private struct PercentSize {
    var width: CGFloat
    var height: CGFloat
    func size(in size: CGSize) -> CGSize {
        CGSize(width: size.width * width, height: size.height * height)
    }
}

private struct LayoutPair {
    var iPhone: PercentPosition
    var iPad: PercentPosition
    func position(for device: DeviceKind) -> PercentPosition {
        device == .iPad ? iPad : iPhone
    }
}

private struct SizePair {
    var iPhone: PercentSize
    var iPad: PercentSize
    func size(for device: DeviceKind) -> PercentSize {
        device == .iPad ? iPad : iPhone
    }
}

private struct BoxLayout {
    var position: LayoutPair
    var size: SizePair
    func frame(in container: CGSize, device: DeviceKind) -> (center: CGPoint, size: CGSize) {
        (position.position(for: device).point(in: container), size.size(for: device).size(in: container))
    }
}

private struct PercentLayout<Content: View>: View {
    let content: (GeometryProxy, DeviceKind) -> Content
    init(@ViewBuilder content: @escaping (GeometryProxy, DeviceKind) -> Content) {
        self.content = content
    }
    var body: some View {
        GeometryReader { proxy in
            let device = DeviceTraits.kind(for: proxy.size)
            ZStack { content(proxy, device) }
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
        }
        .ignoresSafeArea()
    }
}

private struct FittedBackground: View {
    let imageName: String
    var body: some View {
        GeometryReader { proxy in
            let device = DeviceTraits.kind(for: proxy.size)
            Image(imageName)
                .resizable()
                .modifier(BackgroundFitModifier(device: device, size: proxy.size))
        }
        .ignoresSafeArea()
    }
}

private struct BackgroundFitModifier: ViewModifier {
    let device: DeviceKind
    let size: CGSize
    func body(content: Content) -> some View {
        if device == .iPad {
            content
            .scaledToFit()
            .frame(height: size.height)
            .frame(width: size.width, height: size.height)
            .clipped()
            } else {
            content
            .scaledToFill()
            .frame(width: size.width, height: size.height)
            .clipped()
            }
    }
}

private struct DebugBadge: View {
    var body: some View {
        Text("デバッグモード")
            .font(.caption.weight(.bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.45))
            .foregroundStyle(Color.white)
            .cornerRadius(10)
            .padding(.top, 8)
    }
}

// MARK: - Splash

private struct SplashView: View {
    var onNext: () -> Void
    var useTestingAchievementRewards: Bool
    var body: some View {
        ZStack {
            FittedBackground(imageName: "Splash")
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture { onNext() }
        .overlay(alignment: .top) {
            if useTestingAchievementRewards {
                DebugBadge()
            }
        }
    }
}

// MARK: - Home

private struct HomeLayout {
    var specimen: LayoutPair
    var trade: LayoutPair
    var settings: LayoutPair
    var achievements: LayoutPair
    var start: LayoutPair
    var tileSize: SizePair
    var startSize: SizePair
    var statusPosition: LayoutPair
    var statusSize: SizePair

    static let defaultLayout = HomeLayout(
        specimen: LayoutPair(
            iPhone: PercentPosition(x: 0.2, y: 0.25),
            iPad: PercentPosition(x: 0.27, y: 0.22)
        ),
        trade: LayoutPair(
            iPhone: PercentPosition(x: 0.5, y: 0.25),
            iPad: PercentPosition(x: 0.5, y: 0.22)
        ),
        settings: LayoutPair(
            iPhone: PercentPosition(x: 0.8, y: 0.25),
            iPad: PercentPosition(x: 0.73, y: 0.22)
        ),
        achievements: LayoutPair(
            iPhone: PercentPosition(x: 0.5, y: 0.4),
            iPad: PercentPosition(x: 0.5, y: 0.4)
        ),
        start: LayoutPair(
            iPhone: PercentPosition(x: 0.5, y: 0.77),
            iPad: PercentPosition(x: 0.5, y: 0.77)
        ),
        tileSize: SizePair(
            iPhone: PercentSize(width: 0.28, height: 0.11),
            iPad: PercentSize(width: 0.18, height: 0.07)
        ),
        startSize: SizePair(
            iPhone: PercentSize(width: 0.60, height: 0.45),
            iPad: PercentSize(width: 0.65, height: 0.3)
        ),
        statusPosition: LayoutPair(
            iPhone: PercentPosition(x: 0.5, y: 0.52),
            iPad: PercentPosition(x: 0.5, y: 0.53)
        ),
        statusSize: SizePair(
            iPhone: PercentSize(width: 0.60, height: 0.07),
            iPad: PercentSize(width: 0.40, height: 0.09)
        )
    )
}

private struct HomeView: View {
    var layout: HomeLayout
    var clearCount: Int
    var unlockedIllustrations: Set<String>
    @Binding var vibrationEnabled: Bool
    var useTestingAchievementRewards: Bool
    var canClaimAchievement: Bool
    var claimAchievementReward: () -> String?
    var onIllustrated: () -> Void
    var onAchievement: () -> Void
    var onStart: () -> Void

    @State private var showSettings = false
    @State private var achievementPulse = false
    @State private var achievementPopupImage: String?
    @State private var achievementSlideIn: Bool = false

    var body: some View {
        PercentLayout { proxy, device in
            let specimenPos = layout.specimen.position(for: device).point(in: proxy.size)
            let tradePos = layout.trade.position(for: device).point(in: proxy.size)
            let settingsPos = layout.settings.position(for: device).point(in: proxy.size)
            let achievementsPos = layout.achievements.position(for: device).point(in: proxy.size)
            let startPos = layout.start.position(for: device).point(in: proxy.size)
            let tileSize = layout.tileSize.size(for: device).size(in: proxy.size)
            let startSize = layout.startSize.size(for: device).size(in: proxy.size)
            let statusPos = layout.statusPosition.position(for: device).point(in: proxy.size)
            let statusSize = layout.statusSize.size(for: device).size(in: proxy.size)

            ZStack {
                FittedBackground(imageName: "HomeView")
                Group {
                    Button(action: { onIllustrated() }) {
                        Image("Illustrated")
                            .resizable()
                            .scaledToFit()
                            .frame(width: tileSize.width, height: tileSize.height)
                    }
                    .buttonStyle(.plain)
                    .position(x: specimenPos.x, y: specimenPos.y)

                    Button(action: {}) {
                        Image("Exchange")
                            .resizable()
                            .scaledToFit()
                            .frame(width: tileSize.width, height: tileSize.height)
                    }
                    .buttonStyle(.plain)
                    .position(x: tradePos.x, y: tradePos.y)

                    Button(action: { showSettings.toggle() }) {
                        Image("Setting")
                            .resizable()
                            .scaledToFit()
                            .frame(width: tileSize.width, height: tileSize.height)
                    }
                    .buttonStyle(.plain)
                    .position(x: settingsPos.x, y: settingsPos.y)

                    Button(action: {
                        if canClaimAchievement {
                            if let reward = claimAchievementReward() {
                                achievementPopupImage = reward
                            }
                        } else {
                            onIllustrated()
                        }
                    }) {
                        Image("Present")
                            .resizable()
                            .scaledToFit()
                            .frame(width: tileSize.width, height: tileSize.height)
                    }
                    .buttonStyle(.plain)
                    .opacity(canClaimAchievement ? 1.0 : 0.4)
                    .scaleEffect(canClaimAchievement ? (achievementPulse ? 1.08 : 1.0) : 1.0)
                    .animation(canClaimAchievement ? .easeInOut(duration: 0.9).repeatForever(autoreverses: true) : .default, value: achievementPulse)
                    .disabled(!canClaimAchievement)
                    .position(x: achievementsPos.x, y: achievementsPos.y)

                    Button { onStart() } label: {
                        Image("Start")
                            .resizable()
                            .scaledToFit()
                            .frame(width: startSize.width, height: startSize.height)
                    }
                    .buttonStyle(.plain)
                    .position(x: startPos.x, y: startPos.y)
                }

                let nextMilestone = nextMilestoneRemaining(current: clearCount, useTesting: useTestingAchievementRewards)
                VStack(spacing: 4) {
                    Text("\(clearCount)週クリア")
                    Text("次の報酬まであと\(nextMilestone)週")
                }
                .font(.headline.weight(.semibold))
                .frame(width: statusSize.width, height: statusSize.height)
                .multilineTextAlignment(.center)
                .padding(8)
                .background(Color.gray.opacity(0.7))
                .foregroundStyle(Color.white)
                .cornerRadius(12)
                .position(x: statusPos.x, y: statusPos.y)
                .onAppear {
                    if canClaimAchievement {
                        achievementPulse = true
                    } else {
                        achievementPulse = false
                    }
                }
                .onChange(of: canClaimAchievement) { value in
                    if value {
                        achievementPulse = true
                    } else {
                        achievementPulse = false
                    }
                }

                if showSettings {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                        .onTapGesture { showSettings = false }

                    VStack(spacing: 16) {
                        Image("Vibration")
                            .resizable()
                            .scaledToFit()
                            .frame(height: proxy.size.height * 0.2)

                        HStack(spacing: 16) {
                            Button("ON") { vibrationEnabled = true }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 20)
                                .background(vibrationEnabled ? Color.green.opacity(0.8) : Color.gray.opacity(0.3))
                                .cornerRadius(10)
                                .foregroundColor(.white)

                            Button("OFF") { vibrationEnabled = false }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 20)
                                .background(!vibrationEnabled ? Color.red.opacity(0.8) : Color.gray.opacity(0.3))
                                .cornerRadius(10)
                                .foregroundColor(.white)
                        }

                        Button("閉じる") {
                            showSettings = false
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 20)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                    }
                    .padding()
                    .frame(width: proxy.size.width * 0.8, height: proxy.size.height * 0.4)
                    .background(Color.white)
                    .cornerRadius(18)
                    .shadow(radius: 12)
                }
            }
            .overlay(alignment: .center) {
                if let rewardImage = achievementPopupImage {
                    GeometryReader { popupGeo in
                        ZStack {
                            Color.black.opacity(0.7)
                                .ignoresSafeArea()
                                .onTapGesture { closeAchievementPopup() }

                            VStack {
                                Spacer()
                                Image(rewardImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: popupGeo.size.width, height: popupGeo.size.height)
                                    .clipped()
                                    .accessibilityLabel("達成報酬")
                                Spacer()
                            }
                            .frame(width: popupGeo.size.width, height: popupGeo.size.height)
                            .offset(y: achievementSlideIn ? 0 : popupGeo.size.height)
                            .animation(.spring(response: 0.55, dampingFraction: 0.85, blendDuration: 0.2), value: achievementSlideIn)

                            VStack {
                                Spacer()
                                Button(action: { closeAchievementPopup() }) {
                                    Image("Close")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 70, height: 70)
                                        .padding(.bottom, popupGeo.safeAreaInsets.bottom + 16)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .onAppear {
                            achievementSlideIn = false
                            withAnimation(.spring(response: 0.55, dampingFraction: 0.85, blendDuration: 0.2)) {
                                achievementSlideIn = true
                            }
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .overlay(alignment: .top) {
                if useTestingAchievementRewards {
                    DebugBadge()
                }
            }
        }
    }

    private func closeAchievementPopup() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            achievementPopupImage = nil
            achievementSlideIn = false
        }
    }
}

// MARK: - Game

private enum CharacterVariant { case base, b }
private enum MoveDirection { case left, right }
private enum BounceState { case none, leftPendingFlip, rightPendingFlip }
private enum EdgeHit { case left, right }

private struct CharacterVisual {
    var name: String
    var variant: CharacterVariant
    var flipped: Bool
    var direction: MoveDirection
    var x: CGFloat
    var bounceState: BounceState
    var y: CGFloat
    var width: CGFloat
    var containerWidth: CGFloat

    var imageName: String {
        variant == .base ? name : "\(name)_B"
    }
}

private struct GhostVisual: Identifiable {
    let id = UUID()
    let imageName: String
    let flipped: Bool
    let x: CGFloat
    let birth: Date
}

private struct CharacterPicker {
    private let weighted: [(name: String, weight: Double)]
    private var total: Double { weighted.reduce(0) { $0 + $1.weight } }

    init(weights: [String: Double]? = nil) {
        let defaultWeights: [(String, Double)] = [
            ("Chara01", 0.75),
            ("Chara02", 0.15),
            ("Chara03", 0.035),
            ("Chara04", 0.0132),
            ("Chara05", 0.0018)
        ]
        if let w = weights, !w.isEmpty {
            self.weighted = w.map { ($0.key, $0.value) }
        } else {
            self.weighted = defaultWeights
        }
    }

    func nextCharacterName() -> String {
        let roll = Double.random(in: 0..<(total > 0 ? total : 1))
        var acc: Double = 0
        for item in weighted {
            acc += item.weight
            if roll < acc { return item.name }
        }
        return weighted.first?.name ?? "Chara01"
    }
}

private struct GameLayout {
    var counter: LayoutPair
    var tapArea: BoxLayout
    var remainingBox: BoxLayout
    var cumulativeBox: BoxLayout
    var homeButton: BoxLayout
    var characterPosition: LayoutPair
    var characterSize: SizePair

    static let defaultLayout = GameLayout(
        counter: LayoutPair(
            iPhone: PercentPosition(x: 0.5, y: 0.15),
            iPad: PercentPosition(x: 0.5, y: 0.12)
        ),
        tapArea: BoxLayout(
            position: LayoutPair(
                iPhone: PercentPosition(x: 0.5, y: 0.77),
                iPad: PercentPosition(x: 0.5, y: 0.75)
            ),
            size: SizePair(
                iPhone: PercentSize(width: 0.8, height: 0.35),
                iPad: PercentSize(width: 0.5, height: 0.3)
            )
        ),
        remainingBox: BoxLayout(
            position: LayoutPair(
                iPhone: PercentPosition(x: 0.18, y: 0.11),
                iPad: PercentPosition(x: 0.27, y: 0.1)
            ),
            size: SizePair(
                iPhone: PercentSize(width: 0.15, height: 0.06),
                iPad: PercentSize(width: 0.15, height: 0.08)
            )
        ),
        cumulativeBox: BoxLayout(
            position: LayoutPair(
                iPhone: PercentPosition(x: 0.78, y: 0.5),
                iPad: PercentPosition(x: 0.7, y: 0.5)
            ),
            size: SizePair(
                iPhone: PercentSize(width: 0.36, height: 0.02),
                iPad: PercentSize(width: 0.2, height: 0.02)
            )
        ),
        homeButton: BoxLayout(
            position: LayoutPair(
                iPhone: PercentPosition(x: 0.85, y: 0.08),
                iPad: PercentPosition(x: 0.72, y: 0.07)
            ),
            size: SizePair(
                iPhone: PercentSize(width: 0.18, height: 0.03),
                iPad: PercentSize(width: 0.16, height: 0.03)
            )
        ),
        characterPosition: LayoutPair(
            iPhone: PercentPosition(x: 0.5, y: 0.34),
            iPad: PercentPosition(x: 0.5, y: 0.32)
        ),
        characterSize: SizePair(
            iPhone: PercentSize(width: 0.45, height: 0.2),
            iPad: PercentSize(width: 0.34, height: 0.16)
        )
    )
}

private struct GameView: View {
    let stageIndex: Int
    let totalTapsRequired: Int
    var layout: GameLayout
    @Binding var totalTapCount: Int
    @Binding var vibrationEnabled: Bool
    var characterWeights: [String: Double]
    var useTestingAchievementRewards: Bool
    var onStageComplete: (_ stageTotal: Int) -> Void
    var onBackHome: (_ stageBaseline: Int) -> Void

    @State private var tapCount = 0
    @State private var showHomeConfirm = false
    @State private var character: CharacterVisual?
    @State private var ghostTrail: [GhostVisual] = []
    @State private var bounceOffset: CGFloat = 0
    @State private var stageStartTotal: Int = 0

    private var characterPicker: CharacterPicker {
        CharacterPicker(weights: characterWeights)
    }
    private let ghostLifespan: TimeInterval = 0.3
    private let ghostCleanupTimer = Timer.publish(every: 0.02, on: .main, in: .common).autoconnect()

    var body: some View {
        PercentLayout { proxy, device in
            let _ = layout.counter.position(for: device).point(in: proxy.size)
            let tapBox = layout.tapArea.frame(in: proxy.size, device: device)
            let remainingBox = layout.remainingBox.frame(in: proxy.size, device: device)
            let cumulativeBox = layout.cumulativeBox.frame(in: proxy.size, device: device)
            let homeBox = layout.homeButton.frame(in: proxy.size, device: device)
            let characterSize = layout.characterSize.size(for: device).size(in: proxy.size)
            let characterY = layout.characterPosition.position(for: device).point(in: proxy.size).y

            ZStack {
                GameBackground(stageIndex: stageIndex)

                if let char = character {
                    ForEach(Array(ghostTrail.enumerated()), id: \.element.id) { idx, ghost in
                        let alphaSteps: [Double] = [0.6, 0.45, 0.3, 0.15]
                        let opacity = idx < alphaSteps.count ? alphaSteps[idx] : 0.1
                        Image(ghost.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: characterSize.width, height: characterSize.height)
                            .scaleEffect(x: ghost.flipped ? -1 : 1, y: 1)
                            .position(x: ghost.x, y: characterY)
                            .opacity(opacity)
                            .allowsHitTesting(false)
                    }

                    Image(char.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: characterSize.width, height: characterSize.height)
                        .scaleEffect(x: char.flipped ? -1 : 1, y: 1)
                        .position(x: char.x, y: characterY + bounceOffset)
                        .animation(.easeInOut(duration: 0.12), value: char.x)
                        .animation(.easeInOut(duration: 0.12), value: char.flipped)
                        .animation(.spring(response: 0.3, dampingFraction: 0.55), value: bounceOffset)
                        .accessibilityLabel("キャラクター")
                }

                VStack(spacing: 4) {
                    Text("完了まで")
                        .font(.footnote.weight(.semibold))
                    Text("あと")
                        .font(.footnote.weight(.semibold))
                    Text("\(max(totalTapsRequired - tapCount, 0))")
                        .font(.headline.weight(.bold))
                }
                .frame(width: remainingBox.size.width, height: remainingBox.size.height)
                .multilineTextAlignment(.center)
                .padding(8)
                .background(Color.white.opacity(0.7))
                .foregroundStyle(Color.black)
                .cornerRadius(8)
                .position(x: remainingBox.center.x, y: remainingBox.center.y)

                Text("累計ラッシュ数：\(totalTapCount)")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(width: cumulativeBox.size.width, height: cumulativeBox.size.height)
                    .multilineTextAlignment(.center)
                    .padding(8)
                    .background(Color.black.opacity(0.4))
                    .foregroundStyle(Color.white)
                    .cornerRadius(8)
                    .position(x: cumulativeBox.center.x, y: cumulativeBox.center.y)

                Button {
                    showHomeConfirm = true
                } label: {
                    Text("ホームに戻る")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(6)
                        .background(Color(red: 0.69, green: 0.65, blue: 0.96).opacity(0.7))
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .frame(width: homeBox.size.width, height: homeBox.size.height)
                .position(x: homeBox.center.x, y: homeBox.center.y)

                Button {
                    tapCount += 1
                    totalTapCount += 1
                    if vibrationEnabled {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                    advanceCharacter(in: proxy, device: device, characterWidth: characterSize.width, characterHeight: characterSize.height)
                    if tapCount >= totalTapsRequired {
                        let finishedTotal = totalTapCount
                        onStageComplete(finishedTotal)
                        stageStartTotal = finishedTotal
                        tapCount = 0
                        initializeCharacter(in: proxy, device: device, characterWidth: characterSize.width)
                    }
                } label: {
                    Image("Tap")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .buttonStyle(.plain)
                .frame(width: tapBox.size.width, height: tapBox.size.height)
                .position(x: tapBox.center.x, y: tapBox.center.y)
            }
            .alert("ホームに戻ると、このステージのラッシュ数はリセットされます。戻ってよろしいですか？", isPresented: $showHomeConfirm) {
                Button("Yes") {
                    tapCount = 0
                    totalTapCount = stageStartTotal
                    onBackHome(stageStartTotal)
                }
                Button("No", role: .cancel) {}
            }
            .onAppear {
                stageStartTotal = totalTapCount
                initializeCharacter(in: proxy, device: device, characterWidth: characterSize.width)
                ghostTrail.removeAll()
            }
            .onChange(of: stageIndex) { _ in
                stageStartTotal = totalTapCount
                initializeCharacter(in: proxy, device: device, characterWidth: characterSize.width)
                ghostTrail.removeAll()
            }
            .onReceive(ghostCleanupTimer) { _ in
                ghostTrail = ghostTrail.filter { Date().timeIntervalSince($0.birth) <= ghostLifespan }
            }
            .overlay(alignment: .top) {
                if useTestingAchievementRewards {
                    DebugBadge()
                }
            }
        }
    }

    private func initializeCharacter(in proxy: GeometryProxy, device: DeviceKind, characterWidth: CGFloat) {
        let name = characterPicker.nextCharacterName()
        let startX = proxy.size.width * 0.5
        let y = layout.characterPosition.position(for: device).point(in: proxy.size).y
        character = CharacterVisual(
            name: name,
            variant: .base,
            flipped: false,
            direction: .left,
            x: startX,
            bounceState: .none,
            y: y,
            width: characterWidth,
            containerWidth: proxy.size.width
        )
        bounceOffset = 0
    }

    private func advanceCharacter(in proxy: GeometryProxy, device: DeviceKind, characterWidth: CGFloat, characterHeight: CGFloat) {
        guard var current = character else { return }

        // add ghost at current position before moving
        let ghost = GhostVisual(
            imageName: current.imageName,
            flipped: current.flipped,
            x: current.x,
            birth: Date()
        )
        var newGhostTrail = ghostTrail
        newGhostTrail.insert(ghost, at: 0)
        if newGhostTrail.count > 4 { newGhostTrail = Array(newGhostTrail.prefix(4)) }

        let halfWidth = characterWidth / 2
        let minX = halfWidth
        let maxX = proxy.size.width - halfWidth
        let step = proxy.size.width * 0.15

        // Apply pending flip after bounce
        switch current.bounceState {
        case .leftPendingFlip:
            current.variant = .base
            current.flipped = true
            current.direction = .right
            current.bounceState = .none
        case .rightPendingFlip:
            current.variant = .base
            current.flipped = false
            current.direction = .left
            current.bounceState = .none
        case .none:
            break
        }

        var newX = current.x + (current.direction == .left ? -step : step)
        var hitEdge: EdgeHit?

        if newX <= minX {
            newX = minX
            hitEdge = .left
        } else if newX >= maxX {
            newX = maxX
            hitEdge = .right
        }

        if let edge = hitEdge {
            switch edge {
            case .left:
                current.variant = .b
                current.flipped = false
                current.direction = .right
                current.bounceState = .leftPendingFlip
                triggerBounce(height: characterHeight)
            case .right:
                current.variant = .b
                current.flipped = false
                current.direction = .left
                current.bounceState = .rightPendingFlip
                triggerBounce(height: characterHeight)
            }
        }

        current.x = newX
        current.containerWidth = proxy.size.width
        character = current
        ghostTrail = newGhostTrail.filter { Date().timeIntervalSince($0.birth) <= ghostLifespan }
    }

    private func triggerBounce(height: CGFloat) {
        let amplitude = max(height * 0.12, 8)
        withAnimation(.spring(response: 0.22, dampingFraction: 0.46, blendDuration: 0.1)) {
            bounceOffset = -amplitude
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(.spring(response: 0.30, dampingFraction: 0.62, blendDuration: 0.1)) {
                bounceOffset = 0
            }
        }
    }
}

private struct GameBackground: View {
    let stageIndex: Int
    private var imageName: String {
        switch stageIndex {
        case 1: return "Game_01"
        case 2: return "Game_02"
        case 3: return "Game_03"
        case 4: return "Game_04"
        case 5: return "Game_05"
        case 6: return "Game_06"
        default: return "Game_01"
        }
    }
    var body: some View {
        FittedBackground(imageName: imageName)
    }
}

// MARK: - Stage Change

private struct StageChangeLayout {
    var nextButton: LayoutPair
    var reserveArea: BoxLayout

    static let defaultLayout = StageChangeLayout(
        nextButton: LayoutPair(
            iPhone: PercentPosition(x: 0.5, y: 0.5),
            iPad: PercentPosition(x: 0.5, y: 0.5)
        ),
        reserveArea: BoxLayout(
            position: LayoutPair(
                iPhone: PercentPosition(x: 0.5, y: 0.75),
                iPad: PercentPosition(x: 0.5, y: 0.75)
            ),
            size: SizePair(
                iPhone: PercentSize(width: 1.0, height: 0.5),
                iPad: PercentSize(width: 1.0, height: 0.5)
            )
        )
    )
}

private struct StageChangeView: View {
    let stageIndex: Int
    var layout: StageChangeLayout
    var useTestingAchievementRewards: Bool
    var onNext: () -> Void

    var body: some View {
        PercentLayout { proxy, device in
            let buttonPos = layout.nextButton.position(for: device).point(in: proxy.size)
            let reserve = layout.reserveArea.frame(in: proxy.size, device: device)

            ZStack {
                StageChangeBackground(stageIndex: stageIndex)

                Button(action: { onNext() }) {
                    Image("Next")
                        .resizable()
                        .scaledToFit()
                        .frame(width: proxy.size.width * 0.5, height: proxy.size.height * 0.3)
                }
                .buttonStyle(.plain)
                .position(x: buttonPos.x, y: buttonPos.y)

                Rectangle()
                    .fill(Color.clear)
                    .frame(width: reserve.size.width, height: reserve.size.height)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                    )
                    .accessibilityLabel("広告エリアプレースホルダー")
                    .position(x: reserve.center.x, y: reserve.center.y)
            }
            .overlay(alignment: .top) {
                if useTestingAchievementRewards {
                    DebugBadge()
                }
            }
        }
    }
}

private struct StageChangeBackground: View {
    let stageIndex: Int
    private var imageName: String {
        switch stageIndex {
        case 1: return "Change_01"
        case 2: return "Change_02"
        case 3: return "Change_03"
        case 4: return "Change_04"
        case 5: return "Change_05"
        default: return "Change_05"
        }
    }
    var body: some View { FittedBackground(imageName: imageName) }
}

// MARK: - Clear

private struct ClearLayout {
    var completeButton: LayoutPair

    static let defaultLayout = ClearLayout(
        completeButton: LayoutPair(
            iPhone: PercentPosition(x: 0.5, y: 0.9),
            iPad: PercentPosition(x: 0.5, y: 0.85)
        )
    )
}

private struct ClearBackgroundPicker {
    private let weightedImages: [(name: String, weight: Double)]

    init(useTesting: Bool = false) {
        if useTesting {
            weightedImages = [
                ("Clear_01", 1),
                ("Clear_02", 1),
                ("Clear_03", 1),
                ("Clear_04", 1),
                ("Clear_05", 1)
            ]
        } else {
            weightedImages = [
                ("Clear_01", 0.75),
                ("Clear_02", 0.15),
                ("Clear_03", 0.035),
                ("Clear_04", 0.0132),
                ("Clear_05", 0.0018)
            ]
        }
    }
    private func totalWeight() -> Double {
        weightedImages.reduce(0) { $0 + $1.weight }
    }
    func nextImageName() -> String {
        let total = totalWeight()
        guard total > 0 else { return "Clear_01" }
        let roll = Double.random(in: 0..<total)
        var acc: Double = 0
        for item in weightedImages {
            acc += item.weight
            if roll < acc { return item.name }
        }
        return weightedImages.first?.name ?? "Clear_01"
    }
}

private struct ClearBackground: View {
    let imageName: String
    var body: some View { FittedBackground(imageName: imageName) }
}

private struct ClearView: View {
    var layout: ClearLayout
    var onFinish: () -> Void
    var imageName: String
    var useTestingAchievementRewards: Bool

    var body: some View {
        PercentLayout { proxy, device in
            let buttonPos = layout.completeButton.position(for: device).point(in: proxy.size)

            ZStack {
                ClearBackground(imageName: imageName)

                Button(action: { onFinish() }) {
                    Image("OK")
                        .resizable()
                        .scaledToFit()
                        .frame(width: proxy.size.width * 0.50, height: proxy.size.height * 0.3)
                }
                .buttonStyle(.plain)
                .position(x: buttonPos.x, y: buttonPos.y)
            }
            .overlay(alignment: .top) {
                if useTestingAchievementRewards {
                    DebugBadge()
                }
            }
        }
    }
}

// MARK: - Illustrated

private struct IllustratedView: View {
    var unlocked: [String]
    var useTestingAchievementRewards: Bool
    var onBack: () -> Void
    @State private var selectedIllustration: String?
    @State private var popupOffset: CGSize = .zero

    var body: some View {
        PercentLayout { proxy, device in
            let buttonPos = PercentPosition(x: 0.12, y: 0.08).point(in: proxy.size)
            let gridWidth = proxy.size.width * (device == .iPad ? 0.7 : 0.9)
            let columns = [GridItem(.adaptive(minimum: proxy.size.width * 0.38, maximum: proxy.size.width * 0.45), spacing: 16)]

            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                let displayItems: [String] = {
                    let filtered = unlocked.filter { $0.hasPrefix("Ilustrated_") }
                    let withNone = Array(Set(filtered + ["Ilustrated_none"])).sorted()
                    return withNone
                }()

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(displayItems, id: \.self) { item in
                            Image(item)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: gridWidth * 0.45, maxHeight: proxy.size.height * 0.25)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(12)
                                .padding(10)
                                .background(Color.gray.opacity(0.15))
                                .cornerRadius(14)
                                .onTapGesture {
                                    selectedIllustration = item
                                }
                        }
                    }
                    .padding(.top, proxy.size.height * 0.12)
                    .padding(.horizontal, (proxy.size.width - gridWidth) / 2)
                    .padding(.bottom, 24)
                }

                Button {
                    onBack()
                } label: {
                    Text("戻る")
                        .font(.footnote.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(red: 0.69, green: 0.65, blue: 0.96))
                        .foregroundStyle(Color.white)
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .position(x: buttonPos.x, y: buttonPos.y)
            }
            .overlay(alignment: .top) {
                if useTestingAchievementRewards {
                    DebugBadge()
                }
            }
            .sheet(item: Binding(
                get: { selectedIllustration.map { IllustrationItem(name: $0) } },
                set: { newValue in
                    selectedIllustration = newValue?.name
                    popupOffset = .zero
                })
            ) { sheetItem in
                GeometryReader { sheetProxy in
                    ZStack(alignment: .topTrailing) {
                        Color.black.opacity(0.7)
                            .ignoresSafeArea()
                            .onTapGesture { selectedIllustration = nil }

                        VStack(spacing: 10) {
                            Text("左右にスワイプして全体を表示できます")
                                .font(.footnote)
                                .foregroundStyle(Color.white)
                                .padding(.top, sheetProxy.safeAreaInsets.top + 12)

                            ScrollView(.horizontal, showsIndicators: false) {
                                Image(sheetItem.name)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: sheetProxy.size.width * 1.6, height: sheetProxy.size.height * 0.7)
                                    .padding(.horizontal, 32)
                            }
                            .frame(height: sheetProxy.size.height * 0.7)

                            Button(action: { selectedIllustration = nil }) {
                                Image("Close")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 200, height: 200)
                                    .padding(.bottom, sheetProxy.safeAreaInsets.bottom + 20)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}

private struct IllustrationItem: Identifiable {
    let name: String
    var id: String { name }
}

// MARK: - Utility

private func milestoneTargets(useTesting: Bool) -> [Int] {
    useTesting ? [1, 2, 3, 4] : [50, 100, 150, 200]
}

private func nextMilestoneRemaining(current: Int, useTesting: Bool) -> Int {
    let milestones = milestoneTargets(useTesting: useTesting)
    for m in milestones where current < m { return m - current }
    return 0
}

private func selectClearImage(picker: ClearBackgroundPicker) -> String {
    picker.nextImageName()
}

private func pendingAchievementReward(clearCount: Int, unlocked: Set<String>, pending: [String], useTesting: Bool) -> (clearImage: String, illustration: String)? {
    let milestones = milestoneTargets(useTesting: useTesting)
    let rewards: [(count: Int, clear: String, ill: String)] = [
        (milestones[0], "Clear_06", "Ilustrated_06"),
        (milestones[1], "Clear_07", "Ilustrated_07"),
        (milestones[2], "Clear_08", "Ilustrated_08"),
        (milestones[3], "Clear_09", "Ilustrated_09")
    ]
    for reward in rewards where clearCount >= reward.count && !unlocked.contains(reward.ill) && !pending.contains(reward.clear) {
        return (reward.clear, reward.ill)
    }
    return nil
}

private func unlockIllustration(for clearImage: String, into set: inout Set<String>) {
    let map: [String: String] = [
        "Clear_01": "Ilustrated_01",
        "Clear_02": "Ilustrated_02",
        "Clear_03": "Ilustrated_03",
        "Clear_04": "Ilustrated_04",
        "Clear_05": "Ilustrated_05",
        "Clear_06": "Ilustrated_06",
        "Clear_07": "Ilustrated_07",
        "Clear_08": "Ilustrated_08",
        "Clear_09": "Ilustrated_09"
    ]
    if let ill = map[clearImage] { set.insert(ill) }
}

private func serializeSet(_ set: Set<String>) -> String {
    set.sorted().joined(separator: ",")
}

private func deserializeSet(_ string: String) -> Set<String> {
    if string.isEmpty { return [] }
    return Set(string.split(separator: ",").map(String.init))
}

private func serializeArray(_ array: [String]) -> String {
    array.joined(separator: ",")
}

private func deserializeArray(_ string: String) -> [String] {
    if string.isEmpty { return [] }
    return string.split(separator: ",").map(String.init)
}
