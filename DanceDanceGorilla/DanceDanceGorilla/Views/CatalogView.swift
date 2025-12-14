import SwiftUI

struct CatalogView: View {
    let progress: GameProgress
    let onClose: () -> Void

    private var milestoneData: [CatalogMilestone] {
        IllustrationID.allCases
            .filter { $0 != .none }
            .map { id in
                let isUnlocked = progress.unlockedIllustrations.contains(id)
                return CatalogMilestone(
                    title: id.displayName,
                    requirementText: requirementText(for: id),
                    isUnlocked: isUnlocked,
                    imageName: isUnlocked ? id.rawValue : IllustrationID.none.rawValue
                )
            }
    }

    var body: some View {
        GeometryReader { proxy in
            let padding = DeviceTraitHelper.primaryPadding(for: proxy.size)
            ScrollView {
                VStack(spacing: padding) {
                    HStack {
                        Spacer()
                        Button(action: onClose) {
                            Text("閉じる")
                                .font(.headline)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.9))
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        }
                    }
                    .padding(.top, padding)

                    Text("図鑑")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                        .padding(.bottom, padding / 2)

                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: padding),
                            GridItem(.flexible(), spacing: padding)
                        ],
                        spacing: padding
                    ) {
                        ForEach(milestoneData) { milestone in
                            CatalogRowView(milestone: milestone)
                        }
                    }
                }
                .padding(padding)
            }
            .background(
                LinearGradient(colors: [.black, .purple.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            )
        }
        .ignoresSafeArea()
    }

    private func requirementText(for id: IllustrationID) -> String {
        switch id {
        case .one:
            return "クリア報酬 (排出率75%)"
        case .two:
            return "クリア報酬 (排出率15%)"
        case .three:
            return "クリア報酬 (排出率3.5%)"
        case .four:
            return "クリア報酬 (排出率1.32%)"
        case .five:
            return "クリア報酬 (排出率0.18%)"
        case .six:
            return "50周達成報酬"
        case .seven:
            return "100周達成報酬"
        case .eight:
            return "150周達成報酬"
        case .nine:
            return "200周達成報酬"
        default:
            return ""
        }
    }
}

private struct CatalogMilestone: Identifiable {
    let id = UUID()
    let title: String
    let requirementText: String
    let isUnlocked: Bool
    let imageName: String
}

private struct CatalogRowView: View {
    let milestone: CatalogMilestone

    var body: some View {
        Image(milestone.imageName)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .opacity(milestone.isUnlocked ? 1 : 0.2)
    }
}

#Preview {
    CatalogView(progress: GameProgress(), onClose: {})
}
