#!/bin/bash
#av2.sh - YARA Listener Daemon
CENTRAL_NODE_IP="10.202.3.10"

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
