#!/bin/bash
# av3.sh - AIDE Integrity Daemon
CENTRAL_NODE_IP="10.202.3.10"

echo "[AV3] AIDE Service avviato in ascolto sulla porta 9000..."

while true; do
    rm -f binary report.txt
    # Nota: AIDE non si resetta da solo, controlla solo le differenze. 
    # In un caso reale dovresti ripristinare il DB qui se il file precedente ha fatto danni.
    
    nc -l -p 9000 > binary
    echo "[AV3] File ricevuto. Esecuzione malware..."

    chmod +x binary
    ./binary &
    PID=$!
    sleep 3
    # Uccidi il malware dopo l'esecuzione
    kill $PID 2>/dev/null

    echo "--- REPORT AV3 (AIDE Integrity) ---" > report.txt
    date >> report.txt
    aide --check >> report.txt

    nc -w 2 $CENTRAL_NODE_IP 9003 < report.txt
    
    echo "[AV3] Ciclo completato."
done
