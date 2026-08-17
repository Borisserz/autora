import Foundation

enum UITestLaunch {
    static let argument = "-ui-testing"
    static let suiteName = "autora.ui-tests"

    static var isActive: Bool {
        ProcessInfo.processInfo.arguments.contains(argument)
    }

    static func makeModel() -> AppModel {
        guard isActive else { return AppModel() }
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return AppModel(defaults: defaults)
    }
}

enum AutoraID {
    static let searchField = "autora.search.field"
    static let filters = "autora.search.filters"
    static let saveSearch = "autora.search.save"
    static let write = "autora.listing.write"
    static let call = "autora.listing.call"
    static let wizardNext = "autora.wizard.next"
    static let wizardTestPhoto = "autora.wizard.testPhoto"
    static let wizardTestDraft = "autora.wizard.testDraft"
    static let chatField = "autora.chat.field"
    static let chatSend = "autora.chat.send"
    static let newListing = "autora.listings.new"
    static let tabSearch = "autora.tab.search"
    static let tabFavorites = "autora.tab.favorites"
    static let tabListings = "autora.tab.listings"
    static let tabMessages = "autora.tab.messages"
    static let tabProfile = "autora.tab.profile"

    static func listingCard(_ id: String) -> String { "autora.listing.\(id)" }
    static func listingFavorite(_ id: String) -> String { "autora.listing.favorite.\(id)" }
    static func listingCompare(_ id: String) -> String { "autora.listing.compare.\(id)" }
}
