# Scope e assunzioni

## Scope
Implementazione in GNS3 di:
- AS100: OSPF interno + iBGP tra border + eBGP con AS200
- AS200: R201 BGP speaker; R202 e GW200 non-BGP con default verso R201
- Enterprise Net: DMZ con DNS authoritative DNSSEC e web su `www.nsdcourse.xyz`
- Firewalling secondo policy di progetto
- VPN IPsec enterprise: R202 <-> eFW (LAN3 <-> LAN1)
- VPN customer: CE1 <-> CE2 (Site1 LAN <-> Site2 LAN)
- MACsec con MKA in Site2 LAN (CE2, client-B1, client-B2)
- Sandbox AV: central-node + AV1/AV2/AV3 con ripristino via snapshot

## Convenzioni
- Link router-router: /30 su pool privato 10.0.0.0/16
- Loopback router per routing/BGP: /32
- LAN enterprise e customer: /24
- Snapshot AV runners: ripristino via snapshot GNS3 dopo ogni scan

## Note di compliance (rispetto traccia)
- DMZ attuale: 160.80.200.0/24. Se richiesto "DMZ nel pool AS200", spostare DMZ in 2.0.0.0/8 o dichiarare 160.80.200.0/24 come prefisso assegnato ad AS200.
- CE2 WAN attuale: 10.0.102.0/30 (privato). Se richiesto IP pubblico AS100 per CE2, cambiare in 1.0.102.0/30.