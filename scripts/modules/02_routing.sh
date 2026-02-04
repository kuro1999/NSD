#!/usr/bin/env bash
set -euo pipefail

# Step 3: OSPF inside AS100 + BGP

write_file "$OUT/routing/ospf_r101.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
vtysh <<'VEOF'
conf t
router ospf
 ospf router-id 1.255.0.1
 passive-interface default
 no passive-interface eth1
 no passive-interface eth2
exit
interface eth1
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
EOF

write_file "$OUT/routing/ospf_r102.sh" <<'EOF'
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
EOF

write_file "$OUT/routing/ospf_r103.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
vtysh <<'VEOF'
conf t
router ospf
 ospf router-id 1.255.0.3
 passive-interface default
 no passive-interface eth0
 no passive-interface eth1
exit
interface eth0
 ip ospf area 0
 ip ospf network point-to-point
exit
interface eth1
 ip ospf area 0
 ip ospf network point-to-point
exit
interface lo
 ip ospf area 0
exit
end
write memory
VEOF
EOF

write_file "$OUT/routing/bgp_r101.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
vtysh <<'VEOF'
conf t
router bgp 100
 bgp router-id 1.255.0.1
 no bgp ebgp-requires-policy
 neighbor 1.255.0.2 remote-as 100
 neighbor 1.255.0.2 update-source lo
 neighbor 1.255.0.3 remote-as 100
 neighbor 1.255.0.3 update-source lo
 !
 address-family ipv4 unicast
  neighbor 1.255.0.2 activate
  neighbor 1.255.0.3 activate
  network 1.0.101.0/30
 exit-address-family
end
write memory
VEOF
EOF

write_file "$OUT/routing/bgp_r102.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
vtysh <<'VEOF'
conf t
router bgp 100
 bgp router-id 1.255.0.2
 no bgp ebgp-requires-policy
 neighbor 1.255.0.1 remote-as 100
 neighbor 1.255.0.1 update-source lo
 neighbor 1.255.0.3 remote-as 100
 neighbor 1.255.0.3 update-source lo
 !
 address-family ipv4 unicast
  neighbor 1.255.0.1 activate
  neighbor 1.255.0.3 activate
  network 1.0.102.0/30
 exit-address-family
end
write memory
VEOF
EOF

write_file "$OUT/routing/bgp_r103.sh" <<'EOF'
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
EOF

write_file "$OUT/routing/bgp_r201.sh" <<'EOF'
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
EOF
