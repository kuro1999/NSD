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
echo "nameserver 2.80.200.3" > /etc/resolv.conf
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
echo "nameserver 2.80.200.3" > /etc/resolv.conf

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
echo "nameserver 2.80.200.3" > /etc/resolv.conf
EOF

cat > setup/r201.sh <<'EOF'
##!/usr/bin/env bash
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
echo "nameserver 2.80.200.3" > /etc/resolv.conf
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
iptables -t nat -A POSTROUTING -o eth1 -j MASQUERADE
echo "nameserver 2.80.200.3" > /etc/resolv.conf

EOF

cat > setup/client-a1.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
ip addr flush dev eth0 || true
ip addr add 192.168.10.10/24 dev eth0
ip link set eth0 up
ip route replace default via 192.168.10.1
echo "nameserver 2.80.200.3" > /etc/resolv.conf
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
iptables -t nat -A POSTROUTING -o eth1 -j MASQUERADE
echo "nameserver 2.80.200.3" > /etc/resolv.conf
EOF

cat > setup/client-b1.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
ip addr flush dev eth0 || true
ip addr add 192.168.20.10/24 dev eth0
ip link set eth0 up
ip route replace default via 192.168.20.1
echo "nameserver 2.80.200.3" > /etc/resolv.conf
EOF

cat > setup/client-b2.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
ip addr flush dev eth0 || true
ip addr add 192.168.20.11/24 dev eth0
ip link set eth0 up
ip route replace default via 192.168.20.1
echo "nameserver 2.80.200.3" > /etc/resolv.conf
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
echo "nameserver 2.80.200.3" > /etc/resolv.conf
EOF

cat > setup/central-node.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
ip addr flush dev eth0 || true
ip addr add 10.202.3.10/24 dev eth0
ip link set eth0 up
ip route replace default via 10.202.3.1

#connessione a NAT
dhclient -v eth1

# 1. Rimuovi il default gateway attuale (quello interno)
ip route del default

# 2. Aggiungi il NUOVO default gateway verso Internet (NAT)
# (Uso l'IP che ho visto nel tuo log dhclient: 192.168.122.1)
ip route add default via 192.168.122.1 dev eth1

# 3. [FONDAMENTALE] Riaggiungi la rotta per la rete interna
# Diciamo: "Tutto ciÃ² che inizia con 10.x.x.x mandalo al router interno (eth0)"
# Sostituisci 10.202.3.1 con l'IP del tuo router interno se diverso
ip route add 10.0.0.0/8 via 10.202.3.1 dev eth0

#Metti il DNS  di Google per l'installazione
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 2.80.200.3" >> /etc/resolv.conf

apt-get update
apt-get install -y tinyproxy


# Aggiungi "Allow 10.0.0.0/8" alla configurazione
sed -i '/^Allow 127\.0\.0\.1/a Allow 10.0.0.0/8' /etc/tinyproxy/tinyproxy.conf

# Riavvia il servizio
service tinyproxy restart

EOF

cat > setup/gw200.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
sysctl -w net.ipv4.ip_forward=1

ip addr flush dev eth0 || true
ip addr add 10.0.200.2/30 dev eth0
ip link set eth0 up
ip route replace default via 10.0.200.1 dev eth0

ip addr flush dev eth1 || true
ip addr add 2.80.200.1/24 dev eth1
ip link set eth1 up

ip route replace 10.200.1.0/24 via 2.80.200.2 dev eth1
ip route replace 10.200.2.0/24 via 2.80.200.2 dev eth1
echo "nameserver 2.80.200.3" > /etc/resolv.conf

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

echo "nameserver 2.80.200.3" > /etc/resolv.conf

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
echo "nameserver 2.80.200.3" > /etc/resolv.conf

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
echo "nameserver 2.80.200.3" > /etc/resolv.conf

EOF






cat > setup/dns.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
ip addr flush dev eth0 || true
# DNS server in DMZ (pool pubblico AS200): 2.80.200.3/24
ip addr add 2.80.200.3/24 dev eth0
ip link set eth0 up
ip route replace default via 2.80.200.1






#!/bin/bash

echo "--- INIZIO PULIZIA TOTALE DNSSEC ---"

# 1. Ferma il servizio per sicurezza
service named stop

# 2. Rimuove tutte le chiavi generate in precedenza (K...)
rm -f /etc/bind/Knsdcourse.xyz*

