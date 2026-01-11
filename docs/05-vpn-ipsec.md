# VPN IPsec (strongSwan)

## Enterprise VPN (R202 <-> eFW)
- Endpoint R202: 10.0.202.1 (eth0)
- Endpoint eFW: 160.80.200.2 (eth0)
- Protected subnets:
  - LAN3: 10.202.3.0/24
  - LAN1: 10.200.1.0/24

## Customer VPN (CE1 <-> CE2)

### Obiettivo
Implementare una VPN site-to-site IPsec tra due sedi cliente, usando CE1 e CE2 come security gateway, con endpoint pubblici allocati dal pool di AS100.

### Topologia e indirizzi
- CE1 (WAN): 1.0.101.2/30, default via 1.0.101.1
- CE2 (WAN): 1.0.102.2/30, default via 1.0.102.1
- LAN Site A: 192.168.10.0/24 (GW 192.168.10.1, client-A1 192.168.10.10)
- LAN Site B: 192.168.20.0/24 (GW 192.168.20.1, client-B1 192.168.20.10)

### Scelte e motivazione
- IKEv2 + PSK: semplice e robusto per laboratorio, nessuna PKI richiesta.
- Traffic Selectors: cifratura solo del traffico LAN_A ↔ LAN_B, non di tutto Internet.
- TUNNEL mode (ESP): tipico per VPN site-to-site.
- IP forwarding attivo sui CE: necessario perché i CE instradano traffico tra LAN e tunnel.

### Implementazione
- Verifica reachability tra gli endpoint WAN: CE1 ↔ CE2 si pingano sugli IP pubblici.
- Abilitato `net.ipv4.ip_forward=1` su CE1 e CE2.
- Configurato strongSwan via swanctl:
  - file `/etc/swanctl/conf.d/ipsec.conf` su entrambi i CE
  - connessione `ce1-ce2` / `ce2-ce1`
  - child `lan-lan` con Traffic Selectors:
    - CE1: 192.168.10.0/24 ↔ 192.168.20.0/24
    - CE2: speculare
  - autenticazione PSK (secrets)
- Avvio servizio IPsec (`service ipsec start`), load configurazione (`swanctl --load-creds`, `swanctl --load-conns`).
- Iniziata negoziazione dal lato CE1 (`swanctl --initiate --child lan-lan`).

### Verifica
- `swanctl --list-sas`: IKE_SA `ESTABLISHED`, CHILD_SA `INSTALLED` su entrambi.
- Ping client-A1 ↔ client-B1 riuscito.
- Contatori bytes/packets in `swanctl --list-sas` aumentano dopo il traffico → conferma che il traffico passa nel tunnel.
