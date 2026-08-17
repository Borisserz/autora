import Foundation
import UIKit

enum ListingPhotoStore {
    static func saveJPEG(_ data: Data, listingID: String, index: Int) throws -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appending(path: "autora-photos/\(listingID)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        let url = base.appending(path: "\(index).jpg")
        try data.write(to: url, options: .atomic)
        return url
    }

    static func jpegData(from raw: Data) -> Data? {
        guard let image = UIImage(data: raw) else { return raw }
        return image.jpegData(compressionQuality: 0.85) ?? raw
    }
}
