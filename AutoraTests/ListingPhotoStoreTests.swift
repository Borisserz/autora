import Foundation
import Testing
import UIKit
@testable import Autora

struct ListingPhotoStoreTests {
    @Test func jpegDataKeepsValidImage() {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4))
        let raw = renderer.jpegData(withCompressionQuality: 1) { ctx in
            UIColor.gray.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        }
        let jpeg = ListingPhotoStore.jpegData(from: raw)
        #expect(jpeg != nil)
        #expect(UIImage(data: jpeg!) != nil)
    }

    @Test func saveJPEGWritesFile() throws {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4))
        let raw = renderer.jpegData(withCompressionQuality: 1) { ctx in
            UIColor.darkGray.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        }
        let url = try ListingPhotoStore.saveJPEG(raw, listingID: "test-\(UUID().uuidString)", index: 0)
        #expect(FileManager.default.fileExists(atPath: url.path))
        try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
    }
}