# 3. Rimuove i file firmati e i dataset DS
rm -f /etc/bind/db.nsdcourse.xyz.signed
rm -f /etc/bind/dsset-nsdcourse.xyz.
rm -f /etc/bind/named.conf.options.jnl

# 4. RIPRISTINA il file di zona originale (senza chiavi in fondo)
#    Questo sovrascrive il file esistente con una versione pulita.
cat > /etc/bind/db.nsdcourse.xyz <<'EOF2'
\$TTL 3h
@   IN SOA  ns.nsdcourse.xyz. admin.nsdcourse.xyz. (
            1     ; Serial
            3h    ; Refresh
            1h    ; Retry
            1w    ; Expire
            1h )  ; Negative caching TTL

; Name Servers
@       IN NS   ns.nsdcourse.xyz.

; Record A (Indirizzi IP)
@       IN A    2.80.200.3
ns      IN A    2.80.200.3
www     IN A    2.80.200.3
EOF2

# 5. Riavvia il servizio pulito
service named start

echo "--- PULIZIA COMPLETATA ---"
echo "Ora il server Ã¨ tornato allo stato iniziale (senza DNSSEC)."
echo "Puoi procedere con la generazione delle chiavi (una volta sola!)."









#!/bin/bash
set -e

echo ">>> Configurazione Web Server..."
service apache2 start

echo ">>> Configurazione BIND Options..."
cat > /etc/bind/named.conf.options <<CONF
options {
    directory "/var/cache/bind";
    recursion no;
    allow-query { any; };
    listen-on-v6 { any; };
    dnssec-validation auto;
};
CONF

echo ">>> Configurazione BIND Local Zone..."
cat > /etc/bind/named.conf.local <<CONF
zone "nsdcourse.xyz" {
    type master;
    file "/etc/bind/db.nsdcourse.xyz.signed";
};
CONF

echo ">>> Creazione File di Zona..."
cat > /etc/bind/db.nsdcourse.xyz <<ZONE
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
ZONE

echo ">>> Generazione Chiavi DNSSEC (ZSK e KSK)..."
cd /etc/bind
# Genera ZSK
dnssec-keygen -a ECDSAP384SHA384 -n ZONE nsdcourse.xyz
# Genera KSK
dnssec-keygen -f KSK -a ECDSAP384SHA384 -n ZONE nsdcourse.xyz

echo ">>> Inclusione chiavi nella zona..."
for key in Knsdcourse.xyz*.key; do
    echo "\$INCLUDE $key" >> db.nsdcourse.xyz
done

echo ">>> Firma della zona..."
dnssec-signzone -A -3 $(head -c 1000 /dev/random | sha1sum | cut -b 1-16) -N INCREMENT -o nsdcourse.xyz -t db.nsdcourse.xyz

echo ">>> Riavvio BIND..."
service named restart

echo ">>> COMPLETATO! DNSSEC e HTTP attivi."
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
##!/usr/bin/env bash
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
!  rotta verso DMZ per poterla annunciare via BGP
ip route 2.80.200.0/24 10.0.200.2
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

mkdir -p /etc/swanctl/conf.d

cat > /etc/swanctl/conf.d/ipsec.conf <<'EndFile'
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
EndFile

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
#!/bin/bash
set -euo pipefail

mkdir -p /etc/swanctl/conf.d

cat > /etc/swanctl/conf.d/ipsec.conf <<'EOF2'
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
EOF2

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



cat > ipsec/R202.sh <<'EOF'
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
#!/bin/bash

# LAN interface
LAN_IF=eth0

# MACsec interface
MACSEC_IF=macsec0

# IP LAN
IP_ADDR=192.168.20.1/24

# MKA keys
CAK=00112233445566778899aabbccddeeff
CKN=000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f

# MACsec config
cat > macsec.conf <<'EOF2'
eapol_version=3
ap_scan=0
network={
  key_mgmt=NONE
  eapol_flags=0
  macsec_policy=1
  mka_cak=$CAK
  mka_ckn=$CKN
  mka_priority=16
}
EOF2

# Start MKA
wpa_supplicant -i $LAN_IF -B -Dmacsec_linux -c macsec.conf
sleep 2
# Move IP to MACsec
ip addr del $IP_ADDR dev $LAN_IF
ip addr add $IP_ADDR dev $MACSEC_IF
ip link set $MACSEC_IF up

EOF


