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
