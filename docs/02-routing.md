# Routing design (finale)

## AS numbers
- AS100
- AS200

## OSPF (AS100)
- Reti OSPF area 0:
  - 10.0.12.0/30 (R101–R102)
  - 10.0.13.0/30 (R101–R103)
  - 10.0.23.0/30 (R102–R103)
- Router-ID consigliato: loopback 1.255.0.x/32

## iBGP (AS100)
- Full-mesh iBGP tra R101, R102, R103 usando loopback:
  - R101 lo: 1.255.0.1
  - R102 lo: 1.255.0.2
  - R103 lo: 1.255.0.3
- `update-source lo` su tutte le sessioni iBGP
- `next-hop-self` su R103 verso i peer iBGP (per propagare correttamente l’eBGP)

## eBGP (AS100 <-> AS200)
- Peering: R103 (AS100) <-> R201 (AS200) su 10.0.31.0/30
  - R103: 10.0.31.1
  - R201: 10.0.31.2

## AS200 (no IGP)
- R202: default route -> R201 (10.0.202.1)
- GW200: default route -> R201 (10.0.200.1)
- R201: static route verso:
  - 10.202.3.0/24 via 10.0.202.2
  - 2.80.200.0/24 via 10.0.200.2
  - (se necessario) 10.200.1.0/24 e 10.200.2.0/24 via 10.0.200.2

## Annunci BGP minimi
- AS200 annuncia: 2.80.200.0/24 (DMZ) (+ opzionale 2.255.0.1/32)
- AS100 annuncia: 1.0.101.0/30 e 1.0.102.0/30 (WAN customer)

## Evidenze da salvare in `evidence/`
- `show ip ospf neighbor`
- `show ip route`
- `show ip bgp summary`
- `show ip bgp`
- ping/traceroute verso DMZ e verso reti enterprise