cat > macsec/mka_b1.sh <<'EOF'
#!/bin/bash

LAN_IF=eth0
MACSEC_IF=macsec0
IP_ADDR=192.168.20.10/24
GW=192.168.20.1

CAK=00112233445566778899aabbccddeeff
CKN=000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f

cat > macsec.conf <<'EOF2'
eapol_version=3
ap_scan=0
network={
  key_mgmt=NONE
  eapol_flags=0
  macsec_policy=1
  mka_cak=$CAK
  mka_ckn=$CKN
  mka_priority=255
}
EOF2

wpa_supplicant -i $LAN_IF -B -Dmacsec_linux -c macsec.conf
sleep 2
ip addr del $IP_ADDR dev $LAN_IF
ip addr add $IP_ADDR dev $MACSEC_IF
ip link set $MACSEC_IF up

ip route add default via $GW dev $MACSEC_IF
EOF


cat > macsec/mka_b2.sh <<'EOF'
#!/bin/bash

LAN_IF=eth0
MACSEC_IF=macsec0
IP_ADDR=192.168.20.11/24
GW=192.168.20.1

CAK=00112233445566778899aabbccddeeff
CKN=000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f

cat > macsec.conf <<'EOF2'
eapol_version=3
ap_scan=0
network={
  key_mgmt=NONE
  eapol_flags=0
  macsec_policy=1
  mka_cak=$CAK
  mka_ckn=$CKN
  mka_priority=255
}
EOF2

wpa_supplicant -i $LAN_IF -B -Dmacsec_linux -c macsec.conf
sleep 2
ip addr del $IP_ADDR dev $LAN_IF
ip addr add $IP_ADDR dev $MACSEC_IF
ip link set $MACSEC_IF up

ip route add default via $GW dev $MACSEC_IF
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
# 1. Abilita il forwarding (fondamentale)
sysctl -w net.ipv4.ip_forward=1

# 2. Pulisci tutte le regole vecchie
iptables -F
iptables -X
iptables -t nat -F

# 3. Imposta la Policy di Default: BLOCCA TUTTO (tranne l'uscita dal router stesso)
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# --- CHAIN INPUT (Traffico diretto AL router GW200) ---
# Accetta traffico locale (loopback)
iptables -A INPUT -i lo -j ACCEPT
# Accetta risposte a connessioni fatte dal router stesso o giÃ  stabilite
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
# Accetta Ping solo dall'interno per debug
iptables -A INPUT -i eth1 -p icmp -j ACCEPT

# --- CHAIN FORWARD (Traffico che ATTRAVERSA GW200) ---

# REGOLA 0: Stateful Inspection (FONDAMENTALE)
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# REGOLA 1: LAN-Client (LAN2) verso Internet
# Requisito: "LAN-client can access... only if originated by it"
# La LAN2 arriva da eth1 e vuole uscire su eth0
iptables -A FORWARD -i eth1 -o eth0 -s 10.200.2.0/24 -j ACCEPT


# REGOLA 2: Internet verso DNS Server (DMZ)
# Requisito: "DNS requests" e "HTTP traffic" verso DNS-server
iptables -A FORWARD -i eth0 -d 2.80.200.3 -p udp --dport 53 -j ACCEPT
iptables -A FORWARD -i eth0 -d 2.80.200.3 -p tcp --dport 53 -j ACCEPT
iptables -A FORWARD -i eth0 -d 2.80.200.3 -p tcp --dport 80 -j ACCEPT

# REGOLA 3: Internet verso eFW (VPN IPsec)
# Requisito: "IPSEC traffic to eFW" (2.80.200.2)
# Serve per far passare il tunnel Site-to-Site tra R202 e eFW
iptables -A FORWARD -i eth0 -d 2.80.200.2 -p udp --dport 500 -j ACCEPT
iptables -A FORWARD -i eth0 -d 2.80.200.2 -p udp --dport 4500 -j ACCEPT
iptables -A FORWARD -i eth0 -d 2.80.200.2 -p esp -j ACCEPT

# Lascia uscire la DMZ per aggiornamenti (es. eFW o DNS devono scaricare pacchetti)
iptables -A FORWARD -i eth1 -o eth0 -s 2.80.200.0/24 -j ACCEPT


# --- NAT (Masquerade) ---
# Permette agli indirizzi privati di navigare mascherandosi dietro l'IP pubblico di GW200
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

