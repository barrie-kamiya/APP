import SwiftUI

struct SplashView: View {
    var onTap: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.ignoresSafeArea()
                if isPadDevice {
                    Image("Splash")
                        .resizable()
                        .scaledToFit()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                } else {
                    Image("Splash")
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                        .ignoresSafeArea()
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { onTap() }
            .accessibilityLabel(Text("スプラッシュ"))
        }
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
