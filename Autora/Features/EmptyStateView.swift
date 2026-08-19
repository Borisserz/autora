import SwiftUI

enum EmptyIllustration: String {
    case search, favorites, listings, messages

    var imageName: String {
        switch self {
        case .search: "EmptySearch"
        case .favorites: "EmptyFavorites"
        case .listings: "EmptyListings"
        case .messages: "EmptyMessages"
        }
    }
}

struct EmptyStateView: View {
    var title: String
    var text: String
    var illustration: EmptyIllustration?
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer()
            if let illustration {
                Image(illustration.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 280)
                    .clipShape(RoundedRectangle(cornerRadius: AutoraTheme.specRadius, style: .continuous))
                    .accessibilityHidden(true)
            }
            Text(title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(AutoraTheme.ink)
            Text(text)
                .font(.body)
                .foregroundStyle(AutoraTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.body.weight(.bold))
                    .foregroundStyle(AutoraTheme.canvas)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(AutoraTheme.ink, in: RoundedRectangle(cornerRadius: AutoraTheme.specRadius, style: .continuous))
                    .buttonStyle(PressableInkStyle())
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
    }
}
