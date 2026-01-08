# DNS authoritative + DNSSEC + Web (DMZ)

## 1. Obiettivo
- Zona authoritative: `nsdcourse.xyz`
- Record `www.nsdcourse.xyz` -> A verso web server (Apache)
- DNSSEC: firma della zona (KSK+ZSK), senza necessità di DS nel parent

## 2. DNS (BIND9)
### File di configurazione
- named.conf (include zona)
- file zona: `db.nsdcourse.xyz` (o equivalente)
- Abilitare recursion: NO (authoritative only), salvo necessità di lab

### Record minimi richiesti
- SOA
- NS
- A per ns (se necessario)
- A per www

## 3. DNSSEC
### Chiavi
- ZSK: algoritmo e dimensione
- KSK: algoritmo e dimensione

### Firma zona
- Generazione `.signed`
- Configurazione named per servire la zona firmata

## 4. Web server (Apache2)
- VirtualHost o pagina default che risponde su `http://www.nsdcourse.xyz`
- Contenuto pagina: hostname + timestamp (utile per demo)

## 5. Test
- `dig @<DNS_SERVER_IP> nsdcourse.xyz SOA`
- `dig +dnssec @<DNS_SERVER_IP> www.nsdcourse.xyz A` (verificare DNSKEY/RRSIG)
- `curl http://www.nsdcourse.xyz` da LAN-client

## 6. Evidenze
- Output dig/curl in `evidence/`
- Estratto config bind+apache in `configs/`