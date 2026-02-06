#!/usr/bin/env bash
set -euo pipefail

# IPsec R202 <-> eFW (LAN3 <-> LAN1)

write_file "$OUT/ipsec/r202.sh" <<'EOF'


mkdir -p /etc/swanctl/conf.d
#!/bin/bash
set -euo pipefail

echo ">>> Arresto forzato StrongSwan..."
service ipsec stop || true
service strongswan stop || true

killall -9 charonstarter charon ipsec starter 2>/dev/null || true
rm -f /var/run/starter.charon.pid
sleep 2

rm -f /var/run/charon.pid


echo ">>> Configurazione IPsec (Swanctl) su R202..."

cat > /etc/swanctl/conf.d/ipsec.conf <<CONF
connections {
  r202-efw {
    local_addrs  = 2.0.202.2
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
        local_ts  = 10.202.3.0/24
        remote_ts = 10.200.1.0/24

        # MATCH CON EFW 
        esp_proposals = aes128-sha256-modp2048
      }
    }
  }
}

secrets {
  ike-psk {
    id-1 = r202
    id-2 = efw
    secret = "nsd-r202-efw-psk-2026"
  }
}
CONF

echo ">>> Avvio Pulito StrongSwan su R202..."
/usr/lib/ipsec/starter --daemon charon || /usr/sbin/ipsec start
sleep 3

echo ">>> Caricamento credenziali..."
swanctl --load-creds
swanctl --load-conns

echo ">>> Tentativo di avvio connessione..."
swanctl --initiate --child lan-lan

echo ">>> Stato Tunnel:"
swanctl --list-sas
EOF

write_file "$OUT/ipsec/efw.sh" <<'EOF'
EFW:



#!/bin/bash
set -euo pipefail

# 1. Pulizia Totale processi precedenti
echo ">>> Arresto forzato StrongSwan..."
service ipsec stop || true
service strongswan stop || true
killall charon 2>/dev/null || true
rm -f /var/run/charon.pid

mkdir -p /etc/swanctl/conf.d

echo ">>> Configurazione IPsec (Swanctl) su eFW..."

# 2. Configurazione con fallback di compatibilità
cat > /etc/swanctl/conf.d/ipsec.conf <<CONF
connections {
  efw-r202 {
    local_addrs  = 2.80.200.2
    remote_addrs = 2.0.202.2

    version = 2
    mobike = no

    # Manteniamo encap yes per sicurezza
    encap = yes

    local {
      auth = psk
      id = efw
    }
    remote {
      auth = psk
      id = r202
    }

    proposals = aes128-sha256-modp2048

    children {
      lan-lan {
        local_ts  = 10.200.1.0/24
        remote_ts = 10.202.3.0/24

        # Anche qui diamo doppia opzione
        esp_proposals = aes128-sha256-modp2048
      }
    }
  }
}

secrets {
  ike-psk {
    id-1 = efw
    id-2 = r202
    secret = "nsd-r202-efw-psk-2026"
  }
}
CONF

echo ">>> Avvio Pulito StrongSwan su eFW..."
# Usiamo ipsec start diretto per evitare problemi con script di init vecchi
/usr/lib/ipsec/starter --daemon charon || /usr/sbin/ipsec start
sleep 3

echo ">>> Caricamento credenziali..."
swanctl --load-creds
swanctl --load-conns

echo ">>> In attesa di connessione..."
# Monitoriamo i log in tempo reale per vedere l'errore se capita
swanctl --list-sas
EOF
