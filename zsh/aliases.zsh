# ─── BASIC ALIASES ─────────────────────────────────────
alias ls='lsd --group-directories-first'
alias ll='lsd -lah --group-directories-first'
alias vim='nvim'

if command -v fdfind &>/dev/null; then
  alias fd='fdfind'
fi
if command -v batcat &>/dev/null; then
  alias bat='batcat'
fi

alias cls='clear'
alias md='mkdir -p'
alias src='source ~/.zshrc'
alias c='gh copilot'
alias ce='gh copilot explain'
alias cs='gh copilot suggest'

# ─── GIT ALIASES ───────────────────────────────────────
alias gs='git status'
alias ga='git add .'
alias gc='git commit -m'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'
alias gd='git diff'

# ─── MISC ALIASES ──────────────────────────────────────
alias myip="hostname -I | awk '{print \$1}'"
alias myippub='curl -s https://ipinfo.io | jq -r "\"IP: \" + .ip + \" (\" + .city + \", \" + .country + \")\nISP: \" + .org + \"\nLoc: \" + .loc + \"\nHostname: \" + .hostname + \"\nTimezone: \" + .timezone"'
alias pingg='ping google.com'
alias alert='notify-send --urgency=low -i terminal "Terminal Finished"'

# ─── HELP ALIASES ──────────────────────────────────────
alias ayuda='cat ~/.dotfiles/CHEATSHEET.txt'
alias tips='cat ~/.dotfiles/CHEATSHEET.txt'

# ─── NEOFETCH ALIAS ────────────────────────────────────
alias neofetch='neofetch --jp2a ~/.dotfiles/zsh/logo.png --size 550 --color_blocks off --disable infobar'
alias neo='openclaw'
