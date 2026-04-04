import Foundation

enum NASAServiceError: LocalizedError {
    case invalidURL
    case httpError(Int)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:           return "Invalid API URL."
        case .httpError(let c):     return "Server returned status \(c)."
        case .decodingError(let e): return "Failed to decode response: \(e.localizedDescription)"
        }
    }
}

actor NASAService {
    static let apiKey = "a9cIDeUg4J9xKG36ctqKx3RH0xEhN8pFj0KWnppe"

    // MARK: - APOD

    func fetchAPOD(date: Date? = nil) async throws -> APODEntry {
        var items = [URLQueryItem(name: "api_key", value: Self.apiKey),
                     URLQueryItem(name: "thumbs",  value: "true")]
        if let date {
            items.append(URLQueryItem(name: "date", value: Self.isoDate(date)))
        }
        let data = try await get("https://api.nasa.gov/planetary/apod", query: items)
        return try decode(APODEntry.self, from: data)
    }

    // MARK: - NASA Image Library (replaces retired Mars Rover Photos API)

    enum SpaceQuery: String, CaseIterable {
        case mars         = "mars perseverance curiosity"
        case moon         = "moon artemis lunar"
        case hubble       = "hubble telescope deep field"

        var displayName: String {
            switch self {
            case .mars:   return "Mars"
            case .moon:   return "Moon"
            case .hubble: return "Hubble"
            }
        }
    }

    func fetchNASAImages(query: SpaceQuery = .mars, page: Int = 1) async throws -> [NASAImage] {
        try await fetchNASAImages(searchTerm: query.rawValue, page: page)
    }

    func fetchNASAImages(searchTerm: String, page: Int = 1) async throws -> [NASAImage] {
        let items = [
            URLQueryItem(name: "q",          value: searchTerm),
            URLQueryItem(name: "media_type", value: "image"),
            URLQueryItem(name: "page_size",  value: "30"),
            URLQueryItem(name: "page",       value: "\(page)")
        ]
        let data = try await get("https://images-api.nasa.gov/search", query: items)
        let response = try decode(ImageLibraryResponse.self, from: data)
        return response.collection.items.compactMap { $0.toNASAImage() }
    }

    // MARK: - EPIC (Earth) — hosted on epic.gsfc.nasa.gov, no API key required

    func fetchEPICImages() async throws -> [EPICImage] {
        let data = try await get("https://epic.gsfc.nasa.gov/api/natural", query: [])
        return try decode([EPICImage].self, from: data)
    }

    // MARK: - Helpers

    private func get(_ urlString: String, query: [URLQueryItem]) async throws -> Data {
        var components = URLComponents(string: urlString)!
        if !query.isEmpty { components.queryItems = query }
        guard let url = components.url else { throw NASAServiceError.invalidURL }
        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw NASAServiceError.httpError(http.statusCode)
        }
        return data
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw NASAServiceError.decodingError(error)
        }
    }

    private static func isoDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}
