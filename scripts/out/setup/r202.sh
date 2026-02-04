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
