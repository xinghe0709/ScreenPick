import Foundation

enum CaptureNaming {
    static func filename(for date: Date, timeZone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd HH.mm.ss"
        return "屏幕截图 \(formatter.string(from: date)).png"
    }

    static func uniqueURL(in folder: URL, date: Date = Date(), fileManager: FileManager = .default) -> URL {
        let filename = filename(for: date)
        let initial = folder.appendingPathComponent(filename)
        guard fileManager.fileExists(atPath: initial.path) else { return initial }

        let base = initial.deletingPathExtension().lastPathComponent
        for suffix in 2...999 {
            let candidate = folder.appendingPathComponent("\(base) \(suffix).png")
            if !fileManager.fileExists(atPath: candidate.path) {
                return candidate
            }
        }

        return folder.appendingPathComponent("\(base) \(UUID().uuidString).png")
    }
}
