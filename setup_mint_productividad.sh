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

touch "$HOME/.zshrc"

# Copia la plantilla sólo la primera vez
test -s "$HOME/.zshrc" || cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$HOME/.zshrc"

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

# --- Construir lista de plugins verificados ---
DESIRED_PLUGINS=(
  git fzf zsh-completions history-substring-search zoxide sudo docker
  docker-compose colored-man-pages systemd copyfile alias-finder
  zsh-syntax-highlighting zsh-autosuggestions
)
FOUND_PLUGINS=()
OMZ_PLUGINS_DIR="$HOME/.oh-my-zsh/plugins"
CUSTOM_PLUGINS_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"

# Helper function to check if a plugin is defined for custom installation
is_custom_plugin() {
  [[ -v REPOS[$1] ]]
}

for p in "${DESIRED_PLUGINS[@]}"; do
  plugin_path_omz="$OMZ_PLUGINS_DIR/$p"
  plugin_path_custom="$CUSTOM_PLUGINS_DIR/$p"

  # Check if the plugin directory exists (standard or custom)
  if [[ -d "$plugin_path_omz" || -d "$plugin_path_custom" ]]; then
    FOUND_PLUGINS+=("$p")
  # If it doesn't exist, check if it's supposed to be a standard plugin
  elif ! is_custom_plugin "$p"; then
    # Assume standard plugins *should* exist after OMZ install. Add it but warn.
    log "⚠️ Directorio del plugin estándar '$p' no encontrado en '$plugin_path_omz'. Se incluirá de todos modos."
    FOUND_PLUGINS+=("$p")
  else
    # It's a custom plugin (or unknown) and wasn't found/installed
    log "⚠️ Plugin '$p' no encontrado y no es instalable automáticamente, omitiendo."
  fi
done

# Asegurar que zsh-syntax-highlighting esté al final si está presente
SYNTAX_HIGHLIGHTING="zsh-syntax-highlighting"
if [[ " ${FOUND_PLUGINS[*]} " =~ " ${SYNTAX_HIGHLIGHTING} " ]]; then
  # Eliminarlo de la lista actual
  temp_plugins=()
  for p in "${FOUND_PLUGINS[@]}"; do
    [[ "$p" != "$SYNTAX_HIGHLIGHTING" ]] && temp_plugins+=("$p")
  done
  # Añadirlo al final
  FOUND_PLUGINS=("${temp_plugins[@]}" "$SYNTAX_HIGHLIGHTING")
fi

# Modificar la línea de plugins existente o añadirla con los plugins encontrados
PLUGINS_STR=$(IFS=' '; echo "${FOUND_PLUGINS[*]}") # Convertir array a string
if grep -q '^plugins=(' "$HOME/.zshrc"; then
  sed -i "s/^plugins=(.*/plugins=($PLUGINS_STR)/" "$HOME/.zshrc"
else
  append_line "$HOME/.zshrc" "plugins=($PLUGINS_STR)"
fi

# Instalación de bindings de fzf (provee completado y Ctrl‑T)
FZF_INSTALL_SCRIPT="$(dpkg -L fzf | grep -m1 install || true)"
if [[ -x "$FZF_INSTALL_SCRIPT" ]]; then
  "$FZF_INSTALL_SCRIPT" --key-bindings --completion --no-update-rc >/dev/null 2>&1
fi

#─── Aliases & helpers (Modificar .zshrc) ──────────────────────────────

log "📝 Configurando .zshrc paso a paso..."

# Añadir configuración para Powerlevel10k Instant Prompt
append_line "$HOME/.zshrc" '# --- Powerlevel10k Instant Prompt --- #'
append_line "$HOME/.zshrc" 'typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet'

# Añadir configuraciones y alias sección por sección
append_line "$HOME/.zshrc" '' # Línea en blanco para separar
append_line "$HOME/.zshrc" '# ─── STARSHIP PROMPT ─────────────────────────────────────'
append_line "$HOME/.zshrc" '# eval "$(starship init zsh)" # Descomentar si se prefiere Starship'

append_line "$HOME/.zshrc" ''
append_line "$HOME/.zshrc" '# ─── ZOXIDE ───────────────────────────────────────────────'
append_line "$HOME/.zshrc" 'eval "$(zoxide init zsh)"'

append_line "$HOME/.zshrc" ''
append_line "$HOME/.zshrc" '# ─── ALIASES BÁSICOS ─────────────────────────────────────'
append_line "$HOME/.zshrc" "alias fd='fdfind'"
append_line "$HOME/.zshrc" "alias bat='batcat'"
append_line "$HOME/.zshrc" "alias ls='lsd'"

