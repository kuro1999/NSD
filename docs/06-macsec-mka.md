# MACsec con MKA (Site2 LAN)

## Segmento
- Site2 LAN: 192.168.20.0/24
- Nodi: CE2, client-B1, client-B2 (connessi via Sw1)

## Implementazione attesa
- Su CE2, client-B1, client-B2:
  - creare `macsec0` su parent `eth0`
  - usare stessa CAK/CKN (MKA PSK)
  - assegnare IP *su macsec0* (non su eth0):
    - CE2 macsec0: 192.168.20.1/24
    - B1 macsec0: 192.168.20.10/24
    - B2 macsec0: 192.168.20.11/24

## Test
- ping B1 <-> CE2 e B2 <-> CE2 (usando IP su macsec0)
- (opzionale) tcpdump su eth0 per evidenza EAPOL/MKA e frame MACsec