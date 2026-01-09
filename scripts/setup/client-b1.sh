#!/usr/bin/env bash
set -euo pipefail
ip addr flush dev eth0 || true
ip addr add 192.168.20.10/24 dev eth0
ip link set eth0 up
ip route replace default via 192.168.20.1
