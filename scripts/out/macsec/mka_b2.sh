#!/bin/bash

LAN_IF=eth0
MACSEC_IF=macsec0
IP_ADDR=192.168.20.11/24
GW=192.168.20.1

CAK=00112233445566778899aabbccddeeff
CKN=000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f


# 1. Pulizia preventiva
killall wpa_supplicant 2>/dev/null
ip link del $MACSEC_IF 2>/dev/null
ip addr flush dev $LAN_IF
ip link set $LAN_IF up

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

wpa_supplicant -i $LAN_IF -B -Dmacsec_linux -c /root/macsec.conf
sleep 5
ip addr del $IP_ADDR dev $LAN_IF
ip addr add $IP_ADDR dev $MACSEC_IF
ip link set $MACSEC_IF up
sleep 1
ip route del default 2>/dev/null || true
ip route add default via $GW dev $MACSEC_IF
