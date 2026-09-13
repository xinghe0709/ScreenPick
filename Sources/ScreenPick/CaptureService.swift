import AppKit
import CoreGraphics
import ImageIO
import ScreenCaptureKit
import UniformTypeIdentifiers

enum CaptureOutput: String, CaseIterable, Identifiable {
    case clipboard
    case file
    case both

    var id: String { rawValue }

    var title: String {
        switch self {
        case .clipboard: "复制"
        case .file: "保存"
        case .both: "两者"
        }
    }

    var savesFile: Bool { self == .file || self == .both }
    var copiesImage: Bool { self == .clipboard || self == .both }
}

struct CaptureResult {
    let fileURL: URL?
    let copiedToClipboard: Bool
}

enum CaptureFailure: LocalizedError {
    case permissionRequired
    case displayUnavailable
    case imageUnavailable
    case desktopUnavailable
    case writeFailed
    case clipboardWriteFailed
    case unexpectedDimensions(expectedWidth: Int, expectedHeight: Int, actualWidth: Int, actualHeight: Int)

    var errorDescription: String? {
        switch self {
        case .permissionRequired:
            "需要“屏幕与系统音频录制”权限。授权后请重新打开屏选。"
        case .displayUnavailable:
            "这块屏幕已断开，请重新选择。"
        case .imageUnavailable:
            "无法读取这块屏幕的画面，请稍后重试。"
        case .desktopUnavailable:
            "找不到桌面文件夹，无法保存截图。"
        case .writeFailed:
            "截图生成成功，但写入文件失败。"
        case .clipboardWriteFailed:
            "截图生成成功，但无法写入剪贴板。"
        case let .unexpectedDimensions(expectedWidth, expectedHeight, actualWidth, actualHeight):
            "截图尺寸异常：期望 \(expectedWidth) × \(expectedHeight)，实际 \(actualWidth) × \(actualHeight)。"
        }
    }
}

@MainActor
enum CaptureService {
    static var hasPermission: Bool {
        CGPreflightScreenCaptureAccess()
    }

    static func requestPermission() -> Bool {
        CGRequestScreenCaptureAccess()
    }

    static func capture(display: DisplayInfo, output: CaptureOutput) async throws -> CaptureResult {
        guard hasPermission else {
            throw CaptureFailure.permissionRequired
        }

        let image = try await image(for: display)
        var fileURL: URL?

        if output.savesFile {
            fileURL = try saveToDesktop(image)
        }

        if output.copiesImage {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            let pasteboardImage = NSImage(cgImage: image, size: .zero)
            guard pasteboard.writeObjects([pasteboardImage]) else {
                throw CaptureFailure.clipboardWriteFailed
            }
        }

        return CaptureResult(fileURL: fileURL, copiedToClipboard: output.copiesImage)
    }

    private static func image(for display: DisplayInfo) async throws -> CGImage {
        if #available(macOS 14.0, *) {
            let content = try await SCShareableContent.excludingDesktopWindows(
                false,
                onScreenWindowsOnly: true
            )
            guard let screen = content.displays.first(where: { $0.displayID == display.id }) else {
                throw CaptureFailure.displayUnavailable
            }

            let filter = SCContentFilter(display: screen, excludingWindows: [])
            let configuration = SCStreamConfiguration()
            configuration.width = display.pixelWidth
            configuration.height = display.pixelHeight
            configuration.showsCursor = false
            configuration.capturesAudio = false

            let image = try await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: configuration
            )
            try validateDimensions(of: image, for: display)
            return image
        }

        guard let image = CGDisplayCreateImage(display.id) else {
            throw CaptureFailure.imageUnavailable
        }
        try validateDimensions(of: image, for: display)
        return image
    }

    private static func validateDimensions(of image: CGImage, for display: DisplayInfo) throws {
        guard image.width == display.pixelWidth, image.height == display.pixelHeight else {
            throw CaptureFailure.unexpectedDimensions(
                expectedWidth: display.pixelWidth,
                expectedHeight: display.pixelHeight,
                actualWidth: image.width,
                actualHeight: image.height
            )
        }
    }

    private static func saveToDesktop(_ image: CGImage) throws -> URL {
        let fileManager = FileManager.default
        guard let desktop = fileManager.urls(for: .desktopDirectory, in: .userDomainMask).first else {
            throw CaptureFailure.desktopUnavailable
        }

        let folder = desktop.appendingPathComponent("ScreenPick", isDirectory: true)
        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)

        let destinationURL = CaptureNaming.uniqueURL(in: folder)
        let temporaryURL = folder.appendingPathComponent(".screenpick-\(UUID().uuidString).png")

        guard let destination = CGImageDestinationCreateWithURL(
            temporaryURL as CFURL,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            throw CaptureFailure.writeFailed
        }

        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            try? fileManager.removeItem(at: temporaryURL)
            throw CaptureFailure.writeFailed
        }

        do {
            try fileManager.moveItem(at: temporaryURL, to: destinationURL)
            return destinationURL
        } catch {
            try? fileManager.removeItem(at: temporaryURL)
            throw CaptureFailure.writeFailed
        }
    }
}
