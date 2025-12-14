import SwiftUI

struct AspectFitBackground: View {
    let imageName: String

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: proxy.size.width, height: proxy.size.height)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
    }
}
