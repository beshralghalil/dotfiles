export PATH=$HOME/bin:/usr/local/bin:$PATH
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

plugins=(
    git
    vi-mode
    archlinux
    zsh-autosuggestions
    zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# Check archlinux plugin commands here
# https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/archlinux

# fastfetch. Will be disabled if above colorscript was chosen to install
#fastfetch -c $HOME/.config/fastfetch/config-compact.jsonc

# Set-up icons for files/directories in terminal using lsd
alias ls='lsd'
alias l='ls -l'
alias la='ls -a'
alias lla='ls -la'
alias lt='ls --tree'
alias so="source $HOME/.zshrc"

# Set-up FZF key bindings (CTRL R for fuzzy history finder)
source <(fzf --zsh)

# ssh fix with kitty
[ "$TERM" = "xterm-kitty" ] && alias ssh="kitty +kitten ssh"

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory

# doom emacs
export PATH=$HOME/.config/emacs/bin:$PATH

# minicom serial UART
alias minicom='minicom -w -t kitty -l -R UTF-8'
eval "$(zoxide init zsh)"
