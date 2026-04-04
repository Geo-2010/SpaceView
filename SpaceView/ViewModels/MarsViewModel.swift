import Foundation

@MainActor
@Observable
final class MarsViewModel {
    enum SearchMode: Equatable {
        case preset(NASAService.SpaceQuery)
        case custom(String)
    }

    var images: [NASAImage] = []
    var searchMode: SearchMode = .preset(.mars)
    var searchText: String = ""
    var isLoading = false
    var isLoadingMore = false
    var hasMore = true
    var errorMessage: String?

    private var currentPage = 1
    private let service = NASAService()

    var activePreset: NASAService.SpaceQuery? {
        if case .preset(let q) = searchMode { return q }
        return nil
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        currentPage = 1
        do {
            images = try await fetch(page: 1)
            hasMore = !images.isEmpty
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadMore() async {
        guard hasMore, !isLoadingMore, !isLoading else { return }
        isLoadingMore = true
        let nextPage = currentPage + 1
        do {
            let more = try await fetch(page: nextPage)
            if more.isEmpty { hasMore = false } else {
                images.append(contentsOf: more)
                currentPage = nextPage
            }
        } catch { }
        isLoadingMore = false
    }

    func selectPreset(_ query: NASAService.SpaceQuery) async {
        searchMode = .preset(query)
        searchText = ""
        await load()
    }

    func search() async {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        searchMode = .custom(searchText)
        await load()
    }

    private func fetch(page: Int) async throws -> [NASAImage] {
        switch searchMode {
        case .preset(let q):     return try await service.fetchNASAImages(query: q, page: page)
        case .custom(let term):  return try await service.fetchNASAImages(searchTerm: term, page: page)
        }
    }
}
