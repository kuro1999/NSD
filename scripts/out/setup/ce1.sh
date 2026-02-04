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
# 1. Eccezione: NON fare NAT per il traffico verso Site 2 (VPN)
iptables -t nat -A POSTROUTING -s 192.168.10.0/24 -d 192.168.20.0/24 -j ACCEPT

# 2. Regola standard: Fai NAT per tutto il resto (Internet)
iptables -t nat -A POSTROUTING -o eth1 -j MASQUERADE
echo "nameserver 2.80.200.3" > /etc/resolv.conf

