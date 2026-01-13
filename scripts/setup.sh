#!/usr/bin/env bash
set -euo pipefail

# Questo script genera:
#  - setup/   : script di addressing e host configuration
#  - routing/ : script di routing (OSPF in AS100)

mkdir -p setup routing macsec dns ipsec firewall av


# =========================
# Phase A: addressing
# =========================

cat > setup/r101.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
vtysh <<'VEOF'
conf t
interface lo
 no ip address
 ip address 1.255.0.1/32
exit
interface eth0
 no ip address
 ip address 1.0.101.1/30
exit
interface eth1
 no ip address
 ip address 10.0.12.1/30
exit
interface eth2
 no ip address
 ip address 10.0.13.1/30
exit
end
write memory
VEOF
EOF


cat > setup/r102.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
vtysh <<'VEOF'
conf t
interface lo
 no ip address
 ip address 1.255.0.2/32
exit
interface eth0
 no ip address
 ip address 10.0.12.2/30
exit
interface eth1
 no ip address
 ip address 1.0.102.1/30
exit
interface eth2
 no ip address
 ip address 10.0.23.1/30
exit
end
write memory
VEOF
EOF

cat > setup/r103.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
vtysh <<'VEOF'
conf t
interface lo
 no ip address
 ip address 1.255.0.3/32
exit
interface eth0
 no ip address
 ip address 10.0.23.2/30
exit
interface eth1
 no ip address
 ip address 10.0.13.2/30
exit
interface eth2
 no ip address
 ip address 10.0.31.1/30
exit
end
write memory
VEOF
EOF

cat > setup/r201.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
vtysh <<'VEOF'
conf t
interface lo
 no ip address
 ip address 2.255.0.1/32
exit
interface eth0
 no ip address
 ip address 10.0.31.2/30
exit
interface eth1
 no ip address
 ip address 10.0.202.1/30
exit
interface eth2
 no ip address
 ip address 10.0.200.1/30
exit
end
write memory
VEOF
EOF

cat > setup/ce1.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
# CE1: eth1=WAN verso R101, eth0=LAN verso client-A1
sysctl -w net.ipv4.ip_forward=1
ip addr flush dev eth1 || true
ip addr add 1.0.101.2/30 dev eth1
ip link set eth1 up
ip route replace default via 1.0.101.1

ip addr flush dev eth0 || true
ip addr add 192.168.10.1/24 dev eth0
ip link set eth0 up
EOF

cat > setup/client-a1.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
ip addr flush dev eth0 || true
ip addr add 192.168.10.10/24 dev eth0
ip link set eth0 up
ip route replace default via 192.168.10.1
EOF


cat > setup/ce2.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
# CE2: eth1=WAN verso R102, eth0=LAN verso sw1
sysctl -w net.ipv4.ip_forward=1
ip addr flush dev eth1 || true
ip addr add 1.0.102.2/30 dev eth1
ip link set eth1 up
ip route replace default via 1.0.102.1

ip addr flush dev eth0 || true
ip addr add 192.168.20.1/24 dev eth0
ip link set eth0 up
EOF

cat > setup/client-b1.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
ip addr flush dev eth0 || true
ip addr add 192.168.20.10/24 dev eth0
ip link set eth0 up
ip route replace default via 192.168.20.1
EOF

cat > setup/client-b2.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
ip addr flush dev eth0 || true
ip addr add 192.168.20.11/24 dev eth0
ip link set eth0 up
ip route replace default via 192.168.20.1
EOF

cat > setup/r202.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
# R202 non è BGP speaker: default route verso R201
sysctl -w net.ipv4.ip_forward=1
ip addr flush dev eth0 || true
ip addr add 10.0.202.2/30 dev eth0
ip link set eth0 up
ip route replace default via 10.0.202.1

ip addr flush dev eth1 || true
ip addr add 10.202.3.1/24 dev eth1
ip link set eth1 up
EOF

cat > setup/central-node.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
ip addr flush dev eth0 || true
ip addr add 10.202.3.10/24 dev eth0
ip link set eth0 up
ip route replace default via 10.202.3.1
EOF

cat > setup/gw200.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
sysctl -w net.ipv4.ip_forward=1

# --- Verso Internet (R201) ---
ip addr flush dev eth0 || true
ip addr add 10.0.200.2/30 dev eth0
ip link set eth0 up
# Rotta di default verso internet
ip route replace default via 10.0.200.1 dev eth0

# --- Verso DMZ (br1) ---
# GW200 è il gateway della DMZ. 
# [cite_start]Usiamo il pool AS200 come da traccia[cite: 177].
ip addr flush dev eth1 || true
ip addr add 2.80.200.1/24 dev eth1
ip link set eth1 up

