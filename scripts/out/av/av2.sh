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

    rm -f binary report.txt
    echo "[AV2] Ciclo completato."
done
