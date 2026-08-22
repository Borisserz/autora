import Foundation

struct SeedFile: Codable, Sendable {
    var listings: [Listing]
    var chats: [ChatThread]
    var savedSearches: [SavedSearch]
    var fx: FXRate
}

struct FXRate: Codable, Equatable, Sendable {
    var usdBYN: Double
    var source: FXSource

    init(usdBYN: Double, source: FXSource = .seed) {
        self.usdBYN = usdBYN
        self.source = source
    }

    enum CodingKeys: String, CodingKey {
        case usdBYN, source
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        usdBYN = try container.decode(Double.self, forKey: .usdBYN)
        source = try container.decodeIfPresent(FXSource.self, forKey: .source) ?? .seed
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(usdBYN, forKey: .usdBYN)
        try container.encode(source, forKey: .source)
    }
}

enum FXSource: String, Codable, Sendable {
    case seed, cache, nbrb

    var caption: String {
        switch self {
        case .nbrb: "Курс НБРБ"
        case .cache: "Курс НБРБ (кэш)"
        case .seed: "Курс сида"
        }
    }
}

struct SavedSearch: Identifiable, Codable, Equatable, Sendable, Hashable {
    var id: String
    var title: String
    var criteria: SearchCriteria

    var make: String? { criteria.make }
    var model: String? { criteria.model }
    var priceTo: Int? { criteria.priceTo }
    var body: String? { criteria.body }
    var city: String? { criteria.city }

    static func from(criteria: SearchCriteria, id: String = UUID().uuidString) -> SavedSearch {
        SavedSearch(id: id, title: title(from: criteria), criteria: criteria)
    }

    static func title(from criteria: SearchCriteria) -> String {
        var parts: [String] = []
        if let make = criteria.make { parts.append(make) }
        if let model = criteria.model { parts.append(model) }
        if let generation = criteria.generation { parts.append(generation) }
        if let body = criteria.body { parts.append(body) }
        if let city = criteria.city { parts.append(city) }
        if let priceTo = criteria.priceTo {
            parts.append("до \(priceTo.formatted()) Br")
        }
        if parts.isEmpty {
            let query = criteria.query.trimmingCharacters(in: .whitespacesAndNewlines)
            return query.isEmpty ? "Все объявления" : query
        }
        return parts.joined(separator: " · ")
    }

    func isDuplicate(of other: SavedSearch) -> Bool {
        criteria == other.criteria
    }

    func apply(to criteria: inout SearchCriteria) {
        criteria = self.criteria
    }

    enum CodingKeys: String, CodingKey {
        case id, title, criteria, make, model, priceTo, body, city, generation, yearFrom, yearTo
    }

    init(id: String, title: String, criteria: SearchCriteria) {
        self.id = id
        self.title = title
        self.criteria = criteria
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        if let nested = try container.decodeIfPresent(SearchCriteria.self, forKey: .criteria) {
            criteria = nested
        } else {
            var decoded = SearchCriteria()
            decoded.make = try container.decodeIfPresent(String.self, forKey: .make)
            decoded.model = try container.decodeIfPresent(String.self, forKey: .model)
            decoded.generation = try container.decodeIfPresent(String.self, forKey: .generation)
            decoded.priceTo = try container.decodeIfPresent(Int.self, forKey: .priceTo)
            decoded.body = try container.decodeIfPresent(String.self, forKey: .body)
            decoded.city = try container.decodeIfPresent(String.self, forKey: .city)
            decoded.yearFrom = try container.decodeIfPresent(Int.self, forKey: .yearFrom)
            decoded.yearTo = try container.decodeIfPresent(Int.self, forKey: .yearTo)
            criteria = decoded
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(criteria, forKey: .criteria)
        try container.encodeIfPresent(criteria.make, forKey: .make)
        try container.encodeIfPresent(criteria.model, forKey: .model)
        try container.encodeIfPresent(criteria.priceTo, forKey: .priceTo)
        try container.encodeIfPresent(criteria.body, forKey: .body)
        try container.encodeIfPresent(criteria.city, forKey: .city)
    }
}

struct ChatThread: Identifiable, Codable, Equatable, Sendable, Hashable {
    var id: String
    var listingId: String
    var listingTitle: String
    var peerName: String
    var unread: Int
    var messages: [ChatMessage]
    var participantIds: [String]
    var lastText: String
    var lastAt: TimeInterval

