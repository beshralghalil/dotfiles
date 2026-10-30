#!/usr/bin/env bash
# 墨 sumi login screen for greetd: the lock screen's theme in Quickshell, shown by cage.
# greetd runs it as the greeter user (see install-greeter.sh):  cage -s -d -- <install dir>/greeter.sh
# Without GREETD_SOCK (e.g. a test run) it shows the screen but cannot log in.

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export QML2_IMPORT_PATH="$DIR/imports:${QML2_IMPORT_PATH:-}"
export QML_XHR_ALLOW_FILE_READ=1
export QS_THEME_PATH="$DIR/themes/${SUMI_THEME:-clockwork/orbital}"

# the greeter user has no home directory: cache in /var/cache/sumi-greeter (set by greetd's
# config, see install-greeter.sh), state/data in the runtime dir
RUN="${XDG_RUNTIME_DIR:-/tmp}/sumi-greeter"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$RUN/cache}" XDG_STATE_HOME="$RUN/state" XDG_DATA_HOME="$RUN/data"

exec quickshell -p "$DIR/greeter.qml"
