#!/usr/bin/env bash

# -------------------------
# setup_mint_productividad.sh
# -------------------------
# Instalador "a prueba de fallos" para Linux Mint
# Instala Zsh, Oh-My-Zsh, Starship, plugins, Docker, NVM, Pyenv y utilidades
# -------------------------

set -Eeuo pipefail
trap 'echo -e "\033[0;31m❌ Error en línea $LINENO → $BASH_COMMAND\033[0m"; exit 1' ERR

# Colores
GREEN='\033[0;32m'
NC='\033[0m'

# Funciones
info() {
  echo -e "${GREEN}$1${NC}"
}

append_to_zshrc() {
  local line="$1"
  grep -qxF "$line" "$HOME/.zshrc" || echo "$line" >> "$HOME/.zshrc"
}

info "🔧 Iniciando setup en Linux Mint..."

# 1. Actualizar sistema
info "📦 Actualizando sistema..."
sudo apt update -y > /dev/null 2>&1 && sudo apt upgrade -y > /dev/null 2>&1

# 2. Paquetes esenciales
info "📥 Instalando paquetes base..."
PKGS=(zsh curl git fzf fd-find bat ripgrep htop ncdu docker.io docker-compose tig python3-pip neofetch)
sudo apt install -y "${PKGS[@]}" > /dev/null 2>&1

# Alias fd y bat en Mint
append_to_zshrc "alias fd='fdfind'"
append_to_zshrc "alias bat='batcat'"

# 3. Instalar Zsh y ponerlo como shell por defecto
ZSH_PATH="$(command -v zsh || true)"

if [[ -z "$ZSH_PATH" ]]; then
  info "📥 Instalando Zsh..."
  sudo apt install -y zsh > /dev/null 2>&1
  ZSH_PATH="$(command -v zsh)"
fi

if ! grep -qxF "$ZSH_PATH" /etc/shells; then
  info "➕ Agregando $ZSH_PATH a /etc/shells..."
  echo "$ZSH_PATH" | sudo tee -a /etc/shells > /dev/null
fi

CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"
if [[ "$CURRENT_SHELL" != "$ZSH_PATH" ]]; then
  info "🐚 Cambiando a Zsh como shell por defecto..."
  sudo usermod -s "$ZSH_PATH" "$USER"
  info "✅ Shell cambiado a $ZSH_PATH."
  info "🔄 Reemplazando tu sesión actual por Zsh..."
  exec zsh
else
  info "✅ Zsh ya es tu shell por defecto ($CURRENT_SHELL)."
fi

# 4. Oh My Zsh
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  info "⚙️ Instalando Oh My Zsh..."
  RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" > /dev/null
else
  info "ℹ️ Oh My Zsh ya está instalado."
fi

# 5. Starship prompt
if ! command -v starship &>/dev/null; then
  info "🚀 Instalando Starship prompt..."
  curl -sS https://starship.rs/install.sh | sh -s -- -y > /dev/null
fi
append_to_zshrc 'eval "$(starship init zsh)"'

# 6. Plugins Zsh
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
mkdir -p "$ZSH_CUSTOM/plugins"
if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
  info "🔌 Instalando zsh-autosuggestions..."
  git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions" > /dev/null 2>&1
fi
if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
  info "🔌 Instalando zsh-syntax-highlighting..."
  git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" > /dev/null 2>&1
fi
if ! grep -q zsh-autosuggestions "$HOME/.zshrc"; then
  sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' "$HOME/.zshrc"
fi

# 7. Alias personalizados
info "📝 Añadiendo alias personalizados..."
ALIAS_BLOCK="$(cat <<'EOF'

# --- ALIAS PERSONALIZADOS ---

# Git
alias gs='git status'
alias ga='git add .'
alias gc='git commit -m'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'
alias gm='git merge'
alias gprune='git fetch -p && git branch --merged | grep -v "\*" | xargs -n1 git branch -d'

# Desarrollo
alias serve='php -S localhost:8000'
alias artisan='php artisan'
alias sail='./vendor/bin/sail'
alias dev='npm run dev'
alias build='npm run build'
alias nuxt='npx nuxi dev'

# Docker
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dstop='docker stop $(docker ps -q)'
alias drm='docker rm $(docker ps -aq)'
alias dclean='docker system prune -af'

# Utilidades
alias ll='ls -lah --color=auto'
alias cls='clear'
alias fix-perms='sudo chown -R $USER:$USER . && find . -type f -exec chmod 644 {} \; && find . -type d -exec chmod 755 {} \;'

# Rutas
alias proyectos='cd ~/Proyectos'
alias laravelup='cd ~/Proyectos/mi-laravel && sail up'
alias nuxtup='cd ~/Proyectos/mi-nuxt && npm run dev'

# --- FIN ALIAS PERSONALIZADOS ---

EOF
)"
append_to_zshrc "$ALIAS_BLOCK"

# 8. Docker config
info "🐳 Configurando Docker..."
sudo systemctl enable --now docker > /dev/null 2>&1
getent group docker >/dev/null || sudo groupadd docker > /dev/null
sudo usermod -aG docker "$USER"

# 9. NVM
if [[ ! -d "$HOME/.nvm" ]]; then
  info "📦 Instalando NVM..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash > /dev/null
fi
append_to_zshrc '# NVM config'
append_to_zshrc 'export NVM_DIR="$HOME/.nvm"'
append_to_zshrc '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"'

# 10. Pyenv
if [[ ! -d "$HOME/.pyenv" ]]; then
  info "🐍 Instalando Pyenv..."
  curl https://pyenv.run | bash > /dev/null
fi
append_to_zshrc '# Pyenv config'
append_to_zshrc 'export PYENV_ROOT="$HOME/.pyenv"'
append_to_zshrc 'export PATH="$PYENV_ROOT/bin:$PATH"'
append_to_zshrc 'eval "$(pyenv init --path)"'
append_to_zshrc 'eval "$(pyenv init -)"'
append_to_zshrc '# Neofetch'
append_to_zshrc 'neofetch'

info "✅ Listo! Reinicia sesión o ejecuta: exec zsh"
