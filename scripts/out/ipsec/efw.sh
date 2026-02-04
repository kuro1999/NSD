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
