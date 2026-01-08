# MACsec con MKA (Site2 LAN)

## 1. Obiettivo
- Proteggere la LAN di Site2 con MACsec + MKA (pre-shared CAK/CKN)
- Interfaccia logica: `macsec0`
- IP assegnati su `macsec0` (non su eth0)

## 2. Parametri
- CAK (16 byte hex): <CAK_HEX>
- CKN (32 byte hex): <CKN_HEX>
- Nodi partecipanti: CE2, client-B1, client-B2

## 3. Configurazione (nmcli)
Annotare qui i comandi effettivi usati, per ciascun host:
- Creazione connessione macsec
- Set parametri MKA
- Assegnazione IP su macsec0
- Bring up

## 4. Test
- ping tra B1/B2 e CE2 su IP di macsec0
- cattura traffico su eth0 per mostrare frame MACsec/EAPOL (opzionale)

## 5. Evidenze
- Output `nmcli con show` in `configs/` o `evidence/`
- Ping e (opzionale) tcpdump in `evidence/`