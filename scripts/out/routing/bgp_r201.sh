#!/usr/bin/env bash
set -euo pipefail
vtysh <<'VEOF'
conf t

! FILTRO
ip prefix-list AS200_ONLY seq 10 permit 2.0.0.0/8

! ANCHOR ROUTE
ip route 2.0.0.0/8 Null0

! Rotta per il ritorno del traffico verso la DMZ/LAN interna
ip route 2.80.200.0/24 2.0.200.2

router bgp 200
 bgp router-id 2.255.0.1
 no bgp ebgp-requires-policy
 neighbor 10.0.31.1 remote-as 100
 !
 address-family ipv4 unicast
  neighbor 10.0.31.1 activate

  network 2.0.0.0/8

  ! APPLICAZIONE FILTRO
  neighbor 10.0.31.1 prefix-list AS200_ONLY out

 exit-address-family
end
write memory
VEOF
