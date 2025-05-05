# ─── NEOFETCH ─────────────────────────────────────────────
neofetch --w3m --color_blocks off --source all --disable infobar

# ─── POWERLEVEL10K INSTANT PROMPT ─────────────────────────
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ─── ZINIT (Plugin manager ligero y moderno) ──────────────
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
if [[ ! -d "$ZINIT_HOME" ]]; then
  mkdir -p "$(dirname "$ZINIT_HOME")"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"

# ─── POWERLEVEL10K ────────────────────────────────────────
zinit ice depth=1; zinit light romkatv/powerlevel10k

# ─── PLUGINS ──────────────────────────────────────────────
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab
zinit light MichaelAquilina/zsh-you-should-use
zinit light hlissner/zsh-autopair
zinit light lukechilds/zsh-better-npm-completion
zinit light changyuheng/zsh-interactive-cd
zinit light zdharma-continuum/history-search-multi-word
zinit light lukechilds/zsh-nvm
# zinit light djui/alias-tips # es como MichaelAquilina/zsh-you-should-use pero más discreto

# ─── SNIPPETS DE OH-MY-ZSH (pero sin cargar OMZ completo) ─
zinit snippet OMZL::git.zsh
zinit snippet OMZP::git
zinit snippet OMZP::sudo
#zinit snippet OMZP::archlinux
zinit snippet OMZP::command-not-found
zinit snippet OMZP::systemd
zinit snippet OMZP::colored-man-pages

# ─── COMPINIT (para completados zsh) ──────────────────────
autoload -Uz compinit && compinit

# ─── KEYBINDINGS ──────────────────────────────────────────
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

# ─── HISTORIA DEL SHELL ──────────────────────────────────
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory sharehistory hist_ignore_space \
       hist_ignore_all_dups hist_save_no_dups \
       hist_ignore_dups hist_find_no_dups

# ─── COMPLETIONS ──────────────────────────────────────────
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# ─── ALIASES ──────────────────────────────────────────────
[[ -f ~/.dotfiles/zsh/aliases.zsh ]] && source ~/.dotfiles/zsh/aliases.zsh

# ─── FUNCIONES ────────────────────────────────────────────
[[ -f ~/.dotfiles/zsh/functions.zsh ]] && source ~/.dotfiles/zsh/functions.zsh

# ─── NVM ──────────────────────────────────────────────────
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"

# ─── PYENV ────────────────────────────────────────────────
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"

# ─── FZF ──────────────────────────────────────────────────
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# ─── ZOXIDE ───────────────────────────────────────────────
eval "$(zoxide init zsh)"

# ─── POWERLEVEL10K CONFIG ─────────────────────────────────
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# ─── EXTRA PATHS ──────────────────────────────────────────
export PATH="$PATH:/opt/mssql-tools/bin:$HOME/.cargo/bin"

# To customize prompt, run `p10k configure` or edit ~/.dotfiles/zsh/.p10k.zsh.
[[ ! -f ~/.dotfiles/zsh/.p10k.zsh ]] || source ~/.dotfiles/zsh/.p10k.zsh
