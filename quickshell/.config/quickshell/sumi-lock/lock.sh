#!/usr/bin/env bash
# 墨 sumi lock screen: qylock's Quickshell lockscreen with the "clockwork/orbital" theme
# (the same theme Ryoku uses, also the greetd login screen: install-greeter.sh).
# Vendored from qylock (github.com/Darkkal44/qylock, GPL-3.0); see LICENSE.
#   lock.sh [theme]      lock now (theme path relative to ./themes, default clockwork/orbital)
# Called by hypridle's lock_cmd (loginctl lock-session / CTRL+ALT+L).

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# only one lock at a time
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/sumi-lock.lock"
flock -n 9 || exit 0

export QML2_IMPORT_PATH="$DIR/imports:${QML2_IMPORT_PATH:-}"
export QML_XHR_ALLOW_FILE_READ=1
export XDG_SESSION_TYPE="${XDG_SESSION_TYPE:-wayland}"
export QS_THEME="${1:-clockwork/orbital}"
export QS_THEME_PATH="$DIR/themes/$QS_THEME"

[ -f "$QS_THEME_PATH/Main.qml" ] || { echo "sumi-lock: theme not found: $QS_THEME_PATH" >&2; exit 1; }

exec quickshell -p "$DIR/lock_shell.qml"
