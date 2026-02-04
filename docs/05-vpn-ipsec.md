 # VPN IPsec (strongSwan)

 ## Enterprise VPN (R202 <-> eFW)
 - Endpoint R202: 2.0.202.2 (eth0)
 - Endpoint eFW: 2.80.200.2 (eth0)
 - Protected subnets:
   - LAN3: 10.202.3.0/24
   - LAN1: 10.200.1.0/24

### Implementazione (StrongSwan + swanctl)
La VPN enterprise è implementata con strongSwan (IKEv2) e configurata tramite `swanctl`.
I file di configurazione sono generati dagli script `ipsec.sh` su entrambi i nodi e salvati in:
- `/etc/swanctl/conf.d/ipsec.conf`

Parametri principali:
- IKE version: IKEv2
- Autenticazione: PSK (pre-shared key)
- NAT-T/encapsulation: `encap = yes` (abilitato per robustezza anche se non c’è NAT in lab)
- MOBIKE: disabilitato (`mobike = no`)
- Identità:
  - R202 usa `id = r202`
  - eFW usa `id = efw`
- Cifrari (devono combaciare su entrambi i lati):
  - IKE proposal: `aes128-sha256-modp2048`
  - ESP proposal: `aes128-sha256-modp2048`

Traffic Selectors (policy-based):
- R202: `local_ts = 10.202.3.0/24` (LAN3), `remote_ts = 10.200.1.0/24` (LAN1)
- eFW: speculare (`local_ts = 10.200.1.0/24`, `remote_ts = 10.202.3.0/24`)

Avvio del tunnel:
- child SA `lan-lan` con `start_action = trap` (tunnel on-demand: si attiva al primo traffico)
- in demo/diagnostica è possibile forzare l’avvio manuale del child.

### Comandi operativi (runbook)
Su ciascun endpoint (R202 ed eFW):
```bash
service ipsec restart || service strongswan restart
swanctl --load-creds
swanctl --load-conns
```

Forzare l’avvio del child (opzionale, utile per demo):
```bash
# su R202:
swanctl --initiate --child lan-lan
# se necessario, specificare anche la connessione:
# swanctl --initiate --ike r202-efw --child lan-lan
```

Verifica stato SA:
```bash
swanctl --list-sas
```
Ci si aspetta:
- IKE_SA `ESTABLISHED`
- CHILD_SA `INSTALLED`
- contatori bytes/packets che aumentano dopo traffico LAN1↔LAN3.

### Note di troubleshooting rapide
- Se `--initiate --child lan-lan` non trova il child, ripetere `--load-conns` e verificare il nome della connessione/child.
- Se le SA salgono ma non passa traffico, verificare routing e firewall (LAN1↔LAN3 consentito solo via tunnel).

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
