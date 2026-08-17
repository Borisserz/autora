import SwiftUI

struct FavoritesView: View {
    @Environment(AppModel.self) private var model
    @State private var tab = 0
    @State private var path = NavigationPath()
    @Namespace private var catalog

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                Picker("", selection: $tab) {
                    Text("Закладки").tag(0)
                    Text("Поиски").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                if tab == 0 {
                    bookmarks
                } else {
                    searches
                }
            }
            .paperCanvas()
            .navigationTitle("Избранное")
            .navigationDestination(for: String.self) { id in
                if let listing = model.listing(id: id) {
                    ListingDetailView(listing: listing)
                        .navigationTransition(.zoom(sourceID: id, in: catalog))
                }
            }
        }
    }

    @ViewBuilder
    private var bookmarks: some View {
        let items = model.listings.filter { model.favoriteIDs.contains($0.id) }
        if items.isEmpty {
            EmptyStateView(
                title: "Пока пусто",
                text: "Закладка на карточке сохраняет объявление. Входить не обязательно.",
                illustration: .favorites,
                actionTitle: nil
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(items) { listing in
                        ListingFeedRow(listing: listing) {
                            path.append(listing.id)
                        }
                        .matchedTransitionSource(id: listing.id, in: catalog)
                    }
                }
                .padding(20)
            }
        }
    }

    @ViewBuilder
    private var searches: some View {
        if model.savedSearches.isEmpty {
            EmptyStateView(
                title: "Нет сохранённых поисков",
                text: "Сохраните фильтр с хаба — он останется на этом устройстве. Уведомления появятся позже.",
                illustration: .search,
                actionTitle: nil
            )
        } else {
            List {
                ForEach(model.savedSearches) { search in
                    Button {
                        model.openSavedSearch(search)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(search.title)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(AutoraTheme.ink)
                            Text("Откроется на вкладке Поиск")
                                .font(.footnote)
                                .foregroundStyle(AutoraTheme.muted)
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparatorTint(AutoraTheme.hairline)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button("Удалить", role: .destructive) {
                            model.deleteSavedSearch(search.id)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }
}
