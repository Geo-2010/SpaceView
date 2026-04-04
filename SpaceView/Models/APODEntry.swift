import Foundation

struct APODEntry: Codable, Identifiable {
    let date: String
    let title: String
    let explanation: String
    let url: String
    let hdurl: String?
    let mediaType: String
    let copyright: String?

    var id: String { date }
    var isImage: Bool { mediaType == "image" }

    enum CodingKeys: String, CodingKey {
        case date, title, explanation, url, hdurl, copyright
        case mediaType = "media_type"
    }

    // MARK: - Video helpers

    /// Extracts the YouTube video ID from embed URLs like youtube.com/embed/VIDEO_ID
    var youtubeVideoID: String? {
        guard !isImage else { return nil }
        let patterns = [#"/embed/([A-Za-z0-9_\-]{11})"#, #"youtu\.be/([A-Za-z0-9_\-]{11})"#]
        for pattern in patterns {
            if let match = url.range(of: pattern, options: .regularExpression),
               let idMatch = url.range(of: #"[A-Za-z0-9_\-]{11}"#,
                                       options: .regularExpression, range: match) {
                return String(url[idMatch])
            }
        }
        return nil
    }

    var youtubeThumbnailURL: URL? {
        guard let id = youtubeVideoID else { return nil }
        return URL(string: "https://img.youtube.com/vi/\(id)/hqdefault.jpg")
    }

    var youtubeWatchURL: URL? {
        guard let id = youtubeVideoID else { return nil }
        return URL(string: "https://www.youtube.com/watch?v=\(id)")
    }

    static let preview = APODEntry(
        date: "2026-04-04",
        title: "The Pillars of Creation",
        explanation: "The Eagle Nebula's iconic Pillars of Creation, captured by the James Webb Space Telescope in near-infrared light, reveal towering columns of gas and dust where new stars are being born. The pillars stretch several light-years in length, sculpted by ultraviolet radiation from massive young stars lurking just off frame. Translucent wisps and knots of material—Evaporating Gaseous Globules, or EGGs—dot the pillars' edges, some harboring protostars deep within.",
        url: "https://apod.nasa.gov/apod/image/2304/M16_WebbHubble_960.jpg",
        hdurl: "https://apod.nasa.gov/apod/image/2304/M16_WebbHubble_2732.jpg",
        mediaType: "image",
        copyright: "NASA / ESA / CSA"
    )
}
