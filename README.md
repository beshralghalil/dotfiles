# Dotfiles

My personal dotfiles managed with GNU Stow.

## Included Applications

| Category     | Application | Notes                 | Dependencies                                                                        |
| ------------ | ----------- | --------------------- | ----------------------------------------------------------------------------------- |
| Cleanup      | sh,systemd  | dev-cache-cleanup script    |                                                                               |
| Terminal     | Kitty       | Terminal emulator     | Nerd Font                                                                           |
| Shell        | Zsh         | Interactive shell     | `zsh`, `oh-my-zsh` submodule                                                        |
| Editor       | Doom Emacs  | Emacs configuration   | Emacs, Git, Ripgrep, fd, Nerd Font                                                  |
| PDF Viewer   | Zathura     | Minimal PDF viewer    | `zathura`, PDF backend (`zathura-pdf-poppler` or equivalent)                        |
| PDF Viewer   | Sioyek      | Research-paper PDF viewer (sepia / dark mode toggles) | `sioyek`                                        |
| File Manager | Yazi        | Terminal file manager, configured for openners: mpv (audio, video), zathura (pdf) | `ffmpegthumbnailer`, `p7zip`, `jq`, `poppler`, `fd`, `ripgrep`, `fzf` (recommended) |
| Desktop      | Hyprland    | Lua config (Hyprland ≥ 0.55), based on JaKooLit's Hyprland-Dots; scripts, hypridle | `hyprland`, `hypridle`, `hyprlock` (lock fallback), `awww`, `wallust`, `grim`, `slurp`, `swappy`, `cliphist`, `brightnessctl`, `jq`, `curl` |
| Shell UI     | Quickshell (`sumi`) | 墨 black-and-white bar (replaces waybar), launcher, menus, session menu, desktop widgets (clock, calendar, music visualizer, weather, stats); inspired by Ryoku | `quickshell` ≥ 0.3, `cava`, JetBrains Mono + Nerd Font, Noto Sans/Serif CJK JP |
| Lock / Login | Quickshell (`sumi-lock`) | qylock "clockwork/orbital" theme (as used by Ryoku) for the lock screen and the greetd login screen, with keyboard layout and battery | `quickshell`, `qt6-5compat`, `greetd` + `cage` (login screen) |
| Menus        | `sumi-menu` | dmenu-style picker used by all scripts (replaces rofi) | the `sumi` shell running |
| Theme        | GTK / Qt    | Graphite-Dark (GTK 3/4, libadwaita), Kvantum GraphiteDark, qt5ct/qt6ct, KDE colour scheme | `kvantum`, `qt5ct`, `qt6ct` |
| Notifications| SwayNC      | Notification centre   | `swaync`                                                                            |
| Colours      | Wallust     | Wallpaper-derived colours (templates incl. Hyprland Lua) | `wallust`                                                         |

## Directory Layout

```text
.
├── dev-cleanup/
├── doom/
├── hypr/
├── kitty/
├── quickshell/      # sumi shell, sumi-lock, overview
├── sioyek/
├── sumi-menu/
├── swaync/
├── theme/           # GTK/Qt/Kvantum/KDE colours + Graphite-Dark
├── wallust/
├── yazi/
├── zathura/
└── zsh/
```

## Prerequisites

* Git
* GNU Stow

Install your package manager's versions of:

* kitty
* zsh
* emacs
* git
* ripgrep
* fd
* yazi
* zathura
* a Nerd Font

Additional optional packages are listed in the table above.

## Installation

Clone the repository:

```sh
cd ~ && git clone --recurse-submodules https://github.com/beshralghalil/dotfiles
cd ~/.dotfiles
```

Stow the desired packages:

```sh
stow kitty
stow zsh
stow doom
stow yazi
stow zathura
stow sioyek
```

Or install everything:

```sh
stow */
```

For dev-cleanup
```sh
stow dev-cleanup
systemctl --user daemon-reload
systemctl --user enable --now dev-cache-cleanup.timer
```

For the Hyprland desktop (sumi):
```sh
stow hypr quickshell sumi-menu swaync wallust theme

# GTK theme (Graphite-Dark is shipped in theme/.themes)
gsettings set org.gnome.desktop.interface gtk-theme 'Graphite-Dark'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
# libadwaita / GTK4 apps read ~/.config/gtk-4.0: link the theme files
for f in assets gtk.css gtk-dark.css; do ln -sf ~/.themes/Graphite-Dark/gtk-4.0/$f ~/.config/gtk-4.0/$f; done

# Dolphin and other KDE apps: pick the colour scheme in their own config
kwriteconfig6 --file dolphinrc --group UiSettings --key ColorScheme GraphiteDark

# Login screen (needs sudo): greetd + cage + Quickshell, same theme as the lock screen.
# Installs missing packages and makes greetd the display manager (replaces SDDM etc.).
~/.config/quickshell/sumi-lock/install-greeter.sh
```

Desktop widgets are configured in `~/.config/sumi/widgets.json` (created on first run, not tracked):
right-click a widget, press `SUPER+ALT+W`, or e.g. set `"weatherCity": "Your City"` for the weather widget.

## Notes

Some applications have optional integrations that improve the experience but are not required. See each application's documentation for additional features and platform-specific packages.
