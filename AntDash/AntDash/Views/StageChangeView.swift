import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct StageChangeView: View {
    let currentStage: Int
    let totalStages: Int
    let lastClearedStage: Int
    let onNext: () -> Void
    private let remainingTextXRatio: CGFloat = 0.5
    private let remainingTextYRatio: CGFloat = 0.41

    private var backgroundImageName: String {
        switch lastClearedStage {
        case 1: return "Change_01"
        case 2: return "Change_02"
        case 3: return "Change_03"
        case 4: return "Change_04"
        default: return "Change_05"
        }
    }
    
    private var remainingStages: Int {
        max(totalStages - lastClearedStage, 0)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.ignoresSafeArea()
                Image(backgroundImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)

                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: proxy.size.height * (isPad ? 0.43 : 0.41))

                    Button(action: onNext) {
                        Image("Next")
                            .resizable()
                            .scaledToFit()
                            .frame(width: min(proxy.size.width * 0.5, 220),
                                   height: min(proxy.size.height * 0.12, 80))
                    }
                    .accessibilityLabel(Text("次へ"))
                    .padding(.top, isPad ? 32 : 24)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                remainingStageOverlay(in: proxy.size)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea(edges: .bottom)
    }
    
    private func remainingStageOverlay(in size: CGSize) -> some View {
        let boxWidth = min(size.width * 0.45, 240)
        let boxHeight = min(size.height * 0.08, 45)
        let position = CGPoint(x: size.width * remainingTextXRatio,
                               y: size.height * remainingTextYRatio)

        return Text("残り\(remainingStages)ステージ")
            .font(.headline)
            .foregroundColor(.black)
            .frame(width: boxWidth, height: boxHeight)
            .background(Color.white.opacity(0.9))
            .cornerRadius(16)
            .shadow(radius: 4)
            .position(position)
    }
}

#if canImport(UIKit)
private var isPad: Bool {
    let idiomIsPad = UIDevice.current.userInterfaceIdiom == .pad
    let bounds = UIScreen.main.bounds
    let longSide = max(bounds.width, bounds.height)
    return idiomIsPad || longSide >= 1024
}
#else
private let isPad = false
#endif
