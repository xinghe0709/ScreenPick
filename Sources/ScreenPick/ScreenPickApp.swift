import AppKit
import SwiftUI

@main
struct ScreenPickApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var displayStore = DisplayStore()

    var body: some Scene {
        MenuBarExtra {
            ScreenPickerView()
                .environmentObject(displayStore)
        } label: {
            Label("屏选", systemImage: displayStore.menuBarSymbol)
                .accessibilityLabel(displayStore.menuBarAccessibilityLabel)
        }
        .menuBarExtraStyle(.window)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var previewWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        if CommandLine.arguments.contains("--preview") {
            showPreviewWindow()
        } else {
            NSApp.setActivationPolicy(.accessory)
        }

        if CommandLine.arguments.contains("--verify-shortcut") {
            Task { @MainActor in
                // Let SwiftUI finish constructing the menu store and installing
                // its event tap before sending the diagnostic shortcut.
                try? await Task.sleep(for: .seconds(1))
                GlobalShortcutController.postVerificationShortcut()
            }
        }
    }

    private func showPreviewWindow() {
        NSApp.setActivationPolicy(.regular)

        let rootView = ScreenPickerView()
            .environmentObject(DisplayStore())
        let hostingView = NSHostingView(rootView: rootView)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 376, height: 1),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "屏选 · 界面预览"
        window.contentView = hostingView
        window.isReleasedWhenClosed = false
        hostingView.layoutSubtreeIfNeeded()
        window.setContentSize(NSSize(width: 376, height: hostingView.fittingSize.height))
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        previewWindow = window
    }
}
