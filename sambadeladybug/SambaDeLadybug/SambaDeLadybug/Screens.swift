import SwiftUI

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

    private let menuButtons: [(title: String, image: String)] = [
        ("標本", "Illustrated"),
        ("交換", "Exchange"),
        ("設定", "Setting"),
        ("達成", "Present")
    ]

    var body: some View {
        ZStack {
            Image("HomeView")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            VStack(spacing: 24) {
                Spacer()
                GeometryReader { geo in
                    let buttonHeight: CGFloat = 150
                    let spacing: CGFloat = 16
                    let columns: CGFloat = 3
                    let itemWidth = (geo.size.width - spacing * (columns - 1)) / columns
                    let specimenCenterY = geo.size.height * 0.25
                    let menuCenterY = geo.size.height * 0.4

                    ZStack(alignment: .top) {
                        HStack(spacing: spacing) {
                            ForEach(Array(menuButtons.dropFirst().enumerated()), id: \.offset) { item in
                                HomeMenuButton(title: item.element.title, imageName: item.element.image, scale: 1.1, action: {})
                                    .frame(width: itemWidth, height: buttonHeight)
                            }
                        }
                        .frame(width: geo.size.width, height: buttonHeight)
                        .position(x: geo.size.width / 2, y: menuCenterY)
                        if let specimen = menuButtons.first {
                            HomeMenuButton(title: specimen.title, imageName: specimen.image, scale: 1.1, action: {})
                                .frame(width: itemWidth, height: buttonHeight)
                                .frame(width: geo.size.width, height: buttonHeight, alignment: .center)
                                .position(x: geo.size.width / 2, y: specimenCenterY)
                        }
                    }
                }
                HomeMenuButton(title: "スタート", imageName: "Start", scale: 1.8, height: 300, action: {
                    viewModel.startGame()
                })
                Spacer()
            }
            .padding(24)
        }
    }
}

private struct HomeMenuButton: View {
    let title: String
    let imageName: String
    let scale: CGFloat
    let height: CGFloat
    let action: () -> Void

    init(title: String, imageName: String, scale: CGFloat = 1.0, height: CGFloat = 140, action: @escaping () -> Void) {
        self.title = title
        self.imageName = imageName
        self.scale = scale
        self.height = height
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
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .frame(height: height)
    }
}

struct GameScreen: View {
    @EnvironmentObject private var viewModel: AppFlowViewModel

    var body: some View {
        GeometryReader { proxy in
            let backgroundName = String(format: "Game_%02d", min(max(viewModel.currentStage, 1), viewModel.totalStages))
            let halfHeight = proxy.size.height / 2
            ZStack {
                Image(backgroundName)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                VStack(spacing: 0) {
                    VStack(spacing: 12) {
                        Text("ステージ \(viewModel.currentStage) / \(viewModel.totalStages)")
                            .font(.title2.bold())
                        Text("タップ数: \(viewModel.tapCount) / \(viewModel.targetTaps)")
                            .font(.headline)
                        ProgressView(value: Double(viewModel.tapCount), total: Double(viewModel.targetTaps))
                            .tint(.red)
                        Spacer()
                    }
                    .frame(height: halfHeight)
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    Button(action: { viewModel.recordTap() }) {
                        Text("タップする")
                            .font(.title.bold())
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .foregroundColor(.primary)
                    }
                    .frame(height: halfHeight)
                    .background(Color.red.opacity(0.2))
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
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
            let halfHeight = proxy.size.height / 2
            ZStack {
                if let imageName = backgroundName(for: viewModel.currentStage) {
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                } else {
                    Color.clear.ignoresSafeArea()
                }
                VStack(spacing: 0) {
                    VStack(spacing: 16) {
                        Spacer()
                        VStack(spacing: 12) {
                            Text("ステージ \(min(viewModel.currentStage + 1, viewModel.totalStages)) へ進みます")
                                .font(.title2.bold())
                            Text("準備ができたら「次へ」をタップしてください")
                                .font(.body)
                        }
                        Button(action: { viewModel.proceedToNextStage() }) {
                            Text("次へ")
                                .font(.title2.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(Color.blue.opacity(0.7))
                                .foregroundColor(.white)
                                .cornerRadius(16)
                        }
                        Spacer()
                    }
                    .frame(height: halfHeight)
                    .padding(24)
                    Color.clear
                        .frame(height: halfHeight)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

struct GameClearScreen: View {
    @EnvironmentObject private var viewModel: AppFlowViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("コンプリート！")
                .font(.largeTitle.bold())
            Button(action: {
                viewModel.finishGame()
            }) {
                Text("完了")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.green.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(16)
            }
            Spacer()
        }
        .padding(24)
    }
}
