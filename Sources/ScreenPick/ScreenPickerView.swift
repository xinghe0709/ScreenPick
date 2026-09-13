import AppKit
import SwiftUI

struct ScreenPickerView: View {
    @EnvironmentObject private var store: DisplayStore

    var body: some View {
        VStack(spacing: 0) {
            header

            VStack(spacing: 14) {
                if store.displays.isEmpty {
                    emptyState
                } else {
                    DisplayMapView(
                        displays: store.displays,
                        selectedID: store.selectedDisplayID,
                        onSelect: store.select
                    )

                    displayList
                    outputPicker

                    if store.permissionState == .required {
                        permissionCallout
                    }

                    shortcutSetting

                    activityMessage
                    captureButton
                }
            }
            .padding(14)

            footer
        }
        .frame(width: 376)
        .background(.regularMaterial)
        .onAppear {
            store.refreshDisplays()
            store.refreshPermissions()
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.accentColor)
                    .frame(width: 34, height: 34)
                Image(systemName: "rectangle.on.rectangle.angled")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("屏选")
                    .font(.headline)
                Text(displayCountText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                store.refreshDisplays()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.borderless)
            .help("刷新屏幕列表")
            .accessibilityLabel("刷新屏幕列表")
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 12)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    private var displayCountText: String {
        "已发现 \(store.displays.count) 块屏幕"
    }

    private var displayList: some View {
        ScrollView {
            LazyVStack(spacing: 3) {
                ForEach(Array(store.displays.enumerated()), id: \.element.id) { index, display in
                    DisplayRowView(
                        index: index + 1,
                        display: display,
                        isSelected: display.id == store.selectedDisplayID
                    ) {
                        store.select(display)
                    }
                }
            }
        }
        .frame(height: min(CGFloat(store.displays.count) * 51, 154))
    }

    private var outputPicker: some View {
        HStack(spacing: 12) {
            Text("截图后")
                .font(.subheadline.weight(.medium))
            Picker("截图后", selection: $store.output) {
                ForEach(CaptureOutput.allCases) { output in
                    Text(output.title).tag(output)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }

    private var permissionCallout: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "lock.shield")
                .foregroundStyle(.orange)
                .padding(.top, 1)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("需要录屏权限")
                    .font(.caption.weight(.semibold))
                Text("macOS 要求授权后才能读取屏幕画面。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 6)

            Button("授权") {
                store.requestPermission()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .frame(minHeight: 28)

            Button {
                store.openScreenRecordingSettings()
            } label: {
                Image(systemName: "gear")
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.borderless)
            .help("打开系统设置")
            .accessibilityLabel("打开录屏权限设置")
        }
        .padding(10)
        .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.orange.opacity(0.22), lineWidth: 1)
        }
    }

    private var shortcutSetting: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: Binding(
                get: { store.interceptSystemShortcut },
                set: { enabled in
                    store.setSystemShortcutInterception(enabled)
                }
            )) {
                HStack(spacing: 9) {
                    Image(systemName: "keyboard")
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("接管系统全屏快捷键")
                            .font(.subheadline.weight(.medium))
                        Text("⇧⌘3 只截取当前所选屏幕")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .toggleStyle(.switch)
            .accessibilityLabel("接管系统全屏快捷键")
            .accessibilityHint("开启后，Shift-Command-3 只截取当前所选屏幕")

            shortcutStatus
        }
        .padding(10)
        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    @ViewBuilder
    private var shortcutStatus: some View {
        switch store.shortcutStatus {
        case .inactive:
            EmptyView()
        case .active:
            shortcutStatusRow(
                "快捷键已接管；按住 Control 时仅复制",
                symbol: "checkmark.circle.fill",
                color: .green
            )
        case .needsScreenRecording:
            shortcutStatusRow(
                "授予上方录屏权限后即可接管",
                symbol: "arrow.up.circle",
                color: .orange
            )
        case .needsInputMonitoring:
            HStack(spacing: 8) {
                shortcutStatusRow(
                    "还需要输入监控权限",
                    symbol: "keyboard.badge.ellipsis",
                    color: .orange
                )
                Spacer(minLength: 4)
                Button("授权") {
                    store.requestInputMonitoringPermission()
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .frame(minHeight: 28)
                Button {
                    store.openInputMonitoringSettings()
                } label: {
                    Image(systemName: "gear")
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.borderless)
                .help("打开输入监控设置")
                .accessibilityLabel("打开输入监控设置")
            }
        case .needsAccessibility:
            HStack(spacing: 8) {
                shortcutStatusRow(
                    "还需要辅助功能权限",
                    symbol: "hand.raised.fill",
                    color: .orange
                )
                Spacer(minLength: 4)
                Button("授权") {
                    store.requestAccessibilityPermission()
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .frame(minHeight: 28)
                Button {
                    store.openAccessibilitySettings()
                } label: {
                    Image(systemName: "gear")
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.borderless)
                .help("打开辅助功能设置")
                .accessibilityLabel("打开辅助功能设置")
            }
        case .unavailable:
            shortcutStatusRow(
                "无法接管快捷键，请关闭后重新开启",
                symbol: "exclamationmark.triangle.fill",
                color: .red
            )
        }
    }

    private func shortcutStatusRow(_ text: String, symbol: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .foregroundStyle(color)
                .accessibilityHidden(true)
            Text(text)
                .foregroundStyle(.primary)
        }
        .font(.caption)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var activityMessage: some View {
        switch store.activity {
        case .idle:
            EmptyView()
        case .capturing:
            HStack(spacing: 7) {
                ProgressView().controlSize(.small)
                Text("正在截取所选屏幕…")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
        case .success(let message):
            statusRow(message: message, symbol: "checkmark.circle.fill", color: .green)
        case .failure(let message):
            statusRow(message: message, symbol: "exclamationmark.triangle.fill", color: .red)
        }
    }

    private func statusRow(message: String, symbol: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 7) {
            Image(systemName: symbol)
                .foregroundStyle(color)
            Text(message)
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(.caption)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var captureButton: some View {
        Button {
            Task { await store.captureSelected() }
        } label: {
            HStack(spacing: 7) {
                if store.activity == .capturing {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                } else {
                    Image(systemName: "camera.viewfinder")
                }
                Text(captureButtonTitle)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 24)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(store.selectedDisplay == nil || store.activity == .capturing || store.permissionState == .required)
        .keyboardShortcut(.return, modifiers: .command)
        .help("截取所选屏幕（⌘↩）")
    }

    private var captureButtonTitle: String {
        guard let display = store.selectedDisplay else { return "请选择一块屏幕" }
        return "截取 \(display.name)"
    }

    private var footer: some View {
        HStack(spacing: 12) {
            if store.lastSavedURL != nil {
                Button("在访达中显示") {
                    store.revealLastCapture()
                }
                .buttonStyle(.plain)
            } else {
                Text("文件保存至 桌面/ScreenPick")
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Button("退出") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .keyboardShortcut("q")
        }
        .font(.caption)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .overlay(alignment: .top) {
            Divider()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 9) {
            Image(systemName: "display.trianglebadge.exclamationmark")
                .font(.system(size: 30, weight: .regular))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text("没有检测到可用屏幕")
                .font(.subheadline.weight(.semibold))
            Button("重新检测") {
                store.refreshDisplays()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }
}
