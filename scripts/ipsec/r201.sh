
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

