#!/bin/bash
echo "--- BLINDAGGIO iFW ---"

# 1. Pulisci tutto (Tabula rasa)
iptables -F
iptables -X

# 2. Imposta la Policy su DROP (Questo è il comando che uccide il Redirect)
# Se il pacchetto non è autorizzato, viene buttato via SENZA risposta.
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# 3. Regola per connessioni già stabilite (fondamentale per le risposte)
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# 4. LAN-Client (LAN2): LUI PUÒ PASSARE
iptables -A FORWARD -s 10.200.2.0/24 -j ACCEPT

# 5. AV1 (LAN1): PUÒ ANDARE SOLO VERSO LA VPN (Central Node)
# Nota: Non c'è nessuna regola per andare su Internet (10.0.200.1)
iptables -A FORWARD -s 10.200.1.0/24 -d 10.202.3.0/24 -j ACCEPT

# (Opzionale) Permetti ICMP in ingresso al firewall per debug locale
iptables -A INPUT -p icmp -j ACCEPT

echo "iFW ora è in modalità DROP."
