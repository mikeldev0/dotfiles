# 🦞 MIKEL'S DOTFILES CHEATSHEET 🕶️🤘

Esta es una guía de los atajos y funciones universales de tus dotfiles. Algunos comandos requieren que la herramienta esté instalada en el sistema.

## 🛠️ Navegación y Archivos
- **`cls`**: Limpia la pantalla.
- **`md [nombre]`**: Crea una carpeta (incluyendo padres).
- **`src`**: Recarga la configuración del shell (`source ~/.zshrc`).
- **`vim`**: Lanza Neovim (`nvim`).
- **`z [dir]`**: Salta rápidamente entre carpetas (requiere `zoxide`).
- **`extract [fichero]`**: Descomprime casi cualquier formato (.zip, .tar.gz, .rar, etc.).

## 🌍 Red y Sistema
- **`myip`**: IP privada local.
- **`myippub`**: Info detallada de tu IP pública (Ciudad, ISP, Geolocalización).
- **`pingg`**: Ping rápido a Google.
- **`ports`**: Lista los puertos abiertos y sus procesos.
    - `ports 3000`: Filtra por puerto.
    - `ports -L`: Solo en escucha.

## 🐙 Git y Desarrollo
- **`gs`**, **`ga`**, **`gc [msg]`**, **`gp`**: Atajos básicos de Git (status, add, commit, push).
- **`gl`**: Log de Git visual y compacto.
- **`c`**, **`ce`**, **`cs`**: Atajos para GitHub Copilot CLI (si está instalado).

## 🦞 OpenClaw (Solo VPS/Local con OpenClaw)
- **`neo`**: Alias de `openclaw`.
- **`neo status`**, **`neo doctor`**, **`neo logs --follow`**.

## 🎮 Servidores (Solo si aplica)
- **`hytale-logs`**, **`hytale-attach`**: Gestión de servidor Hytale.

## 💡 Pro-Tips Universales
- **FZF**: `CTRL+T` (buscar archivos) y `ALT+C` (buscar y entrar en carpetas).
- **Historial**: `CTRL+R` para búsqueda avanzada en el historial.
- **Sudo**: Pulsa `ESC` dos veces para añadir `sudo` al comando actual.

---
Para ver esta guía: **`ayuda`** o **`tips`**
