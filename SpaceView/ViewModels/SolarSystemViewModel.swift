import Foundation

enum Planet: String, CaseIterable, Identifiable {
    case mercury, venus, earth, mars, jupiter, saturn, uranus, neptune

    var id: String { rawValue }

    var displayName: String { rawValue.capitalized }

    var symbol: String {
        switch self {
        case .mercury: return "☿"
        case .venus:   return "♀"
        case .earth:   return "♁"
        case .mars:    return "♂"
        case .jupiter: return "♃"
        case .saturn:  return "♄"
        case .uranus:  return "⛢"
        case .neptune: return "♆"
        }
    }

    /// Search term for NASA Image Library (Earth uses EPIC instead)
    var searchTerm: String {
        switch self {
        case .mercury: return "mercury planet NASA close-up"
        case .venus:   return "venus planet NASA surface atmosphere"
        case .earth:   return ""   // handled by EPIC
        case .mars:    return "mars planet NASA globe"
        case .jupiter: return "jupiter planet NASA great red spot"
        case .saturn:  return "saturn planet rings NASA"
        case .uranus:  return "uranus planet NASA voyager"
        case .neptune: return "neptune planet NASA voyager"
        }
    }
}

@MainActor
@Observable
final class SolarSystemViewModel {
    var selectedPlanet: Planet = .earth

    // Earth / EPIC
    var epicImages: [EPICImage] = []
    var epicIndex = 0

    // Other planets
    var planetImages: [NASAImage] = []
    var isLoadingMore = false
    var hasMore = true

    var isLoading = false
    var errorMessage: String?

    private var currentPage = 1
    private let service = NASAService()

    var currentEPIC: EPICImage? {
        guard !epicImages.isEmpty else { return nil }
        return epicImages[min(epicIndex, epicImages.count - 1)]
    }

    func selectPlanet(_ planet: Planet) async {
        selectedPlanet = planet
        await load()
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        currentPage = 1
        hasMore = true
        do {
            if selectedPlanet == .earth {
                epicImages = try await service.fetchEPICImages()
                epicIndex = 0
            } else {
                planetImages = try await service.fetchNASAImages(searchTerm: selectedPlanet.searchTerm, page: 1)
                hasMore = !planetImages.isEmpty
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadMore() async {
        guard selectedPlanet != .earth, hasMore, !isLoadingMore, !isLoading else { return }
        isLoadingMore = true
        let nextPage = currentPage + 1
        do {
            let more = try await service.fetchNASAImages(searchTerm: selectedPlanet.searchTerm, page: nextPage)
            if more.isEmpty {
                hasMore = false
            } else {
                planetImages.append(contentsOf: more)
                currentPage = nextPage
            }
        } catch { }
        isLoadingMore = false
    }
}
