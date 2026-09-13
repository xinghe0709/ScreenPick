# ScreenPick Design System

## Direction

ScreenPick behaves like a compact display-routing instrument. The screen topology is the hero and the control: connected displays appear in their real relative positions, and the selected display is reinforced by tint, border weight, a checkmark, and matching detail text.

## Surface

- Native macOS menu-bar extra using a window-style presentation.
- 376-point fixed-width panel with content that grows only for the display list.
- System materials and vibrancy are functional here: the app is a transient menu-bar surface, not a decorative glass panel.

## Color

- Use the user's macOS accent color for selection and the main action.
- Use semantic system background, separator, primary, secondary, green, orange, and red colors.
- Every status and selection state has a non-color cue.

## Typography

- San Francisco through native SwiftUI text styles.
- `.headline` for the product name, `.subheadline` for display names, `.caption` for metadata and status.
- Monospaced digits only for pixel dimensions where column stability is useful.

## Components

- Display map: proportional, spatially registered screen outlines; each outline is a button.
- Display row: one compact selection row per connected display with icon, name, type, resolution, and main-display tag.
- Output picker: a native segmented picker for clipboard, file, or both.
- Shortcut handoff: a compact switch that explains how `Shift-Command-3` changes and exposes the exact permission recovery action inline.
- Capture action: a full-width prominent button whose label names the selected display.
- Permission recovery: an inline semantic callout with a direct Settings action.

## Motion

Display topology changes animate once with a short ease-out. Capture progress uses the native progress indicator; completion changes the menu-bar symbol briefly rather than reopening the closed panel.

## Accessibility

- Minimum 28-point row targets and a 36-point primary action.
- VoiceOver descriptions identify display name, resolution, built-in/external status, and selection.
- All actions are reachable by keyboard; Command-Return captures while the panel is focused.
