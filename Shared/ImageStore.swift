import UIKit

/// Saves reward photos into the shared App Group container so both the app
/// and the widget can read them. Stores a full-size copy for the app and a
/// small thumbnail for widgets (which have tight memory limits).
enum ImageStore {
    static func save(_ data: Data) -> String? {
        guard let image = UIImage(data: data) else { return nil }
        let name = UUID().uuidString
        guard
            let full = downscaled(image, maxDimension: 1400).jpegData(compressionQuality: 0.85),
            let thumb = downscaled(image, maxDimension: 480).jpegData(compressionQuality: 0.8)
        else { return nil }
        do {
            try full.write(to: url(for: name), options: .atomic)
            try thumb.write(to: thumbURL(for: name), options: .atomic)
            return name
        } catch {
            return nil
        }
    }

    static func delete(_ name: String?) {
        guard let name else { return }
        try? FileManager.default.removeItem(at: url(for: name))
        try? FileManager.default.removeItem(at: thumbURL(for: name))
    }

    static func image(_ name: String?) -> UIImage? {
        guard let name else { return nil }
        return UIImage(contentsOfFile: url(for: name).path)
    }

    static func thumbnail(_ name: String?) -> UIImage? {
        guard let name else { return nil }
        return UIImage(contentsOfFile: thumbURL(for: name).path)
    }

    static func url(for name: String) -> URL {
        AppGroup.imagesURL.appendingPathComponent("\(name).jpg")
    }

    static func thumbURL(for name: String) -> URL {
        AppGroup.imagesURL.appendingPathComponent("\(name)_thumb.jpg")
    }

    private static func downscaled(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let largest = max(image.size.width, image.size.height)
        guard largest > maxDimension else { return image }
        let scale = maxDimension / largest
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
