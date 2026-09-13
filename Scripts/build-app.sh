#!/bin/zsh
set -euo pipefail

PROJECT_DIR="${0:A:h:h}"
cd "$PROJECT_DIR"

mkdir -p "$PROJECT_DIR/.build/cache" "$PROJECT_DIR/.build/config" "$PROJECT_DIR/.build/security" "$PROJECT_DIR/.build/clang-cache"
export CLANG_MODULE_CACHE_PATH="$PROJECT_DIR/.build/clang-cache"

if [[ -n "${SCREENPICK_SDKROOT:-}" ]]; then
    export SDKROOT="$SCREENPICK_SDKROOT"
elif [[ -d "/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk" ]]; then
    # Some Command Line Tools releases can leave a newer default SDK paired with
    # an incompatible compiler. The stable 15.4 SDK still supports every API used here.
    export SDKROOT="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"
fi

SWIFTPM_OPTIONS=(
    --disable-sandbox
    --scratch-path "$PROJECT_DIR/.build"
    --cache-path "$PROJECT_DIR/.build/cache"
    --config-path "$PROJECT_DIR/.build/config"
    --security-path "$PROJECT_DIR/.build/security"
)

swift build "${SWIFTPM_OPTIONS[@]}" -c release
BIN_DIR="$(swift build "${SWIFTPM_OPTIONS[@]}" -c release --show-bin-path)"
APP_DIR="$PROJECT_DIR/dist/ScreenPick.app"

mkdir -p "$APP_DIR/Contents/MacOS"
cp "$BIN_DIR/ScreenPick" "$APP_DIR/Contents/MacOS/ScreenPick"
cp "$PROJECT_DIR/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"
chmod 755 "$APP_DIR/Contents/MacOS/ScreenPick"

# Keep the designated requirement stable across local ad-hoc builds. Without an
# explicit requirement, ad-hoc signing falls back to a changing cdhash and macOS
# privacy grants appear enabled while no longer matching the rebuilt executable.
codesign \
    --force \
    --sign - \
    --requirements '=designated => identifier "com.screenpick.macos"' \
    "$APP_DIR"

echo "$APP_DIR"
