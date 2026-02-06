#!/usr/bin/env bash
set -euo pipefail
ip addr flush dev eth0 || true
ip addr add 10.202.3.10/24 dev eth0
ip link set eth0 up
ip route replace default via 10.202.3.1

#connessione a NAT
dhclient -v eth1

# 1. Rimuovi il default gateway attuale (quello interno)
ip route del default

# 2. Aggiungi il NUOVO default gateway verso Internet (NAT)
# (Uso l'IP che ho visto nel tuo log dhclient: 192.168.122.1)
ip route add default via 192.168.122.1 dev eth1

# 3. [FONDAMENTALE] Riaggiungi la rotta per la rete interna
# Sostituisci 10.202.3.1 con l'IP del tuo router interno se diverso
ip route add 10.0.0.0/8 via 10.202.3.1 dev eth0

#Metti il DNS  di Google per l'installazione
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 2.80.200.3" >> /etc/resolv.conf

apt-get update
apt-get install -y tinyproxy

# Aggiungi "Allow 10.0.0.0/8" alla configurazione
sed -i '/^Allow 127\.0\.0\.1/a Allow 10.0.0.0/8' /etc/tinyproxy/tinyproxy.conf

# Riavvia il servizio
service tinyproxy restart

