#!/usr/bin/env bash
# Install the lock screen's "clockwork/orbital" theme as the login screen: a Quickshell greeter for greetd,
# shown by cage, so login and lock look the same. Works on a fresh system; needs sudo.
#   install-greeter.sh           install/update /usr/share/sumi-greeter, configure greetd and enable it
#   install-greeter.sh --remove  remove it and restore the previous /etc/greetd/config.toml
# Keyboard layouts are taken from the running Hyprland, else KB_LAYOUT / KB_OPTIONS, else "us".
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="/usr/share/sumi-greeter"
CONF="/etc/greetd/config.toml"
BACKUP="$CONF.pre-sumi"
PAM="/etc/pam.d/greetd"

if [ "${1:-}" = "--remove" ]; then
    sudo rm -rf "$DEST" /var/cache/sumi-greeter
    if [ -f "$BACKUP" ]; then sudo mv "$BACKUP" "$CONF"; fi
    echo "Removed $DEST and restored $CONF."
    exit 0
fi

# dependencies (Arch: installed with pacman when missing)
need=()
for p in greetd cage quickshell qt6-5compat jq; do
    pacman -Q "$p" >/dev/null 2>&1 || need+=("$p")
done
if [ ${#need[@]} -gt 0 ]; then
    command -v pacman >/dev/null || { echo "missing packages: ${need[*]}" >&2; exit 1; }
    sudo pacman -S --needed "${need[@]}"
fi

# keyboard layouts for cage: same as Hyprland's
layout="${KB_LAYOUT:-us}" options="${KB_OPTIONS:-}"
if command -v hyprctl >/dev/null && hyprctl version >/dev/null 2>&1; then
    layout=$(hyprctl getoption input:kb_layout -j | jq -r '.str // empty'); layout=${layout:-us}
    options=$(hyprctl getoption input:kb_options -j | jq -r '.str // empty')
fi

# greeter files; a cache dir the greeter user can write (Mesa/cage shader cache)
sudo install -d -o greeter -g greeter -m 700 /var/cache/sumi-greeter
sudo rm -rf "$DEST"
sudo mkdir -p "$DEST"
sudo cp -r "$DIR"/{greeter.qml,greeter.sh,session.sh,shim,imports,themes,LICENSE} "$DEST"/
sudo chmod -R a+rX "$DEST"

# greetd: run the greeter in cage on VT1, its output to the journal (not the console)
[ -f "$BACKUP" ] || sudo cp "$CONF" "$BACKUP"
sudo tee "$CONF" >/dev/null <<EOF
# sumi login screen (installed by install-greeter.sh; previous config: $BACKUP)
[terminal]
vt = 1

[default_session]
command = "systemd-cat -t sumi-greeter env XDG_CACHE_HOME=/var/cache/sumi-greeter XKB_DEFAULT_LAYOUT=$layout XKB_DEFAULT_OPTIONS=$options cage -s -d -- $DEST/greeter.sh"
user = "greeter"
EOF

# unlock the gnome-keyring login keyring with the login password ("-" = skipped if not installed)
if ! grep -q pam_gnome_keyring "$PAM"; then
    sudo sed -i -e '/^auth.*system-local-login/a -auth       optional     pam_gnome_keyring.so' \
                -e '/^session.*system-local-login/a -session    optional     pam_gnome_keyring.so auto_start' "$PAM"
fi

# make greetd the display manager (disables any other one)
current=$(basename "$(readlink -f /etc/systemd/system/display-manager.service)" .service)
if [ "$current" != "greetd" ] && [ "$current" != "display-manager" ]; then
    sudo systemctl disable "$current.service"
fi
sudo systemctl enable greetd.service

echo "Installed $DEST (keyboard: $layout${options:+ / $options}); greetd is the display manager."
echo "Greeter logs: journalctl -t sumi-greeter"
