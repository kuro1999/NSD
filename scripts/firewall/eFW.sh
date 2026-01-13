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
# Accetta traffico locale
iptables -A INPUT -i lo -j ACCEPT
# Accetta connessioni già stabilite (es. aggiornamenti del firewall stesso)
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# REGOLA VPN: Accetta traffico IPsec in ingresso (da Internet/GW200)
# Serve per far salire il tunnel con R202
iptables -A INPUT -p udp --dport 500 -j ACCEPT
iptables -A INPUT -p udp --dport 4500 -j ACCEPT
iptables -A INPUT -p esp -j ACCEPT

# (Opzionale) SSH/Ping dalla DMZ (management)
iptables -A INPUT -s 2.80.200.0/24 -p icmp -j ACCEPT


# ================================
# CHAIN FORWARD (Traffico che passa attraverso)
# ================================
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# REGOLA 1: LAN-Client (LAN2) verso Internet
# La LAN2 (10.200.2.0/24) arriva da eth1 (via iFW).
# Deve poter andare ovunque.
iptables -A FORWARD -i eth1 -o eth0 -s 10.200.2.0/24 -j ACCEPT

# REGOLA 2: Antivirus (LAN1) verso Central Node (LAN3)
# Gli AV (10.200.1.0/24) possono parlare SOLO con la rete del Central Node (10.202.3.0/24)
# Questo traffico verrà poi cifrato dalla VPN (che configureremo dopo)
iptables -A FORWARD -s 10.200.1.0/24 -d 10.202.3.0/24 -j ACCEPT

# REGOLA 3: Central Node (LAN3) verso Antivirus (LAN1)
# Permette al Central Node di iniziare connessioni verso gli AV
iptables -A FORWARD -s 10.202.3.0/24 -d 10.200.1.0/24 -j ACCEPT

# NOTA: Manca la regola per LAN1 -> Internet.
# Quindi se un virus prova a uscire, cade nel DROP di default.

echo "Firewall eFW configurato."
iptables -L -v -n
