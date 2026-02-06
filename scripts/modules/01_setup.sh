#!/usr/bin/env bash
set -euo pipefail

# Phase A: addressing
# Qui dentro useremo write_file "$OUT/..." per generare setup/*.sh

write_file "$OUT/setup/r101.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
vtysh <<'VEOF'
conf t
interface lo
 no ip address
 ip address 1.255.0.1/32
exit
interface eth0
 no ip address
 ip address 1.0.101.1/30
exit
interface eth1
 no ip address
 ip address 10.0.12.1/30
exit
interface eth2
 no ip address
 ip address 10.0.13.1/30
exit
end
write memory
VEOF
echo "nameserver 2.80.200.3" > /etc/resolv.conf
EOF

write_file "$OUT/setup/r102.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
vtysh <<'VEOF'
conf t
interface lo
 no ip address
 ip address 1.255.0.2/32
exit
interface eth0
 no ip address
 ip address 10.0.12.2/30
exit
interface eth1
 no ip address
 ip address 1.0.102.1/30
exit
interface eth2
 no ip address
 ip address 10.0.23.1/30
exit
end
write memory
VEOF
echo "nameserver 2.80.200.3" > /etc/resolv.conf

EOF

write_file "$OUT/setup/r103.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
vtysh <<'VEOF'
conf t
interface lo
 no ip address
 ip address 1.255.0.3/32
exit
interface eth0
 no ip address
 ip address 10.0.23.2/30
exit
interface eth1
 no ip address
 ip address 10.0.13.2/30
exit
interface eth2
 no ip address
 ip address 10.0.31.1/30
exit
end
write memory
VEOF
echo "nameserver 2.80.200.3" > /etc/resolv.conf
EOF

write_file "$OUT/setup/r201.sh" <<'EOF'
##!/usr/bin/env bash
set -euo pipefail
vtysh <<'VEOF'
conf t
interface lo
 no ip address
 ip address 2.255.0.1/32
exit
interface eth0
 no ip address
 ip address 10.0.31.2/30
exit
interface eth1
 no ip address
 ip address 2.0.202.1/30
 
exit
interface eth2
 no ip address
 # Sostituisci la vecchia config 10.0.200.1 con questa:
 ip address 2.0.200.1/30
exit
end
write memory
VEOF
echo "nameserver 2.80.200.3" > /etc/resolv.conf
EOF

write_file "$OUT/setup/ce1.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
# CE1: eth1=WAN verso R101, eth0=LAN verso client-A1
sysctl -w net.ipv4.ip_forward=1
ip addr flush dev eth1 || true
ip addr add 1.0.101.2/30 dev eth1
ip link set eth1 up
ip route replace default via 1.0.101.1 
ip addr flush dev eth0 || true
ip addr add 192.168.10.1/24 dev eth0
ip link set eth0 up
echo "nameserver 2.80.200.3" > /etc/resolv.conf
 
# Pulisci tutto per sicurezza
iptables -t nat -F
# Unica regola
iptables -t nat -A POSTROUTING -o eth1 ! -d 192.168.20.0/24 -j MASQUERADE

EOF

write_file "$OUT/setup/client-a1.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
ip addr flush dev eth0 || true
ip addr add 192.168.10.10/24 dev eth0
ip link set eth0 up
ip route replace default via 192.168.10.1
echo "nameserver 2.80.200.3" > /etc/resolv.conf
EOF

write_file "$OUT/setup/ce2.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
# CE2: eth1=WAN verso R102, eth0=LAN verso sw1
sysctl -w net.ipv4.ip_forward=1
ip addr flush dev eth1 || true
ip addr add 1.0.102.2/30 dev eth1
ip link set eth1 up
ip route replace default via 1.0.102.1

ip addr flush dev eth0 || true
ip addr add 192.168.20.1/24 dev eth0
ip link set eth0 up

echo "nameserver 2.80.200.3" > /etc/resolv.conf

# Pulisci tutto
iptables -t nat -F

# Unica regola
iptables -t nat -A POSTROUTING -o eth1 ! -d 192.168.10.0/24 -j MASQUERADE
EOF

write_file "$OUT/setup/client-b1.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
ip addr flush dev eth0 || true
ip addr add 192.168.20.10/24 dev eth0
ip link set eth0 up
ip route replace default via 192.168.20.1
echo "nameserver 2.80.200.3" > /etc/resolv.conf
EOF

