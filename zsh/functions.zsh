# ─── FUNCTION: extract ───────────────────────────────────
# Automatically extracts an archive based on its extension
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
# Runs a command and sends a desktop notification based on the result
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
# Lists ports/connections (macOS and Linux) with a clean format.
ports() {
  local want_port="" proto="" mode="all" color=1 noheader=0 details=0

  # --- Argument parsing ---
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

  # --- Colors ---
  local BOLD="" GREEN="" BLUE="" CYAN="" RESET=""
  if [[ -t 1 && $color -eq 1 ]]; then
    BOLD=$'\033[1m'; GREEN=$'\033[32m'; BLUE=$'\033[34m'; CYAN=$'\033[36m'; RESET=$'\033[0m'
  fi

  # --- Header ---
  if [[ $noheader -ne 1 ]]; then
    if [[ $details -eq 1 ]]; then
      printf "${BOLD}%-8s %-18s %-5s %-12s %s${RESET}\n" "PID" "Process" "Proto" "State" "Local Address"
    else
      printf "${BOLD}%-8s %-18s %s${RESET}\n" "PID" "Process" "Local Address"
    fi
  fi

  local os; os="$(uname -s)"

  if [[ "$os" == "Darwin" ]] && command -v lsof >/dev/null 2>&1; then
    # --- macOS: lsof ---
    local args=( -nP )
    case "$proto" in
      udp) args+=( -iUDP ) ;;
      tcp) args+=( -iTCP ) ;;
      "" ) args+=( -i ) ;;
    esac
    case "$mode" in
      listening)   [[ "$proto" != "udp" ]] && args+=( -sTCP:LISTEN ) ;;
      established) [[ "$proto" != "udp" ]] && args+=( -sTCP:ESTABLISHED ) ;;
    esac
    [[ -n "$want_port" ]] && args+=( -i ":$want_port" )

    lsof "${args[@]}" 2>/dev/null | awk -v wp="$want_port" \
      -v g="$GREEN" -v b="$BLUE" -v c="$CYAN" -v r="$RESET" -v det="$details" '
      NR==1 { next }
      {
        pid=$2; proc=$1;
        last=$NF; before1=$(NF-1); before2=$(NF-2)
        state=""; addr=""; proto=""
        if (last ~ /^\(.*\)$/) { state=substr(last,2,length(last)-2); addr=before1; proto=before2; }
        else { addr=last; proto=before1; }
        portnum=""
        if (addr ~ /]:[0-9]+$/)       { match(addr, /]:([0-9]+)$/, m); portnum=m[1] }
        else if (addr ~ /:[0-9]+$/)   { match(addr, /:([0-9]+)$/, m); portnum=m[1] }
        if (wp != "" && portnum != wp) next
        key=pid "|" addr
        if (!seen[key]++) {
          if (det==1) {
            printf "%s%-8s%s %s%-18s%s %s%-5s%s %s%-12s%s %s%s%s\n", g,pid,r, b,proc,r, c,proto,r, c,state,r, c,addr,r
          } else {
            printf "%s%-8s%s %s%-18s%s %s%s%s\n", g,pid,r, b,proc,r, c,addr,r
          }
        }
      }'
  else
    # --- Linux ---
    if command -v ss >/dev/null 2>&1; then
      local ss_flags=( -H -n )
      case "$proto" in
        tcp) ss_flags+=( -t ) ;;
        udp) ss_flags+=( -u ) ;;
        "" ) ss_flags+=( -t -u ) ;;
      esac
      [[ "$mode" == "listening" ]] && ss_flags+=( -l )
      ss_flags+=( -p )
      local out; out="$(ss "${ss_flags[@]}" 2>/dev/null)"
      if [[ -z "$out" ]] && command -v sudo >/dev/null 2>&1; then
        out="$(sudo -n ss "${ss_flags[@]}" 2>/dev/null)"
      fi

      awk -v wp="$want_port" -v g="$GREEN" -v b="$BLUE" -v c="$CYAN" -v r="$RESET" -v det="$details" '
        {
          proto = tolower($1); state = ($2 == "" ? "" : $2); laddr = $5; pid=""; proc=""
          if (match($0, /users:\(\("([^"]+)",pid=([0-9]+)/, M)) { proc=M[1]; pid=M[2] }
          portnum=""
          if (laddr ~ /]:[0-9]+$/) { match(laddr, /]:([0-9]+)$/, P); portnum=P[1] }
          else if (laddr ~ /:([0-9]+)$/) { match(laddr, /:([0-9]+)$/, P); portnum=P[1] }
          if (wp != "" && portnum != wp) next
          key=pid "|" laddr
          if (!seen[key]++) {
            if (pid=="" && proc=="") { pid="-"; proc="-" }
            if (det==1) {
              printf "%s%-8s%s %s%-18s%s %s%-5s%s %s%-12s%s %s%s%s\n", g,pid,r, b,proc,r, c,proto,r, c,state,r, c,laddr,r
            } else {
              printf "%s%-8s%s %s%-18s%s %s%s%s\n", g,pid,r, b,proc,r, c,addr,r
            }
          }
        }' <<< "$out"
    fi
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
