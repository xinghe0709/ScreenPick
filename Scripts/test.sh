#!/bin/zsh
set -euo pipefail

PROJECT_DIR="${0:A:h:h}"
cd "$PROJECT_DIR"

mkdir -p "$PROJECT_DIR/.build/cache" "$PROJECT_DIR/.build/config" "$PROJECT_DIR/.build/security" "$PROJECT_DIR/.build/clang-cache"
export CLANG_MODULE_CACHE_PATH="$PROJECT_DIR/.build/clang-cache"

if [[ -n "${SCREENPICK_SDKROOT:-}" ]]; then
    export SDKROOT="$SCREENPICK_SDKROOT"
elif [[ -d "/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk" ]]; then
    export SDKROOT="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"
else
    export SDKROOT="$(xcrun --sdk macosx --show-sdk-path)"
fi

swift build \
    --disable-sandbox \
    --scratch-path "$PROJECT_DIR/.build" \
    --cache-path "$PROJECT_DIR/.build/cache" \
    --config-path "$PROJECT_DIR/.build/config" \
    --security-path "$PROJECT_DIR/.build/security"

swiftc \
    -sdk "$SDKROOT" \
    -module-cache-path "$PROJECT_DIR/.build/clang-cache" \
    "$PROJECT_DIR/Sources/ScreenPick/CaptureNaming.swift" \
    "$PROJECT_DIR/Sources/ScreenPick/ScreenshotShortcutMatcher.swift" \
    "$PROJECT_DIR/Tests/ScreenPickTests/CaptureNamingProbe.swift" \
    -o "$PROJECT_DIR/.build/CaptureNamingProbe"

"$PROJECT_DIR/.build/CaptureNamingProbe"
plutil -lint "$PROJECT_DIR/Resources/Info.plist"
zsh -n "$PROJECT_DIR/Scripts/build-app.sh" "$PROJECT_DIR/Scripts/test.sh"
