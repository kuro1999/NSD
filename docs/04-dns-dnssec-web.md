# DNS authoritative + DNSSEC + Web (DMZ)

## IP e host
- DNS-server: 160.80.200.3/24 (GW 160.80.200.1)
- Dominio: nsdcourse.xyz
- www.nsdcourse.xyz -> 160.80.200.3 (Apache sul DNS-server)

## Requisiti
- Authoritative DNS per nsdcourse.xyz
- DNSSEC abilitato (zona firmata)
- Web raggiungibile via www.nsdcourse.xyz

## Test
- `dig @160.80.200.3 nsdcourse.xyz SOA`
- `dig +dnssec @160.80.200.3 www.nsdcourse.xyz A`
- `curl http://www.nsdcourse.xyz` da LAN-client (10.200.2.10)