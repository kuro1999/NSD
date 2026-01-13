#!/bin/bash
set -e

echo "--- Configurazione Firewall GW200 ---"

# 1. Abilita il forwarding (Essenziale per fare da router)
sysctl -w net.ipv4.ip_forward=1

# 2. Pulizia Totale (Flush) delle regole precedenti
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X

# 3. Imposta Policy di Default a DROP (Chiudi tutto)
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# ================================
# CHAIN INPUT (Traffico diretto AL router GW200)
# ================================
# Accetta traffico di loopback (locale)
iptables -A INPUT -i lo -j ACCEPT

# Accetta traffico di connessioni già stabilite (Stateful)
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Accetta ICMP (Ping) dall'interno (eth1) per debug, ma non da Internet
iptables -A INPUT -i eth1 -p icmp -j ACCEPT


# ================================
# CHAIN FORWARD (Traffico che ATTRAVERSA GW200)
# ================================

# REGOLA 0: Stateful Inspection (Lascia passare le risposte)
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# REGOLA 1: LAN-Client (LAN2) verso Internet
# Requisito: "LAN-client can access the external network... if originated by it"
# La LAN2 è 10.200.2.0/24. Arriva dall'interfaccia interna (eth1) ed esce su eth0.
iptables -A FORWARD -i eth1 -o eth0 -s 10.200.2.0/24 -j ACCEPT

# REGOLA 2: Accesso Esterno verso DNS/Web (DMZ)
# Requisito: "Allow inbound connections for DNS requests... HTTP traffic"
# Il DNS server è 2.80.200.3.
iptables -A FORWARD -i eth0 -d 2.80.200.3 -p udp --dport 53 -j ACCEPT
iptables -A FORWARD -i eth0 -d 2.80.200.3 -p tcp --dport 53 -j ACCEPT
iptables -A FORWARD -i eth0 -d 2.80.200.3 -p tcp --dport 80 -j ACCEPT

# REGOLA 3: Transito VPN verso eFW
# Requisito: "IPSEC traffic to eFW"
# eFW è 2.80.200.2. Deve ricevere i pacchetti VPN da R202.
iptables -A FORWARD -i eth0 -d 2.80.200.2 -p udp --dport 500 -j ACCEPT
iptables -A FORWARD -i eth0 -d 2.80.200.2 -p udp --dport 4500 -j ACCEPT
iptables -A FORWARD -i eth0 -d 2.80.200.2 -p esp -j ACCEPT

# REGOLA 4: Uscita generica per la DMZ (opzionale ma consigliata)
# Permette ai server in DMZ (eFW, DNS) di scaricare aggiornamenti
iptables -A FORWARD -i eth1 -o eth0 -s 2.80.200.0/24 -j ACCEPT

# Permetti il traffico di ritorno (Report) verso il Central Node

iptables -A FORWARD -p tcp --dport 9000 -j ACCEPT
iptables -A FORWARD -p tcp --dport 9001 -j ACCEPT
iptables -A FORWARD -p tcp --dport 9002 -j ACCEPT
iptables -A FORWARD -p tcp --dport 9003 -j ACCEPT


# ================================
# NAT (Masquerade)
# ================================
# Tutto ciò che esce da eth0 viene mascherato con l'IP pubblico di GW200
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

echo "Firewall GW200 Attivo!"
iptables -L -v -n
