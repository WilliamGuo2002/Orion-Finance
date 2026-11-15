import SwiftUI
import UIKit

/// Decoded-image cache shared by list thumbnails. AsyncImage re-downloads and re-decodes every time a
/// lazy row reappears, which costs frames while scrolling and makes logos flicker.
@MainActor
final class RemoteImageCache {
    static let shared = RemoteImageCache()
    private let cache = NSCache<NSURL, UIImage>()
    private var inFlight: [URL: Task<UIImage?, Never>] = [:]

    private init() { cache.countLimit = 300 }

    func cached(_ url: URL) -> UIImage? { cache.object(forKey: url as NSURL) }

    func load(_ url: URL) async -> UIImage? {
        if let hit = cached(url) { return hit }
        if let task = inFlight[url] { return await task.value }
        let task = Task<UIImage?, Never> {
            guard let (data, _) = try? await URLSession.shared.data(from: url) else { return nil }
            // Decode off the main thread, at display size, so the first draw is cheap.
            return await Task.detached(priority: .utility) { () -> UIImage? in
                guard let img = UIImage(data: data) else { return nil }
                let scale = min(1, 240 / max(img.size.width, img.size.height, 1))
                let size = CGSize(width: img.size.width * scale, height: img.size.height * scale)
                return img.preparingThumbnail(of: size) ?? img
            }.value
        }
        inFlight[url] = task
        let image = await task.value
        inFlight[url] = nil
        if let image { cache.setObject(image, forKey: url as NSURL) }
        return image
    }
}

/// A remote thumbnail with a stable placeholder.
///
/// Photos fill their frame; images that look like publisher logos (small, very wide or very tall)
/// are shown whole on a neutral tile instead of being cropped to fragments like "REUT".
struct RemoteImage<Placeholder: View>: View {
    let url: URL?
    var cornerRadius: CGFloat = 10
    /// Always show the whole image (company logos).
    var fit: Bool = false
    @ViewBuilder var placeholder: () -> Placeholder

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image {
                if fit {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                } else if Self.looksLikeLogo(image) {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(AppTheme.subtleFill)
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding(8)
                } else {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                }
            } else {
                placeholder()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .task(id: url) {
            guard let url else { image = nil; return }
            if let hit = RemoteImageCache.shared.cached(url) { image = hit; return }
            image = await RemoteImageCache.shared.load(url)
        }
    }

    static func looksLikeLogo(_ image: UIImage) -> Bool {
        let w = image.size.width * image.scale, h = image.size.height * image.scale
        guard w > 0, h > 0 else { return false }
        let ratio = w / h
        return ratio > 2.4 || ratio < 0.5 || max(w, h) < 160
    }
}
