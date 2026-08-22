import Testing
@testable import Autora

struct FirebaseBootstrapTests {
    @Test func authIsForbiddenUntilFirebaseAppExists() {
        #expect(FirebaseBootstrap.mayAccessAuth(plistPresent: true, appConfigured: false) == false)
        #expect(FirebaseBootstrap.mayAccessAuth(plistPresent: false, appConfigured: false) == false)
        #expect(FirebaseBootstrap.mayAccessAuth(plistPresent: true, appConfigured: true) == true)
    }
}
