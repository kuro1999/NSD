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
