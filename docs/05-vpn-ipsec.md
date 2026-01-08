# VPN IPsec (strongSwan)

## 1. Enterprise VPN: R202 <-> eFW
### Obiettivo
- Connettività protetta tra:
  - LAN3 (central-node) <-> LAN1 (AV1-AV3)

### Parametri
- IKEv2 + PSK
- Left/Right: IP dei gateway (R202 e eFW)
- Traffic selectors:
  - leftsubnet = LAN3
  - rightsubnet = LAN1

### Firewall
- Consentire UDP 500/4500 e ESP verso eFW (inbound)
- Consentire forwarding LAN3<->LAN1 solo per i flussi necessari

### Test
- `ipsec statusall`
- ping `central-node -> AV1/AV2/AV3`
- tcpdump su IKE/ESP (opzionale)

## 2. Customer VPN: CE1 <-> CE2
### Obiettivo
- Connettività protetta tra:
  - Site1 LAN (client-A1) <-> Site2 LAN (client-B1/B2 su MACsec)

### Parametri
- IKEv2 + PSK
- leftsubnet = Site1 LAN
- rightsubnet = Site2 LAN

### Test
- ping `client-A1 -> client-B1/client-B2`
- verifica SAs e traffico

## 3. Evidenze
- Config `ipsec.conf` e `ipsec.secrets` in `configs/`
- Output `ipsec statusall` in `evidence/`