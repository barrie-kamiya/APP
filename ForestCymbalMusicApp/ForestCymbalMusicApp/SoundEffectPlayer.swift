#if canImport(UIKit)
import AVFoundation
import UIKit

/// 単発効果音を管理するプレイヤー
final class SoundEffectPlayer {
    static let shared = SoundEffectPlayer()

    private var symbalPlayer: AVAudioPlayer?

    private init() {}

    func playSymbalCue() {
        prepareSymbalPlayerIfNeeded()
        symbalPlayer?.stop()
        symbalPlayer?.currentTime = 0
        symbalPlayer?.play()
    }

    private func prepareSymbalPlayerIfNeeded() {
        guard symbalPlayer == nil else { return }
        guard let asset = NSDataAsset(name: "symbal_se") else {
            assertionFailure("symbal_se asset not found")
            return
        }
        do {
            symbalPlayer = try AVAudioPlayer(data: asset.data)
            symbalPlayer?.prepareToPlay()
        } catch {
            assertionFailure("Failed to load symbal_se: \(error.localizedDescription)")
        }
    }
}
#endif
