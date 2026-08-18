import Foundation
import Observation
import SwiftUI

@Observable
final class AppModel {
    var listings: [Listing] = []
    var chats: [ChatThread] = [] {
        didSet { persistIfReady { persistChats() } }
    }
    var savedSearches: [SavedSearch] = [] {
        didSet { persistIfReady { persistSavedSearches() } }
    }
    var fx = FXRate(usdBYN: 2.99)
    var criteria = SearchCriteria()
    var sort: ListingSort = .newest
    var showUSD = false {
        didSet { persistIfReady { defaults.set(showUSD, forKey: Keys.showUSD) } }
    }
    var favoriteIDs: Set<String> = [] {
        didSet { persistIfReady { persistFavorites() } }
    }
    var deferredIDs: Set<String> = [] {
        didSet { persistIfReady { persistDeferred() } }
    }
    var ownedGarage: [OwnedGarageCar] = [] {
        didSet { persistIfReady { persistOwnedGarage() } }
    }
    var toastMessage: String?
    var recentlyViewedIDs: [String] = []
    var compareIDs: [String] = [] {
        didSet { persistIfReady { defaults.set(compareIDs, forKey: Keys.compare) } }
    }
    var session: UserSession = .guest {
        didSet { persistIfReady { persistSession() } }
    }
    var myListings: [Listing] = [] {
        didSet { persistIfReady { persistMyListings() } }
    }
    var listingDraft = ListingDraft() {
        didSet { persistIfReady { persistDraft() } }
    }
    var blockedSellerIDs: Set<String> = [] {
        didSet { persistIfReady { persistBlocked() } }
    }
    var reports: [ListingReport] = []
    var isOffline = false
    var loadError: String?
    var selectedTab: AutoraTab = .search
    var pendingListingID: String?
    let defaults: UserDefaults
    var now: () -> TimeInterval
    private var isHydrating = true

    var filtered: [Listing] {
        let timestamp = now()
        let base = ListingFilter.apply(criteria, to: listings, usdBYN: fx.usdBYN)
            .filter { !blockedSellerIDs.contains($0.sellerId) }
            .filter { !BumpPolicy.isExpired(bumpedAt: $0.bumpedAt, now: timestamp) }
        return sort.apply(base)
    }

    var brandCounts: [BrandCount] { BrandCounter.counts(in: listings) }

    var unreadCount: Int { chats.reduce(0) { $0 + $1.unread } }

    init(
        seed: SeedFile? = nil,
        defaults: UserDefaults = .standard,
        now: @escaping () -> TimeInterval = { Date().timeIntervalSince1970 },
        seedMissing: Bool = false
    ) {
        self.defaults = defaults
        self.now = now
        if seedMissing {
            loadError = "Не удалось загрузить каталог. Проверьте сеть и повторите."
            isOffline = true
        }
        let loaded: SeedFile
        if let seed {
            loaded = seed
        } else {
            switch SeedLoader.loadResult() {
            case .loaded(let file):
                loaded = file
            case .missing, .invalid:
                loaded = SeedFile(listings: [], chats: [], savedSearches: [], fx: FXRate(usdBYN: 2.99))
                loadError = "Не удалось загрузить каталог. Проверьте сеть и повторите."
                isOffline = true
            }
        }
        fx = loaded.fx
        favoriteIDs = Set(defaults.stringArray(forKey: Keys.favorites) ?? [])
        deferredIDs = Set(defaults.stringArray(forKey: Keys.deferred) ?? [])
        ownedGarage = loadOwnedGarage()
        recentlyViewedIDs = defaults.stringArray(forKey: Keys.recent) ?? []
        blockedSellerIDs = Set(defaults.stringArray(forKey: Keys.blocked) ?? [])
        savedSearches = mergeSearches(seed: loaded.savedSearches, stored: loadPersistedSearches())
        if let data = defaults.data(forKey: Keys.reports),
           let decoded = try? JSONDecoder().decode([ListingReport].self, from: data) {
            reports = decoded
        }
        showUSD = defaults.bool(forKey: Keys.showUSD)
        compareIDs = defaults.stringArray(forKey: Keys.compare) ?? []
        session = loadSession()
        myListings = loadMyListings()
        listings = CatalogMerge.listings(seed: loaded.listings, mine: myListings)
        let storedChats = loadChats()
        chats = storedChats.isEmpty
            ? loaded.chats
            : CatalogMerge.chats(seed: loaded.chats, live: storedChats)
        listingDraft = loadDraft()
        isHydrating = false
    }

