# Routing design e configurazione

## 1. Obiettivi
- AS100: OSPF per reachability interna; iBGP tra border; eBGP verso AS200
- AS200: solo R201 parla BGP; R202 e GW200 hanno default verso R201

## 2. OSPF (AS100)
### Area e reti
- Area: 0
- Interface OSPF: link interni tra R101-R102-R103 (p2p /30)

### Verifiche
- Neighbors: FULL
- Routing table: tutte le reti interne AS100 presenti

## 3. iBGP (AS100)
### Peering
- iBGP tra border router: <R101> <-> <R103>
- Sessione su loopback (consigliato) o su interfaccia stabile
- Next-hop-self dove necessario

### Verifiche
- BGP summary: Established
- Annunci interni propagati

## 4. eBGP (AS100 <-> AS200)
### Peering
- R103 (AS100) <-> R201 (AS200) sul link inter-AS

### Annunci
- AS200 annuncia DMZ (prefisso pubblico AS200)
- AS100 annuncia prefissi pubblici rilevanti (inclusi IP pubblici customer se richiesto)

### Verifiche
- Ping/traceroute verso DMZ da AS100
- Tabella BGP contiene prefissi attesi

## 5. Static routing (AS200 interno)
- R202: default verso R201
- GW200: default verso R201
- R201: static per DMZ via GW200 e LAN3 via R202 (e altre reti interne se applicabile)

## 6. Evidenze richieste (salvare in `evidence/`)
- `show ip ospf neighbor`
- `show ip route`
- `show ip bgp summary`
- `show ip bgp`
- ping/traceroute significativi