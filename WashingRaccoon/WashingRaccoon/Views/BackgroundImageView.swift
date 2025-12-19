import SwiftUI

struct BackgroundImageView: View {
    let name: String
    let isPadLayout: Bool

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            if isPadLayout {
                Image(name)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size.width, height: size.height, alignment: .center)
            } else {
                Image(name)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height, alignment: .center)
                    .clipped()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
}
