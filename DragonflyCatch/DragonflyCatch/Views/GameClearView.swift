import SwiftUI

struct WeightedBackgroundPicker {
    struct Entry {
        let name: String
        let weight: Double
    }

    var entries: [Entry]

    func pick() -> String {
        guard let firstName = entries.first?.name else {
            return "Clear_01"
        }
        let totalWeight = entries.reduce(0) { $0 + max($1.weight, 0) }
        guard totalWeight > 0 else { return firstName }

        let randomPoint = Double.random(in: 0..<totalWeight)
        var cumulative: Double = 0
        for entry in entries {
            cumulative += max(entry.weight, 0)
            if randomPoint < cumulative {
                return entry.name
            }
        }
        return firstName
    }

    static let `default` = WeightedBackgroundPicker(entries: [
        Entry(name: "Clear_01", weight: 0.75),
        Entry(name: "Clear_02", weight: 0.15),
        Entry(name: "Clear_03", weight: 0.035),
        Entry(name: "Clear_04", weight: 0.0132),
        Entry(name: "Clear_05", weight: 0.0018)
    ])
}

struct GameClearView: View {
    var backgroundName: String
    var onFinish: () -> Void

    private let messageLayout = ResponsiveFrame(
        phone: RelativeFrame(xPercent: 0.5, yPercent: 0.35, widthPercent: 0.85, heightPercent: 0.2),
        pad: RelativeFrame(xPercent: 0.5, yPercent: 0.38, widthPercent: 0.6, heightPercent: 0.2)
    )

    private let buttonLayout = ResponsiveFrame(
        phone: RelativeFrame(xPercent: 0.5, yPercent: 0.95, widthPercent: 0.5, heightPercent: 0.1),
        pad: RelativeFrame(xPercent: 0.5, yPercent: 0.9, widthPercent: 0.35, heightPercent: 0.09)
    )

    init(backgroundName: String,
         onFinish: @escaping () -> Void) {
        self.backgroundName = backgroundName
        self.onFinish = onFinish
    }

    var body: some View {
        GeometryReader { geometry in
            let device = LayoutDevice.resolve(for: geometry.size)

            ZStack {
                FittedBackgroundImage(imageName: backgroundName)

                let buttonRect = buttonLayout.rect(for: device, in: geometry.size)
                Button {
                    onFinish()
                } label: {
                    Image("OK")
                        .resizable()
                        .scaledToFit()
                        .frame(width: buttonRect.width, height: buttonRect.height)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .position(x: buttonRect.midX, y: buttonRect.midY)
            }
        }
    }
}