    func retryLoad() {
        switch SeedLoader.loadResult() {
        case .loaded(let file):
            applyCatalog(file)
        case .missing, .invalid:
            loadError = "Не удалось загрузить каталог. Проверьте сеть и повторите."
            isOffline = true
        }
    }

    func applyCatalog(_ file: SeedFile) {
        listings = CatalogMerge.listings(seed: file.listings, mine: myListings)
        chats = CatalogMerge.chats(seed: file.chats, live: chats)
        fx = file.fx
        savedSearches = mergeSearches(seed: file.savedSearches, stored: loadPersistedSearches())
        loadError = nil
        isOffline = false
    }

    func listing(id: String) -> Listing? {
        listings.first { $0.id == id } ?? myListings.first { $0.id == id }
    }

    func toggleFavorite(_ id: String) {
        if favoriteIDs.contains(id) {
            favoriteIDs.remove(id)
            mutateListing(id) { $0.favoritesCount = max(0, $0.favoritesCount - 1) }
            flash("Авто удалено из Избранного")
        } else {
            favoriteIDs.insert(id)
            mutateListing(id) { $0.favoritesCount += 1 }
            flash("Автомобиль добавлен в Избранное")
        }
    }

    func isDeferred(_ id: String) -> Bool {
        deferredIDs.contains(id)
    }

    func toggleDeferred(_ id: String) {
        if deferredIDs.contains(id) {
            deferredIDs.remove(id)
            flash("Удалено из отложенных покупок")
        } else {
            deferredIDs.insert(id)
            let title = listing(id: id)?.title ?? "Авто"
            flash("«\(title)» добавлен в Отложенные покупки")
        }
    }

    func flash(_ message: String) {
        toastMessage = message
    }

    func markViewed(_ id: String) {
        recentlyViewedIDs.removeAll { $0 == id }
        recentlyViewedIDs.insert(id, at: 0)
        if recentlyViewedIDs.count > 20 { recentlyViewedIDs = Array(recentlyViewedIDs.prefix(20)) }
        defaults.set(recentlyViewedIDs, forKey: Keys.recent)
        mutateListing(id) { $0.views += 1 }
    }

    func recordPhoneReveal(listingID: String) {
        mutateListing(listingID) { $0.phoneReveals += 1 }
    }

    func setListingStatus(_ id: String, _ status: ListingStatus) {
        mutateListing(id) { $0.status = status }
    }

    func deleteSavedSearch(_ id: String) {
        savedSearches.removeAll { $0.id == id }
    }

    func clearCompare() {
        compareIDs = []
    }

    func updateProfile(name: String, phone: String) {
        guard case .signedIn(let profile) = session else { return }
        session = .signedIn(UserProfile(id: profile.id, name: name, phone: phone, isOwner: profile.isOwner))
        for listing in myListings {
            mutateListing(listing.id) {
                $0.sellerName = name
                $0.sellerPhone = phone
            }
        }
    }

    func toggleCompare(_ id: String) {
        compareIDs = CompareSet.toggling(id, in: compareIDs)
    }

    @discardableResult
    func saveCurrentSearch() -> SavedSearch {
        let search = SavedSearch.from(criteria: criteria)
        if let existing = savedSearches.first(where: { $0.isDuplicate(of: search) }) {
            return existing
        }
        savedSearches.insert(search, at: 0)
        return search
    }

    func applySavedSearch(_ search: SavedSearch) {
        search.apply(to: &criteria)
    }

    func openSavedSearch(_ search: SavedSearch) {
        applySavedSearch(search)
        selectedTab = .search
    }

    func selectMake(_ name: String) {
        criteria.make = criteria.make == name ? nil : name
        criteria.model = nil
        criteria.generation = nil
    }

