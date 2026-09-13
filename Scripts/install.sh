#!/bin/zsh
set -euo pipefail

PROJECT_DIR="${0:A:h:h}"
APP_SOURCE="$PROJECT_DIR/dist/ScreenPick.app"
APP_DEST="/Applications/ScreenPick.app"

"$PROJECT_DIR/Scripts/build-app.sh"

if [[ ! -d "$APP_SOURCE" ]]; then
    print -u2 "构建失败：没有找到 $APP_SOURCE"
    exit 1
fi

if ! /usr/bin/ditto "$APP_SOURCE" "$APP_DEST"; then
    print -u2 "无法写入 /Applications，请检查权限后重试。"
    exit 1
fi

/usr/bin/open "$APP_DEST"
print "已安装并打开：$APP_DEST"
