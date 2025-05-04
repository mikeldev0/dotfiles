# Dotfiles Repository for Linux Mint Productivity

Este repositorio contiene la configuración y scripts necesarios para dejar tu entorno Linux Mint listo para máxima productividad.

## Estructura de archivos

```
.dotfiles/
├── README.md
├── setup_mint_productividad.sh  # Script principal de instalación de paquetes y herramientas
├── install.sh                   # Script para crear enlaces simbólicos de configuración
├── zsh/                         # Configuración de Zsh
│   ├── .zshrc                   # Configuración principal de Zsh (alias, plugins, etc.)
│   └── .p10k.zsh                # Configuración del tema Powerlevel10k
└── git/                         # Configuración de Git
    └── .gitconfig               # Configuración global de Git
```

_(La estructura puede variar)_

---

## Uso

1.  Clona el repositorio:

    ```bash
    git clone https://github.com/byronnDev/dotfiles.git ~/.dotfiles
    ```

    _(Reemplaza `tu_usuario` con tu nombre de usuario de GitHub)_

2.  Navega al directorio y ejecuta los scripts de instalación:
    ```bash
    cd ~/.dotfiles
    ./setup_mint_productividad.sh # Instala paquetes y herramientas
    ./install.sh                  # Crea los enlaces simbólicos necesarios
    ```
3.  Reinicia la terminal o cierra y vuelve a abrir sesión para aplicar todos los cambios.

---

### Contribuciones

Pull requests son bienvenidas para mejorar aliases, scripts o añadir nuevas herramientas.
