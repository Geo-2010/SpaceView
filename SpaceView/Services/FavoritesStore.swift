import Foundation

@MainActor
@Observable
final class FavoritesStore {
    private(set) var apodEntries: [APODEntry] = []
    private(set) var nasaImages:  [NASAImage]  = []

    private let apodKey = "fav_apod_v1"
    private let nasaKey = "fav_nasa_v1"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() { load() }

    // MARK: - APOD

    func toggle(_ entry: APODEntry) {
        if let i = apodEntries.firstIndex(where: { $0.id == entry.id }) {
            apodEntries.remove(at: i)
        } else {
            apodEntries.insert(entry, at: 0)
        }
        save()
    }

    func contains(_ entry: APODEntry) -> Bool {
        apodEntries.contains(where: { $0.id == entry.id })
    }

    // MARK: - NASA Images

    func toggle(_ image: NASAImage) {
        if let i = nasaImages.firstIndex(where: { $0.id == image.id }) {
            nasaImages.remove(at: i)
        } else {
            nasaImages.insert(image, at: 0)
        }
        save()
    }

    func contains(_ image: NASAImage) -> Bool {
        nasaImages.contains(where: { $0.id == image.id })
    }

    // MARK: - Persistence

    private func load() {
        if let data = UserDefaults.standard.data(forKey: apodKey),
           let decoded = try? decoder.decode([APODEntry].self, from: data) {
            apodEntries = decoded
        }
        if let data = UserDefaults.standard.data(forKey: nasaKey),
           let decoded = try? decoder.decode([NASAImage].self, from: data) {
            nasaImages = decoded
        }
    }

    private func save() {
        if let data = try? encoder.encode(apodEntries) {
            UserDefaults.standard.set(data, forKey: apodKey)
        }
        if let data = try? encoder.encode(nasaImages) {
            UserDefaults.standard.set(data, forKey: nasaKey)
        }
    }
}
