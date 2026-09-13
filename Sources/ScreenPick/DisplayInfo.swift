import AppKit
import CoreGraphics

struct DisplayInfo: Identifiable, Hashable {
    let id: CGDirectDisplayID
    let name: String
    let frame: CGRect
    let pixelWidth: Int
    let pixelHeight: Int
    let scale: CGFloat
    let isMain: Bool
    let isBuiltIn: Bool

    var resolutionText: String {
        "\(pixelWidth) × \(pixelHeight)"
    }

    var kindText: String {
        isBuiltIn ? "内建显示器" : "外接显示器"
    }

    var accessibilitySummary: String {
        var parts = [name, kindText, "分辨率 \(resolutionText)"]
        if isMain { parts.append("主显示器") }
        return parts.joined(separator: "，")
    }

    static func current() -> [DisplayInfo] {
        NSScreen.screens.compactMap { screen in
            guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
                return nil
            }

            let displayID = CGDirectDisplayID(number.uint32Value)
            let scale = screen.backingScaleFactor
            return DisplayInfo(
                id: displayID,
                name: screen.localizedName,
                frame: screen.frame,
                pixelWidth: Int((screen.frame.width * scale).rounded()),
                pixelHeight: Int((screen.frame.height * scale).rounded()),
                scale: scale,
                isMain: CGDisplayIsMain(displayID) != 0,
                isBuiltIn: CGDisplayIsBuiltin(displayID) != 0
            )
        }
        .sorted { left, right in
            if left.isMain != right.isMain { return left.isMain }
            if left.frame.minX != right.frame.minX { return left.frame.minX < right.frame.minX }
            return left.frame.minY > right.frame.minY
        }
    }
}
