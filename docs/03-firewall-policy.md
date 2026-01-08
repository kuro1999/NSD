# Firewall policy e implementazione

## 1. Obiettivi di policy (alto livello)
1. LAN-client -> esterno: consentito solo traffico originato dal LAN-client (stateful)
2. Traffico AV: consentito solo con central-node (nessun altro flusso)
3. Inbound da esterno: consentire solo
   - DNS (TCP/UDP 53) verso dns-server
   - HTTP (TCP 80) verso dns-server
   - IPsec verso eFW (UDP 500/4500 + ESP)

## 2. Architettura
- GW200: enforcement “edge”/perimetro verso DMZ e verso eFW (inbound control)
- eFW: enforcement tra DMZ/outside e LAN1 (protezione enterprise + IPsec termination)
- iFW: enforcement interno LAN1 <-> LAN2

## 3. Regole comuni (baseline)
- Default: DROP su INPUT e FORWARD
- Allow: ESTABLISHED,RELATED
- Allow: ICMP mirato per troubleshooting (opzionale ma consigliato)

## 4. Regole specifiche per nodo (riassunto)
### GW200
- Allow inbound DNS/HTTP verso dns-server
- Allow inbound IPsec verso eFW (forward)
- Drop tutto il resto inbound dall’esterno

### eFW
- Allow IPsec (INPUT) per IKE/ESP
- Allow traffico VPN LAN3 <-> LAN1 (solo ciò che serve per central-node <-> AV)
- Bloccare AV <-> qualsiasi eccetto central-node

### iFW
- Allow LAN2 -> fuori (stateful)
- Limitare LAN2 <-> LAN1 secondo necessità (minimo: evitare accesso LAN2 verso AV)

## 5. Matrice flussi (compilare)
| Source | Dest | Proto/Port | Allowed? | Nodo che applica |
|---|---|---|---|---|
| LAN-client | Internet/DMZ | tcp/80 | YES | iFW/eFW/GW200 |
| LAN-client | Internet/DMZ | udp,tcp/53 | YES | iFW/eFW/GW200 |
| Internet | dns-server | udp,tcp/53 | YES | GW200 |
| Internet | dns-server | tcp/80 | YES | GW200 |
| Internet | eFW | udp/500, udp/4500, ESP | YES | GW200 + eFW INPUT |
| AV1-3 | central-node | ip (via VPN) | YES | eFW/iFW |
| AV1-3 | altro | any | NO | eFW/iFW |

## 6. Evidenze (salvare in `evidence/`)
- Dump regole (iptables/nft)
- Prove positive: curl/dig da LAN-client; accesso DNS/HTTP dall’esterno (se simulato)
- Prove negative: porte non permesse; AV che prova a uscire verso DMZ o LAN-client