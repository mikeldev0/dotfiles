# Dotfiles Repository for Linux Mint Productivity

Este repositorio contiene la configuración y scripts necesarios para dejar tu entorno Linux Mint listo para máxima productividad.

## Estructura de archivos

```
dotfiles/
├── README.md
├── setup_mint_productividad.sh
├── .zshrc
└── .gitignore
```

---

### README.md

````md
# Dotfiles Linux Mint Productividad

Este repositorio contiene:

- `setup_mint_productividad.sh`: Script de instalación y configuración con control de errores.
- `.zshrc`: Alias, plugins y configuración de Zsh.
- `.gitignore`: Archivos que no deben subirse al repositorio.
````

## Uso

1. Clona el repositorio:
   ```bash
   git clone https://github.com/byronnDev/dotfiles.git ~/dotfiles
   cd ~/dotfiles
   ```

2. Ejecuta el script de setup:

   ```bash
   chmod +x setup_mint_productividad.sh
   ./setup_mint_productividad.sh
   ```
3. Reinicia la terminal o cierra sesión para aplicar los cambios.

---

### Contribuciones

Pull requests son bienvenidas para mejorar aliases, scripts o añadir nuevas herramientas.

````

---

### setup_mint_productividad.sh
```bash
#!/bin/bash

set -e  # Salir si cualquier comando falla

# Colores para mensajes
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🔧 Iniciando configuración de entorno productivo en Linux Mint...${NC}"

# Función para comprobar errores
debug() { echo -e "${RED}❌ Error en: $1${NC}"; exit 1; }

# 1. Actualizar sistema
echo -e "${GREEN}📦 Actualizando sistema...${NC}"
sudo apt update && sudo apt upgrade -y || debug "apt update/upgrade"

# 2. Instalar paquetes esenciales
echo -e "${GREEN}📥 Instalando paquetes base...${NC}"
sudo apt install -y zsh curl git fzf fd-find bat ripgrep htop ncdu docker.io docker-compose tig python3-pip || debug "instalación de paquetes"

# Alias para Mint (bat y fd)
grep -qxF "alias fd='fdfind'" ~/.zshrc || echo "alias fd='fdfind'" >> ~/.zshrc
grep -qxF "alias bat='batcat'" ~/.zshrc || echo "alias bat='batcat'" >> ~/.zshrc

# 3. Cambiar shell a Zsh
if [ "$SHELL" != "$(which zsh)" ]; then
  echo -e "${GREEN}🐚 Configurando Zsh como shell por defecto...${NC}"
  chsh -s "$(which zsh)" || debug "chsh"
else
  echo "Zsh ya es el shell por defecto."
fi

# 4. Instalar Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo -e "${GREEN}⚙️ Instalando Oh My Zsh...${NC}"
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || debug "Oh My Zsh"
else
  echo "Ya tienes Oh My Zsh instalado."
fi

# 5. Instalar Starship
if ! command -v starship &> /dev/null; then
  echo -e "${GREEN}🚀 Instalando Starship...${NC}"
  curl -sS https://starship.rs/install.sh | sh -s -- -y || debug "Starship"
fi
grep -qxF 'eval "$(starship init zsh)"' ~/.zshrc || echo 'eval "$(starship init zsh)"' >> ~/.zshrc

# 6. Plugins Zsh
ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}
[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] && git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] && git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc

# 7. Alias personalizados
cat <<'EOF' >> ~/.zshrc

# --- ALIAS PERSONALIZADOS ---
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

alias serve='php -S localhost:8000'
alias artisan='php artisan'
alias sail='./vendor/bin/sail'
alias dev='npm run dev'
alias build='npm run build'
alias nuxt='npx nuxi dev'

alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dstop='docker stop $(docker ps -q)'
alias drm='docker rm $(docker ps -aq)'
alias dclean='docker system prune -af'

alias ll='ls -lah --color=auto'
alias cls='clear'
alias fix-perms='sudo chown -R $USER:$USER . && find . -type f -exec chmod 644 {} \; && find . -type d -exec chmod 755 {} \;'

alias proyectos='cd ~/Proyectos'
alias laravelup='cd ~/Proyectos/mi-laravel && sail up'
alias nuxtup='cd ~/Proyectos/mi-nuxt && npm run dev'

# --- FIN DE ALIAS ---
EOF

# 8. Docker
tmp
sudo systemctl enable docker || debug "enable docker"
sudo usermod -aG docker "$USER" || debug "usermod docker"

# 9. Instalar NVM
if [ ! -d "$HOME/.nvm" ]; then
  echo -e "${GREEN}📦 Instalando NVM...${NC}"
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash || debug "NVM"
fi
grep -qxF 'export NVM_DIR="$HOME/.nvm"' ~/.zshrc || cat <<'EOT' >> ~/.zshrc

# NVM config
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
EOT

# 10. Instalar pyenv
if [ ! -d "$HOME/.pyenv" ]; then
  echo -e "${GREEN}🐍 Instalando pyenv...${NC}"
  curl https://pyenv.run | bash || debug "pyenv"
fi
grep -qxF 'export PYENV_ROOT="$HOME/.pyenv"' ~/.zshrc || cat <<'EOT' >> ~/.zshrc

# pyenv config
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
EOT

echo -e "${GREEN}✅ Configuración completada. Reinicia la terminal o cierra sesión para aplicar los cambios.${NC}"

````
