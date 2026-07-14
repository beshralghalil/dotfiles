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
| File Manager | Yazi        | Terminal file manager, configured for openners: mpv (audio, video), zathura (pdf) | `ffmpegthumbnailer`, `p7zip`, `jq`, `poppler`, `fd`, `ripgrep`, `fzf` (recommended) |

## Directory Layout

```text
.
├── dev-cleanup/
├── doom/
├── kitty/
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
```
```

## Notes

Some applications have optional integrations that improve the experience but are not required. See each application's documentation for additional features and platform-specific packages.
