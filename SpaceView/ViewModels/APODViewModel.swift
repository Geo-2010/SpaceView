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
    }

    func load(date: Date?) async {
        isLoading = true
        errorMessage = nil
        do {
            entry = try await service.fetchAPOD(date: date)
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
}