echo "Firewall GW200 applicato."
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
  # Accetta connessioni gia stabilite (es. aggiornamenti del firewall stesso)
  iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
 
  # REGOLA VPN: Accetta traffico IPsec in ingresso (da Internet/GW200)
  # Serve per far salire il tunnel con R202
  iptables -A INPUT -p udp --dport 500 -j ACCEPT # serve per IKE
  iptables -A INPUT -p udp --dport 4500 -j ACCEPT # serve per traffico mescolato con NAT
  iptables -A INPUT -p esp -j ACCEPT # accetta traffico ESP
 
  # (Opzionale) SSH/Ping dalla DMZ (management)
  iptables -A INPUT -s 2.80.200.0/24 -p icmp -j ACCEPT
 
  # ===============================
  # CHAIN FORWARD (Traffico che passa attraverso)
  # ===============================
  iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
 
  # REGOLA 1: LAN-Client (LAN2) verso Internet
  # La LAN2 arriva da eth1 (via iFW).
  # Deve poter andare ovunque.
  iptables -A FORWARD -i eth1 -o eth0 -s 10.200.2.0/24 -j ACCEPT
  iptables -A FORWARD -i eth0 -o eth1 -d 10.200.2.0/24 -j ACCEPT
 
  # REGOLA 2: Antivirus (LAN1) verso Central Node (LAN3)
  # Gli AV possono parlare SOLO con la rete del Central Node
  iptables -A FORWARD -s 10.200.1.0/24 -d 10.202.3.0/24 -j ACCEPT
 
  # REGOLA 3: Central Node (LAN3) verso Antivirus (LAN1)
  # Permette al Central Node di iniziare connessioni verso gli AV
  iptables -A FORWARD -s 10.202.3.0/24 -d 10.200.1.0/24 -j ACCEPT
  # Permetti il traffico in uscita verso il Central Node
 
  echo "Firewall eFW configurato."
  iptables -L -v -n
EOF



cat > firewall/ifw.sh <<'EOF'
#!/bin/bash
echo "--- Configurazione Firewall iFW ---"

# 1. Abilita il forwarding
sysctl -w net.ipv4.ip_forward=1

# 2. Pulizia regole
# -F = Flush
# -X = Delete chain
# -t = Table (non huardare quella di default)
iptables -F
iptables -X
iptables -t nat -F

# 3. Policy di Default: DROP
# -P = cosa deve fare il firewall quando un pacchetto
# non corrisponde a nessuna delle regole specifiche che hai scritto
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# ================================
# CHAIN INPUT (Traffico diretto a iFW)
# ================================
# -A = append
# -i = interface (specifica da quale scheda di rete deve provenire il pacchetto)
# -j = jump (definisce azione da intraprendere se il pacche corrisponde ai criteri)
# -m state --state= Match (controlla se il pacchetto fa parte di una connessione gia inizializzata)
# -p = protocol (quale protocollo di comunicazione sto filtrando)
# -s = Source (chi ha inviato il pacchetto)
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
# Ping dai router vicini per test
iptables -A INPUT -p icmp -j ACCEPT

# ================================
# CHAIN FORWARD (Traffico che attraversa iFW)
# ================================
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# REGOLA 1: LAN-Client (LAN2) verso OVUNQUE
# La LAN2 è "trusted". Può andare su Internet e verso la DMZ.
iptables -A FORWARD -s 10.200.2.0/24 -j ACCEPT

# REGOLA 2: Antivirus (LAN1) verso Central Node (VPN)
# Permettiamo al traffico AV di passare SOLO se è diretto al Central Node
iptables -A FORWARD -s 10.200.1.0/24 -d 10.202.3.0/24 -j ACCEPT

# REGOLA 3: Antivirus (LAN1) verso LAN2 (Client) -> BLOCCO ESPLICITO
# (Non servirebbe perché c'è il Default DROP, ma lo mettiamo per sicurezza/log)
# Nessuna regola permette 10.200.1.x -> 10.200.2.x

echo "Firewall iFW configurato."

iptables -L -v -n
EOF


##########################################

cat > av/av1.sh <<'EOF'
#!/bin/bash
# service_av.sh - ClamAV Listener Daemon
CENTRAL_NODE_IP="10.202.3.10" # Sostituisci con IP vero del Central Node
sleep 20
echo "[AV1] setup"
# 1. Collega al Proxy
export http_proxy=http://10.202.3.10:8888
export https_proxy=http://10.202.3.10:8888


