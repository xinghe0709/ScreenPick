import CoreGraphics
import Foundation

@main
struct CaptureNamingProbe {
    static func main() throws {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = 2026
        components.month = 9
        components.day = 13
        components.hour = 8
        components.minute = 5
        components.second = 9

        guard let date = components.date else {
            throw ProbeFailure("无法创建测试日期")
        }

        let filename = CaptureNaming.filename(
            for: date,
            timeZone: TimeZone(secondsFromGMT: 0)!
        )
        guard filename == "屏幕截图 2026-09-13 08.05.09.png" else {
            throw ProbeFailure("文件名格式不正确：\(filename)")
        }

        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("ScreenPickTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }

        let firstURL = folder.appendingPathComponent(CaptureNaming.filename(for: date))
        try Data().write(to: firstURL)

        let uniqueURL = CaptureNaming.uniqueURL(in: folder, date: date)
        guard uniqueURL.lastPathComponent.hasSuffix(" 2.png") else {
            throw ProbeFailure("重复文件名没有添加序号：\(uniqueURL.lastPathComponent)")
        }

        let baseFlags: CGEventFlags = [.maskCommand, .maskShift]
        guard ScreenshotShortcutMatcher.matches(keyCode: 20, flags: baseFlags) else {
            throw ProbeFailure("没有识别 Shift-Command-3")
        }
        guard ScreenshotShortcutMatcher.matches(
            keyCode: 20,
            flags: [baseFlags, .maskControl]
        ) else {
            throw ProbeFailure("没有识别 Control-Shift-Command-3")
        }
        guard ScreenshotShortcutMatcher.forcesClipboard(flags: [baseFlags, .maskControl]) else {
            throw ProbeFailure("Control 变体没有切换为剪贴板模式")
        }
        guard !ScreenshotShortcutMatcher.matches(
            keyCode: 20,
            flags: [baseFlags, .maskAlternate]
        ) else {
            throw ProbeFailure("错误拦截了包含 Option 的快捷键")
        }
        guard !ScreenshotShortcutMatcher.matches(keyCode: 19, flags: baseFlags) else {
            throw ProbeFailure("错误拦截了其他数字键")
        }

        print("ScreenPick probes: passed")
    }
}

private struct ProbeFailure: LocalizedError {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var errorDescription: String? { message }
}
