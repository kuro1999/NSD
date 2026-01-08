# Scope e assunzioni

## Scope
Implementazione completa del progetto in GNS3:
- AS100: OSPF interno + iBGP tra border + eBGP con AS200
- AS200: R201 BGP speaker; R202 e GW200 non-BGP con default verso R201
- DMZ con DNS authoritative DNSSEC per `nsdcourse.xyz` e Apache su `www.nsdcourse.xyz`
- Firewalling secondo policy
- VPN IPsec enterprise (R202 <-> eFW) per connettività LAN3 <-> LAN1
- VPN customer IPsec (CE1 <-> CE2)
- MACsec con MKA nella LAN di Site2 (client-B1/B2 e CE2)
- Sandbox AV con 3 runner + central-node

## Assunzioni implementative (da confermare e mantenere coerenti)
- OS: Debian/Ubuntu-like su nodi Linux; FRR per routing (se applicabile)
- IPsec: strongSwan (IKEv2 + PSK)
- Firewall: iptables/nftables (specificare cosa si usa)
- DNS: BIND9
- Snapshot runner AV: snapshot GNS3/QEMU oppure reset “stateless” (documentare la scelta)

## Convezioni
- Tutti i link router-router p2p: /30 privati
- Prefissi pubblici: pool dedicati per AS100 e AS200 (documentazione/riservati)
- DMZ: prefisso preso dal pool AS200
- CE1 e CE2: IP pubblici dal pool AS100 (solo sulle WAN/peering)