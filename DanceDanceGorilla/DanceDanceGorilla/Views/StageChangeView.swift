import SwiftUI

struct StageChangeView: View {
    let stageIndex: Int
    let onNext: () -> Void

    private var backgroundAssetName: String {
        switch stageIndex {
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
            let isPad = DeviceTraitHelper.isPad(for: proxy.size)
            let padding = DeviceTraitHelper.primaryPadding(for: proxy.size)

            ZStack {
                AspectFitBackground(imageName: backgroundAssetName)

                VStack {
                    Spacer(minLength: padding * 0.5)
                    Button(action: onNext) {
                        Image("Next")
                            .resizable()
                            .scaledToFit()
                            .frame(width: isPad ? 280 : 200, height: isPad ? 80 : 56)
                            .contentShape(Rectangle())
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: isPad ? 100 : 80)
                    Spacer(minLength: padding * 0.5)
                }
                .padding(padding)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    StageChangeView(stageIndex: 2) {}
}
