#!/usr/bin/env bash
set -euo pipefail

NOTE_FILE="${TARGET_DIR}/${TARGET_IP}.md"
OUT_DIR="${OUT}"

die() { echo "[!] $*" >&2; exit 1; }

require_env() {
  [ -n "${TARGET_DIR:-}" ] || die "TARGET_DIR empty"
  [ -n "${TARGET_IP:-}" ] || die "TARGET_IP empty"
  [ -n "${OUT:-}" ] || die "OUT empty"
  [ -f "$NOTE_FILE" ] || die "note not found: $NOTE_FILE"
}

replace_block() {
  local start="$1"
  local end="$2"
  local body="$3"

  python3 - "$NOTE_FILE" "$start" "$end" "$body" <<'PY'
import sys
from pathlib import Path

p = Path(sys.argv[1])
start = sys.argv[2]
end = sys.argv[3]
body = sys.argv[4]

t = p.read_text()

s = t.find(start)
e = t.find(end, s + len(start))

if s == -1 or e == -1:
    print("marker error", file=sys.stderr)
    sys.exit(1)

new = t[:s+len(start)] + "\n" + body.strip() + "\n" + t[e:]
p.write_text(new)
PY
}

extract_open() {
  grep -E '^[0-9]+/(tcp|udp).*open' "$1" | sed 's/  */ /g' || true
}

extract_ports() {
  grep -E '^[0-9]+/(tcp|udp).*open' "$1" \
    | cut -d/ -f1 | sort -n -u | paste -sd, - || true
}

build_services() {
  awk '
  /^[0-9]+\/(tcp|udp).*open/ {
    printf "- `%s` %s\n", $1, $3
  }' "$1"
}

build_actions() {
  local f="$1"
  local o
  o="$(grep -E 'open' "$f" || true)"

  {
    echo "$o" | grep -qi http && echo "[WEB] → ffuf / vhost / login"
    echo "$o" | grep -qi smb && echo "[SMB] → enum4linux-ng"
    echo "$o" | grep -qi ldap && echo "[LDAP] → ldapsearch"
    echo "$o" | grep -qi ssh && echo "[SSH] → creds / keys"
    echo "$o" | grep -qi ftp && echo "[FTP] → anonymous"
  } | sed '/^$/d'
}

sync_init() {
  local f="$OUT_DIR/nmap_initial.nmap"
  [ -f "$f" ] || die "no initial"

  replace_block "<auto:init>" "</auto:init>" "$(extract_open "$f")"
}

sync_service() {
  local f="$OUT_DIR/nmap_service.nmap"
  [ -f "$f" ] || die "no service"

  replace_block "<auto:service>" "</auto:service>" "$(extract_open "$f")"
  replace_block "<auto_actions>" "</auto_actions>" "$(build_actions "$f")"

  python3 - "$NOTE_FILE" "$(build_services "$f")" <<'PY'
import sys
from pathlib import Path

p = Path(sys.argv[1])
body = sys.argv[2]

t = p.read_text()

start = "<!-- auto_services_start -->"
end = "<!-- auto_services_end -->"

s = t.find(start)
e = t.find(end)

new = t[:s+len(start)] + "\n" + body.strip() + "\n" + t[e:]
p.write_text(new)
PY
}

sync_full() {
  local f="$OUT_DIR/nmap_full.nmap"
  [ -f "$f" ] || die "no full"

  replace_block "<auto:full>" "</auto:full>" "$(extract_ports "$f")"
}

case "${1:-}" in
  init) require_env; sync_init ;;
  service) require_env; sync_service ;;
  full) require_env; sync_full ;;
  all)
    require_env
    [ -f "$OUT_DIR/nmap_initial.nmap" ] && sync_init || true
    [ -f "$OUT_DIR/nmap_service.nmap" ] && sync_service || true
    [ -f "$OUT_DIR/nmap_full.nmap" ] && sync_full || true
    ;;
  *) echo "usage: init|service|full|all"; exit 1 ;;
esac
