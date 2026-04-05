import Foundation

final class APODCache {
    static let shared = APODCache()
    private init() {}

    private let cacheDir: URL = {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let dir = caches.appendingPathComponent("APODEntries", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    func get(dateKey: String) -> APODEntry? {
        let file = cacheDir.appendingPathComponent("\(dateKey).json")
        guard let data = try? Data(contentsOf: file) else { return nil }
        return try? decoder.decode(APODEntry.self, from: data)
    }

    func store(_ entry: APODEntry) {
        let file = cacheDir.appendingPathComponent("\(entry.date).json")
        guard let data = try? encoder.encode(entry) else { return }
        try? data.write(to: file, options: .atomic)
    }

    /// Silently pre-caches the last `days` APOD entries that aren't already on disk.
    func prefetch(days: Int, using service: NASAService) async {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        for i in 1...days {
            guard let date = calendar.date(byAdding: .day, value: -i, to: Date()) else { continue }
            let key = formatter.string(from: date)
            guard get(dateKey: key) == nil else { continue }
            if let entry = try? await service.fetchAPOD(date: date) {
                store(entry)
            }
        }
    }
}
