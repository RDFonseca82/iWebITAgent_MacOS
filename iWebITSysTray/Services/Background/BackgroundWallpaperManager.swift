import AppKit
import Foundation
import ImageIO

enum BackgroundWallpaperUpdateResult {
    case noRequest
    case alreadyApplied
    case applied(sourceHost: String, displayCount: Int)
}

private enum BackgroundWallpaperError: LocalizedError {
    case invalidURL
    case insecureRedirect
    case invalidResponse
    case unsupportedContentType
    case imageTooLarge
    case invalidImage
    case unsupportedImageFormat
    case unavailableDataDirectory
    case noDisplays

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "BackgroundImage tem de indicar um URL HTTPS válido"
        case .insecureRedirect:
            return "O redirecionamento de BackgroundImage não terminou em HTTPS"
        case .invalidResponse:
            return "O download de BackgroundImage devolveu uma resposta inválida"
        case .unsupportedContentType:
            return "BackgroundImage não devolveu um tipo de imagem suportado"
        case .imageTooLarge:
            return "BackgroundImage excede os limites de segurança"
        case .invalidImage:
            return "BackgroundImage não contém uma imagem válida"
        case .unsupportedImageFormat:
            return "O formato de BackgroundImage não é suportado"
        case .unavailableDataDirectory:
            return "A pasta de dados do agente não está disponível"
        case .noDisplays:
            return "O macOS não devolveu nenhum monitor disponível"
        }
    }
}

final class BackgroundWallpaperManager {
    static let shared = BackgroundWallpaperManager()

    private let baseURL = URL(string: "https://agent.iwebit.app/")!
    private let maxDownloadBytes: Int64 = 10 * 1024 * 1024
    private let maxImageDimension: Int64 = 16_384
    private let maxImagePixels: Int64 = 67_108_864
    private let lastAppliedURLKey = "iwebit.background.lastAppliedURL"
    private let lastAppliedFilenameKey = "iwebit.background.lastAppliedFilename"

    private init() {}

    func synchronize(
        setBackground: Int?,
        backgroundImage: String?
    ) async throws -> BackgroundWallpaperUpdateResult {
        guard setBackground == 1 else {
            clearCommandState()
            return .noRequest
        }

        let sourceURL = try resolveImageURL(backgroundImage)
        let sourceValue = sourceURL.absoluteString

        if UserDefaults.standard.string(forKey: lastAppliedURLKey) == sourceValue,
           let savedURL = savedImageURL(),
           FileManager.default.isReadableFile(atPath: savedURL.path) {
            if try await isAppliedToEveryDisplay(savedURL) {
                return .alreadyApplied
            }

            let displayCount = try await apply(savedURL)
            return .applied(sourceHost: sourceURL.host ?? "unknown", displayCount: displayCount)
        }

        let downloadedImage = try await downloadAndValidate(sourceURL)
        let localURL = try persist(downloadedImage.data, extension: downloadedImage.fileExtension)
        let displayCount = try await apply(localURL)

        UserDefaults.standard.set(sourceValue, forKey: lastAppliedURLKey)
        UserDefaults.standard.set(localURL.lastPathComponent, forKey: lastAppliedFilenameKey)
        return .applied(sourceHost: sourceURL.host ?? "unknown", displayCount: displayCount)
    }

