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
