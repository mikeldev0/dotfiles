# ─── BASIC ALIASES ─────────────────────────────────────
alias ls='lsd --group-directories-first'
alias ll='lsd -lah --group-directories-first'
alias vim='nvim'

# Conditional aliases for Debian/Ubuntu naming quirks
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

# ─── HYTALE SERVER ALIASES ─────────────────────────────
alias hytale-logs='tail -f /home/hytale/logs/$(ls -t /home/hytale/logs/ | grep _server.log | head -n 1)'
alias hytale-attach='screen -r hytale'
alias hytale-status='ps aux | grep HytaleServer'
alias cd-hytale='cd /home/hytale'

# ─── MISC ALIASES ──────────────────────────────────────
alias myip='ip a | grep inet'
alias myippub='curl -s ipinfo.io | jq -r ".ip + \" (\" + .city + ", " + .country + ")\nISP: " + .org + "\nLoc: " + .loc + "\nHostname: " + .hostname + "\nTimezone: " + .timezone"'
alias pingg='ping google.com'
alias alert='notify-send --urgency=low -i terminal "Terminal Finished"'
alias plugins='echo Installed: $(ls -1 "${ZINIT_HOME}/../plugins" 2>/dev/null | sort -u | tr "\n" " ")'

# ─── NEOFETCH ALIAS WITH CUSTOM LOGO ───────────────────
if [[ -f ~/Imágenes/logo.png ]]; then
  alias neofetch='neofetch --jp2a ~/Imágenes/logo.png --size 550 --color_blocks off --disable infobar'
else
  alias neofetch='neofetch --jp2a ~/.dotfiles/zsh/logo.png --size 550 --color_blocks off --disable infobar'
fi
alias neo='openclaw'
# ─── HELP ALIASES ──────────────────────────────────────
alias ayuda='cat ~/.dotfiles/CHEATSHEET.txt'
alias tips='cat ~/.dotfiles/CHEATSHEET.txt'
