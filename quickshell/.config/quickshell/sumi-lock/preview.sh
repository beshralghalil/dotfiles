#!/usr/bin/env bash
# Preview the lock screen in a normal 1280x720 window WITHOUT locking the session.
# Close the window (or enter your password) to quit.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export QML2_IMPORT_PATH="$DIR/imports:${QML2_IMPORT_PATH:-}"
export QML_XHR_ALLOW_FILE_READ=1
export XDG_SESSION_TYPE=x11   # x11 path in lock_shell.qml = plain window, no session lock
export QS_TESTING=1
export QS_THEME="${1:-clockwork/orbital}"
export QS_THEME_PATH="$DIR/themes/$QS_THEME"
exec quickshell -p "$DIR/lock_shell.qml"
