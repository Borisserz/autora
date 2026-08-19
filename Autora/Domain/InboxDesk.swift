import Foundation

enum InboxTab: Int, CaseIterable, Identifiable, Codable, Sendable {
    case all, unread, offers

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .all: "Все"
        case .unread: "Новые"
        case .offers: "К цели"
        }
    }
}

enum InboxDesk {
    static func lastActivity(_ thread: ChatThread) -> TimeInterval {
        thread.messages.last?.at ?? 0
    }

    static func sorted(_ threads: [ChatThread]) -> [ChatThread] {
        threads.sorted { lastActivity($0) > lastActivity($1) }
    }

    static func listings(
        _ threads: [ChatThread],
        tab: InboxTab,
        deferredIDs: Set<String>
    ) -> [ChatThread] {
        let filtered = threads.filter { thread in
            switch tab {
            case .all: true
            case .unread: thread.unread > 0
            case .offers: deferredIDs.contains(thread.listingId)
            }
        }
        return sorted(filtered)
    }

    static func preview(_ thread: ChatThread) -> String {
        guard let last = thread.messages.last else { return "Напишите первое сообщение" }
        return last.fromMe ? "Вы: \(last.text)" : last.text
    }

    static func headline(unread: Int, threads: Int) -> String {
        if unread > 0 {
            return "\(unread) непрочитанных · \(threads) переписок"
        }
        if threads == 0 {
            return "Пусто. Напишите с карточки авто."
        }
        return "\(threads) переписки"
    }

    static func timeLabel(at: TimeInterval, now: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: at)
        let current = Date(timeIntervalSince1970: now)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_BY")
        let calendar = Calendar(identifier: .gregorian)
        if calendar.isDate(date, inSameDayAs: current) {
            formatter.dateFormat = "HH:mm"
        } else {
            formatter.dateFormat = "d.MM"
        }
        return formatter.string(from: date)
    }
}
