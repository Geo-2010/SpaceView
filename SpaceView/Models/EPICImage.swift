import Foundation

struct EPICImage: Codable, Identifiable {
    let identifier: String
    let image: String       // filename used to construct the archive URL
    let caption: String
    let date: String

    var id: String { identifier }

    /// e.g. https://epic.gsfc.nasa.gov/archive/natural/2026/03/25/png/epic_1b_20260325001752.png
    var imageURL: URL? {
        let datePart = String(date.prefix(10))           // "YYYY-MM-DD"
        let parts = datePart.split(separator: "-")
        guard parts.count == 3 else { return nil }
        return URL(string: "https://epic.gsfc.nasa.gov/archive/natural/\(parts[0])/\(parts[1])/\(parts[2])/png/\(image).png")
    }

    var formattedDate: String {
        let parser = DateFormatter()
        parser.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let display = DateFormatter()
        display.dateStyle = .long
        if let d = parser.date(from: date) { return display.string(from: d) }
        return String(date.prefix(10))
    }
}
