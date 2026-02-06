#!/usr/bin/env bash
set -euo pipefail

# =========================
# FIREWALL
# =========================

write_file "$OUT/firewall/gw200.sh" <<'EOF'
#!/bin/bash
# 1. Abilita il forwarding (fondamentale)
sysctl -w net.ipv4.ip_forward=1

# 2. Pulisci tutte le regole vecchie
iptables -F
iptables -X
iptables -t nat -F

# 3. Imposta la Policy di Default: BLOCCA TUTTO (tranne l'uscita dal router stesso)
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# --- CHAIN INPUT (Traffico diretto AL router GW200) ---
# Accetta traffico locale (loopback)
iptables -A INPUT -i lo -j ACCEPT
# Accetta risposte a connessioni fatte dal router stesso o già stabilite
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
# Accetta Ping solo dall'interno per debug
iptables -A INPUT -i eth1 -p icmp -j ACCEPT

# --- CHAIN FORWARD (Traffico che ATTRAVERSA GW200) ---

# REGOLA 0: Stateful Inspection (FONDAMENTALE)
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# REGOLA 1: LAN-Client (LAN2) verso Internet
iptables -A FORWARD -i eth1 -o eth0 -s 10.200.2.0/24 -j ACCEPT

# REGOLA 2: Internet verso DNS Server (DMZ)
iptables -A FORWARD -i eth0 -d 2.80.200.3 -p udp --dport 53 -j ACCEPT
iptables -A FORWARD -i eth0 -d 2.80.200.3 -p tcp --dport 53 -j ACCEPT
iptables -A FORWARD -i eth0 -d 2.80.200.3 -p tcp --dport 80 -j ACCEPT

# REGOLA 3: Internet verso eFW (VPN IPsec)
iptables -A FORWARD -i eth0 -d 2.80.200.2 -p udp --dport 500 -j ACCEPT
iptables -A FORWARD -i eth0 -d 2.80.200.2 -p udp --dport 4500 -j ACCEPT
iptables -A FORWARD -i eth0 -d 2.80.200.2 -p esp -j ACCEPT

# Lascia uscire la DMZ per aggiornamenti
iptables -A FORWARD -i eth1 -o eth0 -s 2.80.200.0/24 -j ACCEPT


echo "Firewall GW200 applicato."
EOF

write_file "$OUT/firewall/eFW.sh" <<'EOF'
#!/bin/bash
echo "--- Configurazione Firewall eFW ---"
  
 # 1. Abilita il forwarding
   sysctl -w net.ipv4.ip_forward=1
  
   # 2. Pulizia regole
   iptables -F
  iptables -X
  iptables -t nat -F
 
  # 3. Policy di Default: DROP (Chiudi tutto)
  iptables -P INPUT DROP
  iptables -P FORWARD DROP
  iptables -P OUTPUT ACCEPT
 
  # ================================
  # CHAIN INPUT (Traffico diretto a eFW)
  # ================================
  iptables -A INPUT -i lo -j ACCEPT
  iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
 
  # REGOLA VPN: Accetta traffico IPsec in ingresso (da Internet/GW200)
  iptables -A INPUT -p udp --dport 500 -j ACCEPT
  iptables -A INPUT -p udp --dport 4500 -j ACCEPT
  iptables -A INPUT -p esp -j ACCEPT
 
  # (Opzionale) SSH/Ping dalla DMZ (management)
  iptables -A INPUT -s 2.80.200.0/24 -p icmp -j ACCEPT
 
  # ===============================
  # CHAIN FORWARD (Traffico che passa attraverso)
  # ===============================
  iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
 
  # REGOLA 1: LAN-Client (LAN2) verso Internet
  iptables -A FORWARD -i eth1 -o eth0 -s 10.200.2.0/24 -j ACCEPT
  iptables -A FORWARD -i eth0 -o eth1 -d 10.200.2.0/24 -j ACCEPT
 
  # REGOLA 2: Antivirus (LAN1) verso Central Node (LAN3)
  iptables -A FORWARD -s 10.200.1.0/24 -d 10.202.3.0/24 -j ACCEPT
 
  # REGOLA 3: Central Node (LAN3) verso Antivirus (LAN1)
  iptables -A FORWARD -s 10.202.3.0/24 -d 10.200.1.0/24 -j ACCEPT

  # eFW maschera le LAN interne uscendo verso la DMZ/GW200
  iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
 
  echo "Firewall eFW configurato."
  iptables -L -v -n
EOF

write_file "$OUT/firewall/ifw.sh" <<'EOF'
#!/bin/bash
echo "--- Configurazione Firewall iFW ---"

# 1. Abilita il forwarding
sysctl -w net.ipv4.ip_forward=1

# 2. Pulizia regole
iptables -F
iptables -X
iptables -t nat -F

# 3. Policy di Default: DROP
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# ================================
# CHAIN INPUT (Traffico diretto a iFW)
# ================================
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p icmp -j ACCEPT

# ================================
# CHAIN FORWARD (Traffico che attraversa iFW)
# ================================
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# REGOLA 1: LAN-Client (LAN2) verso OVUNQUE
iptables -A FORWARD -s 10.200.2.0/24 -j ACCEPT

# REGOLA 2: Antivirus (LAN1) verso Central Node (VPN)
iptables -A FORWARD -s 10.200.1.0/24 -d 10.202.3.0/24 -j ACCEPT

echo "Firewall iFW configurato."
iptables -L -v -n
EOF
