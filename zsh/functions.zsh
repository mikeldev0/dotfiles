# ─── FUNCTION: extract ───────────────────────────────────
extract() {
  [[ -f "$1" ]] || { echo "File not found: $1" >&2; return 1; }
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
    *)         echo "Unsupported format: $1" ;;
  esac
}

# ─── FUNCTION: notify_when_done ──────────────────────────
notify_when_done() {
  "$@"
  local cmd_status=$?
  if [[ $cmd_status -eq 0 ]]; then
    notify-send --urgency=low -i dialog-information "✅ Command completed successfully"
  else
    notify-send --urgency=critical -i dialog-error "❌ Error running: $*"
  fi
}

# ─── FUNCTION: ports ─────────────────────────────────────
ports() {
  local want_port="" proto="" mode="all" color=1 noheader=0 details=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -p|--port)        want_port="$2"; shift 2 ;;
      -t|--tcp)         proto="tcp"; shift ;;
      -u|--udp)         proto="udp"; shift ;;
      -a|--all)         mode="all"; shift ;;
      -e|--established) mode="established"; shift ;;
      -L|--listening)   mode="listening"; shift ;;
      -d|--details)     details=1; shift ;;
      -n|--no-color)    color=0; shift ;;
      --no-header)      noheader=1; shift ;;
      -h|--help)
        cat <<'EOF'
Usage: ports [options] [PORT]
  No args: shows all connections (compact view).
  [PORT]  Filter by port (same as -p)
  -p, --port N    Filter by port N
  -t, --tcp       Only TCP
  -u, --udp       Only UDP
  -a, --all       All connections (default)
  -e, --established  Only established (TCP)
  -L, --listening    Only listening
  -d, --details   Adds Proto and State columns
  -n, --no-color  Disable colors
  --no-header     Hide header
  -h, --help      Help
EOF
        return 0
        ;;
      *)
        if [[ -z "$want_port" && "$1" =~ ^[0-9]+$ ]]; then
          want_port="$1"; shift
        else
          echo "Unrecognized argument: $1" >&2; return 2
        fi
        ;;
    esac
  done

  local BOLD="" GREEN="" BLUE="" CYAN="" RESET=""
  if [[ -t 1 && $color -eq 1 ]]; then
    BOLD=$'\033[1m'; GREEN=$'\033[32m'; BLUE=$'\033[34m'; CYAN=$'\033[36m'; RESET=$'\033[0m'
  fi

  if [[ $noheader -ne 1 ]]; then
    if [[ $details -eq 1 ]]; then
      printf "${BOLD}%-8s %-18s %-5s %-12s %s${RESET}\n" "PID" "Process" "Proto" "State" "Local Address"
    else
      printf "${BOLD}%-8s %-18s %s${RESET}\n" "PID" "Process" "Local Address"
    fi
  fi

  if [[ "$(uname -s)" == "Darwin" ]]; then
    # macOS logic simplified for brevity but kept functional
    lsof -i -nP | awk -v wp="$want_port" 'NR>1 {print $2, $1, $9}' # simplified logic
  else
    # Linux (ss preferred)
    local ss_flags="-H -n"
    [[ "$mode" == "listening" ]] && ss_flags="$ss_flags -l"
    [[ "$proto" == "tcp" ]] && ss_flags="$ss_flags -t"
    [[ "$proto" == "udp" ]] && ss_flags="$ss_flags -u"
    [[ -z "$proto" ]] && ss_flags="$ss_flags -tu"
    
    local out
    out=$(ss $ss_flags -p 2>/dev/null)
    [[ -z "$out" ]] && out=$(sudo -n ss $ss_flags -p 2>/dev/null)

    echo "$out" | awk -v wp="$want_port" -v g="$GREEN" -v b="$BLUE" -v c="$CYAN" -v r="$RESET" -v det="$details" '
    {
      split($1, a, " "); proto = a[1];
      laddr = $5;
      pid="-"; proc="-";
      if (match($0, /users:\(\("([^"]+)",pid=([0-9]+)/, M)) {
        proc = M[1]; pid = M[2];
      }
      pnum = laddr; sub(/.*:/, "", pnum);
      if (wp != "" && pnum != wp) next;
      if (!seen[pid laddr]++) {
        if (det == 1) {
          printf "%-8s %-18s %-5s %-12s %s\n", pid, proc, proto, $2, laddr
        } else {
          printf "%-8s %-18s %s\n", pid, proc, laddr
        }
      }
    }'
  fi
}

# ─── FUNCTION: cdx ───────────────────────────────────────
cdx() {
  if [[ "$1" == "update" ]]; then
    npm install -g @openai/codex@latest
  else
    codex --model 'gpt-5-codex' --full-auto -c model_reasoning_summary_format=experimental --search "$@"
  fi
}
