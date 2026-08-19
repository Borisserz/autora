import SwiftUI

struct ListingCardView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openURL) private var openURL
    let listing: Listing
    var showsCompare: Bool = true
    var showsFavorite: Bool = true
    var showsGarage: Bool = true
    var onOpen: (() -> Void)?
    var onOpenVIN: (() -> Void)?
    var onOpenCompare: (() -> Void)?

    private var price: PriceDisplay.Pair {
        PriceDisplay.pair(byn: listing.priceBYN, rate: model.fx.usdBYN, showUSD: model.showUSD)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            photo
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text(price.primary)
                        .font(.title.weight(.semibold))
                        .foregroundStyle(AutoraTheme.ink)
                        .monospacedDigit()
                    Text(price.secondary)
                        .font(.caption)
                        .foregroundStyle(AutoraTheme.muted)
                    Spacer(minLength: 8)
                    if let percent = MarketDeal.discountPercent(for: listing, in: model.listings) {
                        Text("−\(percent)% ниже рынка")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(AutoraTheme.europeGreen)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AutoraTheme.emerald.opacity(0.18), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    } else if let badge = MarketPrice.badge(for: listing, in: model.listings), badge == "ниже рынка" {
                        Text("ниже рынка")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(AutoraTheme.europeGreen)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AutoraTheme.emerald.opacity(0.18), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
                Text(listing.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AutoraTheme.ink)
                    .lineLimit(1)
                specGrid
                if showsCompare {
                    actionRow
                }
            }
            .padding(16)
        }
        .background(AutoraTheme.canvas)
        .clipShape(RoundedRectangle(cornerRadius: AutoraTheme.photoRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AutoraTheme.photoRadius, style: .continuous)
                .stroke(AutoraTheme.hairline, lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var photo: some View {
        Group {
            if let onOpen {
                Button(action: onOpen) {
                    photoImage
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(AutoraID.listingCard(listing.id))
            } else {
                photoImage
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: AutoraTheme.cardPhotoHeight)
        .clipped()
        .contentShape(Rectangle())
        .overlay(alignment: .topLeading) {
            if let label = photoBadge {
                Text(label)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AutoraTheme.bargainRed, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .padding(12)
            }
        }
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 6) {
                if showsGarage {
                    garageButton
                }
                if showsFavorite {
                    favoriteButton
                }
            }
            .padding(.top, 12)
            .padding(.trailing, 12)
        }
        .overlay(alignment: .bottomLeading) {
            if ListingTrust.showsVerifiedSeal(listing) {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(AutoraTheme.emerald)
                    Text(CoolAVCopy.verified)
                }
                .font(.caption2.weight(.bold))
                .foregroundStyle(AutoraTheme.europeGreen)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(.white.opacity(0.95), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .padding(12)
            }
        }
    }

    private var photoImage: some View {
        Group {
            if let url = listing.photoURLs.first {
                AutoraRemotePhoto(urlString: url, height: AutoraTheme.cardPhotoHeight, accessibilityText: "\(listing.title), фото")
            } else {
                Rectangle()
                    .fill(AutoraTheme.surface)
                    .frame(height: AutoraTheme.cardPhotoHeight)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: AutoraTheme.cardPhotoHeight)
        .clipped()
    }

    private var photoBadge: String? {
        if let purchase = model.deferredPurchase(id: listing.id),
           let drop = DeferredWatch.caption(
            purchase: purchase,
            currentBYN: listing.priceBYN,
            usdBYN: model.fx.usdBYN
           ) {
            return drop
        }
        if ListingCategoryTab.europe.matches(listing, in: model.listings) { return "Из Европы" }
        if listing.isDemo { return "Демо" }
        return nil
    }

    private var specGrid: some View {
        let items: [(String, String)] = [
            ("calendar", "\(listing.year) г."),
            ("gauge", "\(listing.mileageKm.formatted()) км"),
            ("fuelpump", ListingSpecs.engineLine(listing)),
            ("mappin.and.ellipse", "г. \(listing.city)")
        ]
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            ForEach(items, id: \.0) { item in
                HStack(spacing: 6) {
                    Image(systemName: item.0)
                        .font(.caption)
                        .foregroundStyle(AutoraTheme.muted)
                    Text(item.1)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AutoraTheme.muted)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(10)
        .background(AutoraTheme.surface, in: RoundedRectangle(cornerRadius: AutoraTheme.specRadius, style: .continuous))
    }

    private var actionRow: some View {
        HStack(spacing: 8) {
            Button {
                if let url = PhoneLink.telURL(listing.sellerPhone) {
                    model.recordPhoneReveal(listingID: listing.id)
                    openURL(url)
                } else {
                    model.flash("Связь с продавцом: \(listing.sellerPhone)", symbol: "phone.fill")
                }
            } label: {
                Label("Позвонить", systemImage: "phone.fill")
                    .font(.caption.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .foregroundStyle(AutoraTheme.canvas)
                    .background(AutoraTheme.ink, in: RoundedRectangle(cornerRadius: AutoraTheme.specRadius, style: .continuous))
            }
            .buttonStyle(PressableInkStyle())
            Button {
                onOpenVIN?()
            } label: {
                Image(systemName: "checkmark.shield.fill")
                    .frame(width: 44, height: 44)
                    .foregroundStyle(AutoraTheme.ink)
                    .background(AutoraTheme.surface, in: RoundedRectangle(cornerRadius: AutoraTheme.specRadius, style: .continuous))
            }
            .buttonStyle(PressableInkStyle())
            .accessibilityLabel("Проверка VIN")
            Button {
                model.toggleCompare(listing.id)
                onOpenCompare?()
            } label: {
                Image(systemName: "scalemass.fill")
                    .frame(width: 44, height: 44)
                    .foregroundStyle(model.compareIDs.contains(listing.id) ? AutoraTheme.canvas : AutoraTheme.ink)
                    .background(
                        model.compareIDs.contains(listing.id) ? AutoraTheme.ink : AutoraTheme.surface,
                        in: RoundedRectangle(cornerRadius: AutoraTheme.specRadius, style: .continuous)
                    )
            }
            .buttonStyle(PressableInkStyle())
            .accessibilityLabel(model.compareIDs.contains(listing.id) ? "Убрать из сравнения" : "Сравнить")
            .accessibilityIdentifier(AutoraID.listingCompare(listing.id))
        }
    }

    private var garageButton: some View {
        let on = model.isDeferred(listing.id)
        return Button {
            model.toggleDeferred(listing.id)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: on ? "bookmark.fill" : "bookmark")
                Text(on ? "В гараже" : "В гараж")
            }
            .font(.caption2.weight(.bold))
            .foregroundStyle(on ? AutoraTheme.canvas : AutoraTheme.ink)
            .padding(.horizontal, 12)
            .frame(minHeight: 44)
            .background(on ? AutoraTheme.ink : AutoraTheme.canvas.opacity(0.95), in: RoundedRectangle(cornerRadius: 4, style: .continuous))
        }
        .buttonStyle(PressableInkStyle())
        .accessibilityLabel(on ? "Убрать из гаража" : "В гараж")
    }

    private var favoriteButton: some View {
        let on = model.favoriteIDs.contains(listing.id)
        return Button {
            withAnimation(AutoraMotion.press) {
                model.toggleFavorite(listing.id)
            }
        } label: {
            Image(systemName: on ? "heart.fill" : "heart")
                .font(.body.weight(.semibold))
                .foregroundStyle(on ? AutoraTheme.bargainRed : AutoraTheme.ink)
                .frame(width: 44, height: 44)
                .background(AutoraTheme.canvas.opacity(0.95), in: Circle())
        }
        .buttonStyle(PressableInkStyle())
        .accessibilityLabel(on ? "Удалить из избранного" : "В избранное")
        .accessibilityIdentifier(AutoraID.listingFavorite(listing.id))
        .sensoryFeedback(.selection, trigger: on)
    }
}

struct ListingFeedRow: View {
    let listing: Listing
    var onOpen: () -> Void
    var onOpenVIN: (() -> Void)?
    var onOpenCompare: (() -> Void)?

    var body: some View {
        ListingCardView(
            listing: listing,
            showsCompare: true,
            showsFavorite: true,
            showsGarage: true,
            onOpen: onOpen,
            onOpenVIN: onOpenVIN,
            onOpenCompare: onOpenCompare
        )
    }
}