    func selectModel(_ name: String) {
        criteria.model = criteria.model == name ? nil : name
        criteria.generation = nil
    }

    func selectGeneration(_ name: String) {
        criteria.generation = criteria.generation == name ? nil : name
    }

    func handleDeepLink(_ url: URL) {
        guard let id = AutoraDeepLink.listingID(from: url) else { return }
        pendingListingID = id
        selectedTab = .search
    }

    func signInDemo() {
        session = .signedIn(
            UserProfile(id: "me-local", name: "Вы", phone: "+375291000000", isOwner: true)
        )
    }

    func signOut() {
        session = .guest
    }

    func bump(_ id: String, at: Date = .now) {
        guard let idx = myListings.firstIndex(where: { $0.id == id }) else { return }
        let last = myListings[idx].bumpedAt
        guard BumpPolicy.canBump(lastBumped: last, now: at.timeIntervalSince1970) else { return }
        mutateListing(id) {
            $0.bumpedAt = at.timeIntervalSince1970
            $0.status = .active
        }
    }

    func publishDraft(_ listing: Listing) throws {
        guard case .signedIn(let profile) = session else { throw AppError.needAuth }
        guard !profile.phone.isEmpty else { throw AppError.needPhone }
        var copy = listing
        copy.sellerId = profile.id
        copy.sellerName = profile.name
        copy.sellerPhone = profile.phone
        copy.status = .active
        copy.bumpedAt = now()
        copy.createdAt = copy.bumpedAt
        myListings.insert(copy, at: 0)
        listings.insert(copy, at: 0)
    }

    func clearListingDraft() {
        listingDraft = ListingDraft()
    }

    func report(listingID: String, reason: String) {
        let item = ListingReport(
            id: UUID().uuidString,
            listingID: listingID,
            reason: reason,
            at: now()
        )
        reports.insert(item, at: 0)
        if let data = try? JSONEncoder().encode(reports) {
            defaults.set(data, forKey: Keys.reports)
        }
    }

    func block(sellerID: String) {
        blockedSellerIDs.insert(sellerID)
    }

    func sendMessage(threadID: String, text: String) {
        guard let body = ChatDraft.normalized(text) else { return }
        guard let idx = chats.firstIndex(where: { $0.id == threadID }) else { return }
        let msg = ChatMessage(id: UUID().uuidString, fromMe: true, text: body, at: now())
        chats[idx].messages.append(msg)
    }

    func markThreadRead(_ id: String) {
        guard let idx = chats.firstIndex(where: { $0.id == id }) else { return }
        chats[idx].unread = 0
    }

    func startChat(for listing: Listing) throws -> String {
        guard case .signedIn(let profile) = session else { throw ChatStartError.needAuth }
        guard listing.sellerId != profile.id else { throw ChatStartError.cannotMessageSelf }
        if let existing = chats.first(where: { $0.listingId == listing.id }) {
            return existing.id
        }
        let thread = ChatThread(
            id: "chat-\(listing.id)",
            listingId: listing.id,
            listingTitle: listing.title,
            peerName: listing.sellerName,
            unread: 0,
            messages: [],
            participantIds: [profile.id, listing.sellerId]
        )
        chats.insert(thread, at: 0)
        return thread.id
    }

    private func mutateListing(_ id: String, _ body: (inout Listing) -> Void) {
        if let i = listings.firstIndex(where: { $0.id == id }) {
            var item = listings[i]
            body(&item)
            listings[i] = item
        }
        if let i = myListings.firstIndex(where: { $0.id == id }) {
            var item = myListings[i]
            body(&item)
            myListings[i] = item
        }
    }

    private func persistIfReady(_ persist: () -> Void) {
        guard !isHydrating else { return }
        persist()
    }

    private func persistFavorites() {
        defaults.set(Array(favoriteIDs), forKey: Keys.favorites)
    }

    private func persistDeferred() {
        defaults.set(Array(deferredIDs), forKey: Keys.deferred)
    }

    private func persistOwnedGarage() {
        if let data = try? JSONEncoder().encode(ownedGarage) {
            defaults.set(data, forKey: Keys.ownedGarage)
        }
    }

