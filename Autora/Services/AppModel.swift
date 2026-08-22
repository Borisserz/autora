import Foundation
import Observation
import SwiftUI

@Observable
final class AppModel {
    var listings: [Listing] = []
    var chats: [ChatThread] = [] {
        didSet { persistIfReady { persistChats() } }
    }
    var chatDrafts: [String: String] = [:] {
        didSet { persistIfReady { persistChatDrafts() } }
    }
    var savedSearches: [SavedSearch] = [] {
        didSet { persistIfReady { persistSavedSearches() } }
    }
    var fx = FXRate(usdBYN: 2.99)
    var criteria = SearchCriteria() {
        didSet { persistIfReady { persistCriteria() } }
    }
    var sort: ListingSort = .newest {
        didSet { persistIfReady { persistSort() } }
    }
    var garageTab: GarageTab = .favorites {
        didSet { persistIfReady { defaults.set(garageTab.rawValue, forKey: Keys.garageTab) } }
    }
    var sellerDeskTab: SellerDeskTab = .all {
        didSet { persistIfReady { defaults.set(sellerDeskTab.rawValue, forKey: Keys.sellerDeskTab) } }
    }
    var inboxTab: InboxTab = .all {
        didSet { persistIfReady { defaults.set(inboxTab.rawValue, forKey: Keys.inboxTab) } }
    }
    var deletedChatIDs: Set<String> = [] {
        didSet { persistIfReady { defaults.set(Array(deletedChatIDs), forKey: Keys.deletedChats) } }
    }
    var editingListingID: String? {
        didSet { persistIfReady { persistEditingID() } }
    }
    var showUSD = true {
        didSet { persistIfReady { defaults.set(showUSD, forKey: Keys.showUSD) } }
    }
    var pendingOpenWizard = false
    var favoriteIDs: Set<String> = [] {
        didSet { persistIfReady { persistFavorites() } }
    }
    var deferredPurchases: [DeferredPurchase] = [] {
        didSet { persistIfReady { persistDeferred() } }
    }
    var deferredIDs: Set<String> {
        Set(deferredPurchases.map(\.id))
    }
    var ownedGarage: [OwnedGarageCar] = [] {
        didSet { persistIfReady { persistOwnedGarage() } }
    }
    var toastMessage: String?
    var toastSymbol = "checkmark"
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
    private var seedChats: [ChatThread] = []
    private var seedListings: [Listing] = []
    private var remoteListings: [Listing] = []
    private var seedUSDBYN: Double = 2.99

    var filtered: [Listing] {
        let timestamp = now()
        let base = ListingFilter.apply(criteria, to: listings, usdBYN: fx.usdBYN)
            .filter { !blockedSellerIDs.contains($0.sellerId) }
            .filter { !BumpPolicy.isExpired(bumpedAt: $0.bumpedAt, now: timestamp, isDemo: $0.isDemo) }
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
        seedUSDBYN = loaded.fx.usdBYN
        seedChats = loaded.chats
        seedListings = loaded.listings
        let cachedFX = defaults.object(forKey: Keys.fxCache) as? Double
        fx = NBRBRate.pick(fetched: nil, cached: cachedFX, seed: seedUSDBYN)
        favoriteIDs = Set(defaults.stringArray(forKey: Keys.favorites) ?? [])
        ownedGarage = loadOwnedGarage()
        recentlyViewedIDs = defaults.stringArray(forKey: Keys.recent) ?? []
        blockedSellerIDs = Set(defaults.stringArray(forKey: Keys.blocked) ?? [])
        savedSearches = mergeSearches(seed: loaded.savedSearches, stored: loadPersistedSearches())
        if let data = defaults.data(forKey: Keys.reports),
           let decoded = try? JSONDecoder().decode([ListingReport].self, from: data) {
            reports = decoded
        }
        if defaults.object(forKey: Keys.showUSD) == nil {
            showUSD = true
        } else {
            showUSD = defaults.bool(forKey: Keys.showUSD)
        }
        compareIDs = Array((defaults.stringArray(forKey: Keys.compare) ?? []).prefix(CompareSet.limit))
        session = loadSession()
        myListings = loadMyListings()
        listings = CatalogMerge.listings(seed: loaded.listings, mine: myListings, remote: remoteListings)
        deferredPurchases = loadDeferred(from: listings)
        deletedChatIDs = Set(defaults.stringArray(forKey: Keys.deletedChats) ?? [])
        chats = InboxDesk.chats(
            seed: loaded.chats,
            stored: loadChats(),
            deleted: deletedChatIDs,
            isSignedIn: session.isSignedIn
        )
        listingDraft = loadDraft()
        criteria = loadCriteria()
        sort = loadSort()
        garageTab = GarageTab(rawValue: defaults.integer(forKey: Keys.garageTab)) ?? .favorites
        sellerDeskTab = SellerDeskTab(rawValue: defaults.integer(forKey: Keys.sellerDeskTab)) ?? .all
        inboxTab = InboxTab(rawValue: defaults.integer(forKey: Keys.inboxTab)) ?? .all
        editingListingID = defaults.string(forKey: Keys.editingListing)
        chatDrafts = loadChatDrafts()
        isHydrating = false
        if let profile = RemoteChatStore.currentProfile() {
            session = .signedIn(profile)
            Task { await pullRemote(uid: profile.id) }
        }
        startRemoteListeners()
    }

