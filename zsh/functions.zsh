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
    # macOS: simple (si quieres parity real con Linux, lo afinamos luego)
    lsof -i -nP | awk -v wp="$want_port" '
      NR>1 {
        pid=$2; proc=$1; laddr=$9;
        if (wp != "") {
          p=laddr; sub(/^.*:/,"",p);
          if (p != wp) next;
        }
        printf "%-8s %-18s %s\n", pid, proc, laddr
      }'
    return 0
  fi

  # Linux (ss preferred)
  local ss_flags="-H -n -p"
  local filter=()

  [[ "$mode" == "listening" ]] && ss_flags="$ss_flags -l"

  if [[ "$mode" == "established" ]]; then
    # ss "established" tiene sentido en TCP
    [[ "$proto" == "udp" ]] && return 0
    [[ -z "$proto" ]] && proto="tcp"
    filter=(state established)
  fi

  [[ "$proto" == "tcp" ]] && ss_flags="$ss_flags -t"
  [[ "$proto" == "udp" ]] && ss_flags="$ss_flags -u"
  [[ -z "$proto" ]] && ss_flags="$ss_flags -tu"

  local out=""
  out=$(ss $ss_flags "${filter[@]}" 2>/dev/null) || out=""
  if [[ -z "$out" ]]; then
    out=$(sudo -n ss $ss_flags "${filter[@]}" 2>/dev/null) || out=""
  fi

  echo "$out" | awk -v wp="$want_port" -v det="$details" '
    {
      proto=$1;
      state=$2;
      laddr=$5;

      pid="-"; proc="-";

      # Extrae el primer users:(("proc",pid=1234 ...)) sin match(..., ..., array)
      if (match($0, /users:\(\(\"[^"]+\",pid=[0-9]+/)) {
        s = substr($0, RSTART, RLENGTH);
        sub(/^users:\(\(\"/, "", s);          # quita prefijo
        split(s, a, /",pid=/);               # a[1]=proc, a[2]=pid...
        proc = a[1];
        pid  = a[2];
        sub(/[^0-9].*$/, "", pid);           # deja solo dígitos
      }

      pnum=laddr;
      sub(/^.*:/, "", pnum);                 # último ":" -> puerto (ok para IPv6)
      if (wp != "" && pnum != wp) next;

      key = pid "\t" proc "\t" proto "\t" state "\t" laddr;
      if (seen[key]++) next;

      if (det == 1)
        printf "%-8s %-18s %-5s %-12s %s\n", pid, proc, proto, state, laddr;
      else
        printf "%-8s %-18s %s\n", pid, proc, laddr;
    }
  '
}
