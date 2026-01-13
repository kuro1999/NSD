# Firewall policy (finale)

## Nodi firewall/gateway
- GW200: 10.0.200.2/30 (verso R201), 2.80.200.1/24 (DMZ)
- eFW: 2.80.200.2/24 (outside/DMZ), 10.200.1.1/24 (LAN1)
- iFW: 10.200.1.2/24 (LAN1), 10.200.2.1/24 (LAN2)

## Policy richiesta
1) LAN-client (10.200.2.10) -> esterno consentito solo stateful (connessioni originate da LAN-client)
2) AV (10.200.1.11-13) <-> solo central-node (10.202.3.10) via VPN enterprise
3) Inbound da esterno (lato R201/AS100) consentito solo:
   - DNS (TCP/UDP 53) verso DNS-server 2.80.200.3
   - HTTP (TCP 80) verso DNS-server 2.80.200.3
   - IPsec verso eFW 2.80.200.2 (UDP 500/4500 + ESP)

## Implementazione (linee guida)
- Default DROP su INPUT/FORWARD
- ACCEPT ESTABLISHED,RELATED
- GW200: filtra l’inbound verso DMZ/eFW (FORWARD), e consenti solo le eccezioni sopra
- eFW: consenti IPsec in INPUT; consenti solo traffico necessario LAN1<->LAN3 via tunnel; blocca AV verso tutto il resto
- iFW: consenti LAN2 -> fuori (stateful), blocca LAN2 verso AV e verso LAN1 se non necessario

## Matrice flussi (minimo)
| Sorgente                   | Destinazione | Proto/Port           | Esito          | Nodo enforcement   |
|----------------------------|--------------|----------------------|----------------|--------------------|
| Esterno (AS100/AS200 core) | 2.80.200.3   | tcp/80               | ALLOW          | GW200              |
| Esterno (AS100/AS200 core) | 2.80.200.3   | udp,tcp/53           | ALLOW          | GW200              |
| Esterno (AS100/AS200 core) | 2.80.200.2   | udp/500,udp/4500,ESP | ALLOW          | GW200 + eFW(INPUT) |
| 10.200.2.0/24              | Esterno      | any                  | ALLOW stateful | iFW/eFW/GW200      |
| 10.200.1.0/24 (AV)         | 10.202.3.10  | necessary            | ALLOW          | eFW/iFW            |
| 10.200.1.0/24 (AV)         | altro        | any                  | DENY           | eFW/iFW            |