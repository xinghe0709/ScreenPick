import SwiftUI

struct DisplayRowView: View {
    let index: Int
    let display: DisplayInfo
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 11) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isSelected ? Color.accentColor.opacity(0.16) : Color.primary.opacity(0.06))
                        .frame(width: 34, height: 28)
                    Image(systemName: display.isBuiltIn ? "laptopcomputer" : "display")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(display.name)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        if display.isMain {
                            Text("主屏")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.12), in: Capsule())
                        }
                    }
                    Text("\(display.kindText) · \(display.resolutionText)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary.opacity(0.45))
            }
            .padding(.horizontal, 9)
            .frame(minHeight: 48)
            .contentShape(Rectangle())
            .background(
                isSelected ? Color.accentColor.opacity(0.08) : Color.clear,
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("屏幕 \(index)，\(display.accessibilitySummary)")
        .accessibilityHint("选择这块屏幕作为截图目标")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
