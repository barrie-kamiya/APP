import SwiftUI
import UIKit

/// 背景画像を上下フィットさせつつ中央寄せで表示するビュー。
struct FittedBackgroundImage: View {
    let imageName: String

    var body: some View {
        GeometryReader { geometry in
            if let uiImage = UIImage(named: imageName) {
                let targetHeight = geometry.size.height
                let imageRatio = uiImage.size.width / uiImage.size.height
                let targetWidth = targetHeight * imageRatio

                Image(uiImage: uiImage)
                    .resizable()
                    .frame(width: targetWidth, height: targetHeight)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            } else {
                Color.clear
            }
        }
        .ignoresSafeArea()
    }
}
