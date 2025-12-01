#!/usr/bin/env bash
#
# Universal Linux Dotfiles Installer
# Supports: Debian/Ubuntu/Mint, Fedora/RHEL/CentOS
# Author: Mikel
#

set -e
set -o pipefail

# ─── Colors & Logging ────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() { printf "${BLUE}==>${NC} ${GREEN}%s${NC}\n" "$*"; }
info() { printf "${CYAN}  ->${NC} %s\n" "$*"; }
warn() { printf "${YELLOW}WARNING:${NC} %s\n" "$*"; }
error() { printf "${RED}ERROR:${NC} %s\n" "$*" >&2; }

# ─── Distro Detection ────────────────────────────────────────────────────────
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        VERSION=$VERSION_ID
    else
        error "Cannot detect OS. /etc/os-release not found."
        exit 1
    fi
    log "Detected Distribution: $NAME ($DISTRO)"
}

# ─── Package Installation ────────────────────────────────────────────────────
install_packages() {
    log "Installing System Packages..."

    local common_pkgs=(
        zsh curl git fzf htop ncdu tig unzip tree jq net-tools nmap 
        wl-clipboard xclip zoxide
    )
    
    # Distro-specific logic
    case "$DISTRO" in
        ubuntu|debian|linuxmint|pop) 
            local deb_pkgs=(
                "${common_pkgs[@]}"
                fd-find bat ripgrep docker.io docker-compose python3-pip fastfetch lsd rename
                build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev 
                libsqlite3-dev wget llvm libncurses5-dev libncursesw5-dev 
                xz-utils tk-dev libffi-dev liblzma-dev python3-openssl
            )
            
            info "Updating apt cache..."
            sudo apt update -qq
            
            info "Installing packages (this may take a while)..."
            sudo apt install -y -qq --no-install-recommends "${deb_pkgs[@]}"
            ;; 
            
        fedora|rhel|centos) 
            local fedora_pkgs=(
                "${common_pkgs[@]}"
                fd-find bat ripgrep docker docker-compose-plugin python3-pip fastfetch lsd prename
                make gcc zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel 
                openssl-devel tk-devel libffi-devel xz-devel perl-File-Rename
            )
            
            info "Installing packages via dnf..."
            sudo dnf install -y "${fedora_pkgs[@]}"
            ;; 
            
        arch|manjaro) 
            local arch_pkgs=(
                "${common_pkgs[@]}"
                fd bat ripgrep docker docker-compose python-pip fastfetch lsd perl-rename
                base-devel openssl zlib xz tk
            )
            info "Installing packages via pacman..."
            sudo pacman -Syu --noconfirm --needed "${arch_pkgs[@]}"
            ;; 
            
        *) 
            warn "Unsupported distribution '$DISTRO' for automatic package installation."
            warn "Please manually install: ${common_pkgs[*]}"
            read -p "Continue anyway? [y/N] " -n 1 -r
            echo
            [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
            ;; 
    esac
}

# ─── Docker Setup ────────────────────────────────────────────────────────────
setup_docker() {
    log "Configuring Docker..."
    if ! systemctl is-active --quiet docker; then
        info "Starting Docker service..."
        sudo systemctl enable --now docker
    fi
    
    if ! groups "$USER" | grep -q "\bdocker\b"; then
        info "Adding $USER to docker group..."
        sudo usermod -aG docker "$USER" || true
        warn "You will need to log out and back in for Docker group changes to take effect."
    fi
}

