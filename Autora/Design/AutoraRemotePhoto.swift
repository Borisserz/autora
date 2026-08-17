import SwiftUI
import UIKit

struct AutoraRemotePhoto: View {
    let urlString: String
    var height: CGFloat?
    var accessibilityText: String?

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle().fill(AutoraTheme.ink.opacity(0.08))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipped()
        .task(id: urlString) {
            image = await AutoraImageCache.image(for: urlString)
        }
        .modifier(PhotoAccess(text: accessibilityText))
    }
}

private struct PhotoAccess: ViewModifier {
    var text: String?

    func body(content: Content) -> some View {
        if let text {
            content.accessibilityLabel(text)
        } else {
            content.accessibilityHidden(true)
        }
    }
}

enum AutoraImageCache {
    private static let memory = NSCache<NSString, UIImage>()

    static func image(for urlString: String, maxPixel: CGFloat = 1200) async -> UIImage? {
        if let cached = memory.object(forKey: urlString as NSString) {
            return cached
        }
        guard let url = URL(string: urlString) else { return nil }
        let data: Data
        if url.isFileURL {
            guard let file = try? Data(contentsOf: url) else { return nil }
            data = file
        } else {
            guard let (remote, _) = try? await URLSession.shared.data(from: url) else { return nil }
            data = remote
        }
        guard let raw = UIImage(data: data) else { return nil }
        let scaled = downsample(raw, maxPixel: maxPixel)
        memory.setObject(scaled, forKey: urlString as NSString)
        return scaled
    }

    private static func downsample(_ image: UIImage, maxPixel: CGFloat) -> UIImage {
        let size = image.size
        let longest = max(size.width, size.height)
        guard longest > maxPixel, longest > 0 else { return image }
        let scale = maxPixel / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
