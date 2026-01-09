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