# ─── Shell Setup (Starship, Oh-My-Zsh) ───────────────────────────────────────
setup_shell() {
    log "Setting up Shell Environment..."

    # Starship
    if ! command -v starship &> /dev/null; then
        info "Installing Starship..."
        curl -sS https://starship.rs/install.sh | sh -s -- --yes >/dev/null 2>&1
    fi

    # Oh My Zsh
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        info "Installing Oh My Zsh..."
        RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" >/dev/null 2>&1
    fi

    # Powerlevel10k
    local p10k_dir="$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
    if [[ ! -d "$p10k_dir" ]]; then
        info "Cloning Powerlevel10k..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir" >/dev/null 2>&1
    fi

    # Plugins
    local zsh_custom="$HOME/.oh-my-zsh/custom"
    local plugins=(
        "zsh-autosuggestions https://github.com/zsh-users/zsh-autosuggestions"
        "zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting"
        "zsh-completions https://github.com/zsh-users/zsh-completions"
        "history-substring-search https://github.com/zsh-users/zsh-history-substring-search"
    )

    for plugin in "${plugins[@]}"; do
        read -r name url <<< "$plugin"
        if [[ ! -d "$zsh_custom/plugins/$name" ]]; then
            info "Installing plugin: $name..."
            git clone --depth=1 "$url" "$zsh_custom/plugins/$name" >/dev/null 2>&1
        fi
    done

    # FZF Bindings
    if [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]; then
       # Fedora path
       ln -sf /usr/share/doc/fzf/examples/key-bindings.zsh "$HOME/.fzf.zsh"
    elif [ -f /usr/share/doc/fzf/examples/completion.zsh ]; then
       # Fedora path
       ln -sf /usr/share/doc/fzf/examples/completion.zsh "$HOME/.fzf.bash"
    fi
}

# ─── Language Environments (NVM, Pyenv) ──────────────────────────────────────
setup_languages() {
    log "Setting up Language Environments..."

    # NVM
    if [[ ! -d "$HOME/.nvm" ]]; then
        info "Installing NVM..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash >/dev/null 2>&1
    fi

    # Pyenv
    if [[ ! -d "$HOME/.pyenv" ]]; then
        info "Installing Pyenv..."
        curl https://pyenv.run | bash >/dev/null 2>&1
    fi
}

# ─── Fonts ───────────────────────────────────────────────────────────────────
setup_fonts() {
    log "Installing Fonts..."
    local font_dir="$HOME/.local/share/fonts"
    if [[ ! -f "$font_dir/HackNerdFont-Regular.ttf" ]]; then
        mkdir -p "$font_dir"
        info "Downloading Hack Nerd Font..."
        curl -Lf --retry 3 -o "/tmp/Hack.zip" \
            https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip >/dev/null 2>&1
        unzip -qo "/tmp/Hack.zip" -d "$font_dir"
        fc-cache -f >/dev/null 2>&1
        rm -f "/tmp/Hack.zip"
    fi
}

# ─── Dotfiles Linking ────────────────────────────────────────────────────────
setup_dotfiles() {
    log "Linking Dotfiles..."
    local dotfiles_dir="$HOME/.dotfiles"

    # Ensure we are linking from the right place
    if [[ ! -d "$dotfiles_dir" ]]; then
        warn "$dotfiles_dir does not exist. Skipping symlinks."
        return
    fi

    ln -sf "$dotfiles_dir/zsh/.zshrc" "$HOME/.zshrc"
    ln -sf "$dotfiles_dir/zsh/.p10k.zsh" "$HOME/.p10k.zsh"
    ln -sf "$dotfiles_dir/git/.gitconfig" "$HOME/.gitconfig"
    
    info "Symlinks created."
}

# ─── Finalize ────────────────────────────────────────────────────────────────
finalize() {
    log "Finalizing..."
    
    # Set default shell
    local zsh_path
    zsh_path=$(command -v zsh)
    if [[ -n "$zsh_path" ]]; then
        if ! grep -qxF "$zsh_path" /etc/shells; then
            echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
        fi
        if [[ "$SHELL" != "$zsh_path" ]]; then
             info "Changing default shell to zsh..."
             sudo chsh -s "$zsh_path" "$USER"
        fi
    fi

    log "✅ Installation Complete!"
    info "Please restart your terminal or log out and back in for all changes to take effect."
    info "To start zsh now, type: exec zsh"
}

# ─── Main Execution ──────────────────────────────────────────────────────────
main() {
    detect_distro
    install_packages
    setup_docker
    setup_shell
    setup_languages
    setup_fonts
    setup_dotfiles
    finalize
}

main
