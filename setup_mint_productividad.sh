#!/usr/bin/env bash
# Linux Mint — Terminal bootstrap script
# Author: Mikel
# Purpose: Idempotent, minimal‑noise development environment provisioner.

set -Eeuo pipefail
IFS=$'\n\t'

trap 'echo -e "\033[0;31m❌ Error en línea $LINENO. Consulta el registro.\033[0m" >&2' ERR

log() { printf "\033[0;32m%s\033[0m\n" "$*"; }
append_line() {
  local file=$1 line=$2
  grep -qxF "$line" "$file" || printf '%s\n' "$line" >>"$file"
}

log "🔧 Iniciando setup en Linux Mint…"

export DEBIAN_FRONTEND=noninteractive

log "📦 Actualizando sistema…"
sudo apt update -y -qq > /dev/null
sudo apt upgrade -y -qq > /dev/null

log "📥 Instalando paquetes base…"
PKGS=(
  zsh curl git fzf fd-find bat ripgrep htop ncdu docker.io docker-compose
  tig python3-pip neofetch unzip lsd tree jq rename net-tools nmap
  xclip wl-clipboard zoxide
)
sudo apt install -y -qq --no-install-recommends "${PKGS[@]}" > /dev/null

#─── Dotfiles ────────────────────────────────────────────────────────────

touch "$HOME/.zshrc"

#─── Oh My Zsh ───────────────────────────────────────────────────────────

if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  log "⚙️  Instalando Oh‑My‑Zsh…"
  RUNZSH=no CHSH=no sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" >/dev/null 2>&1
fi

# Copia la plantilla sólo la primera vez
test -s "$HOME/.zshrc" || cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$HOME/.zshrc"

#─── Tema ────────────────────────────────────────────────────────────────

if [[ ! -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]]; then
  log "✨ Instalando Powerlevel10k…"
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" >/dev/null 2>&1
fi
sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$HOME/.zshrc"

#─── Plugins ──────────────────────────────────────────────────────────────

ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}
declare -A REPOS=(
  [zsh-autosuggestions]=https://github.com/zsh-users/zsh-autosuggestions
  [zsh-syntax-highlighting]=https://github.com/zsh-users/zsh-syntax-highlighting
  [zsh-completions]=https://github.com/zsh-users/zsh-completions
  [history-substring-search]=https://github.com/zsh-users/zsh-history-substring-search
)
for p in "${!REPOS[@]}"; do
  [[ -d "$ZSH_CUSTOM/plugins/$p" ]] || {
    log "🔌 Instalando plugin: $p…"
    git clone --depth=1 "${REPOS[$p]}" "$ZSH_CUSTOM/plugins/$p" >/dev/null 2>&1
  }
done

# Instalación de bindings de fzf (provee completado y Ctrl‑T)
FZF_INSTALL_SCRIPT="$(dpkg -L fzf | grep -m1 install || true)"
if [[ -x "$FZF_INSTALL_SCRIPT" ]]; then
  "$FZF_INSTALL_SCRIPT" --key-bindings --completion --no-update-rc >/dev/null 2>&1
fi

# Lista de plugins (idempotente)
PLUGIN_LINE='plugins=(git fzf zsh-autosuggestions zsh-syntax-highlighting zsh-completions history-substring-search zoxide)'
if grep -q '^plugins=' "$HOME/.zshrc"; then
  sed -i "s/^plugins=.*/$PLUGIN_LINE/" "$HOME/.zshrc"
else
  append_line "$HOME/.zshrc" "$PLUGIN_LINE"
fi

#─── Aliases & helpers ────────────────────────────────────────────────────

append_line "$HOME/.zshrc" "alias fd='fdfind'"
append_line "$HOME/.zshrc" "alias bat='batcat'"
append_line "$HOME/.zshrc" "alias ls='lsd -lah'"
append_line "$HOME/.zshrc" 'export PATH="$HOME/.local/bin:$PATH"'
append_line "$HOME/.zshrc" 'eval "$(zoxide init zsh)"'

# extract() helper
extract_f='extract() { [[ -f "$1" ]] || { echo "Archivo no encontrado: $1" >&2; return 1; }; case "$1" in *.tar.bz2) tar xjf "$1";; *.tar.gz) tar xzf "$1";; *.bz2) bunzip2 "$1";; *.rar) unrar x "$1";; *.gz) gunzip "$1";; *.tar) tar xf "$1";; *.tbz2) tar xjf "$1";; *.tgz) tar xzf "$1";; *.zip) unzip "$1";; *) echo "Formato no soportado: $1";; esac }'
append_line "$HOME/.zshrc" "$extract_f"

# Git & utilidades
for a in \
  "alias gs='git status'" "alias ga='git add .'" "alias gc='git commit -m'" \
  "alias gp='git push'" "alias gl='git log --oneline --graph --decorate'" \
  "alias gd='git diff'" "alias cls='clear'" "alias src='source ~/.zshrc'"; do
  append_line "$HOME/.zshrc" "$a"
done

#─── Docker ───────────────────────────────────────────────────────────────

log "🐳 Configurando Docker…"
sudo systemctl enable --now docker >/dev/null 2>&1
sudo usermod -aG docker "$USER" || true

#─── NVM ───────────────────────────────────────────────────────────────────

if [[ ! -d "$HOME/.nvm" ]]; then
  log "📦 Instalando NVM…"
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash >/dev/null 2>&1
fi
append_line "$HOME/.zshrc" 'export NVM_DIR="$HOME/.nvm"'
append_line "$HOME/.zshrc" '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"'

#─── Pyenv ────────────────────────────────────────────────────────────────

if [[ ! -d "$HOME/.pyenv" ]]; then
  log "🐍 Instalando Pyenv…"
  curl https://pyenv.run | bash >/dev/null 2>&1
fi
append_line "$HOME/.zshrc" 'export PYENV_ROOT="$HOME/.pyenv"'
append_line "$HOME/.zshrc" 'export PATH="$PYENV_ROOT/bin:$PATH"'
append_line "$HOME/.zshrc" 'eval "$(pyenv init --path)"'
append_line "$HOME/.zshrc" 'eval "$(pyenv init -)"'

#─── Nerd Font ────────────────────────────────────────────────────────────

log "🔤 Instalando Hack Nerd Font…"
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"
curl -Lf --retry 3 -o "/tmp/Hack.zip" \
  https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip >/dev/null 2>&1
unzip -qo "/tmp/Hack.zip" -d "$FONT_DIR"
fc-cache -f >/dev/null 2>&1

#─── Shell predeterminada ─────────────────────────────────────────────────

ZSH_PATH=$(command -v zsh)
if ! grep -qxF "$ZSH_PATH" /etc/shells; then
  echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
fi
[[ "$(getent passwd "$USER" | cut -d: -f7)" == "$ZSH_PATH" ]] || chsh -s "$ZSH_PATH"

#─── Limpieza ─────────────────────────────────────────────────────────────

log "🧹 Limpiando cachés…"
rm -f "$HOME/.zcompdump*" /tmp/Hack.zip

log "✅ ¡Terminal lista! Ejecuta: exec zsh (o reinicia sesión) para aplicar cambios."