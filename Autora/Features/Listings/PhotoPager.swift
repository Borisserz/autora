import SwiftUI

struct PhotoPager: View {
    let urls: [String]
    var title: String = "Фото"
    var height: CGFloat = AutoraTheme.detailPhotoHeight
    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TabView(selection: $page) {
            ForEach(Array(urls.enumerated()), id: \.offset) { index, raw in
                PhotoPage(
                    urlString: raw,
                    label: "\(title), фото \(index + 1) из \(urls.count)",
                    height: height,
                    reduceMotion: reduceMotion
                )
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: height)
        .background(AutoraTheme.ink)
        .overlay(alignment: .bottom) {
            if !urls.isEmpty {
                HStack {
                    Text(PhotoGallery.caption(index: page, count: urls.count))
                        .font(.caption.weight(.semibold))
                    Spacer(minLength: 8)
                    if urls.count > 1 {
                        Text("\(page + 1) / \(urls.count)")
                            .font(.caption.monospacedDigit().weight(.semibold))
                            .contentTransition(.numericText())
                            .animation(AutoraMotion.press, value: page)
                    }
                }
                .foregroundStyle(AutoraTheme.canvas)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(AutoraTheme.ink.opacity(0.62), in: Capsule())
                .padding(12)
                .accessibilityLabel("\(PhotoGallery.caption(index: page, count: urls.count)), фото \(page + 1) из \(urls.count)")
            }
        }
    }
}

struct StretchyCatalogPhoto: View {
    let urls: [String]
    var title: String

    var body: some View {
        GeometryReader { geo in
            let minY = geo.frame(in: .scrollView).minY
            let extra = max(0, minY)
            PhotoPager(urls: urls, title: title, height: AutoraTheme.detailPhotoHeight + extra)
                .offset(y: extra > 0 ? -extra : 0)
        }
        .frame(height: AutoraTheme.detailPhotoHeight)
    }
}

private struct PhotoPage: View {
    let urlString: String
    let label: String
    let height: CGFloat
    let reduceMotion: Bool
    @State private var scale: CGFloat = 1
    @State private var liveScale: CGFloat = 1

    var body: some View {
        AutoraRemotePhoto(urlString: urlString, height: height)
            .scaleEffect(reduceMotion ? 1 : scale * liveScale)
            .gesture(
                MagnifyGesture()
                    .onChanged { liveScale = $0.magnification }
                    .onEnded { value in
                        scale = min(4, max(1, scale * value.magnification))
                        liveScale = 1
                    }
            )
            .onTapGesture(count: 2) {
                scale = 1
                liveScale = 1
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .accessibilityLabel(label)
    }
}
