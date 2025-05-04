#!/bin/bash

echo "Creando enlaces simbólicos..."
ln -sf ~/.dotfiles/zsh/.zshrc ~/.zshrc
ln -sf ~/.dotfiles/zsh/.p10k.zsh ~/.p10k.zsh
ln -sf ~/.dotfiles/git/.gitconfig ~/.gitconfig
echo "¡Listo!"
