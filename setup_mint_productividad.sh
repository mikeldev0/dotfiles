#!/usr/bin/env bash
# Linux Mint — Terminal bootstrap script
# Author: Mikel
# Purpose: Idempotent, minimal‑noise development environment provisioner.

set -Eeuo pipefail
IFS=$'\n\t'

trap 'echo -e "\033[0;31m❌ Error en línea $LINENO. Consulta el registro.\033[0m" >&2' ERR

log() { printf "\033[0;32m%s\033[0m\n" "$*"; }

log "🔧 Iniciando setup en Linux Mint…"

export DEBIAN_FRONTEND=noninteractive

log "📦 Actualizando sistema…"
sudo apt update -y -qq > /dev/null 2>/dev/null # Redirigir stderr
sudo apt upgrade -y -qq > /dev/null 2>/dev/null # Redirigir stderr

log "📥 Instalando paquetes base…"
PKGS=(
  zsh curl git fzf fd-find bat ripgrep htop ncdu docker.io docker-compose
  tig python3-pip neofetch unzip lsd tree jq rename net-tools nmap
  xclip wl-clipboard zoxide
)

# Instalar paquetes y mostrar salida bonita
log "⏳ Instalando los siguientes paquetes:"
for pkg in "${PKGS[@]}"; do
  printf "   \033[0;36m• %s\033[0m\n" "$pkg"
done

APT_OUTPUT=$(mktemp)
if sudo apt install -y -qq --no-install-recommends "${PKGS[@]}" >"$APT_OUTPUT" 2>&1; then
  log "✅ Paquetes instalados correctamente."
else
  log "⚠️  Algunos paquetes ya estaban instalados o hubo advertencias:"
  grep -E "is already the newest version|no longer required|to remove and|upgraded,|newly installed" "$APT_OUTPUT" | while read -r line; do
    printf "   %s\n" "$line"
  done
fi
rm -f "$APT_OUTPUT"

#─── Starship ─────────────────────────────────────────────────────────────
if ! command -v starship &> /dev/null; then
  curl -sS https://starship.rs/install.sh | sh -s -- --yes >/dev/null 2>&1
fi

#─── Dotfiles ────────────────────────────────────────────────────────────

#─── Oh My Zsh ───────────────────────────────────────────────────────────

if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  log "⚙️  Instalando Oh‑My‑Zsh…"
  RUNZSH=no CHSH=no sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" >/dev/null 2>&1
fi

#─── Tema ────────────────────────────────────────────────────────────────

if [[ ! -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]]; then
  log "✨ Instalando Powerlevel10k…"
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" >/dev/null 2>&1
fi

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

#─── Docker ───────────────────────────────────────────────────────────────

log "🐳 Configurando Docker…"
sudo systemctl enable --now docker >/dev/null 2>&1
sudo usermod -aG docker "$USER" || true

#─── NVM ───────────────────────────────────────────────────────────────────

if [[ ! -d "$HOME/.nvm" ]]; then
  log "📦 Instalando NVM…"
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash >/dev/null 2>&1
fi

#─── Pyenv ────────────────────────────────────────────────────────────────

if [[ ! -d "$HOME/.pyenv" ]]; then
  log "🐍 Instalando Pyenv…"
  # Instalar dependencias para construir Python
  sudo apt install -y -qq build-essential libssl-dev zlib1g-dev libbz2-dev \
  libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev \
  xz-utils tk-dev libffi-dev liblzma-dev python3-openssl git > /dev/null
  curl https://pyenv.run | bash >/dev/null 2>&1
fi

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

log "✅ ¡Setup completado! Ejecuta install.sh y luego: exec zsh (o reinicia sesión) para aplicar cambios."