# --- Rotte verso l'interno (Enterprise) ---
# Per raggiungere LAN1 (10.200.1.0) e LAN2 (10.200.2.0)
# devo passare per eFW che ha IP .2 nella DMZ
ip route replace 10.200.1.0/24 via 2.80.200.2 dev eth1
ip route replace 10.200.2.0/24 via 2.80.200.2 dev eth1
EOF


cat > setup/efw.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
sysctl -w net.ipv4.ip_forward=1

# --- Verso DMZ (br1) ---
ip addr flush dev eth0 || true
ip addr add 2.80.200.2/24 dev eth0
ip link set eth0 up

# --- Verso LAN1 (br2) ---
ip addr flush dev eth1 || true
ip addr add 10.200.1.1/24 dev eth1
ip link set eth1 up

# --- Routing ---
# 1. Default Gateway: tutto ciò che non conosco va verso GW200
ip route replace default via 2.80.200.1 dev eth0

# 2. Verso LAN2 (LAN-client)
# LAN2 è dietro iFW. Dobbiamo sapere l'IP di iFW nella LAN1.
# Supponendo che iFW sia collegato a br2 e abbia IP 10.200.1.2:
ip route replace 10.200.2.0/24 via 10.200.1.2 dev eth1
EOF


cat > setup/ifw.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
sysctl -w net.ipv4.ip_forward=1
ip addr flush dev eth0 || true
ip addr add 10.200.1.2/24 dev eth0
ip link set eth0 up

ip addr flush dev eth1 || true
ip addr add 10.200.2.1/24 dev eth1
ip link set eth1 up

ip route replace default via 10.200.1.1
EOF

cat > setup/dns.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
ip addr flush dev eth0 || true
# DNS server in DMZ (pool pubblico AS200): 2.80.200.3/24
ip addr add 2.80.200.3/24 dev eth0
ip link set eth0 up
ip route replace default via 2.80.200.1
EOF

cat > setup/av1.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
ip addr flush dev eth0 || true
ip addr add 10.200.1.11/24 dev eth0
ip link set eth0 up
ip route replace default via 10.200.1.1
EOF

cat > setup/av2.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
ip addr flush dev eth0 || true
ip addr add 10.200.1.12/24 dev eth0
ip link set eth0 up
ip route replace default via 10.200.1.1
EOF

cat > setup/av3.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
ip addr flush dev eth0 || true
ip addr add 10.200.1.13/24 dev eth0
ip link set eth0 up
ip route replace default via 10.200.1.1
EOF

cat > setup/lan-client.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
ip addr flush dev eth0 || true
ip addr add 10.200.2.10/24 dev eth0
ip link set eth0 up
ip route replace default via 10.200.2.1

EOF

# =========================
# Step 3: OSPF inside AS100
# =========================

cat > routing/ospf_r101.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
vtysh <<'VEOF'
conf t
router ospf
 ospf router-id 1.255.0.1
 passive-interface default
 no passive-interface eth1
 no passive-interface eth2
exit
interface eth1
 ip ospf area 0
 ip ospf network point-to-point
exit
interface eth2
 ip ospf area 0
 ip ospf network point-to-point
exit
interface lo
 ip ospf area 0
exit
end
write memory
VEOF
EOF

cat > routing/ospf_r102.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
vtysh <<'VEOF'
conf t
router ospf
 ospf router-id 1.255.0.2
 passive-interface default
 no passive-interface eth0
 no passive-interface eth2
exit
interface eth0
 ip ospf area 0
 ip ospf network point-to-point
exit
interface eth2
 ip ospf area 0
 ip ospf network point-to-point
exit
interface lo
 ip ospf area 0
exit
end
write memory
VEOF
EOF

cat > routing/ospf_r103.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
vtysh <<'VEOF'
conf t
router ospf
 ospf router-id 1.255.0.3
 passive-interface default
 no passive-interface eth0
 no passive-interface eth1
exit
interface eth0
 ip ospf area 0
 ip ospf network point-to-point
exit
interface eth1
 ip ospf area 0
 ip ospf network point-to-point
exit
interface lo
 ip ospf area 0
exit
end
write memory
VEOF
EOF



cat > routing/bgp_r101.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
vtysh <<'VEOF'
conf t
router bgp 100
 bgp router-id 1.255.0.1
 no bgp ebgp-requires-policy
 neighbor 1.255.0.2 remote-as 100
 neighbor 1.255.0.2 update-source lo
 neighbor 1.255.0.3 remote-as 100
 neighbor 1.255.0.3 update-source lo
 !
 address-family ipv4 unicast
  neighbor 1.255.0.2 activate
  neighbor 1.255.0.3 activate
  network 1.0.101.0/30
 exit-address-family
end
write memory
VEOF
EOF

