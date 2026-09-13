import AppKit
import Combine
import CoreGraphics
import Foundation

@MainActor
final class DisplayStore: ObservableObject {
    enum PermissionState {
        case granted
        case required
    }

    enum Activity: Equatable {
        case idle
        case capturing
        case success(String)
        case failure(String)
    }

    enum ShortcutStatus: Equatable {
        case inactive
        case active
        case needsScreenRecording
        case needsInputMonitoring
        case needsAccessibility
        case unavailable
    }

    @Published private(set) var displays: [DisplayInfo] = []
    @Published var selectedDisplayID: CGDirectDisplayID?
    @Published private(set) var permissionState: PermissionState
    @Published private(set) var activity: Activity = .idle
    @Published private(set) var lastSavedURL: URL?
    @Published private(set) var shortcutStatus: ShortcutStatus = .inactive
    @Published private(set) var interceptSystemShortcut: Bool
    @Published var output: CaptureOutput {
        didSet { UserDefaults.standard.set(output.rawValue, forKey: Self.outputDefaultsKey) }
    }

    private static let outputDefaultsKey = "captureOutput"
    private static let displayDefaultsKey = "selectedDisplayID"
    private static let shortcutDefaultsKey = "interceptSystemScreenshotShortcut"
    // NotificationCenter's Objective-C observer token is safe to tear down from deinit.
    private nonisolated(unsafe) var screenObserver: NSObjectProtocol?
    private nonisolated(unsafe) var activationObserver: NSObjectProtocol?
    private var statusResetTask: Task<Void, Never>?
    private lazy var shortcutController = GlobalShortcutController { [weak self] forceClipboard in
        guard let self else { return }
        Task { @MainActor in
            await self.captureSelected(outputOverride: forceClipboard ? .clipboard : nil)
        }
    }

    init() {
        let savedOutput = UserDefaults.standard.string(forKey: Self.outputDefaultsKey)
        output = CaptureOutput(rawValue: savedOutput ?? "") ?? .both
        permissionState = CaptureService.hasPermission ? .granted : .required
        if UserDefaults.standard.object(forKey: Self.shortcutDefaultsKey) == nil {
            interceptSystemShortcut = true
        } else {
            interceptSystemShortcut = UserDefaults.standard.bool(forKey: Self.shortcutDefaultsKey)
        }
        refreshDisplays()
        refreshShortcutState()

        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshDisplays()
            }
        }


        activationObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshPermissions()
            }
        }
    }

    deinit {
        if let screenObserver {
            NotificationCenter.default.removeObserver(screenObserver)
        }
        if let activationObserver {
            NotificationCenter.default.removeObserver(activationObserver)
        }
        statusResetTask?.cancel()
    }

    var selectedDisplay: DisplayInfo? {
        displays.first { $0.id == selectedDisplayID }
    }

    var menuBarSymbol: String {
        switch activity {
        case .success: "checkmark.rectangle.stack.fill"
        case .failure: "exclamationmark.triangle.fill"
        default: "rectangle.on.rectangle"
        }
    }

    var menuBarAccessibilityLabel: String {
        switch activity {
        case .capturing: "屏选，正在截图"
        case .success(let message): "屏选，\(message)"
        case .failure(let message): "屏选，\(message)"
        case .idle: "屏选，选择要截取的屏幕"
        }
    }

    func select(_ display: DisplayInfo) {
        selectedDisplayID = display.id
        UserDefaults.standard.set(display.id, forKey: Self.displayDefaultsKey)
        if case .failure = activity { activity = .idle }
    }

    func refreshDisplays() {
        let current = DisplayInfo.current()
        displays = current

        if let selectedDisplayID, current.contains(where: { $0.id == selectedDisplayID }) {
            return
        }

        let persisted = UInt32(UserDefaults.standard.integer(forKey: Self.displayDefaultsKey))
        let next = current.first(where: { $0.id == persisted }) ?? current.first(where: \.isMain) ?? current.first
        selectedDisplayID = next?.id
    }

    func requestPermission() {
        let granted = CaptureService.requestPermission() || CaptureService.hasPermission
        permissionState = granted ? .granted : .required
        activity = granted
            ? .success("录屏权限已开启")
            : .failure("请在系统设置中允许录屏权限，然后重新打开屏选")
        scheduleStatusReset()
        refreshShortcutState()
    }

    func setSystemShortcutInterception(_ enabled: Bool) {
        interceptSystemShortcut = enabled
        UserDefaults.standard.set(enabled, forKey: Self.shortcutDefaultsKey)

        if enabled,
           permissionState == .granted,
           !GlobalShortcutController.isAccessibilityTrusted {
            GlobalShortcutController.requestAccessibilityPermission()
        }
        refreshShortcutState()
    }

    func requestAccessibilityPermission() {
        GlobalShortcutController.requestAccessibilityPermission()
        refreshShortcutState()
    }

    func requestInputMonitoringPermission() {
        GlobalShortcutController.requestInputMonitoringPermission()
        refreshShortcutState()
    }

    func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    func openInputMonitoringSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    func refreshPermissions() {
        permissionState = CaptureService.hasPermission ? .granted : .required
        refreshShortcutState()
    }

    func openScreenRecordingSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    func revealLastCapture() {
        guard let lastSavedURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([lastSavedURL])
    }

    func captureSelected(outputOverride: CaptureOutput? = nil) async {
        guard activity != .capturing, let display = selectedDisplay else { return }

        permissionState = CaptureService.hasPermission ? .granted : .required
        guard permissionState == .granted else {
            activity = .failure("请先允许录屏权限")
            refreshShortcutState()
            scheduleStatusReset()
            return
        }

        statusResetTask?.cancel()
        activity = .capturing

        // Close the menu window before the frame is sampled so it is not part of the screenshot.
        NSApp.keyWindow?.orderOut(nil)
        try? await Task.sleep(for: .milliseconds(180))

        do {
            let resolvedOutput = outputOverride ?? output
            let result = try await CaptureService.capture(display: display, output: resolvedOutput)
            lastSavedURL = result.fileURL

            let message: String
            switch resolvedOutput {
            case .clipboard: message = "已复制到剪贴板"
            case .file: message = "已保存到桌面/ScreenPick"
            case .both: message = "已保存并复制"
            }
            activity = .success(message)
            NSSound(named: "Tink")?.play()
        } catch {
            permissionState = CaptureService.hasPermission ? .granted : .required
            refreshShortcutState()
            activity = .failure(error.localizedDescription)
            NSSound.beep()
        }

        scheduleStatusReset()
    }

    private func scheduleStatusReset() {
        statusResetTask?.cancel()
        statusResetTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            self?.activity = .idle
        }
    }

    private func refreshShortcutState() {
        guard interceptSystemShortcut else {
            shortcutController.stop()
            shortcutStatus = .inactive
            return
        }

        guard permissionState == .granted else {
            shortcutController.stop()
            shortcutStatus = .needsScreenRecording
            return
        }

        guard GlobalShortcutController.isInputMonitoringGranted else {
            shortcutController.stop()
            shortcutStatus = .needsInputMonitoring
            return
        }

        guard GlobalShortcutController.isAccessibilityTrusted else {
            shortcutController.stop()
            shortcutStatus = .needsAccessibility
            return
        }

        shortcutStatus = shortcutController.start() ? .active : .unavailable
    }
}
