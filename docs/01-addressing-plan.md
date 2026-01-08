# Addressing plan

## 1. Pools
| Uso | Prefisso | Note |
|---|---|---|
| AS100 public pool | <AS100_PUBLIC_POOL>/24 | usato per IP pubblici CE1/CE2 e indirizzi pubblici dove necessario |
| AS200 public pool | <AS200_PUBLIC_POOL>/24 | usato per DMZ (obbligatorio) |
| P2P private pool | <P2P_PRIVATE_POOL>/16 | suddiviso in /30 per link router-router |
| LAN private pools | RFC1918 /24 | LAN1, LAN2, LAN3, Site1 LAN, Site2 LAN |

## 2. LAN e segmenti principali
| Segmento | Prefisso | Gateway | Note |
|---|---|---|---|
| LAN1 (AV1-3, eFW, iFW) | <LAN1>/24 | <LAN1_GW> | AV solo verso central-node (via policy FW) |
| LAN2 (LAN-client, iFW) | <LAN2>/24 | <LAN2_GW> | traffico verso esterno solo stateful |
| LAN3 (central-node, R202) | <LAN3>/24 | <LAN3_GW> | central-node comunica con AV via VPN |
| DMZ (dns-server) | <DMZ_AS200>/24 | <DMZ_GW> | range AS200 |
| Site1 LAN (client-A1) | <SITE1_LAN>/24 | <CE1_LAN_GW> | |
| Site2 LAN (client-B1/B2 su MACsec) | <SITE2_LAN>/24 | <CE2_LAN_GW> | IP su macsec0 |

## 3. Link P2P (/30 privati)
| Link | Network /30 | Lato A (IP) | Lato B (IP) |
|---|---|---|---|
| R101—R102 | <P2P_1>/30 | R101:<IP> | R102:<IP> |
| R102—R103 | <P2P_2>/30 | R102:<IP> | R103:<IP> |
| R103—R201 (eBGP) | <P2P_3>/30 | R103:<IP> | R201:<IP> |
| R201—R202 | <P2P_4>/30 | R201:<IP> | R202:<IP> |
| R201—GW200 | <P2P_5>/30 | R201:<IP> | GW200:<IP> |
| ... | ... | ... | ... |

## 4. Interfacce per nodo (mapping)
> Compilare esattamente secondo la topologia GNS3 (eth0/eth1/…)

### R101
- eth0 -> R102 : <IP>/<MASK>
- eth1 -> CE1 (WAN) : <IP>/<MASK>
- lo -> <LOOPBACK>/32 (se usata)

### R102
- eth0 -> R101 : <IP>/<MASK>
- eth1 -> R103 : <IP>/<MASK>
- lo -> <LOOPBACK>/32

### R103
- eth0 -> R102 : <IP>/<MASK>
- eth1 -> R201 : <IP>/<MASK>
- eth2 -> CE2 (WAN) : <IP>/<MASK>
- lo -> <LOOPBACK>/32

### R201
- eth0 -> R103 : <IP>/<MASK>
- eth1 -> R202 : <IP>/<MASK>
- eth2 -> GW200 : <IP>/<MASK>

### R202
- eth0 -> R201 : <IP>/<MASK>
- eth1 -> LAN3 : <LAN3_GW>/<24>
- Default route -> R201

### GW200
- eth0 -> R201 : <IP>/<MASK>
- eth1 -> DMZ : <DMZ_GW>/<24>
- eth2 -> eFW (outside) : <IP>/<MASK> (se previsto)
- Default route -> R201

### eFW / iFW / CE1 / CE2 / dns-server / central-node / AV1-3 / client-*
Compilare analogo mapping.