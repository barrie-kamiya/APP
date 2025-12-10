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

/// ゲーム中のBGMを制御するプレイヤー
final class SymbalBgmPlayer {
    static let shared = SymbalBgmPlayer()

    private var bgmPlayer: AVAudioPlayer?

    private init() {}

    func play() {
        preparePlayerIfNeeded()
        guard bgmPlayer?.isPlaying != true else { return }
        bgmPlayer?.currentTime = 0
        bgmPlayer?.play()
    }

    func stop() {
        bgmPlayer?.stop()
        bgmPlayer?.currentTime = 0
    }

    private func preparePlayerIfNeeded() {
        guard bgmPlayer == nil else { return }
        guard let asset = NSDataAsset(name: "SymbalBgm") else {
            assertionFailure("SymbalBgm asset not found")
            return
        }
        do {
            bgmPlayer = try AVAudioPlayer(data: asset.data)
            bgmPlayer?.numberOfLoops = -1
            bgmPlayer?.prepareToPlay()
        } catch {
            assertionFailure("Failed to load SymbalBgm: \(error.localizedDescription)")
        }
    }
}
#endif
