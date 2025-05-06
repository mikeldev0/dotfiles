# ─── FUNCIÓN: extract ─────────────────────────────────────
# Descomprime automáticamente el archivo según su extensión
extract() {
  [[ -f "$1" ]] || { echo "Archivo no encontrado: $1" >&2; return 1; }
  case "$1" in
    *.tar.bz2) tar xjf "$1" ;;
    *.tar.gz)  tar xzf "$1" ;;
    *.bz2)     bunzip2 "$1" ;;
    *.rar)     unrar x "$1" ;;
    *.gz)      gunzip "$1" ;;
    *.tar)     tar xf "$1" ;;
    *.tbz2)    tar xjf "$1" ;;
    *.tgz)     tar xzf "$1" ;;
    *.zip)     unzip "$1" ;;
    *)         echo "Formato no soportado: $1" ;;
  esac
}

# ─── FUNCIÓN: notify_when_done ────────────────────────────
# Ejecuta un comando y lanza una notificación según el resultado
notify_when_done() {
  "$@"
  local cmd_status=$?
  if [[ $cmd_status -eq 0 ]]; then
    notify-send --urgency=low -i dialog-information "✅ Comando finalizado con éxito"
  else
    notify-send --urgency=critical -i dialog-error "❌ Error al ejecutar: $*"
  fi
}