    enum CodingKeys: String, CodingKey {
        case id, listingId, listingTitle, peerName, unread, messages, participantIds, lastText, lastAt
    }

    init(
        id: String,
        listingId: String,
        listingTitle: String,
        peerName: String,
        unread: Int,
        messages: [ChatMessage],
        participantIds: [String] = [],
        lastText: String = "",
        lastAt: TimeInterval = 0
    ) {
        self.id = id
        self.listingId = listingId
        self.listingTitle = listingTitle
        self.peerName = peerName
        self.unread = unread
        self.messages = messages
        self.participantIds = participantIds
        self.lastText = lastText
        self.lastAt = lastAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        listingId = try container.decode(String.self, forKey: .listingId)
        listingTitle = try container.decode(String.self, forKey: .listingTitle)
        peerName = try container.decode(String.self, forKey: .peerName)
        unread = try container.decode(Int.self, forKey: .unread)
        messages = try container.decode([ChatMessage].self, forKey: .messages)
        participantIds = try container.decodeIfPresent([String].self, forKey: .participantIds) ?? []
        lastText = try container.decodeIfPresent(String.self, forKey: .lastText) ?? ""
        lastAt = try container.decodeIfPresent(TimeInterval.self, forKey: .lastAt) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(listingId, forKey: .listingId)
        try container.encode(listingTitle, forKey: .listingTitle)
        try container.encode(peerName, forKey: .peerName)
        try container.encode(unread, forKey: .unread)
        try container.encode(messages, forKey: .messages)
        try container.encode(participantIds, forKey: .participantIds)
        try container.encode(lastText, forKey: .lastText)
        try container.encode(lastAt, forKey: .lastAt)
    }
}

struct ChatMessage: Identifiable, Codable, Equatable, Sendable, Hashable {
    var id: String
    var fromMe: Bool
    var text: String
    var at: TimeInterval
    var senderId: String

    enum CodingKeys: String, CodingKey {
        case id, fromMe, text, at, senderId
    }

    init(id: String, fromMe: Bool, text: String, at: TimeInterval, senderId: String = "") {
        self.id = id
        self.fromMe = fromMe
        self.text = text
        self.at = at
        self.senderId = senderId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        fromMe = try container.decode(Bool.self, forKey: .fromMe)
        text = try container.decode(String.self, forKey: .text)
        at = try container.decode(TimeInterval.self, forKey: .at)
        senderId = try container.decodeIfPresent(String.self, forKey: .senderId) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(fromMe, forKey: .fromMe)
        try container.encode(text, forKey: .text)
        try container.encode(at, forKey: .at)
        try container.encode(senderId, forKey: .senderId)
    }

    func oriented(as viewerId: String) -> ChatMessage {
        var copy = self
        if copy.senderId.isEmpty {
            copy.senderId = copy.fromMe ? viewerId : ""
        }
        copy.fromMe = copy.senderId == viewerId
        return copy
    }
}

enum SeedLoader {
    static func load(from url: URL) throws -> SeedFile {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(SeedFile.self, from: data)
    }

    static func loadFromBundle(_ bundle: Bundle = .main) -> SeedFile {
        switch loadResult(from: bundle) {
        case .loaded(let seed): seed
        case .missing, .invalid: SeedFile(listings: [], chats: [], savedSearches: [], fx: FXRate(usdBYN: 2.99))
        }
    }

    static func loadResult(from bundle: Bundle = .main) -> SeedLoadResult {
        guard let url = bundle.url(forResource: "seed", withExtension: "json") else {
            return .missing
        }
        do {
            return .loaded(try load(from: url))
        } catch {
            return .invalid
        }
    }
}

enum SeedLoadResult {
    case loaded(SeedFile)
    case missing
    case invalid
}
