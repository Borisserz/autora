import Foundation
import UIKit
import UniformTypeIdentifiers

enum PhoneClipboard {
    static let ttl: TimeInterval = 60

    static func copy(_ phone: String, pasteboard: UIPasteboard = .general, now: Date = .now) {
        pasteboard.setItems(
            [[UTType.utf8PlainText.identifier: phone]],
            options: [.expirationDate: now.addingTimeInterval(ttl)]
        )
    }
}
