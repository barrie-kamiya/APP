import SwiftUI

struct StageChangeView: View {
    let currentStage: Int
    let totalStages: Int
    let onNext: () -> Void
    @Environment(\.isPadLayout) private var isPadLayout

    private var isFinalStage: Bool { currentStage >= totalStages }
    private var backgroundImageName: String {
        switch currentStage {
        case 1: return "Change_01"
        case 2: return "Change_02"
        case 3: return "Change_03"
        case 4: return "Change_04"
        case 5: return "Change_05"
        default: return "Change_05"
        }
    }

    var body: some View {
        ZStack {
            AdaptiveBackgroundImage(imageName: backgroundImageName)
            GeometryReader { geometry in
                ZStack {
                    let remainingStages = max(totalStages - currentStage, 0)
                    let indicatorPosition = CGPoint(x: 0.5, y: 0.42)
                    VStack(spacing: 0) {
                        Color.clear
                            .frame(height: geometry.size.height / 2)
                        Color.clear
                            .frame(height: geometry.size.height / 2)
                    }
                    Button(action: onNext) {
                        Image("Next")
                            .resizable()
                            .scaledToFit()
                            .frame(width: min(geometry.size.width * 0.5, 240))
                            .shadow(radius: 8)
                    }
                    .buttonStyle(.plain)
                    .position(x: geometry.size.width / 2,
                              y: geometry.size.height * (isPadLayout ? 0.48 : 0.49))

                    if !isFinalStage {
                        VStack(spacing: 4) {
                            Text("残り\(remainingStages)ステージ")
                                .font(.title3.bold())
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                        }
                        .font(.caption)
                        .padding(8)
                        .frame(width: geometry.size.width * 0.4)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(10)
                        .shadow(radius: 4)
                        .position(x: geometry.size.width * indicatorPosition.x,
                                  y: geometry.size.height * (isPadLayout ? 0.41 : 0.41))
                    }
                }
            }
        }
        .ignoresSafeArea(edges: isPadLayout ? [] : .all)
    }
}