# 2. Installa
apt-get update
apt-get install -y clamav netcat

# 3. Pulisci (Hardening locale)
unset http_proxy
unset https_proxy
echo "[AV1] setup completed"

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
# service_av.sh - YARA Listener Daemon
CENTRAL_NODE_IP="10.202.3.10"

sleep 20

echo "[AV2] setup"
# 1. Collega al Proxy
export http_proxy=http://10.202.3.10:8888
export https_proxy=http://10.202.3.10:8888


# 2. Installa
apt-get update
apt-get install -y yara netcat

# 3. Pulisci
unset http_proxy
unset https_proxy

echo "[AV2] setup completed"


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

cat > av/av3.sh <<'EOF'
#!/bin/bash
#v3.sh - STRACE Listener Daemon (Sandbox)
CENTRAL_NODE_IP="10.202.3.10"
sleep 20

# 1. Collega al Proxy
export http_proxy=http://10.202.3.10:8888
export https_proxy=http://10.202.3.10:8888

# 2. Installa
apt-get update
apt-get install -y strace netcat



# 3. Pulisci
unset http_proxy
unset https_proxy



echo "[AV3] SANDBOX Service avviato in ascolto sulla porta 9000..."

# Assicuriamoci che strace sia installato (controllo opzionale ma utile)
if ! command -v strace &> /dev/null; then
    echo "Errore: strace non trovato!"
    exit 1
fi

while true; do
    # 1. Pulizia preventiva (uguale al tuo script yara)
    rm -f binary report.txt

    # 2. Ricezione File
    nc -l -p 9000 > binary

    # Controllo se il file è arrivato davvero
    if [ -s binary ]; then
        echo "[AV3] File ricevuto. Avvio esecuzione sandbox..."

        # --- PASSAGGIO CRUCIALE ---
        # Per far funzionare strace, il file DEVE essere eseguibile
        chmod +x binary

        echo "--- REPORT AV3 (STRACE DYNAMIC ANALYSIS) ---" > report.txt
        date >> report.txt

        # 3. Esecuzione con Strace
        # timeout 5s: ferma il virus dopo 5 secondi
        # -f: segue i processi figli
        # ./binary: esegue il file scaricato
        # 2>&1: cattura l'output di strace (che normalmente va su stderr)
        timeout 5s strace -f -e trace=openat,connect,execve,unlink ./binary >> report.txt 2>&1
    else
        echo "[AV3] Errore: File ricevuto vuoto o non valido." > report.txt
    fi

    # 4. Invio Report indietro (sulla porta 9003 per AV3)
    nc -w 2 $CENTRAL_NODE_IP 9003 < report.txt

    echo "[AV3] Ciclo completato."
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

echo "STOPPING PROXY BEFORE ANALISYS"
service tinyproxy stop

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
echo ">>> REPORT AV3 (Strace):"
cat report_av3.txt

echo "=============================================="
echo "Analisi completata."

service tinyproxy restart

EOF
###############################






cat >nat/config.sh << 'EOF'
# 1. Rimuovi il default gateway attuale (quello interno)
ip route del default

# 2. Aggiungi il NUOVO default gateway verso Internet (NAT)
# (Uso l'IP che ho visto nel tuo log dhclient: 192.168.122.1)
ip route add default via 192.168.122.1 dev eth1

# 3. [FONDAMENTALE] Riaggiungi la rotta per la rete interna
# Diciamo: "Tutto ciò che inizia con 10.x.x.x mandalo al router interno (eth0)"
# Sostituisci 10.202.3.1 con l'IP del tuo router interno se diverso
ip route add 10.0.0.0/8 via 10.202.3.1 dev eth0


# Metti il DNS di Google per l'installazione
echo "nameserver 8.8.8.8" > /etc/resolv.conf

apt-get update
apt-get install -y tinyproxy


# Aggiungi "Allow 10.0.0.0/8" alla configurazione
sed -i '/^Allow 127\.0\.0\.1/a Allow 10.0.0.0/8' /etc/tinyproxy/tinyproxy.conf

# Riavvia il servizio
service tinyproxy restart
EOF

chmod +x setup/*.sh routing/*.sh macsec/*.sh dns/*.sh  ipsec/*.sh firewall/*.sh av/*.sh
echo "OK: creati setup/ e routing/. Ora esegui gli script dentro i nodi GNS3."





