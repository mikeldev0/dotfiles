\#!/usr/bin/env bash

# -----------------------------------------------------------------------------

# setup\_mint\_productividad.sh – Instalador "a prueba de fallos" para Linux Mint

# -----------------------------------------------------------------------------

# Instala Zsh, Oh‑My‑Zsh, Starship, plugins, Docker, NVM, Pyenv y utilidades

# con control estricto de errores y sin duplicar configuraciones en \~/.zshrc.

# -----------------------------------------------------------------------------

set -Eeuo pipefail                           # Abort on error, undefined var or pipefail
trap 'echo -e "\033\[0;31m❌ Error en la línea \$LINENO → \$BASH\_COMMAND\033\[0m"; exit 1' ERR

GREEN='\033\[0;32m'
NC='\033\[0m'

info() { echo -e "\${GREEN}\$1\${NC}"; }
append\_to\_zshrc() { grep -qxF "\$1" "\$HOME/.zshrc" || echo "\$1" >> "\$HOME/.zshrc"; }

# -----------------------------------------------------------------------------

info "🔧 Iniciando configuración de entorno productivo en Linux Mint…"

# 1. Actualizaciones del sistema ------------------------------------------------

info "📦 Actualizando sistema (apt update/upgrade)…"
sudo apt update -y && sudo apt upgrade -y

# 2. Paquetes esenciales --------------------------------------------------------

info "📥 Instalando paquetes base…"
PKGS=(zsh curl git fzf fd-find bat ripgrep htop ncdu docker.io docker-compose tig python3-pip)
sudo apt install -y "\${PKGS\[@]}"

# Mint llama fd-find y batcat ---------------------------------------------------

append\_to\_zshrc "alias fd='fdfind'"
append\_to\_zshrc "alias bat='batcat'"

# 3. Cambiar shell a Zsh ---------------------------------------------------------

if \[\[ "\$SHELL" != "\$(command -v zsh)" ]]; then
info "🐚 Estableciendo Zsh como shell por defecto…"
chsh -s "\$(command -v zsh)"
else
info "✅ Zsh ya es el shell por defecto."
fi

# 4. Oh My Zsh ------------------------------------------------------------------

if \[\[ ! -d "\$HOME/.oh-my-zsh" ]]; then
info "⚙️ Instalando Oh My Zsh…"
RUNZSH=no sh -c "\$(curl -fsSL [https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh](https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh))"
else
info "ℹ️ Oh My Zsh ya estaba instalado."
fi

# 5. Starship --------------------------------------------------------------------

if ! command -v starship &>/dev/null; then
info "🚀 Instalando Starship prompt…"
curl -sS [https://starship.rs/install.sh](https://starship.rs/install.sh) | sh -s -- -y
fi
append\_to\_zshrc 'eval "\$(starship init zsh)"'

# 6. Plugins de Zsh --------------------------------------------------------------

ZSH\_CUSTOM="\${ZSH\_CUSTOM:-\$HOME/.oh-my-zsh/custom}"
\[\[ -d "\$ZSH\_CUSTOM/plugins" ]] || mkdir -p "\$ZSH\_CUSTOM/plugins"
\[\[ -d "\$ZSH\_CUSTOM/plugins/zsh-autosuggestions" ]] || git clone --depth 1 [https://github.com/zsh-users/zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) "\$ZSH\_CUSTOM/plugins/zsh-autosuggestions"
\[\[ -d "\$ZSH\_CUSTOM/plugins/zsh-syntax-highlighting" ]] || git clone --depth 1 [https://github.com/zsh-users/zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) "\$ZSH\_CUSTOM/plugins/zsh-syntax-highlighting"

if ! grep -q "zsh-autosuggestions" "\$HOME/.zshrc"; then
sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' "\$HOME/.zshrc"
fi

# 7. Alias personalizados --------------------------------------------------------

read -r -d '' ALIAS\_BLOCK <<'EOF'

# --- ALIAS PERSONALIZADOS (añadido por setup\_mint\_productividad) ---

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
alias gprune='git fetch -p && git branch --merged | grep -v "\*" | xargs -n 1 git branch -d'

# Desarrollo

alias serve='php -S localhost:8000'
alias artisan='php artisan'
alias sail='./vendor/bin/sail'
alias dev='npm run dev'
alias build='npm run build'
alias nuxt='npx nuxi dev'

# Docker

alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dstop='docker stop \$(docker ps -q)'
alias drm='docker rm \$(docker ps -aq)'
alias dclean='docker system prune -af'

# Utilidades

alias ll='ls -lah --color=auto'
alias cls='clear'
alias fix-perms='sudo chown -R \$USER:\$USER . && find . -type f -exec chmod 644 {} ; && find . -type d -exec chmod 755 {} ;'

# Rutas

alias proyectos='cd \~/Proyectos'
alias laravelup='cd \~/Proyectos/mi-laravel && sail up'
alias nuxtup='cd \~/Proyectos/mi-nuxt && npm run dev'

# --- FIN ALIAS PERSONALIZADOS ---

EOF
append\_to\_zshrc "\$ALIAS\_BLOCK"

# 8. Docker ----------------------------------------------------------------------

info "🐳 Configurando Docker (grupo y arranque)…"
sudo systemctl enable --now docker
getent group docker >/dev/null || sudo groupadd docker
sudo usermod -aG docker "\$USER"

# 9. NVM -------------------------------------------------------------------------

if \[\[ ! -d "\$HOME/.nvm" ]]; then
info "📦 Instalando NVM…"
curl -o- [https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh](https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh) | bash
fi
append\_to\_zshrc '

# NVM config

export NVM\_DIR="\$HOME/.nvm"
\[ -s "\$NVM\_DIR/nvm.sh" ] && . "\$NVM\_DIR/nvm.sh"'

# 10. Pyenv ----------------------------------------------------------------------

if \[\[ ! -d "\$HOME/.pyenv" ]]; then
info "🐍 Instalando pyenv…"
curl [https://pyenv.run](https://pyenv.run) | bash
fi
append\_to\_zshrc '

# pyenv config

export PYENV\_ROOT="\$HOME/.pyenv"
export PATH="\$PYENV\_ROOT/bin:\$PATH"
eval "\$(pyenv init --path)"
eval "\$(pyenv init -)"'

# -----------------------------------------------------------------------------

info "✅ Listo. Reinicia la sesión o ejecuta: exec zsh"
