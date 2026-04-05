import Foundation

@MainActor
@Observable
final class APODViewModel {
    var entry: APODEntry?
    var isLoading = false
    var errorMessage: String?
    var selectedDate: Date = Date()

    private let service = NASAService()

    /// Earliest possible APOD date
    static let minDate = Calendar.current.date(from: DateComponents(year: 1995, month: 6, day: 16))!

    /// For Xcode previews — skips the network call.
    init(preview: APODEntry? = nil) {
        self.entry = preview
    }

    func loadToday() async {
        selectedDate = Date()
        await load(date: nil)
        // Silently pre-cache the past 30 days in the background
        let svc = service
        Task.detached(priority: .background) {
            await APODCache.shared.prefetch(days: 30, using: svc)
        }
    }

    func load(date: Date?) async {
        // Serve from disk cache for past dates — today's image can change
        if let date {
            let key = Self.isoDate(date)
            if let cached = APODCache.shared.get(dateKey: key) {
                entry = cached
                isLoading = false
                errorMessage = nil
                return
            }
        }

        isLoading = true
        errorMessage = nil
        do {
            let fetched = try await service.fetchAPOD(date: date)
            entry = fetched
            if let date { APODCache.shared.store(fetched) }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadPrevious() async {
        let prev = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        guard prev >= APODViewModel.minDate else { return }
        selectedDate = prev
        await load(date: prev)
    }

    func loadNext() async {
        let next = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        guard next <= Date() else { return }
        selectedDate = next
        await load(date: next)
    }

    func loadSelected() async {
        await load(date: Calendar.current.isDateInToday(selectedDate) ? nil : selectedDate)
    }

    var isToday: Bool { Calendar.current.isDateInToday(selectedDate) }
    var canGoNext: Bool { !isToday }
    var canGoPrev: Bool { selectedDate > APODViewModel.minDate }

    private static func isoDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}
