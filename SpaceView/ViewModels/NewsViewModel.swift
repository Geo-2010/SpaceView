import Foundation

@MainActor
@Observable
final class NewsViewModel {
    var articles: [NewsArticle] = []
    var isLoading = false
    var isLoadingMore = false
    var errorMessage: String?
    var hasMore = true

    private var offset = 0
    private let pageSize = 20
    private let service = NewsService()

    func load() async {
        isLoading = true
        errorMessage = nil
        offset = 0
        do {
            let response = try await service.fetchArticles(limit: pageSize, offset: 0)
            articles = response.results
            offset = pageSize
            hasMore = response.next != nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadMore() async {
        guard hasMore, !isLoadingMore, !isLoading else { return }
        isLoadingMore = true
        do {
            let response = try await service.fetchArticles(limit: pageSize, offset: offset)
            articles.append(contentsOf: response.results)
            offset += pageSize
            hasMore = response.next != nil
        } catch {
            // silently fail on pagination — don't replace the existing feed
        }
        isLoadingMore = false
    }
}
