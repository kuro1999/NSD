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
