#!/usr/bin/env bash
set -euo pipefail

echo ">>> Configurazione Network Central Node..."

# 1. Configurazione Interfaccia INTERNA
ip addr flush dev eth0 || true
ip link set eth0 up
ip addr add 10.202.3.10/24 dev eth0

# 2. Configurazione Interfaccia ESTERNA (NAT)
ip addr flush dev eth1 || true
ip link set eth1 up
killall dhclient 2>/dev/null || true
dhclient -v eth1
sleep 5

# 3. Routing (Per rispondere agli Antivirus)
# Serve rotta verso 10.200.1.0/24 (LAN Antivirus) passando per R202
ip route add 10.0.0.0/8 via 10.202.3.1 dev eth0 2>/dev/null || true
# (Opzionale: se vuoi raggiungere anche AS100/AS200 per ping di test)
ip route add 1.0.0.0/8 via 10.202.3.1 dev eth0 2>/dev/null || true
ip route add 2.0.0.0/8 via 10.202.3.1 dev eth0 2>/dev/null || true

# 4. DNS
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 2.80.200.3" >> /etc/resolv.conf

# 5. Installazione Proxy
if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    echo "Internet OK. Procedo con apt..."
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y tinyproxy

    # --- CONFIGURAZIONE SICURA (HARDENING) ---
    # Permettiamo l'accesso SOLO alla subnet degli Antivirus (10.200.1.x)
    # Tutto il resto viene rifiutato di default da Tinyproxy.
    sed -i '/^Allow 127\.0\.0\.1/a Allow 10.200.1.0/24' /etc/tinyproxy/tinyproxy.conf

    service tinyproxy restart
    echo ">>> Central Node Configurato (Accesso ristretto solo ad AV LAN)."
else
    echo "ERRORE CRITICO: Niente Internet."
    exit 1
fi
