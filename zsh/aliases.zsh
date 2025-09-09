# ─── ALIASES BÁSICOS ─────────────────────────────────────
alias ls='lsd --group-directories-first'
alias ll='lsd -lah --group-directories-first'
alias vim='nvim'
alias fd='fdfind'
alias bat='batcat'
alias cls='clear'
alias md='mkdir -p'
alias vim='nvim'
alias src='source ~/.zshrc'
alias c='gh copilot'
alias ce='gh copilot explain'
alias cs='gh copilot suggest'

# ─── ALIASES GIT ──────────────────────────────────────────
alias gs='git status'
alias ga='git add .'
alias gc='git commit -m'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'
alias gd='git diff'

# ─── ALIASES VARIOS ───────────────────────────────────────
alias myip='ip a | grep inet'
alias myippub='curl -s ipinfo.io | jq -r ".ip + \" (\" + .city + \", \" + .country + \")\nISP: \" + .org + \"\nLoc: \" + .loc + \"\nHostname: \" + .hostname + \"\nTimezone: \" + .timezone"'
alias ports='sudo lsof -i -P -n | grep LISTEN'
alias pingg='ping google.com'
alias alert='notify-send --urgency=low -i terminal "Terminal Finished"'
alias plugins='echo Instalados: $(ls -1 "${ZINIT_HOME}/../plugins" 2>/dev/null | sort -u | tr "\n" " ")'
