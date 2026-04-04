import Foundation

actor NewsService {
    private let base = "https://api.spaceflightnewsapi.net/v4/articles/"

    func fetchArticles(limit: Int = 20, offset: Int = 0) async throws -> NewsResponse {
        var components = URLComponents(string: base)!
        components.queryItems = [
            URLQueryItem(name: "limit",  value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)")
        ]
        guard let url = components.url else { throw NASAServiceError.invalidURL }
        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw NASAServiceError.httpError(http.statusCode)
        }
        do {
            return try JSONDecoder().decode(NewsResponse.self, from: data)
        } catch {
            throw NASAServiceError.decodingError(error)
        }
    }
}
