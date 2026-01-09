#!/usr/bin/env bash
set -euo pipefail
vtysh <<'VEOF'
conf t
router ospf
 ospf router-id 1.255.0.2
 passive-interface default
 no passive-interface eth0
 no passive-interface eth2
exit
interface eth0
 ip ospf area 0
 ip ospf network point-to-point
exit
interface eth2
 ip ospf area 0
 ip ospf network point-to-point
exit
interface lo
 ip ospf area 0
exit
end
write memory
VEOF
