import SwiftUI

struct GameView: View {
    let stage: Int
    let tapCount: Int
    let tapGoal: Int
    let characterName: String
    let characterOffsetRatio: CGFloat
    let isCharacterFlipped: Bool
    let characterGhosts: [CharacterGhost]
    let onTap: () -> Void

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

    private var remainingTaps: Int {
        max(tapGoal - tapCount, 0)
    }

    var body: some View {
        GeometryReader { proxy in
            let layout = GameLayout(size: proxy.size)
            ZStack {
                backgroundView(layout: layout)

                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                
                ghostLayers(in: layout)
                characterLayer(in: layout)
                remainingInfoOverlay(in: layout)

                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: proxy.size.height / 2)

                    Button(action: onTap) {
                        Image("Tap")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: proxy.size.width * 0.8,
                                   maxHeight: proxy.size.height / 2 - 32)
                    }
                    .buttonStyle(.plain)
                    .frame(height: proxy.size.height / 2)
                }
            }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private func backgroundView(layout: GameLayout) -> some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Image(backgroundImageName)
                .resizable()
                .scaledToFit()
                .frame(width: layout.size.width, height: layout.size.height)
                .position(x: layout.size.width / 2, y: layout.size.height / 2)
        }
    }

    private func characterLayer(in layout: GameLayout) -> some View {
        let characterWidth = layout.characterWidth
        let movementRange = layout.movementRange
        let horizontalOffset = characterOffsetRatio * movementRange
        let centerY = layout.size.height * layout.characterVerticalRatio

        return Image(characterName)
            .resizable()
            .scaledToFit()
            .frame(width: characterWidth, height: characterWidth)
            .scaleEffect(x: isCharacterFlipped ? -1 : 1, y: 1)
            .position(x: layout.size.width / 2 + horizontalOffset, y: centerY)
    }
    
    private func ghostLayers(in layout: GameLayout) -> some View {
        let characterWidth = layout.characterWidth
        let movementRange = layout.movementRange
        let centerY = layout.size.height * layout.characterVerticalRatio
        return ZStack {
            ForEach(Array(characterGhosts.enumerated()), id: \.element.id) { index, ghost in
                let offset = ghost.offsetRatio * movementRange
                let opacity = ghostOpacity(for: index)
                Image(ghost.name)
                    .resizable()
                    .scaledToFit()
                    .frame(width: characterWidth, height: characterWidth)
                    .scaleEffect(x: ghost.isFlipped ? -1 : 1, y: 1)
                    .opacity(opacity)
                    .position(x: layout.size.width / 2 + offset, y: centerY)
            }
        }
    }
    
    private func ghostOpacity(for index: Int) -> Double {
        switch index {
        case 0: return 0.4
        case 1: return 0.25
        default: return 0.12
        }
    }

    private func remainingInfoOverlay(in layout: GameLayout) -> some View {
        let size = layout.size
        let boxWidth = layout.infoBoxSize.width
        let boxHeight = layout.infoBoxSize.height
        let horizontalOffset = size.width * layout.infoHorizontalRatio
        let verticalOffset = -size.height * layout.infoVerticalRatio

        return VStack(spacing: 6) {
            Text("完了まで")
                .font(.headline)
            Text("あと")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("\(remainingTaps)")
                .font(.title.bold())
        }
        .foregroundColor(.black)
        .frame(width: boxWidth, height: boxHeight)
        .background(Color.white.opacity(0.9))
        .cornerRadius(14)
        .shadow(radius: 6)
        .position(x: size.width - horizontalOffset, y: layout.infoPositionY(for: verticalOffset, boxHeight: boxHeight))
    }
}

private struct GameLayout {
    let size: CGSize
    let isPad: Bool
    let padContentWidth: CGFloat
    let characterWidth: CGFloat
    let movementRange: CGFloat
    let characterVerticalRatio: CGFloat
    let infoBoxSize: CGSize
    let infoHorizontalRatio: CGFloat
    let infoVerticalRatio: CGFloat

    init(size: CGSize) {
        self.size = size
        let longSide = max(size.width, size.height)
        isPad = UIDevice.current.userInterfaceIdiom == .pad || longSide >= 1024
        if isPad {
            padContentWidth = min(size.width * 0.75, 700)
        } else {
            padContentWidth = size.width
        }
        characterWidth = min((isPad ? padContentWidth : size.width) * 0.35, isPad ? 320 : 220)
        movementRange = max((size.width - characterWidth) / 2, 0)
        characterVerticalRatio = isPad ? 0.2 : 0.25
        let infoWidth = min(size.width * (isPad ? 0.22 : 0.26), isPad ? 200 : 160)
        let infoHeight = min(size.height * (isPad ? 0.12 : 0.15), isPad ? 95 : 100)
        infoBoxSize = CGSize(width: infoWidth, height: infoHeight)
        infoHorizontalRatio = isPad ? 0.22 : 0.2
        infoVerticalRatio = isPad ? 0.42 : 0.45
    }
    
    func infoPositionY(for verticalOffset: CGFloat, boxHeight: CGFloat) -> CGFloat {
        let baseY = boxHeight / 2 + verticalOffset + size.height / 2
        return max(boxHeight / 2 + 16, min(size.height - boxHeight / 2 - 16, baseY))
    }
}