    private func persistBlocked() {
        defaults.set(Array(blockedSellerIDs), forKey: Keys.blocked)
    }

    private func persistSavedSearches() {
        if let data = try? JSONEncoder().encode(savedSearches) {
            defaults.set(data, forKey: Keys.searches)
        }
    }

    private func persistSession() {
        switch session {
        case .guest:
            defaults.removeObject(forKey: Keys.session)
        case .signedIn(let profile):
            if let data = try? JSONEncoder().encode(profile) {
                defaults.set(data, forKey: Keys.session)
            }
        }
    }

    private func persistMyListings() {
        if let data = try? JSONEncoder().encode(myListings) {
            defaults.set(data, forKey: Keys.myListings)
        }
    }

    private func persistChats() {
        if let data = try? JSONEncoder().encode(chats) {
            defaults.set(data, forKey: Keys.chats)
        }
    }

    private func persistDraft() {
        if let data = try? JSONEncoder().encode(listingDraft) {
            defaults.set(data, forKey: Keys.draft)
        }
    }

    private func loadPersistedSearches() -> [SavedSearch] {
        guard let data = defaults.data(forKey: Keys.searches) else { return [] }
        return (try? JSONDecoder().decode([SavedSearch].self, from: data)) ?? []
    }

    private func loadSession() -> UserSession {
        guard let data = defaults.data(forKey: Keys.session),
              let profile = try? JSONDecoder().decode(UserProfile.self, from: data) else {
            return .guest
        }
        return .signedIn(profile)
    }

    private func loadMyListings() -> [Listing] {
        guard let data = defaults.data(forKey: Keys.myListings) else { return [] }
        return (try? JSONDecoder().decode([Listing].self, from: data)) ?? []
    }

    private func loadChats() -> [ChatThread] {
        guard let data = defaults.data(forKey: Keys.chats) else { return [] }
        return (try? JSONDecoder().decode([ChatThread].self, from: data)) ?? []
    }

    private func loadOwnedGarage() -> [OwnedGarageCar] {
        if let data = defaults.data(forKey: Keys.ownedGarage),
           let decoded = try? JSONDecoder().decode([OwnedGarageCar].self, from: data) {
            return decoded
        }
        return OwnedGarageCar.demoFleet
    }

    private func loadDraft() -> ListingDraft {
        guard let data = defaults.data(forKey: Keys.draft),
              let draft = try? JSONDecoder().decode(ListingDraft.self, from: data) else {
            return ListingDraft()
        }
        return draft
    }

    private func mergeSearches(seed: [SavedSearch], stored: [SavedSearch]) -> [SavedSearch] {
        if defaults.data(forKey: Keys.searches) != nil {
            return stored
        }
        return seed
    }

    private enum Keys {
        static let favorites = "autora.favorites"
        static let deferred = "autora.deferred"
        static let ownedGarage = "autora.ownedGarage"
        static let recent = "autora.recent"
        static let blocked = "autora.blocked"
        static let searches = "autora.savedSearches"
        static let reports = "autora.reports"
        static let session = "autora.session"
        static let myListings = "autora.myListings"
        static let chats = "autora.chats"
        static let showUSD = "autora.showUSD"
        static let compare = "autora.compare"
        static let draft = "autora.draft"
    }
}

enum UserSession: Equatable {
    case guest
    case signedIn(UserProfile)

    var isSignedIn: Bool {
        if case .signedIn = self { return true }
        return false
    }

    var profile: UserProfile? {
        if case .signedIn(let p) = self { return p }
        return nil
    }
}

struct UserProfile: Equatable, Codable, Sendable {
    var id: String
    var name: String
    var phone: String
    var isOwner: Bool
}

enum AppError: LocalizedError, Equatable {
    case needAuth, needPhone, needPhoto, needMake, needPrice
    var errorDescription: String? {
        switch self {
        case .needAuth: "Войдите, чтобы подать объявление"
        case .needPhone: "Укажите телефон в профиле перед публикацией"
        case .needPhoto: "Добавьте хотя бы одно фото"
        case .needMake: "Укажите марку и модель"
        case .needPrice: "Укажите цену в рублях"
        }
    }
}
