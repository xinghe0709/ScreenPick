import CoreGraphics

enum ScreenshotShortcutMatcher {
    static func matches(keyCode: Int64, flags: CGEventFlags) -> Bool {
        guard keyCode == 20 else { return false } // ANSI/JIS virtual key code for the 3 key.

        let hasRequiredModifiers = flags.contains(.maskCommand) && flags.contains(.maskShift)
        let hasUnsupportedModifier = flags.contains(.maskAlternate)
        return hasRequiredModifiers && !hasUnsupportedModifier
    }

    static func forcesClipboard(flags: CGEventFlags) -> Bool {
        flags.contains(.maskControl)
    }
}
