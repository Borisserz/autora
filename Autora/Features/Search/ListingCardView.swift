import SwiftUI

struct ListingCardView: View {
    @Environment(AppModel.self) private var model
    let listing: Listing
    var showsCompare: Bool = true
    var showsFavorite: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topLeading) {
                photo
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        if listing.isTop {
                            Text("ТОП")
                                .font(.caption.bold())
                                .foregroundStyle(AutoraTheme.ink)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AutoraTheme.badgeTop)
                        }
                        if listing.isDemo {
                            Text("Демо")
                                .font(.caption.bold())
                                .foregroundStyle(AutoraTheme.canvas)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AutoraTheme.ink.opacity(0.72))
                        }
                        if listing.hasVIN {
                            Text("VIN")
                                .font(.caption.bold())
                                .foregroundStyle(AutoraTheme.canvas)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AutoraTheme.ink.opacity(0.72))
                                .accessibilityLabel("VIN указан")
                        }
                    }
                    Spacer()
                    if showsFavorite {
                        favoriteButton
                    }
                }
                .padding(12)
                if listing.photoURLs.count > 1 {
                    Text("\(listing.photoURLs.count)")
                        .font(.caption.monospacedDigit().weight(.semibold))
                        .foregroundStyle(AutoraTheme.canvas)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AutoraTheme.ink.opacity(0.62))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .padding(12)
                        .accessibilityLabel("\(listing.photoURLs.count) фото")
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(listing.title)
                    .font(.system(.title2, design: .serif).weight(.semibold))
                    .foregroundStyle(AutoraTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(PriceConverter.formatBYN(listing.priceBYN))
                        .font(.title.monospacedDigit().weight(.semibold))
                        .foregroundStyle(AutoraTheme.price)
                    if model.showUSD {
                        Text(PriceConverter.formatUSDReference(PriceConverter.usd(fromBYN: listing.priceBYN, rate: model.fx.usdBYN)))
                            .font(.footnote.monospacedDigit())
                            .foregroundStyle(AutoraTheme.muted)
                    }
                    Spacer(minLength: 8)
                    Text(listing.city)
                        .font(.caption)
                        .foregroundStyle(AutoraTheme.muted)
                        .lineLimit(1)
                }
                Text(listing.specLine)
                    .font(.footnote)
                    .foregroundStyle(AutoraTheme.muted)
                    .lineLimit(1)
                if let badge = MarketPrice.badge(for: listing, in: model.listings) {
                    Text(MarketPrice.caption(badge))
                        .font(.caption)
                        .foregroundStyle(AutoraTheme.muted)
                }
                if showsCompare {
                    Button(model.compareIDs.contains(listing.id) ? "В сравнении" : "Сравнить") {
                        model.toggleCompare(listing.id)
                    }
                    .font(.caption)
                    .foregroundStyle(AutoraTheme.muted)
                    .buttonStyle(.plain)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var photo: some View {
        Group {
            if let url = listing.photoURLs.first {
                AutoraRemotePhoto(urlString: url, height: AutoraTheme.cardPhotoHeight, accessibilityText: "\(listing.title), фото")
            } else {
                Rectangle()
                    .fill(AutoraTheme.ink.opacity(0.08))
                    .frame(height: AutoraTheme.cardPhotoHeight)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: AutoraTheme.photoRadius, style: .continuous))
    }

    private var favoriteButton: some View {
        Button {
            withAnimation(AutoraMotion.press) {
                model.toggleFavorite(listing.id)
            }
        } label: {
            Image(systemName: model.favoriteIDs.contains(listing.id) ? "heart.fill" : "heart")
                .font(.body.weight(.semibold))
                .foregroundStyle(AutoraTheme.canvas)
                .shadow(color: AutoraTheme.ink.opacity(0.45), radius: 4, y: 1)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressableInkStyle())
        .accessibilityLabel("В избранное")
        .sensoryFeedback(.selection, trigger: model.favoriteIDs.contains(listing.id))
    }
}

struct ListingFeedRow: View {
    @Environment(AppModel.self) private var model
    let listing: Listing
    var onOpen: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: onOpen) {
                ListingCardView(listing: listing, showsCompare: false, showsFavorite: false)
            }
            .buttonStyle(PressableInkStyle())
            .accessibilityIdentifier(AutoraID.listingCard(listing.id))
            HStack(spacing: 16) {
                Button(model.compareIDs.contains(listing.id) ? "В сравнении" : "Сравнить") {
                    model.toggleCompare(listing.id)
                }
                .font(.caption)
                .foregroundStyle(AutoraTheme.muted)
                .buttonStyle(.plain)
                .accessibilityLabel(model.compareIDs.contains(listing.id) ? "Убрать из сравнения" : "Сравнить")
                .accessibilityIdentifier(AutoraID.listingCompare(listing.id))
                Spacer(minLength: 8)
                favoriteButton
            }
            .frame(minHeight: 44)
        }
    }

    private var favoriteButton: some View {
        Button {
            withAnimation(AutoraMotion.press) {
                model.toggleFavorite(listing.id)
            }
        } label: {
            Image(systemName: model.favoriteIDs.contains(listing.id) ? "heart.fill" : "heart")
                .font(.body.weight(.semibold))
                .foregroundStyle(AutoraTheme.ink)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressableInkStyle())
        .accessibilityLabel("В избранное")
        .sensoryFeedback(.selection, trigger: model.favoriteIDs.contains(listing.id))
        .accessibilityIdentifier(AutoraID.listingFavorite(listing.id))
    }
}
