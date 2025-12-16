import SwiftUI
import UIKit

struct GameView: View {
    let stageIndex: Int
    let tapCount: Int
    let tapsRequired: Int
    let totalTapCount: Int
    let characterImage: String
    let netSwingID: Int
    let isDebugMode: Bool
    let isHapticsEnabled: Bool
    let onRequestHome: () -> Void
    let onTapButton: () -> Void

    private func backgroundAssetName(for stage: Int) -> String {
        switch stage {
        case 2:
            return "Game_02"
        case 3:
            return "Game_03"
        case 4:
            return "Game_04"
        case 5:
            return "Game_05"
        case 6:
            return "Game_06"
        default:
            return "Game_01"
        }
    }

    private let remainingLabelLayout = ResponsiveFrame(
        phone: RelativeFrame(xPercent: 0.15, yPercent: 0.07, widthPercent: 0.2, heightPercent: 0.1),
        pad: RelativeFrame(xPercent: 0.25, yPercent: 0.05, widthPercent: 0.1, heightPercent: 0.05)
    )

    private let totalLabelLayout = ResponsiveFrame(
        phone: RelativeFrame(xPercent: 0.8, yPercent: 0.48, widthPercent: 0.3, heightPercent: 0.12),
        pad: RelativeFrame(xPercent: 0.7, yPercent: 0.49, widthPercent: 0.22, heightPercent: 0.12)
    )
    private let tapButtonLayout = ResponsiveFrame(
        phone: RelativeFrame(xPercent: 0.5, yPercent: 0.75, widthPercent: 0.9, heightPercent: 0.3),
        pad: RelativeFrame(xPercent: 0.5, yPercent: 0.8, widthPercent: 0.6, heightPercent: 0.4)
    )
    private let homeButtonLayout = ResponsiveFrame(
        phone: RelativeFrame(xPercent: 0.85, yPercent: 0.03, widthPercent: 0.18, heightPercent: 0.08),
        pad: RelativeFrame(xPercent: 0.75, yPercent: 0.03, widthPercent: 0.15, heightPercent: 0.07)
    )

    @State private var showHomeConfirm = false

    var body: some View {
        GeometryReader { geometry in
            let device = LayoutDevice.resolve(for: geometry.size)
            let remaining = max(tapsRequired - tapCount, 0)
            let isStageCleared = tapCount >= tapsRequired

            let isPad = device == .pad

            ZStack(alignment: .top) {
                FittedBackgroundImage(imageName: backgroundAssetName(for: stageIndex))

                if isDebugMode {
                    Text("デバッグモード")
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.4))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .position(x: geometry.size.width / 2, y: 24)
                }

                let remainingRect = remainingLabelLayout.rect(for: device, in: geometry.size)
                VStack(spacing: 2) {
                    Text("トンボの")
                        .font(.subheadline.weight(.semibold))
                    Text("HP")
                        .font(.subheadline.weight(.semibold))
                    Text("\(remaining)")
                        .font(.title3.bold())
                }
                .foregroundColor(.black)
                .frame(width: remainingRect.width, height: remainingRect.height)
                .padding(6)
                .background(Color.white.opacity(0.7))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.1), lineWidth: 1)
                )
                .position(x: remainingRect.midX, y: remainingRect.midY)

                let tapRect = tapButtonLayout.rect(for: device, in: geometry.size)
                Button(action: {
                    if isHapticsEnabled {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                    }
                    onTapButton()
                }) {
                    Image("Tap")
                        .resizable()
                        .scaledToFit()
                        .frame(width: tapRect.width, height: tapRect.height)
                        .clipped()
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .position(x: tapRect.midX, y: tapRect.midY)

                let characterAreaHeight = geometry.size.height * 0.5
                RandomFlyingCharacter(imageName: characterImage,
                                      maxWidth: geometry.size.width,
                                      maxHeight: characterAreaHeight,
                                      swingTrigger: netSwingID,
                                      isStageCleared: isStageCleared)
                .frame(width: geometry.size.width,
                       height: characterAreaHeight,
                       alignment: .top)

                let homeRect = homeButtonLayout.rect(for: device, in: geometry.size)
                Button {
                    showHomeConfirm = true
                } label: {
                    Text("ホームに戻る")
                        .font(.caption.bold())
                        .foregroundColor(.black)
                        .frame(width: homeRect.width, height: homeRect.height * 0.4)
                        .background(Color(red: 0.82, green: 0.95, blue: 0.5).opacity(0.7))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.black.opacity(0.2), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .position(x: homeRect.midX, y: homeRect.midY)

                let totalRect = totalLabelLayout.rect(for: device, in: geometry.size)
                Text("累計スイング数：\(totalTapCount)")
                    .font(device == .pad ? .title3.bold() : .headline.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 1)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.4))
                    .frame(width: totalRect.width, height: totalRect.height, alignment: .center)
                    .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
                    .position(x: totalRect.midX, y: totalRect.midY)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .allowsTightening(true)

                if showHomeConfirm {
                    Color.black.opacity(0.45)
                        .ignoresSafeArea()

                    ConfirmationDialogView(onConfirm: {
                        showHomeConfirm = false
                        onRequestHome()
                    }, onCancel: {
                        showHomeConfirm = false
                    })
                    .frame(width: geometry.size.width * (device == .pad ? 0.45 : 0.8),
                           height: geometry.size.height * 0.32)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .modifier(BackgroundClipModifier(isPad: isPad,
                                             imageName: backgroundAssetName(for: stageIndex)))
        }
    }
}

private struct BackgroundClipModifier: ViewModifier {
    let isPad: Bool
    let imageName: String

    func body(content: Content) -> some View {
        if isPad {
            content
                .clipShape(Rectangle())
                .mask(FittedBackgroundImage(imageName: imageName))
        } else {
            content
        }
    }
}

private struct ConfirmationDialogView: View {
    var onConfirm: () -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("ホームに戻ると、このステージのHPは回復します。戻ってよろしいですか？")
                .font(.body.weight(.semibold))
                .multilineTextAlignment(.center)
                .foregroundColor(.black)
                .padding(.horizontal)

            HStack(spacing: 16) {
                Button("No") {
                    onCancel()
                }
                .buttonStyle(ConfirmDialogButtonStyle(background: Color.gray.opacity(0.2),
                                                      foreground: .black))

                Button("Yes") {
                    onConfirm()
                }
                .buttonStyle(ConfirmDialogButtonStyle(background: Color(red: 0.9, green: 0.95, blue: 0.3),
                                                      foreground: .black))
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.25), radius: 20, x: 0, y: 10)
    }
}

private struct ConfirmDialogButtonStyle: ButtonStyle {
    var background: Color
    var foreground: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(foreground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(background.opacity(configuration.isPressed ? 0.7 : 1))
            .cornerRadius(12)
    }
}
