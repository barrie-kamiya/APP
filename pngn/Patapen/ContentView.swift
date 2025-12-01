import SwiftUI

enum AppScreen {
    case splash
    case home
    case game
    case stageChange
    case clear
}

final class AppViewModel: ObservableObject {
    @Published var screen: AppScreen = .splash
    @Published var tapCount: Int = 0
    @Published var currentStage: Int = 1

    let totalStages: Int = 6
    let tapsToClear: Int = 50

    func showHome() {
        if screen == .splash {
            withAnimation {
                screen = .home
            }
        } else {
            screen = .home
        }
    }

    func startGame() {
        currentStage = 1
        tapCount = 0
        withAnimation {
            screen = .game
        }
    }

    func registerTap() {
        guard screen == .game else { return }
        tapCount = min(tapCount + 1, tapsToClear)
        if tapCount >= tapsToClear {
            handleStageCompletion()
        }
    }

    private func handleStageCompletion() {
        if currentStage < totalStages {
            screen = .stageChange
        } else {
            screen = .clear
        }
    }

    func proceedFromStageChange() {
        guard screen == .stageChange else { return }
        if currentStage < totalStages {
            currentStage += 1
            tapCount = 0
            screen = .game
        } else {
            screen = .clear
        }
    }

    func finishGameClear() {
        tapCount = 0
        currentStage = 1
        screen = .home
    }
}

struct ContentView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        switch viewModel.screen {
        case .splash:
            SplashView {
                viewModel.showHome()
            }
        case .home:
            HomeView(onStart: {
                viewModel.startGame()
            })
        case .game:
            GameView(stage: viewModel.currentStage,
                     totalStages: viewModel.totalStages,
                     tapCount: viewModel.tapCount,
                     requiredTaps: viewModel.tapsToClear,
                     onTap: {
                        viewModel.registerTap()
                     })
        case .stageChange:
            StageChangeView(stage: viewModel.currentStage,
                            totalStages: viewModel.totalStages,
                            onNext: {
                                viewModel.proceedFromStageChange()
                            })
        case .clear:
            GameClearView(onFinish: {
                viewModel.finishGameClear()
            })
        }
    }
}

struct SplashView: View {
    var onTap: () -> Void

    var body: some View {
        Image("Splash")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }
    }
}

struct HomeView: View {
    var onStart: () -> Void

    var body: some View {
        ZStack {
            Image("homeview")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .accessibilityHidden(true)

            VStack(spacing: 32) {
                Spacer()
                Text("ぱたペン")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(radius: 4)
                Text("タップで進めるシンプルなミニゲーム")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.85))
                    .shadow(radius: 2)
                Spacer(minLength: 0)
                VStack(spacing: 4) {
                    HomeImageButton(imageName: "Illustrated") {}
                    HomeImageButton(imageName: "Exchange") {}
                    HomeImageButton(imageName: "Setting") {}
                    HomeImageButton(imageName: "Start") {
                        onStart()
                    }
                }
                .frame(maxWidth: 280)
                .padding(.bottom, 24)
            }
            .padding()
        }
    }
}

struct HomeImageButton: View {
    var imageName: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .scaleEffect(0.8, anchor: .center)
                .accessibilityLabel(imageName)
        }
    }
}

struct GameView: View {
    var stage: Int
    var totalStages: Int
    var tapCount: Int
    var requiredTaps: Int
    var onTap: () -> Void
    @State private var charaImageName: String = GameView.randomCharacterImage()
    @State private var jumpProgress: CGFloat = 0
    @State private var isJumping: Bool = false

    private var backgroundImageName: String {
        switch stage {
        case 1: return "Game_01"
        case 2: return "Game_02"
        case 3: return "Game_03"
        case 4: return "Game_04"
        case 5: return "Game_05"
        default: return "Game_06"
        }
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Image(backgroundImageName)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .accessibilityHidden(true)

                VStack(spacing: 0) {
                    VStack(spacing: 12) {
                        Text("ステージ \(stage) / \(totalStages)")
                            .font(.title3)
                            .padding(.top, 24)
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                        Text("タップ数: \(tapCount) / \(requiredTaps)")
                            .font(.headline)
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                        ProgressView(value: Double(tapCount), total: Double(requiredTaps))
                            .tint(.white)
                            .padding(.horizontal)
                        Text("下のエリアを連打してください")
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.8))
                            .shadow(radius: 2)
                            .padding(.bottom, 24)
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.3))

                    Button(action: handleTap) {
                        Image("Tap")
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                            .accessibilityLabel("タップボタン")
                    }
                    .frame(height: proxy.size.height / 2)
                    .frame(maxWidth: .infinity)
                }
                .frame(width: proxy.size.width, height: proxy.size.height)

                Image(charaImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)
                    .position(characterPosition(in: proxy.size))
            }
            .edgesIgnoringSafeArea(.bottom)
            .onAppear {
                charaImageName = GameView.randomCharacterImage()
                jumpProgress = 0
                isJumping = false
            }
            .onChange(of: stage) { _ in
                charaImageName = GameView.randomCharacterImage()
                jumpProgress = 0
                isJumping = false
            }
        }
    }

    private func handleTap() {
        triggerCharacterJump()
        onTap()
    }

    private func triggerCharacterJump() {
        guard !isJumping else { return }
        isJumping = true

        let goDuration = 0.4
        withAnimation(.linear(duration: goDuration)) {
            jumpProgress = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + goDuration) {
            let returnDuration = 0.35
            withAnimation(.easeIn(duration: returnDuration)) {
                jumpProgress = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + returnDuration) {
                isJumping = false
            }
        }
    }

    private static func randomCharacterImage() -> String {
        let index = Int.random(in: 1...6)
        return String(format: "Chara%02d", index)
    }

    private func characterPosition(in size: CGSize) -> CGPoint {
        let startX = size.width * 0.8
        let endX = size.width * 0.2
        let x = startX + (endX - startX) * jumpProgress

        let baseY: CGFloat = 140
        let arcHeight: CGFloat = 120
        let progress = jumpProgress
        let arcOffset = -arcHeight * 4 * progress * (1 - progress)
        let y = baseY + arcOffset
        return CGPoint(x: x, y: y)
    }
}

struct StageChangeView: View {
    var stage: Int
    var totalStages: Int
    var onNext: () -> Void

    private var backgroundImageName: String {
        switch stage {
        case 1: return "Change_01"
        case 2: return "Change_02"
        case 3: return "Change_03"
        case 4: return "Change_04"
        case 5: return "Change_05"
        default: return "Change_05"
        }
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Image(backgroundImageName)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .accessibilityHidden(true)

                VStack(spacing: 24) {
                    Spacer()
                    Text("ステージ \(stage) クリア！")
                        .font(.title2)
                        .foregroundColor(.white)
                        .shadow(radius: 3)
                    Text("次のステージへ進みましょう")
                        .foregroundColor(.white.opacity(0.85))
                        .shadow(radius: 2)
                    Button(action: onNext) {
                        Image("Next")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 220)
                            .accessibilityLabel("次へ")
                    }
                    Spacer()
                }
                .padding()

                VStack {
                    Spacer()
                    Color.clear
                        .frame(height: proxy.size.height / 2)
                        .background(Color.clear)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}

struct GameClearView: View {
    var onFinish: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("ゲームクリア！")
                .font(.largeTitle)
            Text("全てのステージを達成しました")
                .foregroundColor(.secondary)
            Button(action: onFinish) {
                Text("完了")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 160)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(16)
            }
            Spacer()
        }
        .padding()
    }
}

#Preview {
    ContentView()
        .environmentObject(AppViewModel())
}
