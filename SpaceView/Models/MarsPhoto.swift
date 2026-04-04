import Foundation

/// A search result from the NASA Image & Video Library.
struct NASAImage: Identifiable, Codable {
    let id: String          // nasa_id
    let title: String
    let description: String
    let dateCreated: String
    let thumbnailURL: URL?

    /// Derive a large image URL from the thumbnail URL (~thumb → ~large)
    var largeURL: URL? {
        guard let thumb = thumbnailURL?.absoluteString else { return nil }
        return URL(string: thumb.replacingOccurrences(of: "~thumb.jpg", with: "~large.jpg"))
    }

    var formattedDate: String {
        let parser = ISO8601DateFormatter()
        let display = DateFormatter()
        display.dateStyle = .long
        if let d = parser.date(from: dateCreated) { return display.string(from: d) }
        return String(dateCreated.prefix(10))
    }
}

/// Raw decodable types for the Image Library response.
struct ImageLibraryResponse: Decodable {
    let collection: Collection

    struct Collection: Decodable {
        let items: [Item]
    }

    struct Item: Decodable {
        let data: [ItemData]
        let links: [ItemLink]?
    }

    struct ItemData: Decodable {
        let nasaId: String
        let title: String
        let description: String?
        let dateCreated: String?

        enum CodingKeys: String, CodingKey {
            case nasaId       = "nasa_id"
            case title
            case description
            case dateCreated  = "date_created"
        }
    }

    struct ItemLink: Decodable {
        let href: String
        let rel: String
    }
}

extension ImageLibraryResponse.Item {
    func toNASAImage() -> NASAImage? {
        guard let data = self.data.first else { return nil }
        let thumb = links?.first(where: { $0.rel == "preview" }).flatMap { URL(string: $0.href) }
        return NASAImage(
            id: data.nasaId,
            title: data.title,
            description: data.description ?? "",
            dateCreated: data.dateCreated ?? "",
            thumbnailURL: thumb
        )
    }
}
