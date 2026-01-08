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
- Sessione iBGP tra R101 e R103 usando loopback:
  - R101 lo: 1.255.0.1
  - R103 lo: 1.255.0.3
- `next-hop-self` su border dove serve

## eBGP (AS100 <-> AS200)
- Peering: R103 (AS100) <-> R201 (AS200) su 10.0.31.0/30
  - R103: 10.0.31.1
  - R201: 10.0.31.2

## AS200 (no IGP)
- R202: default route -> R201 (10.0.202.2)
- GW200: default route -> R201 (10.0.200.1)
- R201: static route verso:
  - 10.202.3.0/24 via 10.0.202.1
  - 160.80.200.0/24 via 10.0.200.2
  - (se necessario) 10.200.1.0/24 e 10.200.2.0/24 via 10.0.200.2

## Annunci BGP minimi
- AS200 annuncia: 160.80.200.0/24 (DMZ)
- AS100 annuncia: (se richiesto) i prefissi customer WAN e loopback (in base al vostro modello di reachability)

## Evidenze da salvare in `evidence/`
- `show ip ospf neighbor`
- `show ip route`
- `show ip bgp summary`
- `show ip bgp`
- ping/traceroute verso DMZ e verso reti enterprise