cat > routing/bgp_r102.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
vtysh <<'VEOF'
conf t
router bgp 100
 bgp router-id 1.255.0.2
 no bgp ebgp-requires-policy
 neighbor 1.255.0.1 remote-as 100
 neighbor 1.255.0.1 update-source lo
 neighbor 1.255.0.3 remote-as 100
 neighbor 1.255.0.3 update-source lo
 !
 address-family ipv4 unicast
  neighbor 1.255.0.1 activate
  neighbor 1.255.0.3 activate
  network 1.0.102.0/30
 exit-address-family
end
write memory
VEOF

EOF


cat > routing/bgp_r103.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
vtysh <<'VEOF'
conf t
router bgp 100
 bgp router-id 1.255.0.3
 no bgp ebgp-requires-policy
 ! iBGP
 neighbor 1.255.0.1 remote-as 100
 neighbor 1.255.0.1 update-source lo
 neighbor 1.255.0.2 remote-as 100
 neighbor 1.255.0.2 update-source lo
 ! eBGP verso AS200
 neighbor 10.0.31.2 remote-as 200
 !
 address-family ipv4 unicast
  neighbor 1.255.0.1 activate
  neighbor 1.255.0.2 activate
  neighbor 10.0.31.2 activate
  neighbor 1.255.0.1 next-hop-self
  neighbor 1.255.0.2 next-hop-self
 exit-address-family
end
write memory
VEOF

EOF


cat > routing/bgp_r201.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
vtysh <<'VEOF'
conf t
! (opzionale) rotta verso DMZ per poterla annunciare via BGP
ip route 2.80.200.0/24 10.0.200.2
ip route 10.200.1.0/24 10.0.200.2
ip route 10.200.2.0/24 10.0.200.2

!
router bgp 200
 bgp router-id 2.255.0.1
 no bgp ebgp-requires-policy
 neighbor 10.0.31.1 remote-as 100
 !
 address-family ipv4 unicast
  neighbor 10.0.31.1 activate
  network 2.255.0.1/32
  network 2.80.200.0/24
 exit-address-family
end
write memory
VEOF

EOF




# =========================
# Phase B: IPsec Setup (VPN Site 1 <-> Site 2)
# =========================

# --- Configurazione per CE1 (Initiator) ---
cat > ipsec/ce1.sh <<'EOF'
#!/bin/bash
set -euo pipefail

# Assicuriamo che la directory di configurazione esista
mkdir -p /etc/swanctl/conf.d

echo ">>> Configurazione IPsec su CE1..."

cat > /etc/swanctl/conf.d/ipsec.conf <<CONF
connections {
  ce1-ce2 {
    local_addrs  = 1.0.101.2
    remote_addrs = 1.0.102.2

    version = 2
    mobike = no

    local {
      auth = psk
      id = ce1
    }
    remote {
      auth = psk
      id = ce2
    }

    proposals = aes128-sha256-modp2048

    children {
      lan-lan {
        local_ts  = 192.168.10.0/24
        remote_ts = 192.168.20.0/24
        esp_proposals = aes128-sha256-modp2048
      }
    }
  }
}

secrets {
  ike-psk {
    id-1 = ce1
    id-2 = ce2
    secret = "nsd-ce1-ce2-psk-2026"
  }
}
CONF

# Avvio/Riavvio servizi
echo ">>> Riavvio ipsec..."
service ipsec restart || ipsec restart

# Caricamento configurazioni
echo ">>> Caricamento credenziali e connessioni..."
swanctl --load-creds
swanctl --load-conns

# Avvio del tunnel (CE1 fa da initiator)
echo ">>> Avvio connessione..."
swanctl --initiate --child lan-lan

# Verifica finale
echo ">>> Stato Tunnel:"
swanctl --list-sas
EOF


# --- Configurazione per CE2 (Responder) ---
cat > ipsec/ce2.sh <<'EOF'
#!//bin/bash
set -euo pipefail

mkdir -p /etc/swanctl/conf.d

echo ">>> Configurazione IPsec su CE2..."

cat > /etc/swanctl/conf.d/ipsec.conf <<CONF
connections {
  ce2-ce1 {
    local_addrs  = 1.0.102.2
    remote_addrs = 1.0.101.2

    version = 2
    mobike = no

    local {
      auth = psk
      id = ce2
    }
    remote {
      auth = psk
      id = ce1
    }

    proposals = aes128-sha256-modp2048

    children {
      lan-lan {
        local_ts  = 192.168.20.0/24
        remote_ts = 192.168.10.0/24
        esp_proposals = aes128-sha256-modp2048
      }
    }
  }
}

secrets {
  ike-psk {
    id-1 = ce2
    id-2 = ce1
    secret = "nsd-ce1-ce2-psk-2026"
  }
}
CONF