    func startRemoteListeners() {
        RemoteChatStore.listenListings { [weak self] remote in
            Task { @MainActor in
                guard let self else { return }
                self.remoteListings = remote
                self.listings = CatalogMerge.listings(seed: self.seedListings, mine: self.myListings, remote: remote)
            }
        }
        if let uid = session.profile?.id {
            RemoteChatStore.listenInbox(uid: uid) { [weak self] inbox in
                Task { @MainActor in
                    guard let self else { return }
                    self.chats = RemoteInbox.merge(local: self.chats, remote: inbox, viewerId: uid)
                }
            }
        }
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

    func refreshFX() async {
        guard !UITestLaunch.isActive else { return }
        let cached = defaults.object(forKey: Keys.fxCache) as? Double
        do {
            let fetched = try await NBRBClient.fetchUSDBYN()
            defaults.set(fetched, forKey: Keys.fxCache)
            fx = NBRBRate.pick(fetched: fetched, cached: cached, seed: seedUSDBYN)
        } catch {
            fx = NBRBRate.pick(fetched: nil, cached: cached, seed: seedUSDBYN)
        }
    }

    func applyCatalog(_ file: SeedFile) {
        seedListings = file.listings
        listings = CatalogMerge.listings(seed: file.listings, mine: myListings, remote: remoteListings)
        seedChats = file.chats
        seedUSDBYN = file.fx.usdBYN
        chats = InboxDesk.chats(
            seed: file.chats,
            stored: chats,
            deleted: deletedChatIDs,
            isSignedIn: session.isSignedIn
        )
        if fx.source == .seed {
            fx = file.fx
        }
        savedSearches = mergeSearches(seed: file.savedSearches, stored: loadPersistedSearches())
        loadError = nil
        isOffline = false
    }

    func listing(id: String) -> Listing? {
        listings.first { $0.id == id } ?? myListings.first { $0.id == id }
    }

    func garageCount(for tab: GarageTab) -> Int {
        GarageOverview.count(
            tab,
            favoriteIDs: favoriteIDs,
            listings: listings,
            deferred: deferredPurchases,
            fleet: ownedGarage.count,
            searches: savedSearches.count
        )
    }

    var garageHeadline: String {
        GarageOverview.headline(
            drops: DeferredWatch.dropped(
                in: listings,
                purchases: deferredPurchases,
                usdBYN: fx.usdBYN
            ).count,
            favorites: garageCount(for: .favorites),
            fleet: ownedGarage.count
        )
    }

    var sellerHeadline: String {
        let stats = SellerStats.from(myListings)
        let now = now()
        return SellerDesk.headline(
            stats: stats,
            bumpReady: SellerDesk.bumpReady(in: myListings, now: now).count,
            active: SellerDesk.count(.active, in: myListings)
        )
    }

    var inboxHeadline: String {
        InboxDesk.headline(unread: unreadCount, threads: chats.count)
    }

    var profileSnapshot: ProfileSnapshot {
        ProfileDesk.snapshot(
            session: session,
            listings: myListings.count,
            garage: GarageOverview.carTotal(
                favorites: favoriteIDs.count,
                deferred: deferredPurchases.count,
                fleet: ownedGarage.count
            ),
            unread: unreadCount,
            compare: compareIDs.count,
            viewed: recentlyViewedIDs.count,
            blocked: blockedSellerIDs.count,
            reports: reports.count,
            usdBYN: fx.usdBYN
        )
    }

    var profileHeadline: String {
        ProfileDesk.headline(profileSnapshot)
    }

    func toggleFavorite(_ id: String) {
        if favoriteIDs.contains(id) {
            favoriteIDs.remove(id)
            mutateListing(id) { $0.favoritesCount = max(0, $0.favoritesCount - 1) }
            flash("Авто удалено из Избранного", symbol: "heart")
        } else {
            favoriteIDs.insert(id)
            mutateListing(id) { $0.favoritesCount += 1 }
            flash("Автомобиль добавлен в Избранное", symbol: "heart.fill")
        }
    }

    func isDeferred(_ id: String) -> Bool {
        deferredPurchases.contains { $0.id == id }
    }

    func deferredPurchase(id: String) -> DeferredPurchase? {
        deferredPurchases.first { $0.id == id }
    }

    func toggleDeferred(_ id: String) {
        if let idx = deferredPurchases.firstIndex(where: { $0.id == id }) {
            deferredPurchases.remove(at: idx)
            flash("Удалено из отложенных покупок", symbol: "bookmark")
        } else if let listing = listing(id: id) {
            deferredPurchases.insert(DeferredPurchase.capturing(listing, now: now(), usdBYN: fx.usdBYN), at: 0)
            flash("«\(listing.title)» добавлен в Отложенные покупки", symbol: "bookmark.fill")
        }
    }

    func setDeferredNote(_ id: String, _ note: String) {
        guard let idx = deferredPurchases.firstIndex(where: { $0.id == id }) else { return }
        deferredPurchases[idx].userNote = note
    }

    func setDeferredTargetUSD(_ id: String, _ usd: Int) {
        guard let idx = deferredPurchases.firstIndex(where: { $0.id == id }) else { return }
        deferredPurchases[idx].targetPriceUSD = max(0, usd)
    }

    func flash(_ message: String, symbol: String = "checkmark") {
        toastSymbol = symbol
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
        session = .signedIn(UserProfile(id: profile.id, name: name, phone: BelarusPhone.e164(phone), isOwner: profile.isOwner))
        for listing in myListings {
            mutateListing(listing.id) {
                $0.sellerName = name
                $0.sellerPhone = BelarusPhone.e164(phone)
            }
        }
        flash("Профиль сохранён", symbol: "person.fill")
    }

    func clearRecentlyViewed() {
        recentlyViewedIDs = []
        defaults.set(recentlyViewedIDs, forKey: Keys.recent)
    }

    func toggleCompare(_ id: String) {
        compareIDs = CompareSet.toggling(id, in: compareIDs)
    }

    func setCompare(_ id: String, slot: Int) {
        compareIDs = CompareSet.setting(id, at: slot, in: compareIDs)
    }

    func applyValuationToDraft(make: String, year: Int, mileageKm: Int, priceBYN: Int) {
        listingDraft.make = make
        listingDraft.year = year
        listingDraft.mileageKm = mileageKm
        listingDraft.priceBYN = priceBYN
        pendingOpenWizard = true
        selectedTab = .listings
    }

    func addOwned(_ car: OwnedGarageCar) {
        guard !ownedGarage.contains(where: { $0.id == car.id }) else { return }
        ownedGarage.append(car)
        flash("Авто добавлено в автопарк", symbol: "car.fill")
    }

    func removeOwned(_ id: String) {
        ownedGarage.removeAll { $0.id == id }
        flash("Авто удалено из автопарка", symbol: "car")
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

    func signInRemote(email: String, password: String) async throws {
        let profile = try await RemoteChatStore.signIn(email: email, password: password)
        session = .signedIn(profile)
        chats = InboxDesk.chats(
            seed: seedChats,
            stored: chats,
            deleted: deletedChatIDs,
            isSignedIn: true
        )
        await pullRemote(uid: profile.id)
        startRemoteListeners()
    }

    func registerRemote(email: String, password: String, name: String) async throws {
        let profile = try await RemoteChatStore.register(email: email, password: password, name: name)
        session = .signedIn(profile)
        await pullRemote(uid: profile.id)
        startRemoteListeners()
    }

    func pullRemote(uid: String) async {
        let remote = await RemoteChatStore.fetchListings()
        let inbox = await RemoteChatStore.fetchInbox(uid: uid)
        remoteListings = remote
        listings = CatalogMerge.listings(seed: seedListings, mine: myListings, remote: remoteListings)
        chats = RemoteInbox.merge(local: chats, remote: inbox, viewerId: uid)
    }

    func refreshRemoteThread(_ id: String) async {
        guard let uid = session.profile?.id else { return }
        let messages = await RemoteChatStore.fetchMessages(threadId: id, uid: uid)
        guard !messages.isEmpty, let idx = chats.firstIndex(where: { $0.id == id }) else { return }
        chats[idx].messages = messages
        if let last = messages.last {
            chats[idx].lastText = last.text
            chats[idx].lastAt = last.at
        }
    }

    func signInDemo() {
        session = .signedIn(
            UserProfile(id: "me-local", name: "Вы", phone: "+375291000000", isOwner: true)
        )
        chats = InboxDesk.chats(
            seed: seedChats,
            stored: chats,
            deleted: deletedChatIDs,
            isSignedIn: true
        )
    }

    func signOut() {
        RemoteChatStore.signOutRemote()
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

    func bumpAllReady(at: Date = .now) {
        let ids = SellerDesk.bumpReady(in: myListings, now: at.timeIntervalSince1970).map(\.id)
        for id in ids {
            bump(id, at: at)
        }
        if !ids.isEmpty {
            flash("Поднято объявлений: \(ids.count)", symbol: "arrow.up")
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
        listings = CatalogMerge.listings(seed: seedListings, mine: myListings, remote: remoteListings)
        Task { await RemoteChatStore.pushListing(copy) }
    }

    func clearListingDraft() {
        listingDraft = ListingDraft()
        editingListingID = nil
    }

    func prepareNewListing() {
        guard editingListingID != nil else { return }
        editingListingID = nil
        listingDraft = ListingDraft()
    }

    func beginEdit(_ id: String) {
        guard let listing = listing(id: id) else { return }
        listingDraft = ListingDraft.from(listing)
        editingListingID = id
        pendingOpenWizard = true
        selectedTab = .listings
    }

    func duplicateAsDraft(_ id: String) {
        guard let listing = listing(id: id) else { return }
        listingDraft = ListingDraft.from(listing)
        editingListingID = nil
        pendingOpenWizard = true
        selectedTab = .listings
    }

    func saveEditedListing() throws {
        guard case .signedIn(let profile) = session else { throw AppError.needAuth }
        guard !profile.phone.isEmpty else { throw AppError.needPhone }
        guard let id = editingListingID, let existing = listing(id: id) else { return }
        let updated = try listingDraft.apply(onto: existing, seller: profile, now: now())
        mutateListing(id) { $0 = updated }
        clearListingDraft()
    }

    func deferredOffer(for listingID: String) -> (label: String, text: String)? {
        guard let purchase = deferredPurchase(id: listingID),
              let listing = listing(id: listingID) else { return nil }
        let text = ChatDraft.priceOffer(
            make: listing.make,
            model: listing.model,
            targetUSD: purchase.targetPriceUSD
        )
        return ("Предложить $\(purchase.targetPriceUSD)", text)
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

    func unblock(sellerID: String) {
        blockedSellerIDs.remove(sellerID)
    }

    var blockedSellers: [BlockedSeller] {
        blockedSellerIDs.sorted().map { id in
            let name = listings.first { $0.sellerId == id }?.sellerName ?? "Продавец"
            return BlockedSeller(id: id, name: name)
        }
    }

    func deleteListing(_ id: String) {
        guard myListings.contains(where: { $0.id == id }) else { return }
        myListings.removeAll { $0.id == id }
        listings.removeAll { $0.id == id }
        favoriteIDs.remove(id)
        compareIDs.removeAll { $0 == id }
        deferredPurchases.removeAll { $0.id == id }
        flash("Объявление удалено", symbol: "trash")
    }

    func sendMessage(threadID: String, text: String) {
        guard let body = ChatDraft.normalized(text) else { return }
        guard let idx = chats.firstIndex(where: { $0.id == threadID }) else { return }
        let senderId = session.profile?.id ?? ""
        let msg = ChatMessage(id: UUID().uuidString, fromMe: true, text: body, at: now(), senderId: senderId)
        chats[idx].messages.append(msg)
        chats[idx].lastText = body
        chats[idx].lastAt = msg.at
        setChatDraft("", for: threadID)
        let thread = chats[idx]
        Task { await RemoteChatStore.pushMessage(thread: thread, message: msg) }
    }

    func chatDraft(for id: String) -> String {
        chatDrafts[id] ?? ""
    }

    func setChatDraft(_ text: String, for id: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            chatDrafts[id] = nil
        } else {
            chatDrafts[id] = text
        }
    }

    func markThreadRead(_ id: String) {
        guard let idx = chats.firstIndex(where: { $0.id == id }) else { return }
        chats[idx].unread = 0
    }

    func markAllRead() {
        var copy = chats
        for i in copy.indices { copy[i].unread = 0 }
        chats = copy
    }

    func deleteThread(_ id: String) {
        chats.removeAll { $0.id == id }
        deletedChatIDs.insert(id)
        flash("Переписка удалена", symbol: "envelope")
    }

    func startChat(for listing: Listing) throws -> String {
        guard case .signedIn(let profile) = session else { throw ChatStartError.needAuth }
        guard listing.sellerId != profile.id else { throw ChatStartError.cannotMessageSelf }
        if ChatStartError.isGhostSeller(listing.sellerId) { throw ChatStartError.ghostSeller }
        let threadId = ChatThreadID.make(listingId: listing.id, uidA: profile.id, uidB: listing.sellerId)
        if let existing = chats.first(where: { $0.id == threadId }) {
            return existing.id
        }
        if let existing = chats.first(where: {
            $0.listingId == listing.id && $0.participantIds.contains(profile.id)
        }) {
            return existing.id
        }
        let thread = ChatThread(
            id: threadId,
            listingId: listing.id,
            listingTitle: listing.title,
            peerName: listing.sellerName,
            unread: 0,
            messages: [],
            participantIds: [profile.id, listing.sellerId]
        )
        chats.insert(thread, at: 0)
        Task { await RemoteChatStore.pushThread(thread) }
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
        if let data = try? JSONEncoder().encode(deferredPurchases) {
            defaults.set(data, forKey: Keys.deferredPurchases)
        }
    }

    private func loadDeferred(from listings: [Listing]) -> [DeferredPurchase] {
        if let data = defaults.data(forKey: Keys.deferredPurchases),
           let decoded = try? JSONDecoder().decode([DeferredPurchase].self, from: data) {
            return decoded
        }
        return (defaults.stringArray(forKey: Keys.deferred) ?? []).map { id in
            let price = listings.first { $0.id == id }?.priceBYN ?? 0
            let usd = Int(PriceConverter.usd(fromBYN: price, rate: fx.usdBYN).rounded())
            return DeferredPurchase(
                id: id,
                originalPriceBYN: price,
                targetPriceUSD: Int((Double(usd) * 0.95).rounded()),
                userNote: "",
                savedAt: now()
            )
        }
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

    private func persistChatDrafts() {
        if let data = try? JSONEncoder().encode(chatDrafts) {
            defaults.set(data, forKey: Keys.chatDrafts)
        }
    }

    private func persistDraft() {
        if let data = try? JSONEncoder().encode(listingDraft) {
            defaults.set(data, forKey: Keys.draft)
        }
    }

    private func persistCriteria() {
        if let data = try? JSONEncoder().encode(criteria) {
            defaults.set(data, forKey: Keys.criteria)
        }
    }

    private func persistSort() {
        defaults.set(sort.rawValue, forKey: Keys.sort)
    }

    private func persistEditingID() {
        if let editingListingID {
            defaults.set(editingListingID, forKey: Keys.editingListing)
        } else {
            defaults.removeObject(forKey: Keys.editingListing)
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

    private func loadChatDrafts() -> [String: String] {
        guard let data = defaults.data(forKey: Keys.chatDrafts),
              let decoded = try? JSONDecoder().decode([String: String].self, from: data) else {
            return [:]
        }
        return decoded
    }

    private func loadOwnedGarage() -> [OwnedGarageCar] {
        if let data = defaults.data(forKey: Keys.ownedGarage),
           let decoded = try? JSONDecoder().decode([OwnedGarageCar].self, from: data) {
            return decoded
        }
        return []
    }

    private func loadDraft() -> ListingDraft {
        guard let data = defaults.data(forKey: Keys.draft),
              let draft = try? JSONDecoder().decode(ListingDraft.self, from: data) else {
            return ListingDraft()
        }
        return draft
    }

    private func loadCriteria() -> SearchCriteria {
        guard let data = defaults.data(forKey: Keys.criteria),
              let decoded = try? JSONDecoder().decode(SearchCriteria.self, from: data) else {
            return SearchCriteria()
        }
        return decoded
    }

    private func loadSort() -> ListingSort {
        guard let raw = defaults.string(forKey: Keys.sort),
              let sort = ListingSort(rawValue: raw) else {
            return .newest
        }
        return sort
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
        static let deferredPurchases = "autora.deferredPurchases"
        static let ownedGarage = "autora.ownedGarage"
        static let recent = "autora.recent"
        static let blocked = "autora.blocked"
        static let searches = "autora.savedSearches"
        static let reports = "autora.reports"
        static let session = "autora.session"
        static let myListings = "autora.myListings"
        static let chats = "autora.chats"
        static let chatDrafts = "autora.chatDrafts"
        static let showUSD = "autora.showUSD"
        static let compare = "autora.compare"
        static let draft = "autora.draft"
        static let criteria = "autora.criteria"
        static let sort = "autora.sort"
        static let garageTab = "autora.garageTab"
        static let sellerDeskTab = "autora.sellerDeskTab"
        static let inboxTab = "autora.inboxTab"
        static let deletedChats = "autora.deletedChats"
        static let editingListing = "autora.editingListing"
        static let fxCache = "autora.fxCache"
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

struct BlockedSeller: Identifiable, Equatable, Sendable {
    var id: String
    var name: String
}

enum AppError: LocalizedError, Equatable {
    case needAuth, needPhone, needPhoto, needMake, needPrice, needVIN
    var errorDescription: String? {
        switch self {
        case .needAuth: "Войдите, чтобы подать объявление"
        case .needPhone: "Укажите телефон в профиле перед публикацией"
        case .needPhoto: "Добавьте хотя бы одно фото"
        case .needMake: "Укажите марку и модель"
        case .needPrice: "Укажите цену в рублях"
        case .needVIN: "VIN — 17 символов или оставьте пустым"
        }
    }
}
