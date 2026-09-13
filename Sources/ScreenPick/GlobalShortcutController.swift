import ApplicationServices
import CoreGraphics
import Foundation

@MainActor
final class GlobalShortcutController {
    typealias Handler = (_ forceClipboard: Bool) -> Void

    private let handler: Handler
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    init(handler: @escaping Handler) {
        self.handler = handler
    }

    static var isAccessibilityTrusted: Bool {
        AXIsProcessTrusted()
    }

    static var isInputMonitoringGranted: Bool {
        CGPreflightListenEventAccess()
    }

    @discardableResult
    static func requestAccessibilityPermission() -> Bool {
        let promptKey = "AXTrustedCheckOptionPrompt"
        return AXIsProcessTrustedWithOptions([promptKey: true] as CFDictionary)
    }

    @discardableResult
    static func requestInputMonitoringPermission() -> Bool {
        CGRequestListenEventAccess()
    }

    /// Posts the same HID-level key events as Shift-Command-3. This is only
    /// invoked by the opt-in `--verify-shortcut` launch diagnostic.
    @discardableResult
    static func postVerificationShortcut() -> Bool {
        guard CGPreflightPostEventAccess(),
              let source = CGEventSource(stateID: .hidSystemState),
              let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 20, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 20, keyDown: false) else {
            return false
        }

        let flags: CGEventFlags = [.maskCommand, .maskShift]
        keyDown.flags = flags
        keyUp.flags = flags
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
        return true
    }

    var isRunning: Bool {
        eventTap != nil
    }

    func start() -> Bool {
        stop()

        let eventMask = (CGEventMask(1) << CGEventType.keyDown.rawValue)
            | (CGEventMask(1) << CGEventType.keyUp.rawValue)
        let pointer = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: Self.eventCallback,
            userInfo: pointer
        ) else {
            return false
        }

        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) else {
            CGEvent.tapEnable(tap: tap, enable: false)
            return false
        }

        eventTap = tap
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    func stop() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        runLoopSource = nil
        eventTap = nil
    }

    private func trigger(forceClipboard: Bool) {
        handler(forceClipboard)
    }

    private func reenableAfterSystemDisable() {
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: true)
        }
    }

    private nonisolated static let eventCallback: CGEventTapCallBack = { proxy, type, event, userInfo in
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let userInfo {
                let address = UInt(bitPattern: userInfo)
                DispatchQueue.main.async { @MainActor in
                    guard let pointer = UnsafeMutableRawPointer(bitPattern: address) else { return }
                    let controller = Unmanaged<GlobalShortcutController>
                        .fromOpaque(pointer)
                        .takeUnretainedValue()
                    controller.reenableAfterSystemDisable()
                }
            }
            return Unmanaged.passUnretained(event)
        }

        guard type == .keyDown || type == .keyUp,
              let userInfo,
              isSystemScreenshotShortcut(event) else {
            return Unmanaged.passUnretained(event)
        }

        if type == .keyDown,
           event.getIntegerValueField(.keyboardEventAutorepeat) == 0 {
            let forceClipboard = ScreenshotShortcutMatcher.forcesClipboard(flags: event.flags)
            let address = UInt(bitPattern: userInfo)
            DispatchQueue.main.async { @MainActor in
                guard let pointer = UnsafeMutableRawPointer(bitPattern: address) else { return }
                let controller = Unmanaged<GlobalShortcutController>
                    .fromOpaque(pointer)
                    .takeUnretainedValue()
                controller.trigger(forceClipboard: forceClipboard)
            }
        }

        // Suppress both key-down and key-up so the built-in multi-display capture does not run.
        return nil
    }

    private nonisolated static func isSystemScreenshotShortcut(_ event: CGEvent) -> Bool {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        return ScreenshotShortcutMatcher.matches(keyCode: keyCode, flags: event.flags)
    }
}
