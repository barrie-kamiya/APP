import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct GameView: View {
    var stage: Int
    var tapCount: Int
    var targetTapCount: Int
    var vibrationEnabled: Bool
    var characterName: String
    var cumulativeTapCount: Int
    var onTapArea: () -> Void
    var onExitToHome: () -> Void
    @State private var showHomeAlert = false

    private var progress: Double {
        Double(tapCount) / Double(targetTapCount)
    }

    @State private var showPoseA: Bool = true
    @State private var characterOffsetProgress: CGFloat = 0
    @State private var movingLeft: Bool = true

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                backgroundLayer(for: proxy.size)

                characterView
                    .frame(width: proxy.size.width * characterWidthRatio, height: 180)
                    .position(x: characterXPosition(for: proxy.size),
                              y: proxy.size.height * characterPositionRatio)

                Button(action: {
                              triggerHapticIfNeeded()
                              showPoseA.toggle()
                              playSymbalIfNeededOnPoseB()
                              withAnimation(.easeInOut(duration: 0.18)) {
                                  moveCharacterHorizontally()
                              }
                              onTapArea()
                          }) {
                    Image("Tap")
                        .resizable()
                        .scaledToFit()
                        .frame(width: proxy.size.width * tapButtonWidthRatio)
                }
                .contentShape(Rectangle())
                .position(x: proxy.size.width / 2,
                          y: proxy.size.height * tapButtonPositionRatio)
                .edgesIgnoringSafeArea(.bottom)

                remainingTapIndicator
                    .frame(width: proxy.size.width * statusWidthRatio)
                    .position(x: proxy.size.width * statusPositionXRatio,
                              y: proxy.size.height * statusPositionYRatio)

                cumulativeTapOverlay
                    .position(x: proxy.size.width * cumulativePositionXRatio,
                              y: proxy.size.height * cumulativePositionYRatio)
            }
        }
        .onAppear {
            startSymbalBgm()
        }
        .onDisappear {
            stopSymbalBgm()
        }
        .overlay(homeButtonLayer, alignment: .topTrailing)
        .alert("ホームに戻る", isPresented: $showHomeAlert) {
            Button("Yes") {
                showHomeAlert = false
                onExitToHome()
            }
            Button("No", role: .cancel) {
                showHomeAlert = false
            }
        } message: {
            Text("ホームに戻ると、このステージの演奏数はリセットされます。戻ってよろしいですか？")
        }
    }

    private func triggerHapticIfNeeded() {
#if canImport(UIKit)
        guard vibrationEnabled else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
#endif
    }

    private var characterView: some View {
        Image(characterImageName)
            .resizable()
            .scaledToFit()
            .frame(height: 140)
            .shadow(radius: 6)
            .accessibilityHidden(true)
    }

    private var characterImageName: String {
        let suffix = showPoseA ? "_A" : "_B"
        return "\(characterName)\(suffix)"
    }

    private var remainingTapIndicator: some View {
        VStack(alignment: .center, spacing: 4) {
            Text("次ステージ")
                .font(.headline)
            Text("まで")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("\(remainingTaps)")
                .font(statusCountFont)
        }
        .font(statusLabelFont)
        .foregroundColor(.black)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.7))
        .cornerRadius(12)
        .shadow(radius: 4)
        .scaleEffect(isPadDevice ? 0.5 : 1)
        .offset(y: isPadDevice ? -20 : 0)
    }

    private var remainingTaps: Int {
        max(targetTapCount - tapCount, 0)
    }

    private func moveCharacterHorizontally() {
        let step: CGFloat = 0.12
        if movingLeft {
            characterOffsetProgress -= step
            if characterOffsetProgress <= -1 {
                characterOffsetProgress = -1
                movingLeft.toggle()
            }
        } else {
            characterOffsetProgress += step
            if characterOffsetProgress >= 1 {
                characterOffsetProgress = 1
                movingLeft.toggle()
            }
        }
    }

    private func characterXPosition(for size: CGSize) -> CGFloat {
        let characterWidth = size.width * characterWidthRatio
        let maxOffset = max((size.width - characterWidth) / 2, 0)
        return size.width / 2 + characterOffsetProgress * maxOffset
    }

    private var tapButtonWidthRatio: CGFloat {
        return isPadDevice ? 0.6 : 0.75
    }

    private var characterWidthRatio: CGFloat {
        0.6
    }

    private var characterPositionRatio: CGFloat {
        return isPadDevice ? 0.17 : 0.2
    }

    private var tapButtonPositionRatio: CGFloat {
        return isPadDevice ? 0.77 : 0.74
    }

    private var statusPositionXRatio: CGFloat {
        isPadDevice ? 0.22 : 0.17
    }

    private var statusPositionYRatio: CGFloat {
        isPadDevice ? 0.08 : 0.105
    }

    private var statusWidthRatio: CGFloat {
        isPadDevice ? 0.3 : 0.6
    }

    private var statusLabelFont: Font {
        isPadDevice ? .caption : .subheadline
    }

    private var statusCountFont: Font {
        isPadDevice ? .headline.bold() : .title3.weight(.semibold)
    }

    private var cumulativeTapOverlay: some View {
        let background = RoundedRectangle(cornerRadius: isPadDevice ? 20 : 14, style: .continuous)
        return Text("累計演奏数：\(cumulativeTapCount)")
            .font(isPadDevice ? .title2.bold() : .headline.bold())
            .foregroundColor(.white)
            .padding(.horizontal, isPadDevice ? 22 : 18)
            .padding(.vertical, isPadDevice ? 12 : 9)
            .background(background.fill(Color.black.opacity(0.35)))
            .overlay(background.stroke(Color.black.opacity(0.5), lineWidth: 1))
            .shadow(color: .black.opacity(0.6), radius: 6, x: 0, y: 2)
            .scaleEffect(isPadDevice ? 0.5 : 1)
    }

    private var cumulativePositionXRatio: CGFloat {
        isPadDevice ? 0.54 : 0.77
    }

    private var cumulativePositionYRatio: CGFloat {
        isPadDevice ? 0.42 : 0.45
    }
    
    private var homeButtonLayer: some View {
        Button(action: { showHomeAlert = true }) {
            Text("ホームに戻る")
                .font(isPadDevice ? .headline : .caption.bold())
                .foregroundColor(.black)
                .padding(.horizontal, isPadDevice ? 18 : 12)
                .padding(.vertical, isPadDevice ? 10 : 6)
                .background(Color.yellow.opacity(0.5))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.6), lineWidth: 1))
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .padding(.top, isPadDevice ? 50 : 55)
        .padding(.trailing, isPadDevice ? 30 : 16)
        .scaleEffect(isPadDevice ? 0.5 : 1, anchor: .topTrailing)
        .offset(x: isPadDevice ? -30 : 0)
    }

    private var backgroundImage: Image {
        let name: String
        switch stage {
        case 1: name = "Game_01"
        case 2: name = "Game_02"
        case 3: name = "Game_03"
        case 4: name = "Game_04"
        case 5: name = "Game_05"
        default: name = "Game_06"
        }
        return Image(name)
    }

    private func backgroundLayer(for size: CGSize) -> some View {
        ZStack {
            if isPadDevice {
                Color.black.ignoresSafeArea()
                backgroundImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: size.width, height: size.height)
                    .clipped()
            } else {
                backgroundImage
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .ignoresSafeArea()
            }
        }
    }

    private func playSymbalIfNeededOnPoseB() {
#if canImport(UIKit)
        guard !showPoseA else { return }
        SoundEffectPlayer.shared.playSymbalCue()
#endif
    }

    private func startSymbalBgm() {
#if canImport(UIKit)
        SymbalBgmPlayer.shared.play()
#endif
    }

    private func stopSymbalBgm() {
#if canImport(UIKit)
        SymbalBgmPlayer.shared.stop()
#endif
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
