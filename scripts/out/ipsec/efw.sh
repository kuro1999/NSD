
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

    # PROPOSTA MULTIPLA:
    # 1. Quella che vogliamo (AES128 + SHA256 + MODP2048)
    # 2. Fallback compatibilità (AES128 + SHA1 + MODP1024)
    proposals = aes128-sha256-modp2048,aes128-sha1-modp1024

    children {
      lan-lan {
        local_ts  = 10.200.1.0/24
        remote_ts = 10.202.3.0/24

        # Anche qui diamo doppia opzione
        esp_proposals = aes128-sha256-modp2048,aes128-sha1-modp1024
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