    private func clearCommandState() {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: lastAppliedURLKey) != nil ||
                defaults.object(forKey: lastAppliedFilenameKey) != nil else { return }
        defaults.removeObject(forKey: lastAppliedURLKey)
        defaults.removeObject(forKey: lastAppliedFilenameKey)
    }

    private func resolveImageURL(_ rawValue: String?) throws -> URL {
        guard let value = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty,
              let url = URL(string: value, relativeTo: baseURL)?.absoluteURL,
              url.scheme?.lowercased() == "https",
              url.host?.isEmpty == false,
              url.user == nil,
              url.password == nil else {
            throw BackgroundWallpaperError.invalidURL
        }
        return url
    }

    private func savedImageURL() -> URL? {
        guard let filename = UserDefaults.standard.string(forKey: lastAppliedFilenameKey),
              filename == (filename as NSString).lastPathComponent,
              filename.hasPrefix("managed-background."),
              let dataDirectory = FilesManager.shared.getApplicationSupportDirectory() else {
            return nil
        }
        return dataDirectory.appendingPathComponent(filename, isDirectory: false)
    }

    private func downloadAndValidate(_ url: URL) async throws -> (data: Data, fileExtension: String) {
        var request = URLRequest(url: url)
        request.timeoutInterval = 45
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("image/jpeg, image/png, image/heic, image/tiff", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw BackgroundWallpaperError.invalidResponse
        }
        guard httpResponse.url?.scheme?.lowercased() == "https" else {
            throw BackgroundWallpaperError.insecureRedirect
        }
        if httpResponse.expectedContentLength > maxDownloadBytes ||
            Int64(data.count) > maxDownloadBytes {
            throw BackgroundWallpaperError.imageTooLarge
        }
        if let mimeType = httpResponse.mimeType?.lowercased(),
           mimeType == "image/svg+xml" ||
            (!mimeType.hasPrefix("image/") && mimeType != "application/octet-stream") {
            throw BackgroundWallpaperError.unsupportedContentType
        }

        let options = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, options),
              CGImageSourceGetCount(imageSource) > 0,
              let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, options) as NSDictionary?,
              let width = (properties[kCGImagePropertyPixelWidth] as? NSNumber)?.int64Value,
              let height = (properties[kCGImagePropertyPixelHeight] as? NSNumber)?.int64Value,
              width > 0,
              height > 0 else {
            throw BackgroundWallpaperError.invalidImage
        }
        guard width <= maxImageDimension,
              height <= maxImageDimension,
              width * height <= maxImagePixels else {
            throw BackgroundWallpaperError.imageTooLarge
        }

        let sourceType = CGImageSourceGetType(imageSource).map { $0 as String } ?? ""
        guard let fileExtension = fileExtension(for: sourceType) else {
            throw BackgroundWallpaperError.unsupportedImageFormat
        }
        return (data, fileExtension)
    }

    private func fileExtension(for imageType: String) -> String? {
        switch imageType.lowercased() {
        case "public.jpeg":
            return "jpg"
        case "public.png":
            return "png"
        case "public.tiff":
            return "tiff"
        case "public.heic", "public.heif":
            return "heic"
        default:
            return nil
        }
    }

    private func persist(_ data: Data, extension fileExtension: String) throws -> URL {
        guard let dataDirectory = FilesManager.shared.getApplicationSupportDirectory() else {
            throw BackgroundWallpaperError.unavailableDataDirectory
        }
        let destination = dataDirectory.appendingPathComponent(
            "managed-background.\(fileExtension)",
            isDirectory: false
        )
        try data.write(to: destination, options: .atomic)
        return destination
    }

    private func isAppliedToEveryDisplay(_ imageURL: URL) async throws -> Bool {
        try await MainActor.run {
            let screens = NSScreen.screens
            guard !screens.isEmpty else { throw BackgroundWallpaperError.noDisplays }
            return screens.allSatisfy { screen in
                NSWorkspace.shared.desktopImageURL(for: screen)?.standardizedFileURL ==
                    imageURL.standardizedFileURL
            }
        }
    }

    private func apply(_ imageURL: URL) async throws -> Int {
        try await MainActor.run {
            let screens = NSScreen.screens
            guard !screens.isEmpty else { throw BackgroundWallpaperError.noDisplays }
            let options: [NSWorkspace.DesktopImageOptionKey: Any] = [
                .imageScaling: NSImageScaling.scaleProportionallyUpOrDown.rawValue,
                .allowClipping: true,
                .fillColor: NSColor.black
            ]
            for screen in screens {
                try NSWorkspace.shared.setDesktopImageURL(imageURL, for: screen, options: options)
            }
            return screens.count
        }
    }
}
