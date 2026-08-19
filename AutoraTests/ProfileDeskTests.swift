import Foundation
import Testing
@testable import Autora

struct ProfileDeskTests {
    @Test func guestHeadlineAsksToSignIn() {
        let snap = ProfileDesk.snapshot(
            session: .guest,
            listings: 0,
            garage: 2,
            unread: 1,
            compare: 0,
            viewed: 3,
            blocked: 0,
            reports: 0,
            usdBYN: 2.99
        )
        #expect(snap.isSignedIn == false)
        #expect(snap.canPost == false)
        #expect(ProfileDesk.kicker(false) == "ID")
        #expect(ProfileDesk.headline(snap) == "Гость. Войдите, чтобы продавать и писать.")
    }

    @Test func signedHeadlineNeedsPhoneWhenShort() {
        let snap = ProfileDesk.snapshot(
            session: .signedIn(UserProfile(id: "me", name: "Борис", phone: "+37529", isOwner: false)),
            listings: 1,
            garage: 4,
            unread: 0,
            compare: 0,
            viewed: 0,
            blocked: 0,
            reports: 0,
            usdBYN: 3.22
        )
        #expect(snap.isSignedIn)
        #expect(snap.name == "Борис")
        #expect(snap.canPost == false)
        #expect(ProfileDesk.kicker(true) == "CAB")
        #expect(ProfileDesk.headline(snap) == "Нужен телефон, чтобы подавать объявления.")
    }

    @Test func signedHeadlineCountsListingsGarageAndUnread() {
        let snap = ProfileDesk.snapshot(
            session: .signedIn(UserProfile(id: "me", name: "Вы", phone: "+375291000000", isOwner: true)),
            listings: 1,
            garage: 4,
            unread: 3,
            compare: 2,
            viewed: 5,
            blocked: 1,
            reports: 2,
            usdBYN: 2.99
        )
        #expect(snap.canPost)
        #expect(ProfileDesk.headline(snap) == "1 объявл. · 4 в гараже · 3 новых")
        #expect(ProfileDesk.headline(ProfileDesk.snapshot(
            session: .signedIn(UserProfile(id: "me", name: "Вы", phone: "+375291000000", isOwner: true)),
            listings: 0,
            garage: 0,
            unread: 0,
            compare: 0,
            viewed: 0,
            blocked: 0,
            reports: 0,
            usdBYN: 2.99
        )) == "0 объявл. · 0 в гараже")
    }

    @Test func canPostRequiresFullBelarusNumber() {
        #expect(ProfileDesk.canPost(phone: "+375291000000"))
        #expect(!ProfileDesk.canPost(phone: "+37529"))
        #expect(!ProfileDesk.canPost(phone: ""))
    }

    @Test func rateLineAndReportReasonsAreRussian() {
        #expect(ProfileDesk.rateLine(2.99) == "1 $ = 2.99 Br")
        #expect(ProfileDesk.reportReason("spam") == "Спам")
        #expect(ProfileDesk.reportReason("sold") == "Уже продано")
        #expect(ProfileDesk.reportReason("fraud") == "Мошенничество")
        #expect(ProfileDesk.reportReason("other") == "other")
    }

    @Test func clearRecentlyViewedPersistsAndUpdateProfileFlashes() {
        let listing = listingFixture(id: "a")
        let defaults = UserDefaults(suiteName: "autora.tests.\(UUID().uuidString)")!
        let app = AppModel(
            seed: SeedFile(listings: [listing], chats: [], savedSearches: [], fx: FXRate(usdBYN: 2.99)),
            defaults: defaults,
            now: { 1 }
        )
        app.markViewed("a")
        #expect(app.recentlyViewedIDs == ["a"])
        app.clearRecentlyViewed()
        #expect(app.recentlyViewedIDs.isEmpty)

        let reloaded = AppModel(
            seed: SeedFile(listings: [listing], chats: [], savedSearches: [], fx: FXRate(usdBYN: 2.99)),
            defaults: defaults,
            now: { 1 }
        )
        #expect(reloaded.recentlyViewedIDs.isEmpty)

        app.session = .signedIn(UserProfile(id: "me-local", name: "Вы", phone: "+375291000000", isOwner: true))
        app.updateProfile(name: "Борис", phone: "+375 (29) 100-00-00")
        #expect(app.session.profile?.name == "Борис")
        #expect(app.toastMessage == "Профиль сохранён")
        #expect(app.toastSymbol == "person.fill")
        #expect(app.profileSnapshot.listings == 0)
        #expect(app.profileSnapshot.garage == app.ownedGarage.count)
        #expect(app.profileHeadline == ProfileDesk.headline(app.profileSnapshot))
    }
}
