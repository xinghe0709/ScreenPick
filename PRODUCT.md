# Product

<!-- impeccable:product-schema 1 -->

## Platform

macOS

## Stack

Inferred from the requested native macOS menu-bar behavior: Swift 6, SwiftUI, AppKit, ScreenCaptureKit, and Swift Package Manager. No third-party runtime dependencies.

## Users

People who work with a Mac and one or more external displays and need to capture a specific whole display without rearranging windows or remembering display coordinates.

## Product Purpose

Let the user see every currently connected display, select one explicitly, and capture exactly that display from the macOS menu bar.

## Positioning

Screen selection is persistent and spatial: the app mirrors the physical display arrangement in its picker instead of hiding display choice behind a generic screenshot mode.

## Operating Context

The app lives only in the menu bar, reacts to displays being attached or removed, and saves captures to `Desktop/ScreenPick` and/or copies them to the clipboard.

## Capabilities and Constraints

- Capture one complete selected display, including Retina-resolution pixels.
- Optionally intercept the familiar `Shift-Command-3` system-wide shortcut so it captures only the display selected in ScreenPick. `Control-Shift-Command-3` preserves the clipboard-only convention.
- Support built-in, external, rotated, and differently scaled displays.
- Keep the best available selection when display topology changes.
- Require the macOS Screen Recording privacy permission.
- Require Accessibility permission only when system shortcut interception is enabled.
- Target macOS 13 or newer; use ScreenCaptureKit on macOS 14+ and a Core Graphics fallback on macOS 13.

## Evidence on Hand

No supplied brand assets, screenshots, copy deck, or existing implementation. Product requirements come from the user's request.

## Product Principles

- Make the capture target unambiguous before capture.
- Stay instantly available without occupying the Dock.
- Respect native macOS behavior, appearance, keyboard access, and privacy.
- Fail with a concrete recovery action when permission is missing.

## Accessibility & Inclusion

Use native controls, VoiceOver labels, keyboard focus, light/dark appearance, and text that does not rely on color alone.
