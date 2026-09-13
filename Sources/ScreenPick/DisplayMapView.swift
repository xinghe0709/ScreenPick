import SwiftUI

struct DisplayMapView: View {
    let displays: [DisplayInfo]
    let selectedID: DisplayInfo.ID?
    let onSelect: (DisplayInfo) -> Void

    private var displayBounds: CGRect {
        displays.reduce(.null) { partial, display in
            partial.union(display.frame)
        }
    }

    var body: some View {
        GeometryReader { proxy in
            let bounds = displayBounds
            let inset: CGFloat = 14
            let available = CGSize(
                width: max(1, proxy.size.width - inset * 2),
                height: max(1, proxy.size.height - inset * 2)
            )
            let scale = min(
                available.width / max(bounds.width, 1),
                available.height / max(bounds.height, 1)
            )
            let contentSize = CGSize(width: bounds.width * scale, height: bounds.height * scale)
            let origin = CGPoint(
                x: (proxy.size.width - contentSize.width) / 2,
                y: (proxy.size.height - contentSize.height) / 2
            )

            ZStack(alignment: .topLeading) {
                ForEach(Array(displays.enumerated()), id: \.element.id) { index, display in
                    let isSelected = display.id == selectedID
                    let width = max(48, display.frame.width * scale)
                    let height = max(30, display.frame.height * scale)
                    let x = origin.x + (display.frame.minX - bounds.minX) * scale
                    let y = origin.y + (bounds.maxY - display.frame.maxY) * scale

                    Button {
                        onSelect(display)
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(isSelected ? Color.accentColor.opacity(0.18) : Color.primary.opacity(0.045))

                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .stroke(
                                    isSelected ? Color.accentColor : Color.secondary.opacity(0.5),
                                    lineWidth: isSelected ? 2 : 1
                                )

                            VStack(spacing: 2) {
                                Image(systemName: display.isBuiltIn ? "laptopcomputer" : "display")
                                    .font(.system(size: min(18, height * 0.28), weight: .medium))
                                Text("\(index + 1)")
                                    .font(.caption2.weight(.semibold))
                            }
                            .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)

                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(Color.accentColor, Color(nsColor: .windowBackgroundColor))
                                    .padding(5)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                            }
                        }
                        .frame(width: width, height: height)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .position(x: x + width / 2, y: y + height / 2)
                    .accessibilityLabel(display.accessibilitySummary)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .animation(.easeOut(duration: 0.22), value: displays)
            .animation(.easeOut(duration: 0.16), value: selectedID)
        }
        .frame(height: 116)
        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.secondary.opacity(0.16), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("屏幕布局")
    }
}
