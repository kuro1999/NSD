#!/usr/bin/env bash
set -euo pipefail
ip addr flush dev eth0 || true
# DNS server in DMZ (pool pubblico AS200): 2.80.200.3/24
ip addr add 2.80.200.3/24 dev eth0
ip link set eth0 up
ip route replace default via 2.80.200.1
ip route add 10.200.2.0/24 via 2.80.200.2 dev eth0
