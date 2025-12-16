import SwiftUI

struct StageChangeView: View {
    let stageIndex: Int
    var onNext: () -> Void

    private func backgroundAssetName(for stage: Int) -> String {
        switch stage {
        case 2:
            return "Change_02"
        case 3:
            return "Change_03"
        case 4:
            return "Change_04"
        case 5:
            return "Change_05"
        default:
            return "Change_01"
        }
    }

    private let messageLayout = ResponsiveFrame(
        phone: RelativeFrame(xPercent: 0.5, yPercent: 0.28, widthPercent: 0.85, heightPercent: 0.14),
        pad: RelativeFrame(xPercent: 0.5, yPercent: 0.32, widthPercent: 0.6, heightPercent: 0.14)
    )

    private let adPlaceholderLayout = ResponsiveFrame(
        phone: RelativeFrame(xPercent: 0.5, yPercent: 0.75, widthPercent: 0.95, heightPercent: 0.5),
        pad: RelativeFrame(xPercent: 0.5, yPercent: 0.75, widthPercent: 0.7, heightPercent: 0.5)
    )

    var body: some View {
        GeometryReader { geometry in
            let device = LayoutDevice.resolve(for: geometry.size)

            ZStack {
                FittedBackgroundImage(imageName: backgroundAssetName(for: stageIndex))

                let buttonWidth: CGFloat = geometry.size.width * (device == .pad ? 0.3 : 0.45)
                let buttonHeight: CGFloat = geometry.size.height * 0.12
                Button {
                    onNext()
                } label: {
                    Image("Next")
                        .resizable()
                        .scaledToFit()
                        .frame(width: buttonWidth, height: buttonHeight)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .position(x: geometry.size.width / 2,
                          y: geometry.size.height / 2 + buttonHeight / 2 - (device == .pad ? 80 : 70))

                let adRect = adPlaceholderLayout.rect(for: device, in: geometry.size)
                Color.clear
                    .positioned(in: adRect)
            }
        }
    }
}
