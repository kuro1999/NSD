# VPN IPsec (strongSwan)

## Enterprise VPN (R202 <-> eFW)
- Endpoint R202: 10.0.202.1 (eth0)
- Endpoint eFW: 160.80.200.2 (eth0)
- Protected subnets:
  - LAN3: 10.202.3.0/24
  - LAN1: 10.200.1.0/24

## Customer VPN (CE1 <-> CE2)
- Endpoint CE1: 1.0.101.2 (eth1)
- Endpoint CE2: 10.0.102.2 (eth1)  (se si rende pubblico AS100, cambiare in 1.0.102.2)
- Protected subnets:
  - Site1 LAN: 192.168.10.0/24
  - Site2 LAN: 192.168.20.0/24