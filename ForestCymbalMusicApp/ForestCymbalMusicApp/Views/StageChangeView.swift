import SwiftUI

struct StageChangeView: View {
    var stage: Int
    var totalStages: Int
    var onNext: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                backgroundLayer(size: proxy.size)

                VStack(spacing: 16) {
                    Text(remainingStagesText)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(16)
                    Button(action: onNext) {
                        Image("Next")
                            .resizable()
                            .scaledToFit()
                            .frame(width: min(280, proxy.size.width * 0.6))
                            .shadow(radius: 6)
                            .accessibilityLabel("次へ")
                    }
                    .contentShape(Rectangle())
                }
                .position(x: proxy.size.width / 2,
                          y: proxy.size.height * 0.48)
            }
            .edgesIgnoringSafeArea(.bottom)
        }
    }

    @ViewBuilder
    private func backgroundLayer(size: CGSize) -> some View {
        if let name = backgroundImageName {
            ZStack {
                if isPadDevice {
                    Color.black.ignoresSafeArea()
                    Image(name)
                        .resizable()
                        .scaledToFit()
                        .frame(width: size.width, height: size.height)
                        .clipped()
                } else {
                    Image(name)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size.width, height: size.height)
                        .clipped()
                        .ignoresSafeArea()
                }
            }
        } else {
            Color(.systemBackground)
                .ignoresSafeArea()
        }
    }

    private var backgroundImageName: String? {
        switch stage {
        case 1: return "Change_01"
        case 2: return "Change_02"
        case 3: return "Change_03"
        case 4: return "Change_04"
        case 5: return "Change_05"
        default: return nil
        }
    }

    private var remainingStagesText: String {
        let remaining = max(totalStages - stage, 0)
        return remaining > 0 ? "残り \(remaining) ステージ" : "最終ステージ"
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
