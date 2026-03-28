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
  local file="$1"
  [ -f "$file" ] || return 0

  local open_lines
  open_lines="$(grep -E '^[0-9]+/(tcp|udp)[[:space:]]+open' "$file" || true)"

  {
    if echo "$open_lines" | grep -Eqi 'http|https'; then
      echo "[WEB]"
      echo "  → title / tech / login / upload / API"
      echo "  → ffuf / gobuster / vhost"

      grep -qi 'apache' "$file" && echo "  → Apache: CGI / misconfig / default files"
      grep -qi 'nginx' "$file" && echo "  → Nginx: proxy / config / hidden paths"
      grep -qi 'iis' "$file" && echo "  → IIS: ASP.NET / shortname / web.config"
      grep -qi 'tomcat' "$file" && echo "  → Tomcat: manager / WAR deploy / default creds"
      grep -qi 'jetty' "$file" && echo "  → Jetty: admin / debug / Java app surface"
      grep -qiE 'https|ssl|tls' "$file" && echo "  → SSL: cert CN/SAN / subdomain / TLS config"
      echo
    fi

    if echo "$open_lines" | grep -qiE 'microsoft-ds|netbios|smb'; then
      echo "[SMB]"
      echo "  → enum4linux-ng / smbclient"
      echo "  → anonymous / shares / users"
      grep -qi 'signing' "$file" && echo "  → check SMB signing"
      grep -qi 'samba' "$file" && echo "  → Samba version / known vulns / writable share"
      echo
    fi

    if echo "$open_lines" | grep -qiE 'ldap|kerberos'; then
      echo "[AD / LDAP / KERBEROS]"
      echo "  → ldapsearch / kerbrute / enum"
      echo "  → users / domain / AS-REP / password policy"
      grep -qi 'kerberos' "$file" && echo "  → check AS-REP roast / user enum"
      grep -qi 'ldap' "$file" && echo "  → check naming contexts / anonymous bind"
      echo
    fi

    if echo "$open_lines" | grep -qi 'winrm'; then
      echo "[WINRM]"
      echo "  → evil-winrm (when creds available)"
      echo
    fi

    if echo "$open_lines" | grep -qi 'ms-wbt-server'; then
      echo "[RDP]"
      echo "  → xfreerdp / creds / NLA"
      echo
    fi

    if echo "$open_lines" | grep -qi 'ssh'; then
      echo "[SSH]"
      echo "  → creds / keys / version"
      echo "  → usually lower priority unless creds exist"
      echo
    fi

    if echo "$open_lines" | grep -qi 'telnet'; then
      echo "[TELNET]"
      echo "  → manual login check first"
      echo "  → default / weak creds"
      echo "  → inspect banner / prompt"
      echo
    fi

    if echo "$open_lines" | grep -qi 'ftp'; then
      echo "[FTP]"
      echo "  → anonymous / ls / get / put"
      echo "  → writable upload check"
      echo
    fi

    if echo "$open_lines" | grep -qi 'smtp'; then
      echo "[SMTP]"
      echo "  → user enum / VRFY / EXPN"
      echo
    fi

    if echo "$open_lines" | grep -qi 'mysql'; then
      echo "[MYSQL]"
      echo "  → creds / anonymous / local file / version"
      echo
    fi

    if echo "$open_lines" | grep -qi 'postgresql'; then
      echo "[POSTGRESQL]"
      echo "  → creds / db enum / role check"
      echo
    fi

    if echo "$open_lines" | grep -qi 'mongodb'; then
      echo "[MONGODB]"
      echo "  → no-auth / db list / dump"
      echo
    fi

    if echo "$open_lines" | grep -qi 'redis'; then
      echo "[REDIS]"
      echo "  → unauth / config / file write"
      echo
    fi

    if echo "$open_lines" | grep -qi 'elasticsearch'; then
      echo "[ELASTICSEARCH]"
      echo "  → unauth API / indices / data leak"
      echo
    fi

    if echo "$open_lines" | grep -qi 'docker'; then
      echo "[DOCKER]"
      echo "  → Docker API exposure / container escape surface"
      echo
    fi
  } | sed '/^$/N;/^\n$/D'
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
