# DNS authoritative + DNSSEC + Web (DMZ)

## IP e host
- DNS-server: 2.80.200.3/24 (GW 2.80.200.1)
- Dominio: nsdcourse.xyz
- www.nsdcourse.xyz → 2.80.200.3 (Apache sul DNS-server)

## Requisiti
- Authoritative DNS per nsdcourse.xyz
- DNSSEC abilitato (zona firmata)
- Web raggiungibile via www.nsdcourse.xyz

## Test
- `dig @2.80.200.3 nsdcourse.xyz`
- `dig +dnssec @2.80.200.3 www.nsdcourse.xyz`
- `wget http://www.nsdcourse.xyz` da LAN-client (10.200.2.10)
