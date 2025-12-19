import SwiftUI

struct StageChangeView: View {
    let context: LayoutContext
    let stage: Int
    let totalStages: Int
    let onNext: () -> Void

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
            let layout = LayoutConfig.stageChange(isPad: context.isPadLayout)
            let size = proxy.size
            ZStack {
                BackgroundImageView(name: backgroundImageName, isPadLayout: context.isPadLayout)

                Button(action: onNext) {
                    Image("Next")
                        .resizable()
                        .scaledToFit()
                }
                .frame(width: layout.nextButtonSize.width, height: layout.nextButtonSize.height)
                .position(LayoutConfig.point(layout.nextButton, in: size))

                VStack(spacing: 0) {
                    Spacer()
                    Color.clear
                        .frame(height: size.height * 0.5)
                }
            }
            .frame(width: size.width, height: size.height)
        }
    }
}
