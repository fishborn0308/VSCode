# General
alias ll='ls -alF'
alias vpnip="ip -br -4 a show tun0 | awk '{print \$3}' | cut -d/ -f1"
alias gclone='cd ~/Tools/Git && git clone'
alias opentarget='xdg-open "$TARGET_DIR/$TARGET_IP.md"'
alias gup='find ~/Tools/Git -maxdepth 2 -name .git -type d -execdir git pull --rebase \;'
alias maintenance='sudo apt update && sudo apt dist-upgrade -y && gup && pipx upgrade-all'

# Tools
alias udot='updog -p 80'
alias pserv='python3 -m http.server 8000'
alias pserv80='sudo python3 -m http.server 80'
alias chisel_srv='~/Tools/Bin/chisel server -p 8080 --reverse'
alias icat='kitty +kitten icat'
alias l2m='~/Tools/Shell/log2memo.sh'
alias l2o='~/Tools/Shell/log2obsidian.sh'

# Recon & Logs (複雑なものは本来 functions/ へ)
alias arlog='tail -f $OUT/autorecon/autorecon.log'
alias ar='autorecon "$TARGET_IP" -o "$OUT/autorecon" 2>&1 | tee "$OUT/autorecon/autorecon.log"'
alias ar_f_nmap='autorecon "$TARGET_IP" -p "$INIT_PORTS" -o "$OUT/autorecon" 2>&1 | tee "$OUT/autorecon/autorecon_nmap.log"'
alias ar_f_nmap_full='ports=$(extract_ports_gnmap "$OUT/nmap_full.gnmap"); autorecon "$TARGET_IP" -p "$ports" -o "$OUT/autorecon" 2>&1 | tee "$OUT/autorecon/autorecon_full.log"'
alias udp-open='grep -E "open|open\\|filtered" $OUT/nmap_udp_*.nmap 2>/dev/null'

# cd aliases
alias cdword='cd "$WORDLISTS"'
alias cdusers='cd "$USERS"'
alias cdpass='cd "$PASSES"'
alias cdcreds='cd "$CREDS"'
alias cddisc='cd "$DISCOVERY"'
alias cdseclists='cd "$SECLISTS"'
