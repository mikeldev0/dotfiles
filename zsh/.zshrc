# ─── POWERLEVEL10K INSTANT PROMPT ─────────────────────────
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ─── ZINIT (gestor de plugins) ────────────────────────────
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
if [[ ! -d "$ZINIT_HOME" ]]; then
  mkdir -p "$(dirname "$ZINIT_HOME")"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"
unalias zi 2>/dev/null

# ─── POWERLEVEL10K (tema de prompt) ───────────────────────
zinit ice depth=1; zinit light romkatv/powerlevel10k

# ─── PLUGINS ──────────────────────────────────────────────
zinit wait lucid for \
  zsh-users/zsh-syntax-highlighting \
  zsh-users/zsh-completions \
  zsh-users/zsh-autosuggestions \
  Aloxaf/fzf-tab \
  MichaelAquilina/zsh-you-should-use \
  hlissner/zsh-autopair \
  lukechilds/zsh-better-npm-completion \
  changyuheng/zsh-interactive-cd \
  zdharma-continuum/history-search-multi-word \
  lukechilds/zsh-nvm

# ─── SNIPPETS OH-MY-ZSH (sin cargar OMZ completo) ─────────
zinit snippet OMZL::git.zsh
zinit snippet OMZP::git
zinit snippet OMZP::sudo
#zinit snippet OMZP::archlinux
zinit snippet OMZP::command-not-found
zinit snippet OMZP::systemd
zinit snippet OMZP::colored-man-pages

# ─── ZOXIDE (cd mejorado con fzf) ─────────────────────────
zinit light ajeetdsouza/zoxide
eval "$(zoxide init zsh)"

# ─── FZF (búsqueda rápida en ficheros/carpetas) ───────────
zinit light junegunn/fzf
zinit snippet https://github.com/junegunn/fzf/blob/master/shell/key-bindings.zsh
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'

# ─── PYENV (versiones de Python) ──────────────────────────
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
command -v pyenv &>/dev/null && {
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
}

# ─── NVM (versiones de Node.js, ya gestionado por plugin) ─
export NVM_DIR="$HOME/.nvm"

# ─── COMPINIT (completado inteligente) ────────────────────
autoload -Uz compinit && compinit -C

# ─── COMPLETIONS Y FZF-TAB ────────────────────────────────
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# ─── KEYBINDINGS (atajos de teclado) ──────────────────────
bindkey -e                          # modo emacs
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

# ─── HISTORIA DEL SHELL ──────────────────────────────────
HISTSIZE=5000
SAVEHIST=$HISTSIZE
export HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
mkdir -p "$(dirname "$HISTFILE")"
touch "$HISTFILE"

setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# ─── NEOFETCH (solo si terminal interactiva) ──────────────
alias neofetch='neofetch --jp2a ~/Imágenes/codetec.png --size 550 --color_blocks off --disable infobar'
neofetch

# ─── ALIASES ──────────────────────────────────────────────
[[ -f ~/.dotfiles/zsh/aliases.zsh ]] && source ~/.dotfiles/zsh/aliases.zsh

# ─── FUNCIONES ────────────────────────────────────────────
[[ -f ~/.dotfiles/zsh/functions.zsh ]] && source ~/.dotfiles/zsh/functions.zsh

# ─── EXTRA PATHS ──────────────────────────────────────────
export PATH="${PATH:+$PATH:}/opt/mssql-tools/bin:$HOME/.cargo/bin"

# ─── POWERLEVEL10K CONFIG ─────────────────────────────────
[[ -f ~/.dotfiles/zsh/.p10k.zsh ]] && source ~/.dotfiles/zsh/.p10k.zsh
