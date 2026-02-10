#!/usr/bin/env bash
# Universal Dotfiles Installer
# Supports: Ubuntu/Debian/Mint, Fedora, macOS

set -e
set -o pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { printf "${BLUE}==>${NC} ${GREEN}%s${NC}\n" "$*"; }
info() { printf "${CYAN}  ->${NC} %s\n" "$*"; }
warn() { printf "${YELLOW}WARNING:${NC} %s\n" "$*"; }
error() { printf "${RED}ERROR:${NC} %s\n" "$*" >&2; }

OS_FAMILY=""
DISTRO=""
PKG_MANAGER=""

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    error "Missing required command: $1"
    exit 1
  }
}

detect_os() {
  if [[ "$(uname -s)" == "Darwin" ]]; then
    OS_FAMILY="macos"
    DISTRO="macos"
    PKG_MANAGER="brew"
    log "Detected OS: macOS"
    return
  fi

  if [[ -f /etc/os-release ]]; then
    # shellcheck source=/dev/null
    . /etc/os-release
    DISTRO="$ID"
    OS_FAMILY="linux"

    case "$ID" in
      ubuntu|debian|linuxmint|pop)
        PKG_MANAGER="apt"
        ;;
      fedora)
        PKG_MANAGER="dnf"
        ;;
      *)
        error "Unsupported Linux distro: $ID"
        exit 1
        ;;
    esac

    log "Detected OS: ${PRETTY_NAME:-$ID}"
  else
    error "Cannot detect OS. Missing /etc/os-release"
    exit 1
  fi
}

ensure_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    return
  fi

  warn "Homebrew not found. Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  need_cmd brew
}

install_packages() {
  log "Installing packages..."

  case "$PKG_MANAGER" in
    apt)
      sudo apt update -qq
      sudo apt install -y -qq --no-install-recommends \
        zsh curl git fzf zoxide neofetch bat ripgrep fd-find

      # lsd via cargo if apt package missing
      if ! command -v lsd >/dev/null 2>&1; then
        info "Installing lsd (cargo)..."
        curl -fsSL https://sh.rustup.rs | sh -s -- -y
        # shellcheck disable=SC1090
        source "$HOME/.cargo/env"
        cargo install lsd --locked || true
      fi
      ;;

    dnf)
      sudo dnf install -y \
        zsh curl git fzf zoxide fastfetch bat ripgrep fd-find lsd
      ;;

    brew)
      ensure_homebrew
      brew update
      brew install \
        zsh curl git fzf zoxide starship fastfetch bat ripgrep fd lsd || true
      ;;

    *)
      error "Unsupported package manager: $PKG_MANAGER"
      exit 1
      ;;
  esac

  # Starship: install via package manager where possible, fallback script
  if ! command -v starship >/dev/null 2>&1; then
    info "Installing Starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- --yes >/dev/null 2>&1
  fi

  # fzf shell integration on macOS
  if [[ "$PKG_MANAGER" == "brew" ]]; then
    "$(brew --prefix)/opt/fzf/install" --all --no-bash --no-fish || true
  fi
}

setup_shell() {
  log "Setting up Oh My Zsh + Powerlevel10k + plugins..."

  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" >/dev/null 2>&1
  fi

  local p10k_dir="$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
  if [[ ! -d "$p10k_dir" ]]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir" >/dev/null 2>&1
  fi

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
      info "Installing plugin: $name"
      git clone --depth=1 "$url" "$zsh_custom/plugins/$name" >/dev/null 2>&1
    fi
  done
}

setup_dotfiles() {
  log "Linking dotfiles..."

  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  local zsh_src="$script_dir/zsh/.zshrc"
  local p10k_src="$script_dir/zsh/.p10k.zsh"

  [[ -f "$zsh_src" ]] || { error "Missing file: $zsh_src"; exit 1; }
  [[ -f "$p10k_src" ]] || { error "Missing file: $p10k_src"; exit 1; }

  ln -sfn "$zsh_src" "$HOME/.zshrc"
  ln -sfn "$p10k_src" "$HOME/.p10k.zsh"

  info "Linked ~/.zshrc -> $zsh_src"
  info "Linked ~/.p10k.zsh -> $p10k_src"
  info "Skipping ~/.gitconfig by design"
}

finalize() {
  log "Finalizing setup..."

  local zsh_path
  zsh_path="$(command -v zsh || true)"

  if [[ -z "$zsh_path" ]]; then
    error "zsh not found after installation"
    exit 1
  fi

  if [[ "$OS_FAMILY" == "linux" ]]; then
    if [[ -f /etc/shells ]] && ! grep -qx "$zsh_path" /etc/shells; then
      echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    fi
    if [[ "$SHELL" != "$zsh_path" ]]; then
      chsh -s "$zsh_path" "$USER" || warn "Could not change shell automatically. Run: chsh -s $zsh_path"
    fi
  elif [[ "$OS_FAMILY" == "macos" ]]; then
    if ! grep -qx "$zsh_path" /etc/shells; then
      echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    fi
    if [[ "$SHELL" != "$zsh_path" ]]; then
      chsh -s "$zsh_path" || warn "Could not change shell automatically. Run: chsh -s $zsh_path"
    fi
  fi

  log "✅ Done"
  info "Restart terminal or run: exec zsh"
}

main() {
  detect_os
  install_packages
  setup_shell
  setup_dotfiles
  finalize
}

main "$@"
