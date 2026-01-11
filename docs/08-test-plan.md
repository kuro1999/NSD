# Test plan (dimostrazione requisiti)

## 1. Routing
### OSPF (AS100)
- show neighbor FULL
- routing table completa

### iBGP / eBGP
- sessioni Established
- raggiungibilità DMZ da AS100

## 2. Servizi DMZ
### DNS + DNSSEC
- dig con +dnssec (RRSIG/DNSKEY presenti)

### HTTP
- curl a `www.nsdcourse.xyz` da LAN-client

## 3. Firewall policy
- Inbound: solo DNS/HTTP verso dns-server e IPsec verso eFW
- LAN-client: traffico outbound stateful ok
- AV: bloccato verso tutto tranne central-node

## 4. VPN enterprise
- ping central-node <-> AV (via IPsec R202-eFW)
- ipsec statusall

## 5. MACsec Site2
- ping B1/B2 <-> CE2 su macsec0
- (opzionale) evidenza EAPOL/MKA e MACsec

## 6. VPN customer
- ping client-A1 <-> client-B1/B2 (IPsec CE1-CE2)
- swanctl --list-sas (IKE_SA ESTABLISHED, CHILD_SA INSTALLED + contatori bytes/packets)
- (fallback) ipsec statusall

## 7. AV sandbox
- esecuzione completa: invio file -> scansioni -> report
- ripristino runner e rerun (dimostrare “clean state”)

## Output da salvare
Salvare tutti gli output in `evidence/` con naming coerente:
- `evidence/01-routing-ospf.txt`
- `evidence/02-routing-bgp.txt`
- `evidence/03-dnssec-dig.txt`
- `evidence/04-http-curl.txt`
- `evidence/05-firewall-tests.txt`
- `evidence/06-ipsec-enterprise.txt`
- `evidence/07-macsec.txt`
- `evidence/08-ipsec-customer.txt`
- `evidence/09-av-sandbox.txt`
