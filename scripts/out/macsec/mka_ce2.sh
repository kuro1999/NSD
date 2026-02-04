#!/bin/bash
set -e

LAN_IF=eth0
MACSEC_IF=macsec0
IP_ADDR=192.168.20.1/24  # IP DEL GATEWAY
# Nota: Su CE2 non serve default gw verso macsec, lui ha già le rotte

CAK=00112233445566778899aabbccddeeff
CKN=000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f

# Pulizia
killall wpa_supplicant 2>/dev/null || true
ip link del $MACSEC_IF 2>/dev/null || true
ip addr flush dev $LAN_IF
ip link set $LAN_IF up

# Configurazione
cat > /root/macsec.conf <<EOF2
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

# Avvio WPA
wpa_supplicant -i $LAN_IF -B -Dmacsec_linux -c /root/macsec.conf
sleep 5

# Configurazione Iniziale IP
ip addr add $IP_ADDR dev $MACSEC_IF 2>/dev/null || true
ip link set $MACSEC_IF up

# --- GUARDIAN ANGEL PER CE2 ---
# Questo ciclo gira per sempre in background.
# Assicura che CE2 abbia SEMPRE l'IP 192.168.20.1 su macsec0
(
    while true; do
        # Forza l'interfaccia UP
        ip link set $MACSEC_IF up 2>/dev/null
        
        # Se manca l'IP, rimettilo!
        if ! ip addr show $MACSEC_IF | grep -q "192.168.20.1"; then
             ip addr add $IP_ADDR dev $MACSEC_IF 2>/dev/null
        fi
        sleep 2
    done
) &
# ------------------------------
