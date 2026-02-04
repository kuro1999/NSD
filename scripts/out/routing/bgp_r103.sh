#!/usr/bin/env bash
#etc/frr/frr.conf
set -euo pipefail
vtysh <<'VEOF'
conf t

ip prefix-list AS100_ONLY seq 10 permit 1.0.0.0/8


! Crea la rete stabilmente nella tabella di routing
ip route 1.0.0.0/8 Null0
!
router bgp 100
 bgp router-id 1.255.0.3
 no bgp ebgp-requires-policy
 ! iBGP Interne
 neighbor 1.255.0.1 remote-as 100
 neighbor 1.255.0.1 update-source lo
 neighbor 1.255.0.2 remote-as 100
 neighbor 1.255.0.2 update-source lo
 ! eBGP verso AS200
 neighbor 10.0.31.2 remote-as 200
 !
 address-family ipv4 unicast
  neighbor 1.255.0.1 activate
  neighbor 1.255.0.2 activate
  neighbor 10.0.31.2 activate


  neighbor 1.255.0.1 next-hop-self
  neighbor 1.255.0.2 next-hop-self

  ! ANNUNCIO UFFICIALE 
  network 1.0.0.0/8
  ! "Verso AS200, lascia passare SOLO la 1.0.0.0/8"
  neighbor 10.0.31.2 prefix-list AS100_ONLY out
 exit-address-family
end
write memory
VEOF