# Avvio/Riavvio servizi
echo ">>> Riavvio ipsec..."
service ipsec restart || ipsec restart

# Caricamento configurazioni
echo ">>> Caricamento credenziali e connessioni..."
swanctl --load-creds
swanctl --load-conns

# Niente initiate qui, CE2 aspetta la connessione
echo ">>> Stato Tunnel (in attesa):"
swanctl --list-sas || true
EOF



cat > ipsec/r201.sh <<'EOF'

#!/bin/bash
set -euo pipefail

mkdir -p /etc/swanctl/conf.d

echo ">>> Configurazione IPsec (Swanctl) su R202..."

cat > /etc/swanctl/conf.d/ipsec.conf <<CONF
connections {
  r202-efw {
    local_addrs  = 10.0.202.2
    remote_addrs = 2.80.200.2

    version = 2
    mobike = no
    encap = yes

    local {
      auth = psk
      id = r202
    }
    remote {
      auth = psk
      id = efw
    }

    # MATCH CON EFW
    proposals = aes128-sha256-modp2048

    children {
      lan-lan {
        # Rete Locale (Central Node LAN3)
        local_ts  = 10.202.3.0/24
        # Rete Remota (Antivirus LAN1)
        remote_ts = 10.200.1.0/24

        # MATCH CON EFW
        esp_proposals = aes128-sha256-modp2048

        start_action = trap
      }
    }
  }
}

secrets {
  ike-psk {
    id-1 = r202
    id-2 = efw
    secret = "nsd-efw-r202-psk-2026"
  }
}
CONF

echo ">>> Riavvio StrongSwan su R202..."
service ipsec restart || service strongswan restart
sleep 2

echo ">>> Caricamento credenziali..."
swanctl --load-creds
swanctl --load-conns

echo ">>> Tentativo di avvio connessione..."
swanctl --initiate --child lan-lan

echo ">>> Stato Tunnel:"
swanctl --list-sas

EOF


cat > ipsec/eFW.sh <<'EOF'

#!/bin/bash
set -euo pipefail

mkdir -p /etc/swanctl/conf.d

echo ">>> Configurazione IPsec (Swanctl) su eFW..."

cat > /etc/swanctl/conf.d/ipsec.conf <<CONF
connections {
  efw-r202 {
    local_addrs  = 2.80.200.2
    remote_addrs = 10.0.202.2

    version = 2
    mobike = no

    # Importante: se ci sono firewall NAT o problemi di MTU
    encap = yes

    local {
      auth = psk
      id = efw
    }
    remote {
      auth = psk
      id = r202
    }

    # DEVE ESSERE IDENTICO A R202
    proposals = aes128-sha256-modp2048

    children {
      lan-lan {
        # Rete Locale (Antivirus LAN1)
        local_ts  = 10.200.1.0/24
        # Rete Remota (Central Node LAN3)
        remote_ts = 10.202.3.0/24

        # DEVE ESSERE IDENTICO A R202
        esp_proposals = aes128-sha256-modp2048

        # Start action trap: fa salire il tunnel appena c'è traffico
        start_action = trap
      }
    }
  }
}

secrets {
  ike-psk {
    id-1 = efw
    id-2 = r202
    secret = "nsd-efw-r202-psk-2026"
  }
}
CONF

echo ">>> Riavvio StrongSwan su eFW..."
service ipsec restart || service strongswan restart
sleep 2

echo ">>> Caricamento credenziali..."
swanctl --load-creds
swanctl --load-conns

echo ">>> Stato Tunnel:"
swanctl --list-sas
EOF








# =========================
# Phase C: MACsec (MKA) - Site 2 LAN
# =========================

cat > macsec/mka_ce2.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

LAN_IF=eth0
MACSEC_IF=macsec0
IP_ADDR=192.168.20.1/24

CAK=00112233445566778899aabbccddeeff
CKN=000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f

cat > macsec.conf <<EOF2
eapol_version=3
ap_scan=0
network={
  key_mgmt=NONE
  eapol_flags=0
  macsec_policy=1
  mka_cak=$CAK
  mka_ckn=$CKN
}
EOF2

wpa_supplicant -i $LAN_IF -B -Dmacsec_linux -c macsec.conf

# piccolo delay: macsec0 viene creata qualche istante dopo
sleep 2

ip addr del $IP_ADDR dev $LAN_IF 2>/dev/null || true
ip addr replace $IP_ADDR dev $MACSEC_IF
ip link set $MACSEC_IF up
EOF


cat > macsec/mka_b1.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

LAN_IF=eth0
MACSEC_IF=macsec0
IP_ADDR=192.168.20.10/24
GW=192.168.20.1