append_line "$HOME/.zshrc" ''
append_line "$HOME/.zshrc" '# ─── ALIASES GIT ────────────────────────────────────────'
append_line "$HOME/.zshrc" "alias gs='git status'"
append_line "$HOME/.zshrc" "alias ga='git add .'"
append_line "$HOME/.zshrc" "alias gc='git commit -m'"
append_line "$HOME/.zshrc" "alias gp='git push'"
append_line "$HOME/.zshrc" "alias gl='git log --oneline --graph --decorate'"
append_line "$HOME/.zshrc" "alias gd='git diff'"

append_line "$HOME/.zshrc" ''
append_line "$HOME/.zshrc" '# ─── ALIASES VARIOS ─────────────────────────────────────'
append_line "$HOME/.zshrc" "alias ll='lsd -lah'"
append_line "$HOME/.zshrc" "alias cls='clear'"
append_line "$HOME/.zshrc" "alias md='mkdir -p'"
append_line "$HOME/.zshrc" "alias src='source ~/.zshrc'"
append_line "$HOME/.zshrc" "alias myip='ip a | grep inet'"
append_line "$HOME/.zshrc" "alias myippub='curl -s ipinfo.io | jq -r \".ip + \\\" (\\\" + .city + \\\", \\\" + .country + \\\")\\nISP: \\\" + .org + \\\"\\nLoc: \\\" + .loc + \\\"\\nHostname: \\\" + .hostname + \\\"\\nTimezone: \\\" + .timezone\"'"
append_line "$HOME/.zshrc" "alias ports='sudo lsof -i -P -n | grep LISTEN'"
append_line "$HOME/.zshrc" "alias pingg='ping google.com'"
append_line "$HOME/.zshrc" "alias alert='notify-send --urgency=low -i terminal Terminal Finished'"
append_line "$HOME/.zshrc" "alias plugins='echo Activos: \$(grep -E \"^plugins=\" ~/.zshrc | sed \"s/^plugins=(//;s/)//\") && echo Instalados: \$(ls -1 \"\${ZSH_CUSTOM:-\$HOME/.oh-my-zsh/custom}/plugins\" \"\$HOME/.oh-my-zsh/plugins\" 2>/dev/null | sort -u | tr \"\\n\" \" \")'"

append_line "$HOME/.zshrc" ''
append_line "$HOME/.zshrc" '# ─── EXTRACT FUNCTION ─────────────────────────────────────'
append_line "$HOME/.zshrc" 'extract() { [[ -f "$1" ]] || { echo "Archivo no encontrado: $1" >&2; return 1; }; case "$1" in *.tar.bz2) tar xjf "$1";; *.tar.gz) tar xzf "$1";; *.bz2) bunzip2 "$1";; *.rar) unrar x "$1";; *.gz) gunzip "$1";; *.tar) tar xf "$1";; *.tbz2) tar xjf "$1";; *.tgz) tar xzf "$1";; *.zip) unzip "$1";; *) echo "Formato no soportado: $1";; esac }'

append_line "$HOME/.zshrc" ''
append_line "$HOME/.zshrc" '# ─── NVM ──────────────────────────────────────────────────'
append_line "$HOME/.zshrc" 'export NVM_DIR="$HOME/.nvm"'
append_line "$HOME/.zshrc" '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"'
append_line "$HOME/.zshrc" '[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"'

append_line "$HOME/.zshrc" ''
append_line "$HOME/.zshrc" '# ─── PYENV ────────────────────────────────────────────────'
append_line "$HOME/.zshrc" 'export PYENV_ROOT="$HOME/.pyenv"'
append_line "$HOME/.zshrc" '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"'
append_line "$HOME/.zshrc" 'eval "$(pyenv init -)"'

append_line "$HOME/.zshrc" ''
append_line "$HOME/.zshrc" '# ─── FZF ──────────────────────────────────────────────────'
append_line "$HOME/.zshrc" 'export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"'
append_line "$HOME/.zshrc" 'export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"'
append_line "$HOME/.zshrc" 'export FZF_ALT_C_COMMAND="fd --type d --hidden --follow --exclude .git"'
append_line "$HOME/.zshrc" '[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh'

append_line "$HOME/.zshrc" ''
append_line "$HOME/.zshrc" '# ─── POWERLEVEL10K CONFIG ─────────────────────────────────'
append_line "$HOME/.zshrc" '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh'

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

append_line "$HOME/.zshrc" '# ─── NEOFETCH ─────────────────────────────────────────────'
append_line "$HOME/.zshrc" 'neofetch --w3m --color_blocks off --source all --disable infobar'
#─── Limpieza ─────────────────────────────────────────────────────────────

log "🧹 Limpiando cachés…"
rm -f "$HOME/.zcompdump*" /tmp/Hack.zip

log "✅ ¡Terminal lista! Ejecuta: exec zsh (o reinicia sesión) para aplicar cambios."