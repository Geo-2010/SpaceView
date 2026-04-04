import Foundation

struct NewsArticle: Codable, Identifiable {
    let id: Int
    let title: String
    let url: String
    let imageUrl: String?
    let newsSite: String
    let summary: String
    let publishedAt: String

    var articleURL: URL? { URL(string: url) }
    var thumbnailURL: URL? {
        guard let s = imageUrl, !s.isEmpty else { return nil }
        return URL(string: s)
    }

    var formattedDate: String {
        let parser = ISO8601DateFormatter()
        let display = DateFormatter()
        display.dateStyle = .medium
        display.timeStyle = .short
        if let d = parser.date(from: publishedAt) { return display.string(from: d) }
        return String(publishedAt.prefix(10))
    }

    enum CodingKeys: String, CodingKey {
        case id, title, url, summary
        case imageUrl    = "image_url"
        case newsSite    = "news_site"
        case publishedAt = "published_at"
    }
}

struct NewsResponse: Codable {
    let count: Int
    let next: String?
    let results: [NewsArticle]
}