CAK=00112233445566778899aabbccddeeff
CKN=000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f

cat > macsec.conf <<EOF2
eapol_version=3
ap_scan=0
network={
  key_mgmt=NONE
  eapol_flags=0
  macsec_policy=1
  mka_cak=$CAK
  mka_ckn=$CKN
}
EOF2

wpa_supplicant -i $LAN_IF -B -Dmacsec_linux -c macsec.conf
sleep 2

ip addr del $IP_ADDR dev $LAN_IF 2>/dev/null || true
ip addr replace $IP_ADDR dev $MACSEC_IF
ip link set $MACSEC_IF up

# fondamentale: default route via CE2 su macsec0
ip route replace default via $GW dev $MACSEC_IF
EOF


cat > macsec/mka_b2.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

LAN_IF=eth0
MACSEC_IF=macsec0
IP_ADDR=192.168.20.11/24
GW=192.168.20.1

CAK=00112233445566778899aabbccddeeff
CKN=000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f

cat > macsec.conf <<EOF2
eapol_version=3
ap_scan=0
network={
  key_mgmt=NONE
  eapol_flags=0
  macsec_policy=1
  mka_cak=$CAK
  mka_ckn=$CKN
}
EOF2

wpa_supplicant -i $LAN_IF -B -Dmacsec_linux -c macsec.conf
sleep 2

ip addr del $IP_ADDR dev $LAN_IF 2>/dev/null || true
ip addr replace $IP_ADDR dev $MACSEC_IF
ip link set $MACSEC_IF up

ip route replace default via $GW dev $MACSEC_IF
EOF



# =========================
# Phase D: DNSSEC + HTTP Setup (Configuration Files Only)
# =========================

# 1. Opzioni di BIND (Slide 115)
cat > dns/named.conf.options <<EOF
options {
    directory "/var/cache/bind";
    recursion no;
    allow-query { any; };
    listen-on-v6 { any; };
    dnssec-validation auto;
};
EOF

# 2. Definizione della Zona (Slide 124 - Versione finale che punta al .signed)
cat > dns/named.conf.local <<EOF
zone "nsdcourse.xyz" {
    type master;
    file "/etc/bind/db.nsdcourse.xyz.signed";
};
EOF

# 3. File di Zona non firmato (Slide 116)
cat > dns/db.nsdcourse.xyz <<EOF
\$TTL 3h
@   IN  SOA ns.nsdcourse.xyz. admin.nsdcourse.xyz. (
        1       ; Serial
        3h      ; Refresh
        1h      ; Retry
        1w      ; Expire
        1h )    ; Negative Cache TTL

@       IN  NS  ns.nsdcourse.xyz.
@       IN  A   2.80.200.3
ns      IN  A   2.80.200.3
www     IN  A   2.80.200.3
EOF

# 4. Crea il file "promemoria" con i comandi da lanciare manualmente
cat > dns/config.txt <<'EOF'
# --- COMANDI DA LANCIARE MANUALMENTE NEL NODO DNS-SERVER ---

# 1. Vai nella cartella
cd /etc/bind

# 2. Genera le chiavi (Slide 117-120)
dnssec-keygen -a ECDSAP384SHA384 -n ZONE nsdcourse.xyz
dnssec-keygen -f KSK -a ECDSAP384SHA384 -n ZONE nsdcourse.xyz

# 3. Includi le chiavi nel file di zona (Slide 121)
for key in Knsdcourse.xyz*.key; do echo "\$INCLUDE $key" >> db.nsdcourse.xyz; done

# 4. Firma la zona (crea il file .signed) (Slide 122)
dnssec-signzone -A -3 $(head -c 1000 /dev/random | sha1sum | cut -b 1-16) -N INCREMENT -o nsdcourse.xyz -t db.nsdcourse.xyz

# 5. Correggi i permessi (IMPORTANTE)
chown -R bind:bind /etc/bind

# 6. Avvia tutto
service apache2 start
service named restart
EOF


# 5. Script di pulizia/reset (da lanciare SOLO se devi rifare tutto da zero)
cat > dns/clean_dns.sh <<'EOF'
#!/bin/bash
set -e

echo "--- INIZIO PULIZIA CONFIGURAZIONE DNSSEC ---"

# 1. Arresto del servizio (gestione errore se gia' fermo)
service named stop || true

