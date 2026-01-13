#!/bin/bash
#av1.sh - ClamAV Listener Daemon
CENTRAL_NODE_IP="10.202.3.10" # Sostituisci con IP vero del Central Node

echo "[AV1] ClamAV Service avviato in ascolto sulla porta 9000..."

while true; do
    # 1. Pulizia preventiva (Clean State)
    rm -f binary report.txt
    
    # 2. Attesa ricezione (Bloccante finché non arriva qualcosa)
    nc -l -p 9000 > binary
    echo "[AV1] File ricevuto. Avvio scansione..."

    # 3. Scansione ClamAV
    echo "--- REPORT AV1 (ClamAV) ---" > report.txt
    date >> report.txt
    clamscan binary >> report.txt

    # 4. Invio Report al Central Node
    echo "[AV1] Invio report..."
    nc -w 2 $CENTRAL_NODE_IP 9001 < report.txt
    
    echo "[AV1] Ciclo completato. In attesa del prossimo file."
    echo "----------------------------------------------------"
done
