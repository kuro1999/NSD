#!/usr/bin/env bash
set -euo pipefail

# Questo script genera:
#  - setup/   : script di addressing e host configuration
#  - routing/ : script di routing (OSPF in AS100)

mkdir -p setup routing

# =========================
# Phase A: addressing
# =========================

cat > setup/r101.sh <<'EOF'
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
EOF


cat > setup/r102.sh <<'EOF'
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
EOF

cat > setup/r103.sh <<'EOF'
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
EOF

cat > setup/r201.sh <<'EOF'
#!/usr/bin/env bash
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
 ip address 10.0.202.1/30
exit
interface eth2
 no ip address
 ip address 10.0.200.1/30
exit
end
write memory
VEOF
EOF

cat > setup/ce1.sh <<'EOF'
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
EOF

cat > setup/client-a1.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
ip addr flush dev eth0 || true
ip addr add 192.168.10.10/24 dev eth0
ip link set eth0 up
ip route replace default via 192.168.10.1
EOF


cat > setup/ce2.sh <<'EOF'
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
EOF

cat > setup/client-b1.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
ip addr flush dev eth0 || true
ip addr add 192.168.20.10/24 dev eth0
ip link set eth0 up
ip route replace default via 192.168.20.1
EOF

cat > setup/client-b2.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
ip addr flush dev eth0 || true
ip addr add 192.168.20.11/24 dev eth0
ip link set eth0 up
ip route replace default via 192.168.20.1
EOF

cat > setup/r202.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
# R202 non è BGP speaker: default route verso R201
sysctl -w net.ipv4.ip_forward=1
ip addr flush dev eth0 || true
ip addr add 10.0.202.2/30 dev eth0
ip link set eth0 up
ip route replace default via 10.0.202.1

ip addr flush dev eth1 || true
ip addr add 10.202.3.1/24 dev eth1
ip link set eth1 up
EOF

cat > setup/central-node.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
ip addr flush dev eth0 || true
ip addr add 10.202.3.10/24 dev eth0
ip link set eth0 up
ip route replace default via 10.202.3.1
EOF

cat > setup/gw200.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
# GW200 non è BGP speaker: default route verso R201
sysctl -w net.ipv4.ip_forward=1
ip addr flush dev eth0 || true
ip addr add 10.0.200.2/30 dev eth0
ip link set eth0 up
ip route replace default via 10.0.200.1

ip addr flush dev eth1 || true
# DMZ presa dal pool pubblico di AS200 (2.0.0.0/8) -> qui: 2.80.200.0/24
ip addr add 2.80.200.1/24 dev eth1
ip link set eth1 up

# Rotte verso Enterprise dietro eFW (DMZ side eFW = 2.80.200.2)
ip route replace 10.200.1.0/24 via 2.80.200.2
ip route replace 10.200.2.0/24 via 2.80.200.2
EOF

cat > setup/efw.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
sysctl -w net.ipv4.ip_forward=1
ip addr flush dev eth0 || true
# eFW su DMZ (pool pubblico AS200): 2.80.200.2/24
ip addr add 2.80.200.2/24 dev eth0
ip link set eth0 up

ip addr flush dev eth1 || true
ip addr add 10.200.1.1/24 dev eth1
ip link set eth1 up

ip route replace default via 2.80.200.1
ip route replace 10.200.2.0/24 via 10.200.1.2
EOF

cat > setup/ifw.sh <<'EOF'
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
EOF

cat > setup/dns.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
ip addr flush dev eth0 || true
# DNS server in DMZ (pool pubblico AS200): 2.80.200.3/24
ip addr add 2.80.200.3/24 dev eth0
ip link set eth0 up
ip route replace default via 2.80.200.2
EOF

cat > setup/av1.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
ip addr flush dev eth0 || true
ip addr add 10.200.1.11/24 dev eth0
ip link set eth0 up
ip route replace default via 10.200.1.2
EOF

cat > setup/av2.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
ip addr flush dev eth0 || true
ip addr add 10.200.1.12/24 dev eth0
ip link set eth0 up
ip route replace default via 10.200.1.2
EOF

cat > setup/av3.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
ip addr flush dev eth0 || true
ip addr add 10.200.1.13/24 dev eth0
ip link set eth0 up
ip route replace default via 10.200.1.2
EOF

cat > setup/lan-client.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
ip addr flush dev eth0 || true
ip addr add 10.200.2.10/24 dev eth0
ip link set eth0 up
ip route replace default via 10.200.2.1
EOF

# =========================
# Step 3: OSPF inside AS100
# =========================

cat > routing/ospf_r101.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
vtysh <<'VEOF'
conf t
router ospf
 ospf router-id 1.255.0.1
 passive-interface default
 no passive-interface eth1
 no passive-interface eth2
exit
interface eth1
 ip ospf area 0
 ip ospf network point-to-point
exit
interface eth2
 ip ospf area 0
 ip ospf network point-to-point
exit
interface lo
 ip ospf area 0
exit
end
write memory
VEOF
EOF

cat > routing/ospf_r102.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
vtysh <<'VEOF'
conf t
router ospf
 ospf router-id 1.255.0.2
 passive-interface default
 no passive-interface eth0
 no passive-interface eth2
exit
interface eth0
 ip ospf area 0
 ip ospf network point-to-point
exit
interface eth2
 ip ospf area 0
 ip ospf network point-to-point
exit
interface lo
 ip ospf area 0
exit
end
write memory
VEOF
EOF

cat > routing/ospf_r103.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
vtysh <<'VEOF'
conf t
router ospf
 ospf router-id 1.255.0.3
 passive-interface default
 no passive-interface eth0
 no passive-interface eth1
exit
interface eth0
 ip ospf area 0
 ip ospf network point-to-point
exit
interface eth1
 ip ospf area 0
 ip ospf network point-to-point
exit
interface lo
 ip ospf area 0
exit
end
write memory
VEOF
EOF

chmod +x setup/*.sh routing/*.sh
echo "OK: creati setup/ e routing/. Ora esegui gli script dentro i nodi GNS3."