# 2. Rimozione file chiavi, firme e journal residui
rm -f /etc/bind/Knsdcourse.xyz*
rm -f /etc/bind/db.nsdcourse.xyz.signed
rm -f /etc/bind/dsset-nsdcourse.xyz*
rm -f /etc/bind/*.jnl

# 3. Ripristino configurazione zona (named.conf.local)
cat > /etc/bind/named.conf.local <<CONF
zone "nsdcourse.xyz" {
    type master;
    file "/etc/bind/db.nsdcourse.xyz";
};
CONF

# 4. Ripristino file di zona originale (Clean State)
cat > /etc/bind/db.nsdcourse.xyz <<ZONE
$TTL 3h
@   IN SOA  ns.nsdcourse.xyz. admin.nsdcourse.xyz. (
            1       ; Serial
            3h      ; Refresh
            1h      ; Retry
            1w      ; Expire
            1h )    ; Negative caching TTL

; Name Servers
@       IN NS   ns.nsdcourse.xyz.

; Record A
@       IN A    2.80.200.3
ns      IN A    2.80.200.3
www     IN A    2.80.200.3
ZONE

# 5. Correzione permessi
chown -R bind:bind /etc/bind

# 6. Riavvio del servizio
service named start

echo "--- PULIZIA COMPLETATA ---"
echo "Il server e' stato ripristinato allo stato iniziale (senza DNSSEC)."
EOF
#permessi


################
# FIREWALL #####


cat > firewall/gw200.sh <<'EOF'
#!/bin/bash
set -e

echo "--- Configurazione Firewall GW200 ---"

# 1. Abilita il forwarding (Essenziale per fare da router)
sysctl -w net.ipv4.ip_forward=1

# 2. Pulizia Totale (Flush) delle regole precedenti
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X

# 3. Imposta Policy di Default a DROP (Chiudi tutto)
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# ================================
# CHAIN INPUT (Traffico diretto AL router GW200)
# ================================
# Accetta traffico di loopback (locale)
iptables -A INPUT -i lo -j ACCEPT

# Accetta traffico di connessioni già stabilite (Stateful)
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Accetta ICMP (Ping) dall'interno (eth1) per debug, ma non da Internet
iptables -A INPUT -i eth1 -p icmp -j ACCEPT


# ================================
# CHAIN FORWARD (Traffico che ATTRAVERSA GW200)
# ================================

# REGOLA 0: Stateful Inspection (Lascia passare le risposte)
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# REGOLA 1: LAN-Client (LAN2) verso Internet
# Requisito: "LAN-client can access the external network... if originated by it"
# La LAN2 è 10.200.2.0/24. Arriva dall'interfaccia interna (eth1) ed esce su eth0.
iptables -A FORWARD -i eth1 -o eth0 -s 10.200.2.0/24 -j ACCEPT

# REGOLA 2: Accesso Esterno verso DNS/Web (DMZ)
# Requisito: "Allow inbound connections for DNS requests... HTTP traffic"
# Il DNS server è 2.80.200.3.
iptables -A FORWARD -i eth0 -d 2.80.200.3 -p udp --dport 53 -j ACCEPT
iptables -A FORWARD -i eth0 -d 2.80.200.3 -p tcp --dport 53 -j ACCEPT
iptables -A FORWARD -i eth0 -d 2.80.200.3 -p tcp --dport 80 -j ACCEPT

# REGOLA 3: Transito VPN verso eFW
# Requisito: "IPSEC traffic to eFW"
# eFW è 2.80.200.2. Deve ricevere i pacchetti VPN da R202.
iptables -A FORWARD -i eth0 -d 2.80.200.2 -p udp --dport 500 -j ACCEPT
iptables -A FORWARD -i eth0 -d 2.80.200.2 -p udp --dport 4500 -j ACCEPT
iptables -A FORWARD -i eth0 -d 2.80.200.2 -p esp -j ACCEPT

# REGOLA 4: Uscita generica per la DMZ (opzionale ma consigliata)
# Permette ai server in DMZ (eFW, DNS) di scaricare aggiornamenti
iptables -A FORWARD -i eth1 -o eth0 -s 2.80.200.0/24 -j ACCEPT

# Permetti il traffico di ritorno (Report) verso il Central Node

iptables -A FORWARD -p tcp --dport 9000 -j ACCEPT
iptables -A FORWARD -p tcp --dport 9001 -j ACCEPT
iptables -A FORWARD -p tcp --dport 9002 -j ACCEPT
iptables -A FORWARD -p tcp --dport 9003 -j ACCEPT


# ================================
# NAT (Masquerade)
# ================================
# Tutto ciò che esce da eth0 viene mascherato con l'IP pubblico di GW200
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

echo "Firewall GW200 Attivo!"
iptables -L -v -n
EOF



cat > firewall/eFW.sh <<'EOF'
#!/bin/bash
echo "--- Configurazione Firewall eFW ---"

# 1. Abilita il forwarding
sysctl -w net.ipv4.ip_forward=1

# 2. Pulizia regole
iptables -F
iptables -X
iptables -t nat -F

# 3. Policy di Default: DROP (Chiudi tutto)
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# ================================
# CHAIN INPUT (Traffico diretto a eFW)
# ================================
# Accetta traffico locale
iptables -A INPUT -i lo -j ACCEPT
# Accetta connessioni già stabilite (es. aggiornamenti del firewall stesso)
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# REGOLA VPN: Accetta traffico IPsec in ingresso (da Internet/GW200)
# Serve per far salire il tunnel con R202
iptables -A INPUT -p udp --dport 500 -j ACCEPT
iptables -A INPUT -p udp --dport 4500 -j ACCEPT
iptables -A INPUT -p esp -j ACCEPT

# (Opzionale) SSH/Ping dalla DMZ (management)
iptables -A INPUT -s 2.80.200.0/24 -p icmp -j ACCEPT


# ================================
# CHAIN FORWARD (Traffico che passa attraverso)
# ================================
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# REGOLA 1: LAN-Client (LAN2) verso Internet
# La LAN2 (10.200.2.0/24) arriva da eth1 (via iFW).
# Deve poter andare ovunque.
iptables -A FORWARD -i eth1 -o eth0 -s 10.200.2.0/24 -j ACCEPT

# REGOLA 2: Antivirus (LAN1) verso Central Node (LAN3)
# Gli AV (10.200.1.0/24) possono parlare SOLO con la rete del Central Node (10.202.3.0/24)
# Questo traffico verrà poi cifrato dalla VPN (che configureremo dopo)
iptables -A FORWARD -s 10.200.1.0/24 -d 10.202.3.0/24 -j ACCEPT

# REGOLA 3: Central Node (LAN3) verso Antivirus (LAN1)
# Permette al Central Node di iniziare connessioni verso gli AV
iptables -A FORWARD -s 10.202.3.0/24 -d 10.200.1.0/24 -j ACCEPT

# NOTA: Manca la regola per LAN1 -> Internet.
# Quindi se un virus prova a uscire, cade nel DROP di default.

echo "Firewall eFW configurato."
iptables -L -v -n
EOF



cat > firewall/iFW.sh <<'EOF'
#!/bin/bash
echo "--- BLINDAGGIO iFW ---"

# 1. Pulisci tutto (Tabula rasa)
iptables -F
iptables -X

# 2. Imposta la Policy su DROP (Questo è il comando che uccide il Redirect)
# Se il pacchetto non è autorizzato, viene buttato via SENZA risposta.
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# 3. Regola per connessioni già stabilite (fondamentale per le risposte)
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# 4. LAN-Client (LAN2): LUI PUÒ PASSARE
iptables -A FORWARD -s 10.200.2.0/24 -j ACCEPT

# 5. AV1 (LAN1): PUÒ ANDARE SOLO VERSO LA VPN (Central Node)
# Nota: Non c'è nessuna regola per andare su Internet (10.0.200.1)
iptables -A FORWARD -s 10.200.1.0/24 -d 10.202.3.0/24 -j ACCEPT

# (Opzionale) Permetti ICMP in ingresso al firewall per debug locale
iptables -A INPUT -p icmp -j ACCEPT

echo "iFW ora è in modalità DROP."
EOF



##########################################

cat > av/av1.sh <<'EOF'
#!/bin/bash
#av1.sh - ClamAV Listener Daemon
CENTRAL_NODE_IP="10.202.3.10" # Sostituisci con IP vero del Central Node

echo "[AV1] ClamAV Service avviato in ascolto sulla porta 9000..."

while true; do
    # 1. Pulizia preventiva (Clean State)
    rm -f binary report.txt
    
    # 2. Attesa ricezione (Bloccante finché non arriva qualcosa)
    nc -l -p 9000 > binary
    echo "[AV1] File ricevuto. Avvio scansione..."

    # 3. Scansione ClamAV
    echo "--- REPORT AV1 (ClamAV) ---" > report.txt
    date >> report.txt
    clamscan binary >> report.txt

    # 4. Invio Report al Central Node
    echo "[AV1] Invio report..."
    nc -w 2 $CENTRAL_NODE_IP 9001 < report.txt
    
    echo "[AV1] Ciclo completato. In attesa del prossimo file."
    echo "----------------------------------------------------"
done
EOF



cat > av/av2.sh << 'EOF'
#!/bin/bash
#av2.sh - YARA Listener Daemon
CENTRAL_NODE_IP="10.202.3.10"

echo "[AV2] YARA Service avviato in ascolto sulla porta 9000..."

# Assicurati che la regola esista
if [ ! -f /root/rule.yar ]; then
    echo 'rule Malicious { strings: $a="malevolo" condition: $a }' > /root/rule.yar
fi

while true; do
    rm -f binary report.txt
    
    nc -l -p 9000 > binary
    echo "[AV2] File ricevuto. Avvio scansione..."

    echo "--- REPORT AV2 (YARA) ---" > report.txt
    date >> report.txt
    yara /root/rule.yar binary >> report.txt

    nc -w 2 $CENTRAL_NODE_IP 9002 < report.txt
    
    echo "[AV2] Ciclo completato."
done
EOF

cat > av/av3.sh << 'EOF'
#!/bin/bash
# av3.sh - Chkrootkit Daemon
# Riferimento: Rilevamento Rootkit

CENTRAL_NODE="10.202.3.10" # IP del tuo Central Node

echo "[AV3] Chkrootkit Service avviato sulla porta 9000..."

while true; do
    # 1. Pulizia
    rm -f binary report.txt
    
    # 2. Ricezione Malware
    nc -l -p 9000 > binary
    echo "[AV3] File ricevuto. Esecuzione e analisi..."

    # 3. Esecuzione (Analisi Dinamica)
    # È necessario eseguire il file per vedere se altera i processi o le porte
    chmod +x binary
    ./binary &
    PID=$!
    
    # Aspettiamo 3 secondi che il virus faccia "cose"
    sleep 3
    
    # Uccidiamo il processo (per evitare blocchi)
    kill $PID 2>/dev/null

    # 4. Scansione con Chkrootkit
    echo "--- REPORT AV3 (Chkrootkit) ---" > report.txt
    date >> report.txt
    
    # -q = Quiet mode (stampa solo se trova qualcosa di sospetto)
    # Se non trova nulla, l'output sarà vuoto (ma noi aggiungiamo una nota dopo)
    chkrootkit -q >> report.txt
    
    # Se il file report.txt ha solo la data (è quasi vuoto), scriviamo che è pulito
    if [ $(wc -l < report.txt) -le 1 ]; then
        echo "Nessun rootkit o anomalia rilevata nel sistema." >> report.txt
    else
        # Se c'è output, aggiungiamo l'intestazione di allarme
        sed -i '1s/^/[!!!] ALLARME SICUREZZA RILEVATO\n/' report.txt
    fi

    # 5. Invio Risultato (Porta 9003)
    nc -w 2 $CENTRAL_NODE 9003 < report.txt
    echo "[AV3] Report inviato."
    
done
EOF



cat >av/test.sh << 'EOF'
#!/bin/bash
# test.sh - Invia malware e raccoglie i report

# CONFIGURAZIONE IP
IP_AV1="10.200.1.11" # Metti gli IP corretti della tua rete
IP_AV2="10.200.1.12"
IP_AV3="10.200.1.13"
VIRUS_FILE="virus.exe"

# Pulizia vecchi report locali
rm -f report_av*.txt

echo "=============================================="
echo "   CENTRAL NODE - MALWARE ANALYSIS SYSTEM     "
echo "=============================================="

# 1. Prepara l'ascolto dei report (in background)
echo "[*] Avvio listener per i report in ingresso..."
nc -l -p 9001 > report_av1.txt &
PID1=$!
nc -l -p 9002 > report_av2.txt &
PID2=$!
nc -l -p 9003 > report_av3.txt &
PID3=$!

# Piccola pausa per essere sicuri che nc sia partito
sleep 1

# 2. Invia il Malware
if [ ! -f "$VIRUS_FILE" ]; then
    echo "Errore: $VIRUS_FILE non trovato! Crealo prima."
    exit 1
fi

echo "[*] Invio malware ($VIRUS_FILE) ai nodi..."
nc -w 1 $IP_AV1 9000 < $VIRUS_FILE
echo "    -> Inviato a AV1"
nc -w 1 $IP_AV2 9000 < $VIRUS_FILE
echo "    -> Inviato a AV2"
nc -w 1 $IP_AV3 9000 < $VIRUS_FILE
echo "    -> Inviato a AV3"

echo "[*] Attesa risultati (Timeout 10s)..."

# 3. Attesa attiva dei file (o timeout)
# Aspetta che i processi nc di ascolto terminino (terminano appena ricevono il file)
wait $PID1 $PID2 $PID3 2>/dev/null

echo ""
echo "=============================================="
echo "             RISULTATI ANALISI                "
echo "=============================================="

echo ""
echo ">>> REPORT AV1 (ClamAV):"
cat report_av1.txt

echo ""
echo ">>> REPORT AV2 (YARA):"
cat report_av2.txt

echo ""
echo ">>> REPORT AV3 (AIDE):"
cat report_av3.txt

echo "=============================================="
echo "Analisi completata."
EOF
###############################

chmod +x setup/*.sh routing/*.sh macsec/*.sh dns/*.sh  ipsec/*.sh firewall/*.sh av/*.sh
echo "OK: creati setup/ e routing/. Ora esegui gli script dentro i nodi GNS3."
