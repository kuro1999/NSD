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
