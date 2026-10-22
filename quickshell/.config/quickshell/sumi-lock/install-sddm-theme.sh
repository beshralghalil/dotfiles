#!/usr/bin/env bash
# Install the lock screen's "clockwork/orbital" theme (qylock, as used by Ryoku) as the
# SDDM login theme, so login and lock look the same. Needs sudo.
#   install-sddm-theme.sh          install + activate
#   install-sddm-theme.sh --remove remove + go back to SDDM's default theme
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$DIR/themes/clockwork/orbital"
NAME="sumi-orbital"
DEST="/usr/share/sddm/themes/$NAME"
CONF="/etc/sddm.conf.d/10-sumi-theme.conf"

if [ "${1:-}" = "--remove" ]; then
    sudo rm -rf "$DEST" "$CONF"
    echo "Removed $NAME; SDDM will use its default theme."
    exit 0
fi

[ -f "$SRC/Main.qml" ] || { echo "theme not found: $SRC" >&2; exit 1; }

sudo mkdir -p /usr/share/sddm/themes /etc/sddm.conf.d
sudo rm -rf "$DEST"
sudo cp -r "$SRC" "$DEST"
sudo cp "$DIR/LICENSE" "$DEST/LICENSE"
printf '[Theme]\nCurrent=%s\n' "$NAME" | sudo tee "$CONF" >/dev/null

echo "Installed $NAME to $DEST and set it in $CONF."
echo "Preview without logging out:  sddm-greeter-qt6 --test-mode --theme $DEST"
