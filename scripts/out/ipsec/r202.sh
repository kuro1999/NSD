
#!/bin/bash
set -euo pipefail

echo ">>> Arresto forzato StrongSwan..."
service ipsec stop || true
service strongswan stop || true
killall charon 2>/dev/null || true
rm -f /var/run/charon.pid

mkdir -p /etc/swanctl/conf.d

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

    # MATCH CON EFW (Doppia Opzione)
    proposals = aes128-sha256-modp2048,aes128-sha1-modp1024

    children {
      lan-lan {
        local_ts  = 10.202.3.0/24
        remote_ts = 10.200.1.0/24

        # MATCH CON EFW (Doppia Opzione)
        esp_proposals = aes128-sha256-modp2048,aes128-sha1-modp1024
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
