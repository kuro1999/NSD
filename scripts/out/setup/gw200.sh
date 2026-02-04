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

