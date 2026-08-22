import Foundation

enum FirebaseBootstrap {
    static func mayAccessAuth(plistPresent: Bool, appConfigured: Bool) -> Bool {
        plistPresent && appConfigured
    }
}