write_file "$OUT/setup/client-b2.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
ip addr flush dev eth0 || true
ip addr add 192.168.20.11/24 dev eth0
ip link set eth0 up
ip route replace default via 192.168.20.1
echo "nameserver 2.80.200.3" > /etc/resolv.conf
EOF

write_file "$OUT/setup/r202.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
# R202 non è BGP speaker: default route verso R201
sysctl -w net.ipv4.ip_forward=1

# Usiamo IP Pubblico AS200 per coerenza e raggiungibilità VPN diretta
ip addr flush dev eth0 || true
ip addr add 2.0.202.2/30 dev eth0
ip link set eth0 up
# Default gateway verso R201
ip route replace default via 2.0.202.1

ip addr flush dev eth1 || true
ip addr add 10.202.3.1/24 dev eth1
ip link set eth1 up
echo "nameserver 2.80.200.3" > /etc/resolv.conf
EOF

write_file "$OUT/setup/central-node.sh" <<'EOF'
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
EOF

write_file "$OUT/setup/gw200.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
sysctl -w net.ipv4.ip_forward=1

# Usiamo un IP Pubblico della classe AS200
ip addr flush dev eth0 || true
ip addr add 2.0.200.2/30 dev eth0
ip link set eth0 up
# Il gateway è l'interfaccia di R201
ip route replace default via 2.0.200.1 dev eth0

ip addr flush dev eth1 || true
ip addr add 2.80.200.1/24 dev eth1
ip link set eth1 up

ip route replace 10.200.1.0/24 via 2.80.200.2 dev eth1
ip route replace 10.200.2.0/24 via 2.80.200.2 dev eth1
echo "nameserver 2.80.200.3" > /etc/resolv.conf

EOF

write_file "$OUT/setup/efw.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
sysctl -w net.ipv4.ip_forward=1

# --- Verso DMZ (br1) ---
ip addr flush dev eth0 || true
ip addr add 2.80.200.2/24 dev eth0
ip link set eth0 up

# --- Verso LAN1 (br2) ---
ip addr flush dev eth1 || true
ip addr add 10.200.1.1/24 dev eth1
ip link set eth1 up

# --- Routing ---
# 1. Default Gateway: tutto ciò che non conosco va verso GW200
ip route replace default via 2.80.200.1 dev eth0

# 2. Verso LAN2 (LAN-client)
# LAN2 è dietro iFW. Dobbiamo sapere l'IP di iFW nella LAN1.
# Supponendo che iFW sia collegato a br2 e abbia IP 10.200.1.2:
ip route replace 10.200.2.0/24 via 10.200.1.2 dev eth1

echo "nameserver 2.80.200.3" > /etc/resolv.conf

EOF

write_file "$OUT/setup/ifw.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
sysctl -w net.ipv4.ip_forward=1
ip addr flush dev eth0 || true
ip addr add 10.200.1.2/24 dev eth0
ip link set eth0 up

ip addr flush dev eth1 || true
ip addr add 10.200.2.1/24 dev eth1
ip link set eth1 up

ip route replace default via 10.200.1.1
echo "nameserver 2.80.200.3" > /etc/resolv.conf

EOF

write_file "$OUT/setup/dns-net.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
ip addr flush dev eth0 || true
# DNS server in DMZ (pool pubblico AS200): 2.80.200.3/24
ip addr add 2.80.200.3/24 dev eth0
ip link set eth0 up
ip route replace default via 2.80.200.1
ip route add 10.200.2.0/24 via 2.80.200.2 dev eth0
EOF

write_file "$OUT/setup/av1.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
ip addr flush dev eth0 || true
ip addr add 10.200.1.11/24 dev eth0
ip link set eth0 up
ip route replace default via 10.200.1.1
EOF

write_file "$OUT/setup/av2.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
ip addr flush dev eth0 || true
ip addr add 10.200.1.12/24 dev eth0
ip link set eth0 up
ip route replace default via 10.200.1.1
EOF

write_file "$OUT/setup/av3.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
ip addr flush dev eth0 || true
ip addr add 10.200.1.13/24 dev eth0
ip link set eth0 up
ip route replace default via 10.200.1.1
EOF

write_file "$OUT/setup/lan-client.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
ip addr flush dev eth0 || true
ip addr add 10.200.2.10/24 dev eth0
ip link set eth0 up
ip route replace default via 10.200.2.1
echo "nameserver 2.80.200.3" > /etc/resolv.conf

EOF


